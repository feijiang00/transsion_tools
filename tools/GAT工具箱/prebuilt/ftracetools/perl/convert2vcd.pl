#!/usr/bin/perl -s
# Copyright Statement:
# 
# This software/firmware and related documentation ("MediaTek Software") are
# protected under relevant copyright laws. The information contained herein is
# confidential and proprietary to MediaTek Inc. and/or its licensors. Without
# the prior written permission of MediaTek inc. and/or its licensors, any
# reproduction, modification, use or disclosure of MediaTek Software, and
# information contained herein, in whole or in part, shall be strictly
# prohibited.
# 
# MediaTek Inc. (C) 2010. All rights reserved.
# 
# BY OPENING THIS FILE, RECEIVER HEREBY UNEQUIVOCALLY ACKNOWLEDGES AND AGREES
# THAT THE SOFTWARE/FIRMWARE AND ITS DOCUMENTATIONS ("MEDIATEK SOFTWARE")
# RECEIVED FROM MEDIATEK AND/OR ITS REPRESENTATIVES ARE PROVIDED TO RECEIVER
# ON AN "AS-IS" BASIS ONLY. MEDIATEK EXPRESSLY DISCLAIMS ANY AND ALL
# WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR
# NONINFRINGEMENT. NEITHER DOES MEDIATEK PROVIDE ANY WARRANTY WHATSOEVER WITH
# RESPECT TO THE SOFTWARE OF ANY THIRD PARTY WHICH MAY BE USED BY,
# INCORPORATED IN, OR SUPPLIED WITH THE MEDIATEK SOFTWARE, AND RECEIVER AGREES
# TO LOOK ONLY TO SUCH THIRD PARTY FOR ANY WARRANTY CLAIM RELATING THERETO.
# RECEIVER EXPRESSLY ACKNOWLEDGES THAT IT IS RECEIVER'S SOLE RESPONSIBILITY TO
# OBTAIN FROM ANY THIRD PARTY ALL PROPER LICENSES CONTAINED IN MEDIATEK
# SOFTWARE. MEDIATEK SHALL ALSO NOT BE RESPONSIBLE FOR ANY MEDIATEK SOFTWARE
# RELEASES MADE TO RECEIVER'S SPECIFICATION OR TO CONFORM TO A PARTICULAR
# STANDARD OR OPEN FORUM. RECEIVER'S SOLE AND EXCLUSIVE REMEDY AND MEDIATEK'S
# ENTIRE AND CUMULATIVE LIABILITY WITH RESPECT TO THE MEDIATEK SOFTWARE
# RELEASED HEREUNDER WILL BE, AT MEDIATEK'S OPTION, TO REVISE OR REPLACE THE
# MEDIATEK SOFTWARE AT ISSUE, OR REFUND ANY SOFTWARE LICENSE FEES OR SERVICE
# CHARGE PAID BY RECEIVER TO MEDIATEK FOR SUCH MEDIATEK SOFTWARE AT ISSUE.
# 
# The following software/firmware and/or related documentation ("MediaTek
# Software") have been modified by MediaTek Inc. All revisions are subject to
# any receiver's applicable license agreements with MediaTek Inc.

# author: mtk04259
#   convert trace file to vcd for gtkwave visualization
#
# 2014/04/01    add irq_{entry,exit} events
#
# 2014/03/10    provide more info about ipi/irq events unpair problem
#               skip those unpair events automiatically
#
# 2013/07/26    adjust the ftrace trimming algorithm
#               once cpu_hotplug events are available, trim to the latest timestamp of the following events
#               1) CPU0's 1st event
#               2) if the 1st event of the other CPU is online event, the last offline timestamp
#               3) timestamp of 1st event if the 1st event of the other CPUs is not online event
#               
# 2013/06/24    reset all waves to sleep when ftrace is disabled
#               add cpu online/offline handling
#
# 2013/04/26    unhandled irq handler events handling
#
# 2013/02/25    redesign to handle irq/softirq events more smoothly
#               enqueue 'proc-$pid-$prio', 'irq-$irq', and 'softirq-$softirq' into exec_stack[$cpu] to track
#               which is executing now
#               record prio additionally from ftrace_cputime.pl to dispict
#
# 2013/02/22    support softirq events
#               softirq_raise as waking up softirq handler
#               softirq_entry/softirq_exit as entry and exit of the softirq handler
#
# 2013/02/19    detect nested interrupts
#               able to handle trace file with irq-info
#
# 2013/01/02    read from stdin and output to stdout if input file not exist
#               for the purpose of redirecting input/output
#
# 2012/12/07    align to the first CPU0 event
#               because of the ring-buffer architecture and CPUs but CPU0 will be hotplugged when system loading not heavy
#               Ftrace may keep events on CPUx long ago (except CPU0)
#               get rid of those events to avoid confusing
#               error handling for invalid input
# 
# 2012/10/23    enhanced with I/O waiting visualization with '-' yellow color
#               fine-tune the task migration between cores
#
# 2012/09/05    first version   
#
# -- irq-info comment --
#                              _-----=> irqs-off
#                             / _----=> need-resched
#                            | / _---=> hardirq/softirq
#                            || / _--=> preempt-depth
#                            ||| /     delay
#         <idle>-0     [002] d..2 15696.184022: irq_handler_entry: irq=1 name=IPI_CPU_START
# 
# irqs-off: d for IRQS_OFF, X for IRQS_NOSUPPORT, . otherwise
# need-resched: N for need_resched
# hardirq/softirq: H for TRACE_FLAG_HARDIRQ & TRACE_FLAG_SOFTIRQ both on, h for hardirq, s for softirq
# preempt-depth: preempt_count
# 
# save:  tracing_generic_entry_update() in kernel/trace/trace.c
# print: trace_print_context() in kernel/trace/trace_output.c

use strict;
use warnings;
use vars qw($h $c);

BEGIN {
    my $is_linux = $^O =~ /linux/;
    eval <<'USE_LIB' if($is_linux);
        use FindBin;
        use lib "$FindBin::Bin/lib/mediatek/";
USE_LIB
    eval 'use ftrace_parsing_utils;';
}

my $version = "2014-04-01";
my (%proc_table, %irq_table, %tag_table, $first_timestamp, %softirq_table, @exec_stack, @irq_count);
my $script_name = &_basename($0);

# fix process name of idle/init process
sub fix_cmd{
    (my $proc, my $pid) = @_;
    if(!defined($pid) || ($pid>1)){
        $proc =~ s/\W+/_/g;
        return $proc;
    }elsif($pid == 0){
        return "<idle>";
    }elsif($pid == 1){
        return "init";
    }
}

# determine the character for the process about to schedule out 
# by (1) its priority (2) its state
sub from_proc_char{
    my ($prio, $state) = @_;

    if(index($state, 'R') != -1){
        # schedule out due to preemption
        if($prio < 100){
            return 'L';
        }else{
            return '0'
        }
    }elsif(index($state, 'd') != -1){
        # schedule out due to I/O
        return '-';
    }else{
        # schedule out to sleep/mutex wait/exit
        if($prio < 100){
            return 'W';
        }else{
            return 'Z'
        }
    }

}

# determine the end character of the process about to schedule in
# by its priority
sub to_proc_char{
    local $_ = $_[0];

    if($_ < 100){
        return 'H';
    }else{
        return '1';
    }
}

# generate process tag for gtkwave
sub gentag{
    (local $_) = @_;
    my $ret;
    do{
        $ret .= chr(($_ % 93) +34);
        $_ = int($_ / 93);
    }while($_ > 0);
    return $ret;
}

# set irq & idle process to runnable
sub cpu_online_str{
    local $_;
    my ($cpu) = (@_);
    my $output;

    for(grep {
            m/^(?:irq\-\d+|proc\-0)\-$cpu$/xs
        }keys %tag_table)
    {
        $output .= sprintf "0%s\n", $tag_table{$_};
    }
    return $output;
}

sub cpu_offline_str{
    local $_;
    my ($cpu) = (@_);
    my $output;

    # reset exec_stack
    while(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]})>0){
        pop @{$exec_stack[$cpu]};
    }

    # reset irq, softirq, & idle process
    for(grep {
            m/^(?:(?:soft)?irq\-\d+|proc\-0)\-$cpu$/s
        }keys %tag_table)
    {
            $output .= sprintf "Z%s\n", $tag_table{$_};
    }

    for(keys %proc_table){
        if(int($_) != 0 && exists $proc_table{$_}{cpu}
            && defined $proc_table{$_}{cpu} && 
            $cpu == $proc_table{$_}{cpu}
        ){

            if(exists $proc_table{$_}{state} and
                defined $proc_table{$_}{state} and 
                $proc_table{$_}{state} ne 'running')
            {
                $output .= sprintf "Z%s\n", $tag_table{"proc-$_-$proc_table{$_}{cpu}"};
                delete $proc_table{$_}{cpu};
                delete $proc_table{$_}{state};
            }
        }
    }
    return $output;
}

sub usage{
    print <<USAGE
Usage: $script_name <input_file> <output_file>
        convert ftrace into vcd format
        -h: show usage
        -c: console mode, input from stdin and output to stdout
USAGE
    ;
    exit 0;
}

# ------------
# collect 1) task cmd, highest priority, and cpus 2)irq/softirq id and cpus
# ------------
sub collect_runtime_info{
    local $_;
    my $ref = $_[0];
    my $event_count;

    for(@{$ref}){
        chomp;
        my ($cpu, $pid, $tgid);

        if(m/^.{16}\-(\d+)\s+
                (?:\(([\s\d-]{5})\)\s+)?
                \[(\d+)\]\s+
                (?:\S{4}\s+)?
                (\d+\.\d+)\:/xso)
        {
            ($pid, $cpu) = (int($1), int($3));
            if(!defined($first_timestamp) and $cpu == 0){
                $first_timestamp = $4;
                $first_timestamp =~ s/\.//;
                $first_timestamp = int($first_timestamp) - 1000;
            }
            if(defined $2){
                $tgid = $2;
                if($tgid =~ m/^\s*\d+$/o){
                    $proc_table{$pid}{tgid} = int($tgid);
                }
            }

        }else{
            # skip un-recognized strings
            #print "skip: $_\n";
            next;
        }

        if(m/\s
            sched_switch\:\s+
            prev_comm=(.+)\s
            prev_pid=(\d+)\s
            prev_prio=(\d+)\s
            prev_state=\S+\s
            ==>\s
            next_comm=(.+)\s
            next_pid=(\d+)\s
            next_prio=(\d+)
            /xso)
        {
            $proc_table{$2}{name} = $1;
            $proc_table{$2}{prio} = ($proc_table{$2}{prio} && $proc_table{$2}{prio} < $3)?$proc_table{$2}{prio}:$3;
            $proc_table{$2}{cpus} |= (1<<$cpu);
            $proc_table{$5}{name} = $4;
            $proc_table{$5}{prio} = ($proc_table{$5}{prio} && $proc_table{$5}{prio} < $6)?$proc_table{$5}{prio}:$6;
            $proc_table{$5}{cpus} |= (1<<$cpu);
            $event_count++;

        }elsif(m/\s
            sched_wakeup(?:_new)?\:\s+
            comm=(.+)\s
            pid=(\d+)\s
            prio=(\d+)\s
            success=1\s
            target_cpu=(\d+)
            /xso)
        {
            $proc_table{$2}{name} = $1;
            $proc_table{$2}{prio} = ($proc_table{$2}{prio} && $proc_table{$2}{prio}<$3)?$proc_table{$2}{prio}:$3;
            $proc_table{$2}{cpus} |= (1<<$4);
            $event_count++;
        }elsif(m/\s
            sched_migrate_task\:\s+
            comm=(.+)\s
            pid=(\d+)\s
            prio=(\d+)\s
            orig_cpu=(\d+)\s
            dest_cpu=(\d+)
            /xso)
        {
            $proc_table{$2}{name} = $1;
            $proc_table{$2}{prio} = ($proc_table{$2}{prio} && $proc_table{$2}{prio}<$3)?$proc_table{$2}{prio}:$3;
            $proc_table{$2}{cpus} |= (1<<$4 | 1<<$5);
            $event_count++;
        }elsif(m/\s
            (?:irq_handler_entry|ipi_handler_entry|irq_entry)\:\s+
            (?:irq|ipi)=(\d+)\s
            name=(.+)
            /xso)
        {
            $irq_table{"$1-$cpu"} = $2;
            $event_count++;

        }elsif(m/\s
            (?:irq_handler_exit|ipi_handler_exit|irq_exit)\:\s+
            /xso)
        {
            $event_count++;
        }elsif(m/\s
            softirq_raise\:\s+
            /xso)
        {
            $event_count ++;
        }elsif(m/\s
            softirq_entry\:\s+
            vec=(\d+)\s
            \[action=(.+)\]/xso)
        {
            $softirq_table{"$1-$cpu"} = $2;
            $event_count++;
        }elsif(m/\s
            softirq_exit\:\s+
            /xso){
            $event_count++;
        }
    }
    return $event_count;
}

sub print_vcd_header{
    local $_;
    my $fout = $_[0];
    my $i=0;

    printf $fout <<'HEADER', $version;
$version
    generated by convert2vcd ver %s
$end
$timescale 1us $end
$scope module sched_switch $end
HEADER
    for (sort {
        my ($airq, $acpu) = split /\-/, $a;
        my ($birq, $bcpu) = split /\-/, $b;
        return ($airq<=>$birq) || ($acpu<=>$bcpu);
        } 
        keys %irq_table)
    {
        my ($irq, $cpu) = split /\-/, $_;
        $tag_table{"irq-$_"} = &gentag($i++);
        printf $fout "\$var wire 1 %s 0-IRQ%s-%s[%03d]_nc=0 \$end\n", $tag_table{"irq-$_"}, $irq, &fix_cmd($irq_table{$_}), $cpu;
    }

    for (sort {
        my ($airq, $acpu) = split /\-/, $a;
        my ($birq, $bcpu) = split /\-/, $b;
        return ($airq<=>$birq) || ($acpu<=>$bcpu);
        } 
        keys %softirq_table)
    {
        my ($softirq, $cpu) = split /\-/, $_;
        $tag_table{"softirq-$_"} = &gentag($i++);
        printf $fout "\$var wire 1 %s 0-SOFTIRQ%s-%s[%03d]_nc=0 \$end\n", $tag_table{"softirq-$_"}, $softirq, &fix_cmd($softirq_table{$_}), $cpu;
    }

    for(sort {$a <=> $b} keys %proc_table){
        my $j=0;
        while($proc_table{$_}{cpus}>>$j){
            if($proc_table{$_}{cpus} & (1<<$j)){
                #$proc_table{$_}{"tag-$j"} = &gentag($i++);
                $tag_table{"proc-$_-$j"} = &gentag($i++);
                printf $fout "\$var wire 1 %s %s%d-%s[%03d]_%s=%d \$end\n",
                    $tag_table{"proc-$_-$j"},
                    (exists $proc_table{$_}{tgid}?
                        "$proc_table{$_}{tgid}-":""),
                    $_,
                    &fix_cmd($proc_table{$_}{name}, $_),
                    $j,
                    ($proc_table{$_}{prio}<100?q(RT):q(nc)),
                    ($proc_table{$_}{prio}<100?
                        (99-$proc_table{$_}{prio}):
                        ($proc_table{$_}{prio}-120));

                        #if($proc_table{$_}{prio} <100){
                        #    printf $fout "\$var wire 1 %s %d-%s[%03d]_RT=%d \$end\n",
                        #    $tag_table{"proc-$_-$j"},
                        #    $_,
                        #    &fix_cmd($proc_table{$_}{name}, $_),
                        #    $j,
                        #    99-$proc_table{$_}{prio};
                        #}else{
                        #    printf $fout "\$var wire 1 %s %d-%s[%03d]_nc=%d \$end\n",
                        #    $tag_table{"proc-$_-$j"},
                        #    $_,
                        #    &fix_cmd($proc_table{$_}{name}, $_),
                        #    $j,
                        #    $proc_table{$_}{prio}-120;
                        #}
                #print "$_: $proc_table{$_}{name}, $proc_table{$_}{prio}, $proc_table{$_}{\"tag-$j\"}";
                #printf ", [%d]\n", $j;
            }
            $j++;
        }
    }

    printf $fout <<'HEADER_END', $first_timestamp;
$upscope $end
$enddefinitions $end
#%d
HEADER_END
# initialize all processes
    for(my $j = 0; $j < $i; ++$j){
        print $fout "Z@{[&gentag($j)]}\n";
    }
}

# ------------
# main parsing subroutine
# ------------
sub parse {
    local $_;
    my $tracing_on = 1;
    my @cpu_online;
    my ($fout, $ref) = @_;
    my $nested_irq_warn_already = 0;
    my $output;

    for(@{$ref}){
        my ($curr_pid, $cpu, $timestamp);
        if((($curr_pid, $cpu, $timestamp) = m/^
                .{16}\-(\d+)\s+
                (?:\([\s\d-]{5}\)\s+)?
                \[(\d+)\]\s+
                (?:\S{4}\s+)?
                (\d+\.\d+)\:
                /xso)<3){
            # skip un-recognized strings
            next;
        }

        $timestamp =~ s/\.//go;
        $timestamp = int($timestamp);
        $cpu = int($cpu);
        $cpu_online[$cpu] = 1;

        # reset output string
        $output = undef;

# state characters used internally
#
# R:            running
# r:            runable
# w:            runable, and waked up from state not running or runnable
# m:            waiting for mutex
# d:            waiting for I/O
# s:            sleeping (including interruptible & uninterruptible state)
# (align with ftrace_cputime.pl to represent waking up as 'w'
        if(m/\s
            sched_switch\:\s+
            prev_comm=.+\s
            prev_pid=(\d+)\s
            prev_prio=(\d+)\s
            prev_state=(\S+)\s
            ==>\s
            next_comm=.+\s
            next_pid=(\d+)\s
            next_prio=(\d+)
            (?:\sextra_prev_state=(\S+))?
            /xso)
        {
            my ($prev_pid, $prev_prio, $prev_state, $next_pid, $next_prio) =
            ($1, $2, ((defined $6)?"$3|$6":$3), $4, $5);

            $output .= "#$timestamp\n";

            if($next_pid != 0 && defined($proc_table{$next_pid}{cpu}) &&
                ($proc_table{$next_pid}{cpu} ne $cpu) && defined($proc_table{$next_pid}{state}) &&
                (($proc_table{$next_pid}{state} eq 'waking' || $proc_table{$next_pid}{state} eq 'runable' || $proc_table{$next_pid}{state} eq 'io') ||
                    $next_prio < 100 # only RT process need to be reset to 'Z'
                )
            ){
                # handle migration
                # note: IDLE process DOESN'T migrate!!
                $output .= sprintf "%s%s\n",
                # $next_prio<100?"W":"Z",
                "Z",
                $tag_table{"proc-$next_pid-$proc_table{$next_pid}{cpu}"};
            }

            if(index($prev_state, 'R') != -1){
                $proc_table{$prev_pid}{state} = 'runable';
                #runable, but not running state
            }elsif(index($prev_state, 'd') != -1){
                $proc_table{$prev_pid}{state} = 'io';
                # d, i/o wait
            }else{
                $proc_table{$prev_pid}{state} = 'sleep'; # restored to "not assigned to cpu" state
            }
            $proc_table{$prev_pid}{cpu} = $cpu;
            $proc_table{$next_pid}{state} = 'running';   # running
            $proc_table{$next_pid}{cpu} = $cpu;

            # check which context we are in
            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                my ($type, $id, $prio) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)(?:\-(\d+))?$/o);

                #if($type eq 'proc' and $id == $prev_pid){
                #    # check pass
                #    pop @{$exec_stack[$cpu]};
                if($type eq 'proc' and $id != $prev_pid){
                    # should not parse anymore because it seems certain ftrace events lost
                    die "$script_name: scheduling event not matched, ts=$timestamp, proc_to_schedule_out=[$prev_pid:$proc_table{$prev_pid}{name}], proc_in_exec=[$id:$proc_table{$id}{name}]\n";
                }elsif($type eq 'softirq'){
                    # since softirq priority > process, the softirq_exit event must be lost
                    warn "$script_name: proc [$next_pid:$proc_table{$next_pid}] scheduling-in in softirq $id context or softirq event lost\n";
                    pop @{$exec_stack[$cpu]};
                }elsif($type eq 'irq'){
                    # since irq priority > process, the irq_handler_exit must be lost
                    warn "$script_name: proc [$next_pid:$proc_table{$next_pid}] scheduling-in in irq $id context or irq event lost\n";
                    pop @{$exec_stack[$cpu]};
                }else{
                    # warn "un-recognized exec_stack: ${$exec_stack[$cpu]}[-1]\n";
                    # or pass...
                    pop @{$exec_stack[$cpu]};
                }
            }
            push @{$exec_stack[$cpu]}, "proc-$next_pid-$next_prio";

            $output .= sprintf <<SCHED_SWITCH, &from_proc_char($prev_prio, $prev_state), $tag_table{"proc-$prev_pid-$cpu"}, to_proc_char($next_prio), $tag_table{"proc-$next_pid-$cpu"};
%s%s
%s%s
SCHED_SWITCH
            print $fout $output if(defined $output);
        }elsif(m/\s
            sched_wakeup(?:_new)?\:\s+
            comm=.+\s
            pid=(\d+)\s
            prio=(\d+)\s
            success=1\s
            target_cpu=(\d+)
            (?:\sstate=(\S+))?
            /xso)
        {
            my ($pid, $prio, $target_cpu) = ($1, $2, int($3));
            my $do_print = 0;

            if(!defined $cpu_online[$target_cpu] || $cpu_online[$target_cpu] == 0){
                # since the target cpu is not active, skip it
                # (maybe that cpu is running out of ring buffer or offline)
                next;
            }

            $output .= sprintf <<SCHED_WAKEUP;
#$timestamp
SCHED_WAKEUP

            # waked up on another cpu, we have to make it sleep on current cpu
            if(exists($proc_table{$pid}{cpu}) && ($proc_table{$pid}{cpu} ne $target_cpu) && 
                exists($proc_table{$pid}{state}) && 
                ($proc_table{$pid}{state} eq 'waking' || $proc_table{$pid}{state} eq 'runable' || $proc_table{$pid}{state} eq 'io' || $prio < 100)){
                # for process suddenly migrated to another core
                $output .= sprintf "Z%s\n", $tag_table{"proc-$pid-$proc_table{$pid}{cpu}"};
                $do_print = 1;
            }

            # waked up, give it the waking up string
            if(!exists $proc_table{$pid}{state} ||
                ($proc_table{$pid}{state} ne 'running' &&
                    $proc_table{$pid}{state} ne 'runable' &&
                    $proc_table{$pid}{state} ne 'waking')
                ){
                # only wake up tasks that are not running/runable/waking, otherwise this waking event is meaningless
                $proc_table{$pid}{state} = 'waking'; # waked up
                $proc_table{$pid}{cpu} = $target_cpu;
                $output .= sprintf "X%s\n", $tag_table{"proc-$pid-$target_cpu"};
                $do_print = 1;
            }
            print $fout $output if($do_print);

        }elsif(m/\s
            sched_migrate_task\:\s+
            comm=.+\s
            pid=(\d+)\s
            prio=(\d+)\s
            orig_cpu=(\d+)\s
            dest_cpu=(\d+)
            (?:\sstate=(\S+))?
            /xso)
        {
            my ($pid, $prio, $orig_cpu, $dest_cpu, $state) = ($1, $2, $3, $4, $5);
            $orig_cpu = int($orig_cpu);
            $dest_cpu = int($dest_cpu);

            if(!defined $cpu_online[$dest_cpu] || $cpu_online[$dest_cpu] == 0){
                # since the target cpu is not active, skip it
                # (maybe that cpu is running out of ring buffer or offline)
                next;
            }
            if(($orig_cpu != $dest_cpu) &&
                (defined($proc_table{$pid}{state}) || $prio < 100)){

                # end the line on the original cpu
                $output .= sprintf <<SCHED_MIGRATE_TASK, $tag_table{"proc-$pid-$orig_cpu"};
#$timestamp
Z%s
SCHED_MIGRATE_TASK
                if(defined $proc_table{$pid}{cpu} and ($proc_table{$pid}{cpu} ne $orig_cpu)){
                    $output .= sprintf "Z%s\n", $tag_table{"proc-$pid-$proc_table{$pid}{cpu}"};
                }

                if(defined($proc_table{$pid}{state})){
                    if($proc_table{$pid}{state} eq 'runable'){
                        if($prio < 100){
                            $output .= sprintf "L%s\n", $tag_table{"proc-$pid-$dest_cpu"};
                        }else{
                            $output .= sprintf "0%s\n", $tag_table{"proc-$pid-$dest_cpu"};
                        }
                    }elsif($proc_table{$pid}{state} eq 'waking'){
                        $output .= sprintf "X%s\n", $tag_table{"proc-$pid-$dest_cpu"};
                    }elsif($proc_table{$pid}{state} eq 'io'){
                        $output .= sprintf "-%s\n", $tag_table{"proc-$pid-$dest_cpu"};
                    }elsif($proc_table{$pid}{state} eq 'running'){
                        # migrate during running, which is weird
                        if($prio < 100){
                            $output .= sprintf "H%s\n", $tag_table{"proc-$pid-$dest_cpu"};
                        }else{
                            $output .= sprintf "1%s\n", $tag_table{"proc-$pid-$dest_cpu"};
                        }
                    }else{
                        if($prio < 100){
                            $output .= sprintf "W%s\n", $tag_table{"proc-$pid-$dest_cpu"};
                        }else{
                            $output .= sprintf "Z%s\n", $tag_table{"proc-$pid-$dest_cpu"};
                        }
                    }
                }
            }
            $proc_table{$pid}{cpu} = int($dest_cpu);
            print $fout $output if(defined $output);

        }elsif(m/\s
            (?:irq_handler_entry|ipi_handler_entry|irq_entry)\:\s+
            (?:irq|ipi)=(\d+)\s
            name=(.+)
            /xso)
        {
            no warnings 'uninitialized';

            my $irq = $1;
            my ($type, $id, $prio);

            if ($irq_count[$cpu]>0 && $nested_irq_warn_already == 0){
                my $last_irq = (&find_last_event($exec_stack[$cpu], qr!^irq\-!o) =~ m/^irq\-(\d+)/o);
                $nested_irq_warn_already++;
                warn "$script_name: nested irq handler detected, ts=$timestamp cpu=$cpu irq=[$irq:$2] in_irq=@{[ $last_irq || 'unknown' ]}";
            }
            $irq_count[$cpu]++;

            $output .= sprintf <<IRQ_HANDLER_ENTRY, $tag_table{"irq-$irq-$cpu"};
#$timestamp
1%s
IRQ_HANDLER_ENTRY

            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                ($type, $id, $prio) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)(?:\-(\d+))?$/o);
            }
            $output .= sprintf <<IRQ_HANDLER_ENTRY, &from_proc_char((defined($prio)?$prio:'120'), 'R'), $tag_table{"@{[defined($type)?$type:'proc']}-@{[defined($id)?$id:$curr_pid]}-$cpu"};
%s%s
IRQ_HANDLER_ENTRY
            push @{$exec_stack[$cpu]}, "irq-$irq";

            print $fout $output if(defined $output);

        }elsif(m/\s
            (?:irq_handler_exit|ipi_handler_exit|irq_exit)\:\s+
            (?:irq|ipi)=(\d+)
            (?:\sret=handled)?
            /xso)
        {

            my $irq = $1;
            $irq_count[$cpu]-- if(defined($irq_count[$cpu]) && $irq_count[$cpu] > 0);

            $output .= "#$timestamp\n";
            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                my ($type, $id, $prio) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)(?:\-(\d+))?$/o);

                if($type eq 'irq' and $id != $irq){
                    warn "$script_name: irq entry/exit event not matched, maybe irq event lost, ts=$timestamp, irq_to_exit=[$irq:$irq_table{\"$irq-$cpu\"}], in_irq=[$id:$irq_table{\"$id-$cpu\"}]\n";
                    pop @{$exec_stack[$cpu]};
                    $output .= sprintf "0%s\n", $tag_table{"irq-$id-$cpu"};
                }elsif($type eq 'softirq'){
                    # should not parse anymore because it seems certain ftrace events lost
                    warn "$script_name: irq entry event lost, ts=$timestamp, irq_to_exit=[$irq:$irq_table{\"$irq-$cpu\"}], softirq_in_exec=[$id:$softirq_table{\"$id-$cpu\"}]\n";
                    next;
                }elsif($type eq 'proc'){
                    warn "$script_name: irq entry event lost, ts=$timestamp, irq_to_exit=[$irq:$irq_table{\"$irq-$cpu\"}], proc_in_exec=[$id:$proc_table{$id}{name}]\n";
                    next;
                }else{
                    # warn "un-recognized exec_stack: ${$exec_stack[$cpu]}[-1]\n";
                    # or pass...
                    pop @{$exec_stack[$cpu]};
                }
            }

            $output .= sprintf "0%s\n", $tag_table{"irq-$irq-$cpu"};

            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                my ($type, $id, $prio) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)(?:\-(\d+))?$/o);
                if(!defined $prio && $type eq 'softirq'){
                    $prio = 120;
                }
                $output .= sprintf <<IRQ_HANDLER_EXIT, &to_proc_char($prio), $tag_table{"$type-$id-$cpu"};
%s%s
IRQ_HANDLER_EXIT
            }
            print $fout $output if(defined $output);
        }elsif(m/\s
            softirq_raise\:\s
            vec=(\d+)\s
            \[action=.+\]
            /xso)
        {
            $output .= sprintf <<SOFTIRQ_RAISE, $tag_table{"softirq-$1-$cpu"};
#$timestamp
X%s
SOFTIRQ_RAISE
            print $fout $output if(defined $output);
        }elsif(m/\s
            softirq_entry\:\s
            vec=(\d+)\s
            \[action=.+\]
            /xso)
        {

            my $softirq = $1;
            my ($type, $id, $prio);

            $output .= sprintf <<SOFTIRQ_ENTRY, $tag_table{"softirq-$softirq-$cpu"};
#$timestamp
1%s
SOFTIRQ_ENTRY

            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                ($type, $id, $prio) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)(?:\-(\d+))?$/o);
            }
            $output .= sprintf <<SOFTIRQ_ENTRY, &from_proc_char((defined($prio)?$prio:'120'), 'R'), $tag_table{"@{[defined($type)?$type:'proc']}-@{[defined($id)?$id:$curr_pid]}-$cpu"};
%s%s
SOFTIRQ_ENTRY
            push @{$exec_stack[$cpu]}, "softirq-$softirq";
            print $fout $output if(defined $output);

        }elsif(m/\s
            softirq_exit\:\s
            vec=(\d+)\s
            \[action=.+\]
            /xso)
        {
            my $softirq = $1;
            $output .= "#$timestamp\n";
            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                my ($type, $id, $prio) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)(?:\-(\d+))?$/o);
                if($type eq 'irq'){
                    warn "$script_name: irq exit event lost, ts=$timestamp, softirq_to_exit=[$softirq:$softirq_table{\"$softirq-$cpu\"}], irq_in_exec=[$id:$irq_table{\"$id-$cpu\"}]\n";
                    pop @{$exec_stack[$cpu]} ;
                    $output .= sprintf "Z%s\n", $tag_table{"irq-$id-$cpu"};
                }elsif($type eq 'softirq' and $id != $softirq){
                    # should not parse anymore because it seems certain ftrace events lost
                    warn "$script_name: softirq entry/exit event not matched, ts=$timestamp, softirq_to_exit=[$softirq:$softirq_table{\"$softirq-$cpu\"}], softirq_in_exec=[$id:$softirq_table{\"$softirq-$cpu\"}]\n";
                    $output .= sprintf "Z%s\n", $tag_table{"softirq-$id-$cpu"};
                }elsif($type eq 'proc'){
                    warn "$script_name: softirq entry event lost, ts=$timestamp, softirq_to_exit=[$softirq:$softirq_table{\"$softirq-$cpu\"}], proc_in_exec=[$id:$proc_table{$id}{name}]\n";
                    next;
                }else{
                    pop @{$exec_stack[$cpu]} ;
                }
            }

            $output .= sprintf <<SOFTIRQ_EXIT, $tag_table{"softirq-$softirq-$cpu"};
Z%s
SOFTIRQ_EXIT
            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                my ($type, $id, $prio) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)(?:\-(\d+))?$/o);
                #@print "timestamp = $timestamp, last exec=${$exec_stack[$cpu]}[-1]\n";
                $output .= sprintf <<SOFTIRQ_EXIT, to_proc_char(($type eq 'softirq')?120:$prio), $tag_table{"$type-@{[defined($id)?$id:$curr_pid]}-$cpu"};
%s%s
SOFTIRQ_EXIT
            }
            print $fout $output if(defined $output);
        }elsif(m/\s
            tracing_on\:\s
            ftrace\s is\s ((?:dis|en)abled)$
            /oxs)
        {
            my $enabled = $1;

            if($enabled eq 'disabled' && $tracing_on == 1){
                $tracing_on = 0;
                $output .= sprintf <<FTRACE_DISABLED;
#$timestamp
FTRACE_DISABLED
                for(my $j = 0; $j <= $#exec_stack ; ++$j){
                    $output .= &cpu_offline_str($j);
                }
            }elsif($enabled eq 'enabled' && $tracing_on == 0){
                $tracing_on = 1;
                $output = sprintf <<FTRACE_ENABLED;
#$timestamp
FTRACE_ENABLED

                for(my $j = 0; $j <= $#exec_stack ; ++$j){
                    $output .= &cpu_online_str($j);
                }
            }
            print $fout $output if(defined $output);
        }elsif(m/\s
            cpu_hotplug\:\s
            cpu=(\d+)\s
            state=(\w+)
            /oxs)
        {
            my $state = $2;
            my $cpu_id = int($1);

            if($state eq 'online'){
                $output = sprintf <<"CPU_ONLINE", &cpu_online_str($cpu_id);
#$timestamp
%s
CPU_ONLINE
            }elsif($state eq 'offline'){
                $cpu_online[$cpu_id] = 0;
                $output = sprintf <<"CPU_OFFLINE", &cpu_offline_str($cpu_id);
#$timestamp
%s
CPU_OFFLINE
            }

            print $fout $output if(defined $output);
        }elsif(m/\s
            unnamed_irq\:\s
            irq=(\d+)
            /oxs)
        {
            warn "$script_name: unknown irq=$1, ts=$timestamp\n";
        }
    }
}

# tag_table index: proc-<pid>-<cpu>, irq-<id>-<cpu>, softirq-<id>-<cpu>
# exec_stack value: proc-<pid>-<prio>, irq-<irq>, softirq-<irq>
sub main{
    my ($input_file, $output_file) = ($_[0]||"SYS_FTRACE", $_[1]||"trace.vcd");
    my ($fout, @inputs);
    my $event_count = 0;

    &usage() if($h);

    if(-e $input_file and !defined $c){
        warn "$script_name: input=$input_file, output=$output_file\n";
        open my $fin, '<', $input_file or die "$script_name: unable to open $input_file\n";
        @inputs = <$fin>;
        close $fin;
        open $fout, '>', $output_file or die "$script_name: unable to open $output_file\n";
    }else{
        warn "$script_name: $input_file not exist and read from stdin instead\n";
        @inputs = @{ &trim_events(<STDIN>) };
        open $fout, ">&=STDOUT" or die "$script_name: unable to alias STDOUT: $!\n"
    }

    $event_count = &collect_runtime_info(\@inputs);
    if($event_count == 0){
        die "$script_name: no recognized events, exit\n";
    }
    &print_vcd_header($fout);
    &parse($fout, \@inputs);
    close $fout;
}

&main(@ARGV);
