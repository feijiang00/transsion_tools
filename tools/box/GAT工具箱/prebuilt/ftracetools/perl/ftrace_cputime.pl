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
#   retrieve executing information of processes from ftrace trace
#   and ISR, softirq information if these events available
#   special processes appear on all cpus, ex: idle
#
# 2014/04/14    fix runable time not considering cpu offline problem
#
# 2014/04/01    add irq_{entry,exit} events
#
# 2014/03/10    workqueue events analysis
#
# 2013/07/26    adjust the ftrace trimming algorithm
#               once cpu_hotplug events are available, trim to the latest timestamp of the following events
#               1) CPU0's 1st event
#               2) if the 1st event of the other CPU is online event, the last offline timestamp
#               3) timestamp of 1st event if the 1st event of the other CPUs is not online event
#
# 2013/07/02    cpu hotplug support and track cpu offline duration
#
# 2013/06/24    reset all waves to sleep when ftrace is disabled
#               add cpu online/offline handling
#
# 2013/04/26    unhandled irq handler events handling
#
# 2013/04/15    add -w option to get the time from waked up to execute
#
# 2013/02/25    redesign to handle irq/softirq events more smoothly
#               enqueue 'proc-$pid', 'irq-$irq', and 'softirq-$softirq' into exec_stack to track
#               which is executing now
#
# 2013/02/23    support softirq events
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
# 2012/11/21    fix the problem of error counting exec time when 
#               ring buffer is extremely unbalanced
# 
# 2012/10/23    statistics info added, including:
#               priority setting
#               time in sleeping state
#               time in runqueue waiting
#               time in iowait
#               time in mutex waiting
#               more detailed info of IRQ handler
#
# 2012/09/05    first version   

use strict;
use vars qw($v $h $f $c $w $m $l);

BEGIN {
    my $is_linux = $^O =~ /linux/;
    eval <<'USE_LIB' if($is_linux);
        use FindBin;
        use lib "$FindBin::Bin/lib/mediatek/";
USE_LIB
    eval 'use ftrace_parsing_utils;';
}

my $version = "2014-04-01";
my (%proc_table, %irq_table, $verbose_fout, @cpu_table, %softirq_table, @softirq_count, @irq_count, @exec_stack, $tgid_support, %workqueue_table, $workqueue_support);
my %event_count ;                   # event_count collected events
my $script_name = &_basename($0);

sub verbose_printf{
    printf $verbose_fout @_ if(defined $v);
}

sub usage{
        print <<"USAGE" ;
Usage: $script_name <input_file> <output_file>
       -v=<filename>: verbose mode, dump the intervals of each events into file
       -f           : convert input into vcd without trimming events.
                      By default, this script will only convert events since first CPU0 event
       -c           : console mode, input from stdin and output to stdout
       -w           : wakeup time tracking mode, track all wakeup-to-exec time
       -m           : output max exec/runable/sleep/mutex/io duration and timestamp
                      and exec_count (count of task being scheduled to run)
       -l           : track process executing time on each cpu
USAGE
    exit 0;
}

my @proc_table_header = (
    qq(pid),
    qq(proc_name),
    qq(percent(%)),
    qq(ISR_time),
    qq{exec_time(excl. ISR)},
    qq(exec_max),
    qq(exec_max_ts),
    qq(exec_count),
    qq(first_event),
    qq(last_event),
    qq(active_duration),
    qq(runable_time),
    qq(runable_max),
    qq(runable_max_ts),
    qq(sleep_time),
    qq(sleep_max),
    qq(sleep_max_ts),
    qq(mutex_time),
    qq(mutex_max),
    qq(mutex_max_ts),
    qq(io_time),
    qq(io_max),
    qq(io_max_ts),
    qq(total_time),
    "",
    qq(priorities),
);

my @irq_table_header =(
    qq(IRQ NO),
    qq(CPU),
    qq(IRQ_name),
    qq(exec_time),
    qq(exec_max),
    qq(exec_count),
    qq(exec_max_ts),
);

my @softirq_table_header =(
    qq(SOFTIRQ NO),
    qq(CPU),
    qq(SOFTIRQ_name),
    qq(exec_time),
    qq(exec_max),
    qq(exec_count),
    qq(exec_max_ts),
    qq(wakeup_time),
    qq(wakeup_max),
    qq(wakeup_count),
    qq(wakeup_max_ts),
);

# combine a priority string & new priority into a new string
# priority string is series of kernel priority for each task,
# separated by ':', such as '1:2'
sub generate_numeric_priorities{
    my ($old_prio_str, $prio) = @_;
    local $_;

    if(grep {$_ == $prio} split(/\:/, $old_prio_str)){
        return $old_prio_str;
    }else{
        return "$old_prio_str:$prio";
    }
}

# state characters used internally
#
# R:            running
# r:            runable
# w:            runable, and waked up from state not running or runable
# m:            waiting for mutex
# d:            waiting for I/O
# s:            sleeping (including interruptible & uninterruptible state)
sub proc_state_str {
    local ($_) = @_;

    if(index($_, 'R') != -1){
        # runable but not waking
        return 'runable';
    }elsif(index($_, 'W') != -1){
        return 'waking';
    }elsif(index($_, 'd') != -1){
        return 'io';
    }elsif(index($_, 'r') != -1){
        return 'mutex';
    }elsif(index($_, 'm') != -1){
        return 'mutex';
    }else{
        return 'sleep'
    }
}

# convert kernel internal priority into nice value and real time and combine as a string
sub kernel_priority_to_string {
    my ($numeric_prio_str) = @_;
    local $_;
    #print "numeric_prio_str = $numeric_prio_str\n";
    if($numeric_prio_str =~ m/\d+(?:\:\d+)*/o){
        my @prios = map {
            if($_ < 100){
                sprintf "RT%d", 99-$_;
            }else{
                sprintf "nc=%d", $_-120
            }
        } sort {$a <=> $b} split(/\:/, $numeric_prio_str);

        return join("\; ", @prios);
    }else{
        return '';
    }
}

# update xx_time, xx_max, xx_max_timestamp, xx_count
sub update_stat_in_table{
    my ($tab_name, $keya, $keyb, $duration, $timestamp, $cpu) = @_;
    my ($ref, $pid);

    if($tab_name eq 'proc'){
        $ref = \%proc_table;
        my ($local_pid, $local_cpu) = split /\-/, $keya;

        if(defined $local_cpu){
            # idle process
            &verbose_printf("[%.3f]pid=$local_pid, cpu=$local_cpu, add duration=%.3fms to ${keyb}\n", 1e-3*$timestamp, 1e-3*$duration);
        }else{
            &verbose_printf("[%.3f]pid=$keya, add duration=%.3fms to ${keyb}\n",1e-3* $timestamp, $duration*1e-3);
        }
    }elsif($tab_name eq 'irq'){
        $ref = \%irq_table;
        my ($irq, $cpu) = split /\-/, $keya;
        &verbose_printf("[%.3f]irq=$irq, cpu=$cpu, add duration=%.3fms to ${keyb}\n", $timestamp*1e-3, $duration*1e-3);
    }elsif($tab_name eq 'softirq'){
        $ref = \%softirq_table;
        my ($softirq, $cpu) = split /\-/, $keya;
        &verbose_printf("[%.3f]softirq=$softirq, cpu=$cpu, add duration=%.3fms to ${keyb}\n", $timestamp*1e-3, $duration*1e-3);
    }

    # count process execution duration in each cpu
    if($l and
        $tab_name eq 'proc' and
        ( $keyb eq 'exec' || $keyb eq 'runable') and
        defined $cpu and
        $keya !~ m/\d+\-\d+/o)
    {
        ${$ref}{$keya}{$keyb."_cpu$cpu"} += $duration;
    }

    if(!exists ${$ref}{$keya}{$keyb.'_max'} or
        $duration > ${$ref}{$keya}{$keyb.'_max'})
    {
        ${$ref}{$keya}{$keyb.'_max'} = $duration;
        ${$ref}{$keya}{$keyb.'_max_ts'} = $timestamp;
    }
    ${$ref}{$keya}{$keyb.'_count'}++;
    ${$ref}{$keya}{$keyb.'_time'} += $duration;
}

sub _merge{
    my ($ref, $idx1, $idx2) = @_;

    if(exists ${$ref}{"${idx1}_time"} && exists ${$ref}{"${idx2}_time"}){
        my ($max, $max_ts);
        if(${$ref}{"${idx1}_max"} > ${$ref}{"${idx2}_max"}){
            $max = ${$ref}{"${idx1}_max"};
            $max_ts = ${$ref}{"${idx1}_max_ts"};
        }else{
            $max = ${$ref}{"${idx2}_max"};
            $max_ts = ${$ref}{"${idx2}_max_ts"};
        }
        return (${$ref}{"${idx2}_time"} + ${$ref}{"${idx1}_time"}, $max, $max_ts);
    }elsif(exists ${$ref}{"${idx1}_time"}){
        return (${$ref}{"${idx1}_time"}, ${$ref}{"${idx1}_max"}, ${$ref}{"${idx1}_max_ts"});
    }else{
        return (${$ref}{"${idx2}_time"}, ${$ref}{"${idx2}_max"}, ${$ref}{"${idx2}_max_ts"});
    }
}

sub per_worker_spirntf {
    local $_;
    my ($pid, $exec_time) = @_;

    #no warnings 'uninitialized';

    # 0: pid,cmdline
    # 1: func(addr),
    # 2: duration
    # 3: percentage
    my @results;
    $results[0] = "pid=$pid,cmdline=$proc_table{$pid}{name}";
    $results[1] = "work func(work addr),";
    $results[2] = "exec time(ms),";

    for my $addr (sort {
                $workqueue_table{$pid}{$b}{duration} <=> $workqueue_table{$pid}{$a}{duration}
            } keys %{$workqueue_table{$pid}})
    {
        $results[1] .= "$workqueue_table{$pid}{$addr}{name}($addr),";
        $results[2] .= $workqueue_table{$pid}{$addr}{duration}*1e-3.",";
    }
    return map {"$_\n";} @results;
}

# format task output
sub per_task_sprintf{
    my ($pid, $total_time) = @_;
    my @keys = qw{
        sleep_time sleep_max sleep_max_ts
        mutex_time mutex_max mutex_max_ts
        io_time io_max io_max_ts};

    push @keys,qw{waking_time waking_max waking_max_ts} if($w);
    @keys = grep {
                !m/_max(?:_ts)?$/o
            } @keys if(!$m);

            #no warnings 'uninitialized';

    my $result;
    if($tgid_support){
        $result = ((exists $proc_table{$pid}{tgid} and $proc_table{$pid}{tgid} !~ m/^\-+$/o)?$proc_table{$pid}{tgid}:"").",";
    }

    $result .= 
        join(",", $pid, $proc_table{$pid}{name},
            sprintf("%2.3f%%", $proc_table{$pid}{exec_time}/$total_time*1e2),
            sprintf("%.3f", 1e-3*($proc_table{$pid}{isr_time} + $proc_table{$pid}{softirq_time})),
            sprintf("%.3f", 1e-3*($proc_table{$pid}{exec_time} - $proc_table{$pid}{isr_time} - $proc_table{$pid}{softirq_time}))
    );
    $result .= ",". join(",", 
            sprintf("%.3f", 1e-3*($proc_table{$pid}{exec_max})),
            sprintf("%.3f", 1e-3*($proc_table{$pid}{exec_max_ts}||0)),
            sprintf("%.3f", 1e-3*($proc_table{$pid}{exec_count})),
            sprintf("%.3f", 1e-3*($proc_table{$pid}{first_event})),
            sprintf("%.3f", 1e-3*($proc_table{$pid}{last_event})),
            sprintf("%.3f", 1e-3*($proc_table{$pid}{last_event} - $proc_table{$pid}{first_event}))
        ) if($m);
    $result .= ",".join(",",
            (map { sprintf "%.3f", $_*1e-3;} (&_merge(\%{$proc_table{$pid}}, 'runable', 'waking'))[0], @{$proc_table{$pid}}{@keys}),
            sprintf("%.3f", 1e-3*($proc_table{$pid}{waking_time} +
                $proc_table{$pid}{runable_time} +
                $proc_table{$pid}{sleep_time} +
                $proc_table{$pid}{mutex_time} +
                $proc_table{$pid}{io_time} +
                $proc_table{$pid}{exec_time})),
            "",
            &kernel_priority_to_string($proc_table{$pid}{prio}));

    return $result;
}

# format irq/softirq output
sub per_irq_sprintf{
    my ($ref, $irq, $cpu, @keys) = @_;

    #no warnings 'uninitialized';
    my $result = join(",",
        $irq,
        $cpu,
        ${$ref}{"$irq-$cpu"}{name},
        map {
                sprintf("%.3f", 1e-3*(${$ref}{"$irq-$cpu"}{$_.'_time'} || 0)),
            } @keys);

    if($m){
        $result .= ",".join(",",
            map{
                sprintf("%.3f", 1e-3*(${$ref}{"$irq-$cpu"}{$_.'_max'}||0)),
                ${$ref}{"$irq-$cpu"}{$_.'_count'},
                sprintf("%.3f", 1e-3*(${$ref}{"$irq-$cpu"}{$_.'_max_ts'}||0))
            }@keys);
    }
    return $result;
}

# sum_fields(ref to hash, 2nd field name, regex match 1st field)
sub sum_fields{
    my ($ref, $regex, @field_name) = @_;
    my $sum = 0;

    for(keys %{$ref}){
        for my $field (@field_name){
            if(exists ${$ref}{$_}{$field} && $_ =~ $regex){
                #if($code->($_)){
                    $sum += ${$ref}{$_}{$field};
                    #}
            }
        }
    }
    return $sum;
}

# summerize count of events
sub count_events{
    local $_ ;
    my $counts = 0;
    my $ref = $_[0];

    #no warnings 'uninitialized';
    if($#_ > 1){
        for(@_[1 .. $#_]){
            $counts += ${$ref}{$_};
        }
    }else{
        for(keys %{$ref}){
            $counts += ${$ref}{$_};
        }
    }
    return $counts;
}

# before cpu goes offline (or ftrace disabled)
# update statistics and reset per cpu info
sub reset_stat_per_cpu{
    local $_;
    my ($cpu, $ts) = @_;
    my $this_duration;

    # find which task this cpu is executing
    my ($pid) = (&find_last_event($exec_stack[$cpu], qr!^proc\-!o) =~ m/^proc\-(\d+)/o);
    if(!defined $pid or $pid eq ''){
        $pid = $cpu_table[$cpu]{last_pid};
    }
    $pid = "0-$cpu" if($pid eq '0');

    if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
        my ($type, $id) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)$/o);
        if($type eq 'softirq'){
            $this_duration = $ts - $softirq_table{"$id-$cpu"}{last_entry};
            &update_stat_in_table('softirq', "$id-$cpu", 'exec', $this_duration, $ts);
            $proc_table{$pid}{softirq_time} += $this_duration;

        }elsif($type eq 'irq'){
            $this_duration = $ts - $irq_table{"$id-$cpu"}{last_entry};
            &update_stat_in_table('irq', "$id-$cpu", 'exec', $this_duration, $ts);
            $proc_table{$pid}{irq_time} += $this_duration;
        }else{
            # executing in process, use pid directly
            $this_duration = $ts - $proc_table{$pid}{last_entry};
            &update_stat_in_table('proc', $pid, 'exec', $this_duration, $ts, $cpu);
        }
    }

}

sub reset_stat{
    local $_;

    # erase exec_stack
    for (0 .. $#exec_stack){
        while(scalar(@{$exec_stack[$_]}) > 0){
            pop @{$exec_stack[$_]};
        }
    }

    # reset process info
    for (keys %proc_table){
        if(exists $proc_table{$_}{state}){
            delete $proc_table{$_}{state};
        }
    }

    # reset irq & softirq info
    for (keys %irq_table){
        if(exists $irq_table{$_}{last_entry}){
            delete $irq_table{$_}{last_entry};
        }
    }
    for (keys %softirq_table){
        if(exists $softirq_table{$_}{last_entry}){
            delete $softirq_table{$_}{last_entry};
            $softirq_table{$_}{last_raise} = undef;
        }
    }
    for(0 .. $#irq_count){
        $irq_count[$_] = 0;
    }
    for(0 .. $#softirq_count){
        $softirq_count[$_] = 0;
    }
}

# ------------
# main parsing subroutine
# ------------
sub parse {
    local $_; 
    my $ref = $_[0];
    my $this_duration;
    my $nested_irq_warn_already = 0;
    my $tracing_on = 1;
    $tgid_support = 0;
    my ($timestamp, $first_ts_of_all);

    for (@{$ref}){
        chomp;
        s/[\n\r]+$//o;

        my ($curr_pid, $tgid, $cpu);
        if((($curr_pid, $tgid, $cpu, $timestamp) = m/^
            .{16}\-(\d+)\s+
            (?:\(([\s\d-]{5})\)\s+)?
            \[(\d+)\]\s+(?:\S{4}\s+)?
            (\d+\.\d+)\:
        /xso)==0){
            # skip unrecognized strings
            next;
        }

        if(defined $tgid){
            if($tgid =~ s/^\s*(\d+)$/$1/xgso){
                $proc_table{$curr_pid}{tgid} = int($tgid);
                $tgid_support = 1;
            }else{
                $proc_table{$curr_pid}{tgid} = $tgid;
            }
        }

        # $timestamp = scalar($timestamp)*1e3;
        $timestamp =~ s/\.//go;
        $timestamp = int($timestamp);
        $cpu = int($cpu);

        unless(defined $first_ts_of_all){
            $first_ts_of_all = $timestamp;
        }
        unless(exists $cpu_table[$cpu]{first_ts}){
            $cpu_table[$cpu]{first_ts} = $timestamp;
        }
        # separate from first_ts in case that 'tracing_on toggled to 1' event lost
        unless(exists $cpu_table[$cpu]{last_online_ts}){
            $cpu_table[$cpu]{last_online_ts} = $timestamp;
        }
        $cpu_table[$cpu]{last_ts} = $timestamp;
        $cpu_table[$cpu]{last_pid} = $curr_pid;

        if(m/\s
            sched_switch\:\s
            prev_comm=(.+)\s
            prev_pid=(\d+)\s
            prev_prio=(\d+)\s
            prev_state=(\S+)\s
            ==>\s
            next_comm=(.+)\s
            next_pid=(\d+)\s
            next_prio=(\d+)
            (?:\sextra_prev_state=(\S+))?
            /xso)
        {

            my ($prev_pid, $prev_prio, $prev_state, $next_pid, $next_prio) =
                ($2, $3, ((defined $8)?"$4|$8":$4), $6, $7);
            my ($prev_comm, $next_comm) = ($1, $5);

            # check if process being scheduled out and last scheduled in match
            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                my ($type, $id) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)$/o);
                if($type eq 'proc' and $id != $prev_pid){
                    warn "$script_name: scheduling event not matched, timestamp=$timestamp, pid_to_schedule_out: $prev_pid, pid_in_exec=$id\n";
                    return;
                }elsif($type ne 'proc'){
                }else{
                    pop @{$exec_stack[$cpu]};
                }
            }
            push @{$exec_stack[$cpu]}, "proc-$next_pid";

            $prev_pid = "0-$cpu" if($prev_pid == 0);
            $next_pid = "0-$cpu" if($next_pid == 0);

            $proc_table{$prev_pid}{name} = $prev_comm;
            $proc_table{$prev_pid}{prio} = (exists $proc_table{$prev_pid}{prio})?&generate_numeric_priorities($proc_table{$prev_pid}{prio}, $prev_prio):$prev_prio;
            $proc_table{$prev_pid}{first_event} = $timestamp unless(defined $proc_table{$prev_pid}{first_event});
            $proc_table{$prev_pid}{last_event} = $timestamp;

            $proc_table{$prev_pid}{state} = &proc_state_str($prev_state);
            $this_duration = $timestamp - &_max($proc_table{$prev_pid}{last_entry}, $cpu_table[$cpu]{last_online_ts});

            &update_stat_in_table('proc', $prev_pid, 'exec', $this_duration, $timestamp, $cpu);

            $proc_table{$next_pid}{name} = $next_comm;
            $proc_table{$next_pid}{prio} = (exists $proc_table{$next_pid}{prio})?&generate_numeric_priorities($proc_table{$next_pid}{prio}, $next_prio):$next_prio;
            $proc_table{$next_pid}{first_event} = $timestamp unless(defined $proc_table{$next_pid}{first_event});

            # event_count the runable, sleep, mutex, and I/O waiting time for next_pid process
            if(exists $proc_table{$next_pid}{last_event} and defined $proc_table{$next_pid}{state}){
                $this_duration = $timestamp - &_max($proc_table{$next_pid}{last_event}, $cpu_table[$cpu]{last_online_ts});
                &update_stat_in_table('proc', $next_pid, $proc_table{$next_pid}{state}, $this_duration, $timestamp);
            }
            $proc_table{$next_pid}{last_event} = $timestamp;
            $proc_table{$next_pid}{last_entry} = $timestamp;
            $proc_table{$next_pid}{state} = 'running';
            $proc_table{$next_pid}{exec_time} ||= 0;

            $event_count{sched_switch}++;
        }elsif(m/\s
            sched_wakeup(?:_new)?\:\s
            comm=(.+)\s
            pid=(\d+)\s
            prio=(\d+)\s
            success=1\s
            target_cpu=(\d+)
            (?:\sstate=(\S+))?
            /xso)
        {

            my $pid = $2;
            $proc_table{$pid}{name} = $1;
            $proc_table{$pid}{prio} = (exists $proc_table{$pid}{prio})?&generate_numeric_priorities($proc_table{$pid}{prio}, $3):$3;
            $proc_table{$pid}{first_event} = $timestamp unless(defined $proc_table{$pid}{first_event});

            # sometimes processes may be waked up but never actually turned
            # into runable (but why?, interrupt?)
            # avoid this case

            if(exists $proc_table{$pid}{last_event} and defined $proc_table{$pid}{state}){
                $this_duration = $timestamp - &_max($proc_table{$pid}{last_event}, $cpu_table[$cpu]{last_online_ts});
                &update_stat_in_table('proc', $pid, $proc_table{$pid}{state}, $this_duration, $timestamp);

            }

            $proc_table{$pid}{last_event} = $timestamp;
            if(!defined $proc_table{$pid}{state} or  
                ($proc_table{$pid}{state} ne 'running' and
                $proc_table{$pid}{state} ne 'runable'))
            {
                # this task is just waked up and not runable or running before
                $proc_table{$pid}{state} = 'waking';
            }else{
                $proc_table{$pid}{state} = 'runable';
            }
            $proc_table{$pid}{exec_time} ||= 0;

            $event_count{sched_wakeup}++;
        }elsif(m/\s
            sched_migrate_task\:\s
            comm=(.+)\s
            pid=(\d+)\s
            prio=(\d+)\s
            orig_cpu=(\d+)\s
            dest_cpu=(\d+)
            (?:state=(\S+))?
            /xso)
        {
            my $pid = $2;
            my $state = $6;
            $proc_table{$pid}{name} = $1;
            $proc_table{$pid}{prio} = (exists $proc_table{$pid}{prio})?generate_numeric_priorities($proc_table{$pid}{prio}, $3):$3;
            $proc_table{$pid}{first_event} = $timestamp unless(defined $proc_table{$pid}{first_event});

            if(exists $proc_table{$pid}{last_event} and defined $proc_table{$pid}{state}){
                $this_duration = $timestamp - &_max($proc_table{$pid}{last_event}, $cpu_table[$cpu]{last_online_ts});

                &update_stat_in_table('proc', $pid, $proc_table{$pid}{state}, $this_duration, $timestamp);
            }

            $proc_table{$pid}{last_event} = $timestamp;

            if(defined $state){
                my $migrated_state = &proc_state_str($state);
                if(defined $proc_table{$pid}{state} and 
                    $proc_table{$pid}{state} eq 'waking' and
                    ( 'runable' eq $migrated_state ||
                        'waking' eq $migrated_state)
                ){
                    $proc_table{$pid}{state} = 'waking';
                }else{
                    $proc_table{$pid}{state} = $migrated_state;
                }
            }

            $proc_table{$pid}{exec_time} ||= 0;

            $event_count{sched_migrate_task}++;
        }elsif(m/\s
            (?:irq_handler_entry|ipi_handler_entry|irq_entry)\:\s
            (?:irq|ipi)=(\d+)\s
            name=(.+)
            /xso)
        {

            my ($irq, $irq_name) = ($1, $2);

            my ($pid) = (&find_last_event($exec_stack[$cpu], qr!^proc\-!o) =~ m/^proc\-(\d+)/o);

            #no warnings 'uninitialized';
            if(!defined $pid or $pid eq ''){
                $pid = $curr_pid;
            }
            $pid = "0-$cpu" if($pid eq '0');

            if($softirq_count[$cpu] > 0){
                # preempt softirq
                my ($softirq) = (&find_last_event($exec_stack[$cpu], qr!^softirq\-!o) =~ m/^softirq\-(\d+)/o); 
                $this_duration = $timestamp - &_max($softirq_table{"$softirq-$cpu"}{last_entry}, $cpu_table[$cpu]{last_online_ts});
                &update_stat_in_table('softirq', "$softirq-$cpu", 'exec', $this_duration, $timestamp);
                $proc_table{$pid}{softirq_time} += $this_duration;
            }

            $irq_table{"$irq-$cpu"}{name} = $irq_name;
            $irq_table{"$irq-$cpu"}{last_entry} = $timestamp;

            $event_count{irq_handler_entry}++;

            if ($irq_count[$cpu]>0 && $nested_irq_warn_already == 0){
                my ($last_irq) = (&find_last_event($exec_stack[$cpu], qr!^irq\-!o) =~ m/^irq\-(\d+)/o);
                $nested_irq_warn_already++;
                warn "$script_name: nested irq handler detected, time=$timestamp cpu=$cpu irq=$irq-$irq_name in_irq=@{[$last_irq || 'unknown']}";
                return;
            }
            $irq_count[$cpu]++;
            push @{$exec_stack[$cpu]}, "irq-$irq";

        }elsif(m{\s
            (?:irq_handler_exit|ipi_handler_exit|irq_exit)\:\s
            (?:irq|ipi)=(\d+)
            (?:\sret=handled)?
            }xso)
        {
            my $irq = $1;

            # no warnings 'uninitialized';
            if($softirq_count[$cpu] > 0){
                # update softirq info before leaving irq
                my ($softirq) = (&find_last_event($exec_stack[$cpu], qr!^softirq\-!o) =~ m/^softirq\-(\d+)/o); 
                $softirq_table{"$softirq-$cpu"}{last_entry} = $timestamp;
            }
            my ($pid) = (&find_last_event($exec_stack[$cpu], qr!^proc\-!o) =~ m/^proc\-(\d+)/o);
            if(!defined $pid or $pid eq ''){
                $pid = $curr_pid;
            }
            $pid = "0-$cpu" if($pid eq '0');

            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                my ($type, $id) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)$/o);
                if($type ne 'irq' or $id != $irq){
                    warn "$script_name: irq entry/exit event not matched, timestamp=$timestamp, irq_to_exit=$irq, in_irq=$id\n";
                    return;
                }else{
                    pop @{$exec_stack[$cpu]} ;
                }
            }

            $this_duration = $timestamp - &_max($irq_table{"$irq-$cpu"}{last_entry}, $cpu_table[$cpu]{last_online_ts});

            &update_stat_in_table('irq', "$irq-$cpu", 'exec', $this_duration, $timestamp);
            $proc_table{$pid}{isr_time} += $this_duration;

            # $irq_table{"$irq-$cpu"}{last_event} = $timestamp;
            delete $irq_table{"$irq-$cpu"}{last_entry};
            $event_count{irq_handler_exit}++;

            $irq_count[$cpu]-- if(defined($irq_count[$cpu]) && $irq_count[$cpu]>0);
        }elsif(m/\s
            softirq_raise\:\s
            vec=(\d+)\s
            \[action=.+\]
            /xso)
        {
            $softirq_table{"$1-$cpu"}{name} = $2;
            # avoid the softirq being raised more than once, and it can be only reset while exiting softirq
            $softirq_table{"$1-$cpu"}{last_raise} = $timestamp if(!defined($softirq_table{"$1-$cpu"}{last_raise}));
            $event_count{softirq_raise}++;
        }elsif(m/\s
            softirq_entry\:\s
            vec=(\d+)\s
            \[action=(.+)\]
            /xso)
        {
            my $softirq = $1;
            $softirq_table{"$softirq-$cpu"}{name} = $2;
            my ($pid) = (&find_last_event($exec_stack[$cpu], qr!^proc\-!o) =~ m/^proc\-(\d+)/o);
            if(!defined $pid or $pid eq ''){
                $pid = $curr_pid;
            }
            $pid = "0-$cpu" if($pid eq '0');

            $softirq_table{"$softirq-$cpu"}{last_entry} = $timestamp;

            if(defined $softirq_table{"$softirq-$cpu"}{last_raise}){
                my $this_duration = $timestamp - &_max($softirq_table{"$softirq-$cpu"}{last_raise}, $cpu_table[$cpu]{last_online_ts});
                &update_stat_in_table('softirq', "$softirq-$cpu", 'wakeup', $this_duration, $timestamp) if($this_duration > 0);
            }

            push @{$exec_stack[$cpu]}, "softirq-$softirq";

            $softirq_count[$cpu]++;
            $event_count{softirq_entry}++;
        }elsif(m/\s
            softirq_exit\:\s
            vec=(\d+)\s
            \[action=.+\]
            /xso)
        {
            my $softirq = $1;

            my ($pid) = (&find_last_event($exec_stack[$cpu], qr!^proc\-!o) =~ m/^proc\-(\d+)/o);
            if(!defined $pid or $pid eq ''){
                $pid = $curr_pid;
            }
            $pid = "0-$cpu" if($pid eq '0');

            #no warnings 'uninitialized';
            $this_duration = $timestamp - 
                &_max($softirq_table{"$softirq-$cpu"}{last_entry}, $cpu_table[$cpu]{last_online_ts});
                
            &update_stat_in_table('softirq', "$softirq-$cpu", 'exec', $this_duration, $timestamp);
            $softirq_table{"$softirq-$cpu"}{last_raise} = undef; # reset softirq raise time
            $proc_table{$pid}{softirq_time} += $this_duration;

            if(defined $exec_stack[$cpu] and scalar(@{$exec_stack[$cpu]}) > 0){
                my ($type, $id) = (${$exec_stack[$cpu]}[-1] =~ m/^(\w+)\-(\d+)$/o);
                if($type ne 'softirq' or $id != $softirq){
                    warn "$script_name: softirq entry/exit event not matched, timestamp=$timestamp, softirq_to_exit: $softirq, in_softirq=$id\n";
                    return;
                }else{
                    pop @{$exec_stack[$cpu]} ;
                }
            }

            $softirq_count[$cpu]-- if($softirq_count[$cpu]>0);
            #$curr_softirq[$cpu] = "";
            $event_count{softirq_exit}++;
        }elsif(m/\s
            tracing_on\:\s
            ftrace\s is\s ((?:dis|en)abled)$
            /oxs)
        {
            my $enabled = $1;
            if($enabled eq 'disabled' && $tracing_on == 1){
                $tracing_on = 0;
                for my $cpu (0 .. $#cpu_table){
                    &reset_stat_per_cpu($cpu, $timestamp);
                    $cpu_table[$cpu]{last_offline_ts} = $timestamp;
                }
                &reset_stat();
            }elsif($enabled eq 'enabled' && $tracing_on == 0){
                $tracing_on = 1;
                for my $cpu (0 .. $#cpu_table){
                    $cpu_table[$cpu]{last_online_ts} = $timestamp;
                    $cpu_table[$cpu]{offline_duration} += $timestamp - $cpu_table[$cpu]{last_offline_ts};
                }
            }
        }elsif(m/\s
            cpu_hotplug\:\s
            cpu=(\d+)\s
            state=(\w+)\s
        /xso)
        {
            #no warnings 'uninitialized';
            my $state = $2;
            my $cpu_id = int($1);

            if($state eq 'offline'){
                &reset_stat_per_cpu($cpu_id, $timestamp);
                $cpu_table[$cpu_id]{last_offline_ts} = $timestamp;
            }elsif($state eq 'online'){
                $cpu_table[$cpu_id]{last_online_ts} = $timestamp;

                if(exists $cpu_table[$cpu_id]{last_offline_ts}){
                    $cpu_table[$cpu_id]{offline_duration} += $timestamp - $cpu_table[$cpu_id]{last_offline_ts};
                    delete $cpu_table[$cpu_id]{last_offline_ts};
                }else{
                    # this cpu never goes offline, because it already offline
                    $cpu_table[$cpu_id]{offline_duration} += $timestamp - $first_ts_of_all;
                }
            }
        }elsif(m/\s
            unnamed_irq\:\s
            irq=(\d+)
            /oxs)
        {
            warn "$script_name: unknown irq=$1, ts=$timestamp\n";
        }elsif(m/\s
            workqueue_execute_start\:\s
            work\sstruct\s(\w+)\:\s
            function\s(\w+)
            /oxs)
        {
            my ($work_addr, $work_func) = ($1, $2);
            $workqueue_table{$curr_pid}{$work_addr}{name} = $work_func;
            $workqueue_table{$curr_pid}{$work_addr}{start} = $timestamp;
        }elsif(m/\s
            workqueue_execute_end\:\s
            work\sstruct\s(\w+)
            /oxs)
        {
            my $work_addr = $1;
            if(exists $workqueue_table{$curr_pid}{$work_addr}{start}){
                $workqueue_table{$curr_pid}{$work_addr}{duration} += $timestamp - $workqueue_table{$curr_pid}{$work_addr}{start};
                $workqueue_support = 1;
            }
        }
    }

    # collect offline_duration if cpu is offline and hotplug trace is available
    for(my $i = 0 ; $i<=$#exec_stack; ++$i){
        if(exists $cpu_table[$i]{last_offline_ts}){
            $cpu_table[$i]{offline_duration} += $timestamp - $cpu_table[$i]{last_offline_ts};
            delete $cpu_table[$i]{last_offline_ts};
        }
    }
}

sub print_csv{
    local $_;
    my ($fout) = @_;
    my $total_exectime = 0;
    my $duration_per_cpu = 0;           # max active duration per cpu

    # find first & last timestamp of all CPUs
    my ($first_ts_of_all, $last_ts_of_all) = ($cpu_table[0]{first_ts}, $cpu_table[0]{last_ts});
    for(my $i = 1; $i <= $#exec_stack ; ++$i){
        $first_ts_of_all = $cpu_table[$i]{first_ts} if($cpu_table[$i]{first_ts} < $first_ts_of_all);
        $last_ts_of_all = $cpu_table[$i]{last_ts} if($last_ts_of_all < $cpu_table[$i]{first_ts});
        # warn "cpu=$i, first_ts=$cpu_table[$i]{first_ts}, last_ts=$cpu_table[$i]{last_ts}\n";
    }
    $duration_per_cpu = $last_ts_of_all - $first_ts_of_all;

    printf $fout <<HEADER, $version, $duration_per_cpu*1e-3, $first_ts_of_all*1e-3, $last_ts_of_all*1e-3;
script version %s
recorded duration(unit:ms),start ts,end ts
%.3f,%.3f,%.3f
cpu,offline_duration
HEADER
    for(my $i = 0; $i <= $#exec_stack ; ++$i){
        #no warnings 'uninitialized';
        &reset_stat_per_cpu($i, $cpu_table[$i]{last_ts});
        printf $fout ("cpu$i,%.3f\n",
            $cpu_table[$i]{offline_duration}*1e-3);
    }

    
    if(&count_events(\%event_count, "sched_switch", "sched_wakeup", "sched_migrate_task") > 0){
        # summerize total execution but idle process
        for(grep {
                !/^0\-/o && exists $proc_table{$_}{exec_time}
            } keys %proc_table)
        {
            $total_exectime += $proc_table{$_}{exec_time};
        }
        
        print $fout join(qq(,), @proc_table_header, "\n");
        
        my $idle_isr_time = &sum_fields(\%proc_table, qr!^0\-!, 'isr_time', 'softirq_time') || 0;
        # idle processes
        print $fout "0," if($tgid_support);
        printf $fout (
            "0,IDLE,%2.2f%%,%.3f,%.3f\n",
            (1-$total_exectime/($#exec_stack+1)/$duration_per_cpu)*1e2*($#exec_stack+1),
            $idle_isr_time*1e-3,
            (($#exec_stack+1)*$duration_per_cpu - $total_exectime - $idle_isr_time)*1e-3,
        );

        for(grep { !/^0\-/ } keys %proc_table){
            $proc_table{$_}{exec_time} ||= 0;
        }
        for(sort {
            $proc_table{$b}{exec_time} <=> $proc_table{$a}{exec_time} or
            ($tgid_support and
                (exists $proc_table{$a}{tgid} and exists $proc_table{$b}{tgid}) and
                ($proc_table{$a}{tgid} !~ m/^\-+$/o and $proc_table{$b}{tgid} !~ m/^\-+$/o ) and
                ($proc_table{$a}{tgid} <=> $proc_table{$b}{tgid})) or
            $a <=> $b
        } grep {
            # filter out idle processes
            !/^0\-/
        } keys %proc_table){
            print $fout &per_task_sprintf($_, $duration_per_cpu)."\n";
        }
    }

    if(!$m){
        @irq_table_header = grep {
            !m/_max(?:_ts)?$/o && !m/^exec_count$/o
        } @irq_table_header;
        @softirq_table_header = grep {
            !m/_max(?:_ts)?$/o && !m/_count$/o
        } @softirq_table_header;
    }

    # print IRQ info if irq_handler_entry/exit events are available
    if(&count_events(\%event_count, "irq_handler_entry", "irq_handler_exit", "ipi_handler_entry", "ipi_handler_exit", "irq_entry", "irq_exit") > 0){
        print $fout "\n".join(qq(,), @irq_table_header, "\n");
        for(sort {
            my ($airq, $acpu) = ($a =~ m/(\d+)-(\d+)/o);
            my ($birq, $bcpu) = ($b =~ m/(\d+)-(\d+)/o);
            $airq <=> $birq || $acpu <=> $bcpu;
        } keys %irq_table){
            my ($irq, $cpu) = m/(\d+)-(\d+)/o;
            print $fout &per_irq_sprintf(\%irq_table, $irq, $cpu, 'exec')."\n";
        }
    }

    # print SOFTIRQ info if softirq_entry/exit events are available
    if(&count_events(\%event_count, "softirq_entry", "softirq_exit", "softirq_raise") > 0){
        print $fout "\n".join(qq(,), @softirq_table_header, "\n");
        for(sort {
            my ($airq, $acpu) = ($a =~ m/(\d+)-(\d+)/o);
            my ($birq, $bcpu) = ($b =~ m/(\d+)-(\d+)/o);
            $airq <=> $birq || $acpu <=> $bcpu;
        } keys %softirq_table){
            my ($irq, $cpu) = m/(\d+)-(\d+)/o;
            print $fout &per_irq_sprintf(\%softirq_table, $irq, $cpu, 'exec', 'wakeup')."\n";
        }
    }

    # print process exec time on each cpu
    if($l){

        printf $fout <<LOAD_BALANCE_TABLE_HEADER, @{[join(",", map{ sprintf "cpu$_";} 0 .. $#exec_stack)]};

The load balance distribution on each cpu for each task
pid,%s
LOAD_BALANCE_TABLE_HEADER

        #no warnings 'uninitialized';
        for my $pid (sort {$a <=> $b} grep { !/^0\-/o } keys %proc_table){
            print $fout "$pid,".
            join(',', map {sprintf("%.3f", 1e-3*($proc_table{$pid}{"exec_cpu$_"}+$proc_table{$pid}{"runable_cpu$_"}));}
                sort {$a <=> $b}
                map {s/^(?:exec|runable)_cpu//o; $_;}
                grep {/^(?:exec|runable)_cpu/o}
                keys %{$proc_table{$pid}}).
            "\n";
        }
    }

    if($workqueue_support){
        print $fout "\n";
        for my $pid (sort {$a <=> $b} keys %workqueue_table){
            print $fout &per_worker_spirntf($pid);
            #print $fout "$pid\n";
            #for my $work_addr(keys %{$workqueue_table{$pid}}){
            #    print $fout "$workqueue_table{$pid}{$work_addr}{name}:$workqueue_table{$pid}{$work_addr}{duration},";
            #}
            #print $fout "\n";
        }
    }
}

sub main {
    my ($input, $output) = ($_[0]||"SYS_FTRACE", $_[1]||"ftrace_cputime.csv");
    my (@inputs, $fout);

    &usage() if($h);

    open $verbose_fout, '>', $v or die "$script_name: unable to open $v" if(defined $v);

    if(-e $input and !defined($c)){
        warn "$script_name: input=$input, output=$output\n";
        open my $fin, '<', $input or die "$script_name: unable to open $input\n";
        @inputs = <$fin>;
        close $fin;
        open $fout, '>', $output or die "$script_name: unable to open $output\n";
    }else{
        warn "$script_name: $input not exist and read from stdin instead\n";
        # @inputs = <STDIN>;
        @inputs = @{ &trim_events(<STDIN>) };
        open $fout, ">&=STDOUT" or die "$script_name: unable to alias STDOUT: $!\n"
    }

    if($w){
        my $idx = 0;
        for(@proc_table_header){
            if($proc_table_header[$idx] eq 'total_time'){
                last;
            }
            $idx++;
        }
        splice @proc_table_header, $idx, 0, qw(wake2exec wake2exec_max wake2exec_max_ts);
    }
    if(!$m){
        @proc_table_header = grep {
            !m/_max(?:_ts)?$/o and
            !m/^exec_count$/o and
            !m/^(?:first|last)_event$/o and
            !m/^active_duration$/o
        } @proc_table_header;
    }

    &parse(\@inputs);
    die "$script_name: no recognized events, exit\n" if(&count_events(\%event_count) == 0);

    if($tgid_support){
        unshift @proc_table_header, "tgid";
    }

    # output the results
    &print_csv($fout);
    close $verbose_fout if(defined $v);
}

&main(@ARGV);
