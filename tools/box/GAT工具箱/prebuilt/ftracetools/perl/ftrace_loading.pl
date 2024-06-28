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
#  calculate the variation of TLP based on captured ftrace raw data
#  and output it as .csv or .html. The front-end visualization is via
#  nvd3 java script library.

use strict;
use warnings;
use vars qw($h $p $t $r $v);
use feature qw(switch state);
BEGIN {
    my $is_linux = $^O =~ /linux/;
    eval <<'USE_LIB' if($is_linux);
        use FindBin;
        use lib "$FindBin::Bin/lib/mediatek/";
USE_LIB
    eval 'use ftrace_parsing_utils;';
}
use constant CPU_NO => 0;
use constant TLP => 1;

my ($verbose_fout);

my %nvd3_js_modules = (
    common => [ qw(
        nvd3/lib/d3.v3.js
	    nvd3/nv.d3.js
	    nvd3/src/tooltip.js
	    nvd3/src/utils.js
        nvd3/src/models/legend.js
        nvd3/src/models/axis.js
    )],

    multiBarChart => [ qw(
	    nvd3/src/models/multiBar.js
	    nvd3/src/models/multiBarChart.js
    )],

    lineWithFocusChart => [ qw(
        nvd3/src/models/scatter.js
        nvd3/src/models/line.js
        nvd3/src/models/lineWithFocusChart.js
    )],

    linePlusBarWithFocusChart => [ qw(
        nvd3/src/models/scatter.js
        nvd3/src/models/line.js
        nvd3/src/models/historicalBar.js
        nvd3/src/models/linePlusBarWithFocusChart.js
    )],
);

sub usage{
    print <<"USAGE"
Usage: $0 <options> <input_file> <output_file_prefix>
       -p:  specify unit period to calculate CPU loading, in ms
       -r:  specify counting rate(Hz) to calculate CPU loading
       -t:  specify total count to calculate CPU loading

            Only one argument among these above three ones should be configured at the same time
            priority -t > -r > -p

       -v=<filename>:   verbose mode, dump all variation of CPU loading
USAGE
}

sub verbose_printf{
    printf $verbose_fout @_ if(defined $v);
}

sub _sum_key{
    my ($ref, @field_name) = @_;
    local $_;
    my $sum = 0;

    for my $idx (0 .. $#{$ref}){
        for my $field (@field_name){
            if(exists ${$ref}[$idx]{$field}){
                    $sum += ${$ref}{$idx}{$field};
            }
        }
    }
    return $sum;
}

sub sum {
    local $_;
    my $sum = 0;
    no warnings 'uninitialized';
    for(@{$_[0]}){
        $sum += $_;
    }
    return $sum;
}

sub parse_app_usage{
    local $_;
}

sub parse_app_tlp{
}

# calculate CPU loading
sub parse_cpu_usage {
    local $_;
    my (@loading,
	    $last_period_end_ts,
	    @cpu_table
    );
    my ($ref,                   # reference to inputs
        $period) = @_;          # period for calculation

    $last_period_end_ts = &_ts(${$ref}[0]);

    die "$0: period not specified\n" if(!$period);

    for(@{$ref}){
        my ($current_pid, $cpu, $ts);
        if((($current_pid, $cpu, $ts) = m/^
                .{16}\-(\d+)\s+
                (?:\([\s\d-]{5}\)\s+)?
                \[(\d+)\]\s+
                (?:\S{4}\s+)?
                (\d+\.\d+)\:
                /xso)<3){
            # skip un-recognized strings
            next;
        }

        $ts =~ s/\.//go;
        $ts = int($ts);
        $cpu = int($cpu);

        # set cpu_in_use ASAP
        if(!exists $cpu_table[$cpu]{in_use} || !defined $cpu_table[$cpu]{in_use}){
            if( $current_pid != 0){
                $cpu_table[$cpu]{in_use} = 1;
            }else{
                $cpu_table[$cpu]{in_use} = 0;
            }
        }

        if(m/\s
            sched_switch\:\s+
            prev_comm=.+\s
            prev_pid=(\d+)\s
            prev_prio=\d+\s
            prev_state=\S+\s
            ==>\s
            next_comm=.+\s
            next_pid=(\d+)\s
            next_prio=\d+
            (?:\sextra_prev_state=\S+)?
            /xso)
        {
            use bignum;
            my ($prev_pid, $next_pid) = ($1, $2);
            my $new_in_use = ($next_pid!=0?1:0);


            if($ts > ($period + $last_period_end_ts)){
                # while loop to handle those period that 
                while($ts > ($period + $last_period_end_ts)){
                    for my $cpu_idx(0 .. $#cpu_table){

                        # initialize loading if not defined
                        $cpu_table[$cpu_idx]{loading} ||= 0;

                        if(exists $cpu_table[$cpu_idx]{in_use} && $cpu_table[$cpu_idx]{in_use} != 0){
                            $cpu_table[$cpu_idx]{loading} += $last_period_end_ts + $period - 
                                (exists $cpu_table[$cpu_idx]{last_sched_switch_ts}? $cpu_table[$cpu_idx]{last_sched_switch_ts}: $last_period_end_ts);
                        }
                        $cpu_table[$cpu_idx]{loading} = eval {$cpu_table[$cpu_idx]{loading} / $period;} || 0;
                        verbose_printf("[%.3f] cpu=%d loading=%.1f\n", ($period + $last_period_end_ts)*1e-3, $cpu_idx, $cpu_table[$cpu_idx]{loading});
                        push @{$loading[$cpu_idx]}, [($period + $last_period_end_ts), $cpu_table[$cpu_idx]{loading}];
                        $cpu_table[$cpu_idx]{last_sched_switch_ts} = $ts;
                        $cpu_table[$cpu_idx]{loading} = $cpu_table[$cpu_idx]{in_use}?($ts - $period - $last_period_end_ts):0;
                    }
                    $last_period_end_ts = $last_period_end_ts + $period;
                }
            }else{
                if($cpu_table[$cpu]{in_use} != $new_in_use){
                    if(exists $cpu_table[$cpu]{in_use} && $cpu_table[$cpu]{in_use}!=0){
                        $cpu_table[$cpu]{loading} += $ts - 
                            (exists $cpu_table[$cpu]{last_sched_switch_ts}? $cpu_table[$cpu]{last_sched_switch_ts}: $last_period_end_ts);
                    }
                    $cpu_table[$cpu]{in_use} = $new_in_use;
                    $cpu_table[$cpu]{last_sched_switch_ts} = $ts;
                }
            }
        }
    }
    return \@loading;
}

sub task_waking{
    local ($_) = @_;
    given($_){
        when(index($_, 'R') != -1){ return 1;}
        when(index($_, 'W') != -1){ return 1;}
        default{ return 0; }
    }
}

sub _verbose_printf_tlp_info{
    local $_;
    my ($ts, $task_table, $cpu_online) = @_;
    my ($waking_tasks, $running_tasks);
    $running_tasks = scalar (grep {${$task_table}{$_} eq 'running'; } keys %{$task_table});
    $waking_tasks = scalar (grep {${$task_table}{$_} eq 'waking'; } keys %{$task_table});

    verbose_printf("[%.3f] tlp=%d, ", $ts*1e-3, scalar(keys %{$task_table}));
    verbose_printf("running tasks: %s, ",
        join(" ", sort {($a) <=> ($b)} grep {${$task_table}{$_} eq 'running';} keys %{$task_table})) if($running_tasks);
    verbose_printf("waking tasks: %s, ",
        join(" ", sort {($a) <=> ($b)} grep {${$task_table}{$_} eq 'waking';} keys %{$task_table})) if($waking_tasks);
    verbose_printf("online cpus: %s\n", 
            join(", ", sort grep { ${$cpu_online}[$_] } 0 .. $#{$cpu_online}));
}

# TLP = running + runable
sub parse_online_cpu_tlp {
    local $_;
    my (@info, @cpu_online, %task_table);
    my ($ref) = @_;

    for(@{$ref}){
        my ($current_pid, $cpu, $ts);

        if((($current_pid, $cpu, $ts) = m/^
                .{16}\-(\d+)\s+
                (?:\([\s\d-]{5}\)\s+)?
                \[(\d+)\]\s+(?:\S{4}\s+)?
                (\d+\.\d+)\:
                /xso)<3){
            # skip un-recognized strings
            next;
        }

        if(!defined $cpu_online[$cpu]){
            $cpu_online[$cpu] = 1;
        }

        if($current_pid != 0 and !exists $task_table{$current_pid}){
            $task_table{$current_pid} = 'running'
        }

        $ts =~ s/\.//go;
        $ts = int($ts);
        $cpu = int($cpu);

        if(m/\s
            cpu_hotplug\:\s
            cpu=(\d+)\s
            state=(\w+)
            /oxs)
        {
            my ($cpu_idx, $state) = ($1, $2);
            if($state eq 'online'){
                $cpu_online[$cpu] = 1;
            }elsif($state eq 'offline'){
                $cpu_online[$cpu] = 0;
            }
        }elsif(m/\s
            sched_migrate_task\:\s+
            comm=.+\s
            pid=(\d+)\s
            prio=\d+\s
            orig_cpu=\d+\s
            dest_cpu=\d+
            (?:\sstate=(\S+))?
            /xso)
        {
            my ($pid, $state) = ($1, $2);
            if(task_waking($state) and !exists $task_table{$pid}){
                $task_table{$pid} = 'waking';

                _verbose_printf_tlp_info($ts, \%task_table, \@cpu_online);

                push @{$info[CPU_NO]}, [$ts, sum(\@cpu_online)];
                push @{$info[TLP]}, [$ts, scalar(keys %task_table)];
            }
        }elsif(m/\s
            sched_wakeup(?:_new)?\:\s+
            comm=.+\s
            pid=(\d+)\s
            prio=\d+\s
            success=1\s
            target_cpu=\d+
            /xso)
        {
            my $pid = $1;
            if(!exists $task_table{$pid}){
                $task_table{$pid} = 'waking';

                _verbose_printf_tlp_info($ts, \%task_table, \@cpu_online);

                push @{$info[CPU_NO]}, [$ts, sum(\@cpu_online)];
                push @{$info[TLP]}, [$ts, scalar(keys %task_table)];
            }
        }elsif(m/\s
            sched_switch\:\s+
            prev_comm=.+\s
            prev_pid=(\d+)\s
            prev_prio=\d+\s
            prev_state=(\S+)\s
            ==>\s
            next_comm=.+\s
            next_pid=(\d+)\s
            next_prio=\d+
            /xso)
        {
            my ($prev_pid, $prev_state, $next_pid) = (int($1), $2, int($3));

            # not waken but run directly, weird
            # idle task will never be recorded in task_table
            if($next_pid != 0){
                $task_table{$next_pid} = 'running';
            }

            if($prev_pid != 0 and (!task_waking($prev_state) and exists $task_table{$prev_pid})){
                # prev_pid leave 'running or runable' state
                delete $task_table{$prev_pid};

                _verbose_printf_tlp_info($ts, \%task_table, \@cpu_online);

                push @{$info[TLP]}, [$ts, scalar(keys %task_table)];
                push @{$info[CPU_NO]}, [$ts, sum(\@cpu_online)];
            }elsif ($prev_pid != 0 and task_waking($prev_state)){
                $task_table{$prev_pid} = 'waking';
            }
        }
    
    }
    return \@info;
}

sub _scale_data{
    local $_;
    my ($ref, $sub1, $sub2) = @_;

    for(my $i = 0; $i <= $#{$ref}; ++$i){
        @{${$ref}[$i]} = map {
            [
            defined $sub1?$sub1->(${$_}[0]):${$_}[0],
            defined $sub2?$sub2->(${$_}[1]):${$_}[1]
            ]
        } (@{${$ref}[$i]})
    }

    return $ref;
}

sub periodization{
    local $_;
    my ($ref, $starting_ts, $period) = @_;
    my (@formatted_output, $ts);
    my (@max, @avg);
    
    for(my $i = 0; $i <= $#{$ref}; ++$i){

        # finding max ts & value
        $max[$i] = [$ref->[$i][0][0], $ref->[$i][0][1]];
        for(my $j = 1; $j <= $#{$ref->[$i]}; ++$j){
            use bigint;
            if($max[$i]->[1] < $ref->[$i][$j][1]){
                $max[$i] = [$ref->[$i][$j][0], $ref->[$i][$j][1]];
            }
        }
        #for(my $j = 0; $j <$#max; ++$j){
        #    warn "ts=$max[$i]->[0], cpu=$i, max=$max[$i]->[1]\n";
        #}
        
        # averaging
        #my $last_ts = $starting_ts;
        for(my $j = 1; $j <= $#{$ref->[$i]}; ++$j){
            use bigint;
            $avg[$i] += ($ref->[$i][$j][0] - $ref->[$i][$j-1][0]) * $ref->[$i][$j-1][1];
        }
        $avg[$i] = eval { $avg[$i]/($ref->[$i][-1][0] - $starting_ts) } || 0;
        #warn "cpu=$i avg=$avg[$i]\n";

        # actually periodization
        $ts = int(($ref->[$i][0][0] - $starting_ts)/$period) * $period + $starting_ts;
        for(my $j = 0; $j < $#{$ref->[$i]}; ++$j){
            use bigint;
            if($ts < $ref->[$i][$j+1][0]){
                push @{$formatted_output[$i]}, [$ts, $ref->[$i][$j][1]];
                $ts += $period;
            }
        }

    }
    return (\@formatted_output, \@max, \@avg);
}

# deprecated, and should not be used anymore
#sub print_csv{
#    local $_;
#    my ($fout, $ref) = @_;
#    my $i;
#
#    for($i = 0; $i < ($#{$ref}+1)/2; $i+=2){
#        printf $fout "%.3f,%.3f\n", ${$ref}[$i], ${$ref}[$i+1];
#    }
#}

sub print_nvd3_html{
    local $_;
    my ($html_filename,
        $title,
        $figure_header,
        $figure_subheader,
        $nvd3_modules,
        $script_string,
    ) = @_;

    open my $html_fout, '>', $html_filename or die "$0: unable to open $html_filename";

    print $html_fout <<"HTML_HEADER";
<!DOCTYPE html>
<link href="nvd3/nv.d3.css" rel="stylesheet" type="text/css">
<html>
	<head>
		<meta charset="utf-8">
		<title>$title</title>
		<link href="nvd3/src/nv.d3.css" rel="stylesheet" type="text/css">
HTML_HEADER

    for (@$nvd3_modules){
        for my $module(@{$nvd3_js_modules{$_}}){
            print $html_fout <<"HTML_JS_SCRIPTS";
        <script src="$module"></script>
HTML_JS_SCRIPTS
        }
    }
    print $html_fout <<"HTML_HEAD_END";
	</head>
    <body class='with-3d-shadow with-transitions'>
		<style>
HTML_HEAD_END

        print $html_fout <<"CHART_HEIGHT";
#chart svg {
  height: 700px;
}
CHART_HEIGHT

    print $html_fout <<"STYLE_END";
    </style>

STYLE_END

        printf $html_fout <<"CHART_DIV", ((defined $figure_subheader and $figure_subheader ne '')?"$figure_subheader":"");
<H1>$figure_header</H1>
%s
<div id="chart">
  <svg></svg>
</div>

CHART_DIV

    printf $html_fout <<"SCRIPT", $script_string;
<script>
%s
</script>
SCRIPT

    print $html_fout <<"HTML_TAIL";
	</body>
</html>
HTML_TAIL

    close $html_fout;
}

sub sprint_nvd3_linePlusBarWithFocusChart{
    local $_;
    my $return_string;
    my ($data_ref, $xlabel, $ylabels, $formats) = @_;

    $return_string = sprintf <<"JS_HEADER";
    var data = [
JS_HEADER

    for(my $i = 0; $i <= $#{$data_ref}; ++$i){
        if($i == 0){
            $return_string .= sprintf <<"PER_DATA_HEADER";
        {
            "key": "${$ylabels}[$i]",
            "bar": true,
            "values": [
PER_DATA_HEADER
        }else{
            $return_string .= sprintf <<"PER_DATA_HEADER";
        {
            "key": "${$ylabels}[$i]",
            "values": [
PER_DATA_HEADER
        }

        for(my $j = 0 ; $j <= $#{${$data_ref}[$i]}; ++$j){
            $return_string .= sprintf "\t{x: %.3f, y:%.2f},\n",
                ${${$data_ref}[$i][$j]}[0],
                ${${$data_ref}[$i][$j]}[1];
        }
        $return_string .= print <<'PER_DATA_END';
            ]
        },
PER_DATA_END
    }

    $return_string .= sprintf <<"JS_END";
    ];
    nv.addGraph(function() {
    var chart = nv.models.linePlusBarWithFocusChart()
        .color(d3.scale.category10().range());

    chart.xAxis
            .tickFormat(d3.format('${$formats}[0]'));

    chart.x2Axis
            .tickFormat(d3.format('${$formats}[0]'));
    
    chart.y1Axis
        .tickFormat(d3.format('${$formats}[1]'));

    chart.y3Axis
        .tickFormat(d3.format('${$formats}[1]'));
        
    chart.y2Axis
        .tickFormat(d3.format('${$formats}[1]'));

    chart.y4Axis
        .tickFormat(d3.format('${$formats}[1]'));

    d3.select('#chart svg')
    	      .datum(data)
    	      .call(chart);

    nv.utils.windowResize(chart.update);
    return chart;
    })
JS_END
    return $return_string;
}

sub sprint_nvd3_multiBarChart_js{
    local $_;
    my ($data_ref, $xlabel, $ylabels, $formats) = @_;
    my $return_string;

    $return_string = sprintf <<"JS_HEADER";
    var data = [
JS_HEADER

    for(my $i = 0; $i <= $#{$data_ref}; ++$i){
        $return_string .= sprintf <<"PER_DATA_HEADER";
        {
            "key": "${$ylabels}[$i]",
            "values": [
PER_DATA_HEADER
        for(my $j = 0 ; $j <= $#{${$data_ref}[$i]}; ++$j){
            $return_string .= sprintf "\t{x: %.3f, y:%.2f},\n",
                ${${$data_ref}[$i][$j]}[0],
                ${${$data_ref}[$i][$j]}[1];
        }
        $return_string .= sprintf <<'PER_DATA_END';
            ]
        },
PER_DATA_END
    }

    $return_string .= sprintf <<"JS_END";
    ];
    nv.addGraph(function() {
    var chart = nv.models.multiBarChart()
        .color(d3.scale.category10().range())
        .transitionDuration(250);

    chart.xAxis
    	       .axisLabel("$xlabel")
    	      .tickFormat(d3.format('${$formats}[0]'));

    chart.yAxis
    	      .tickFormat(d3.format('${$formats}[1]'));

    chart.forceY([0]);

    d3.select('#chart svg')
    	      .datum(data)
    	    .transition().duration(0)
    	      .call(chart);
    nv.utils.windowResize(chart.update);
    return chart;
    })
JS_END
    return $return_string;
}

sub sprint_nvd3_lineWithFocusChart_js{
    local $_;
    my $return_string;
    my ($data_ref, $xlabel, $ylabels, $formats) = @_;

    $return_string = sprintf <<"JS_HEADER";
    var data = [ 
JS_HEADER

    for(my $i = 0; $i <= $#{$data_ref}; ++$i){
        $return_string .= sprintf <<"PER_DATA_HEADER";
        {
            "key"       :  "${$ylabels}[$i]",
            "values"    :   [
PER_DATA_HEADER
        for(my $j = 0; $j <= $#{${$data_ref}[$i]}; $j++){
            $return_string .= sprintf "\t{ x: %.3f, y: %.2f},\n",
                ${${$data_ref}[$i][$j]}[0],
                ${${$data_ref}[$i][$j]}[1];
        }
        $return_string .= sprintf <<'PER_DATA_END';
            ]
        } ,
PER_DATA_END
    }

    $return_string .= sprintf <<"JS_END";
    ];
    nv.addGraph(function() {
    var chart = nv.models.lineWithFocusChart()
        .color(d3.scale.category10().range())
        .transitionDuration(300);

    chart.xAxis
    	       .axisLabel("$xlabel")
    	      .tickFormat(d3.format('${$formats}[0]'));

    chart.x2Axis
    	       .axisLabel("$xlabel")
    	      .tickFormat(d3.format('${$formats}[0]'));

    chart.yAxis
    	      .tickFormat(d3.format('${$formats}[1]'));

    chart.y2Axis
    	      .tickFormat(d3.format('${$formats}[1]'));

    chart.forceY([0]);

    d3.select('#chart svg')
    	      .datum(data)
    	      .call(chart);

    nv.utils.windowResize(chart.update);

    return chart;
    });
JS_END
    return $return_string;
}

sub main {
    my ($input_file, $output_file_prefix) = ($_[0]||"SYS_FTRACE", $_[1]||"ftrace_");
    my ($js_fout, @inputs, $period);

    # 10ms for period as default value
    $period = 1e4;

    open $verbose_fout, '>', $v or die "$0: unable to open $v" if(defined $v);
    if(-e $input_file){
        open my $fin, '<', $input_file or die "$0: unable to open $input_file\n";
        @inputs = @{trim_events(<$fin>)};
        close $fin;
    }else{
        die "$0: input file: $input_file not exist!\n";
    }

    # prepare the period for calculation later
    if($t && $t > 0){
        $period = (&_ts($inputs[-1]) - &_ts($inputs[0]))/$t;
    }elsif($r and $r > 0){
        $period = 1e6/$r;
    }elsif($p and $p >0){
        $period = $p*1e3;
    }

    if($period < 0){
        die "$0: unable to decide the period to calculat TLP\n";
    }else{
        warn "period: $period us\n";
    }

    # start CPU loading calculation
    my $usage_data = _scale_data(&parse_cpu_usage(\@inputs, $period),
        sub{
            return $_[0]*1e-3;
        },
        sub {
            return $_[0]*1e2;
        });

    my ($tlp_data, $tlp_max_data, $tlp_avg_data);
    ($tlp_data, $tlp_max_data, $tlp_avg_data) = periodization(parse_online_cpu_tlp(\@inputs), _ts($inputs[0]), $period);
    $tlp_data = _scale_data($tlp_data, sub { return $_[0]*1e-3});

    #my $tlp_data = _scale_data(periodization(
    #    &count_online_cpu_tlp(\@inputs),
    #    _ts($inputs[0]), $period),
    #    sub {
    #        return $_[0]*1e-3;
    #    }
    #);

    # open $js_fout, '>', "$output_file_prefix.js" or die "$0: unable to open $output_file_prefix.js"; 

    my $usage_script_string = sprint_nvd3_lineWithFocusChart_js(
        $usage_data,
        qq[Time(ms)],
        [qw(CPU0 CPU1 CPU2 CPU3 CPU4 CPU5 CPU6 CPU7 CPU8 CPU9 CPU10 CPU11 CPU12 CPU13 CPU14 CPU15)],
        [',.3f', ',.1f']
    );

    my $tlp_script_string = sprint_nvd3_lineWithFocusChart_js(
         $tlp_data,
         qq[Time(ms)],
         ["online CPUs", "TLP"],
         [',.3f', ',.1f']
    );

    &print_nvd3_html(qq(${output_file_prefix}loading.html),
        "CPU usage", 
        "CPU usage",
        undef,
        [qw(common lineWithFocusChart)],
        $usage_script_string
    );

    &print_nvd3_html(qq(${output_file_prefix}TLP.html),
        "TLP & online CPU", 
        "TLP & online CPU",
         sprintf(<<"TLP_MAX_AVG", $tlp_max_data->[1][1], $tlp_max_data->[1][0]*1e-3, ${$tlp_avg_data}[0], $tlp_max_data->[0][1], $tlp_max_data->[0][0]*1e-3, ${$tlp_avg_data}[1]),
<h4>TLP max = %d (ts = %.3f), avg = %.3f</h4>
<h4>CPU# max = %d (ts = %.3f), avg = %.3f</h4>
TLP_MAX_AVG
        [qw(common lineWithFocusChart)],
        $tlp_script_string
    );

    
    close $verbose_fout if(defined $v);
}

&main(@ARGV);
