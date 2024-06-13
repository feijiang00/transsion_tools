#!/usr/bin/perl
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

package ftrace_parsing_utils;
use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION    = 1.00;
@ISA        = qw(Exporter);
@EXPORT     = qw(find_last_event trim_events _max _ts _basename _dirname);
@EXPORT_OK  = qw(find_last_event trim_events _max _ts _basename _dirname);
%EXPORT_TAGS= ( DEFAULT => [qw(&find_last_event trim_events _max _ts _basename _dirname)]);

my $tracing_on_regex = qr/\s
            tracing_on\:\s
            ftrace\sis\s
            /xs;

sub find_last_event{
    my ($ref, $regex) = @_;
    local $_;

    if(!defined($ref) || scalar(@{$ref}) == 0){
        return '';
    }

    for(reverse @{$ref}){
        if($_ =~ $regex){
            return $_;
        }
    }
    return '';
}

sub _split_event{
    use bigint;
    local $_ = $_[0];
    my ($pid, $cpu, $ts) = m/^
                .{16}\-(\d+)\s+
                (?:\([\s\d-]{5}\)\s+)?
                \[(\d+)\]
                \s+(?:\S{4}\s+)?
                (\d+\.\d+)\:
                /xso;
    $ts =~ s/\.//go;
    return ($pid, $cpu, int($ts));
}

sub _max{
    use bigint;
    local $_;
    return (sort {$a <=> $b} grep {defined $_ } @_)[-1];
}

sub _ts{
    return (&_split_event($_[0]))[-1];
}

sub _binary_search_ts{
    my ($ref, $ts, $first) = @_;
    my ($last, $index) = ($#{$ref}, 0);
    local $_;

    if(!defined $first){
        $first = 0;
    }

    while($first < $last){
        use bigint;
        $index = int($first + $last)/2;
        my $index_ts = &_ts(${$ref}[$index]);

        if($ts == $index_ts){
            return $index;
        }elsif ($ts < $index_ts){
            $last = $index-1;
        }else{
            $first = $index+1;
        }
    }

    return $first;
}

# wrapper for trimming function
sub trim_events{
    local $_;
    if($_[0] =~ m/^\#\strimmed/xso){
        return \@_;
    }else{
        return _trim_events(\@_);
    }
}

# get rid of events that before cpu0
# detect if this is trace file in old format
# detect if any lost events in ftrace, which may cause parser confused
# delete unhandled irq events
sub _trim_events{
    local $_;
    my (@events, @cpu_1st_event_index, $splice_index, $event_count);
    my $cpu_hotplug_event_support = 0;
    $splice_index = 0;

    # filter comment & events not match our patterns out
    for(@{$_[0]}){
        if(m/^\#\senabled\s events\: .*
            \:\bcpu_hotplug\b/xso){
            $cpu_hotplug_event_support = 1;
        }elsif(/^\#/o){
            ; # skip comments
        }elsif(m/^.{16}\-\d+\s+
                  (?:\([\s\d-]{5}\)\s+)?
                  \[(\d+)\]/xso)
        {
            my $cpu = int($1);
            # the parsing will start from first cpu0 event
            if(defined $cpu_1st_event_index[0] || $cpu == 0){
                push (@events, $_);
                $event_count++;
                if(!defined $cpu_1st_event_index[$cpu]){
                    $cpu_1st_event_index[$cpu] = $#events ;
                }
            }
        }

        if(m/^\#\stracer\:\ssched_switch\b/xso){
            warn "$0: sched_switch tracer is not supported to convert with this script\n";
            exit 0;
        }
        if(/\blost\s.+\sevents\b/io){
            warn "$0: some events lost in raw trace data, the generated vcd may be incorrect\n";
        }
    }

    if(!defined $event_count){
        die "$0: no events available\n";
    }

    # if hotplug event support, transform the first index of each cpu
    if($cpu_hotplug_event_support){
        my @cpu_events_ts = map{
            if( m/\s
                cpu_hotplug\:\s
                cpu=\d+\s
                state=online\s
                last_offline_ts=(\d+)
            /xso){
                $1;
            }else{
                &_ts($_);
            }
           } @events[@cpu_1st_event_index];

        my $pivot_ts = &_max(@cpu_events_ts);
        $splice_index = &_binary_search_ts(\@events, $pivot_ts, $cpu_1st_event_index[0]);
        #warn "splice_index = $splice_index, pivot_ts=$pivot_ts\n";
        if(&_ts($events[$splice_index]) < $pivot_ts){
            $splice_index++;
        }
    }

    if($splice_index){
        splice @events, 0, $splice_index;
    }

    # filter out unhandled irq events
    my @output_events;
    my @irq_unhandled ;
    for(reverse @events){
        my $cpu = undef; 
        if(m/^.{16}\-\d+\s+
               (?:\([\s\d-]{5}\)\s+)?
            \[(\d+)\]/xso){
            $cpu = int($1);
        }

        if(m/\s
            irq_handler_exit\:\s+
            irq=(\d+)\s
            ret=unhandled
            /xso)
        {
            if(defined $cpu){
                $irq_unhandled[$cpu] = 1;
            }
        }elsif(defined $cpu              and 
            defined $irq_unhandled[$cpu] and
            $irq_unhandled[$cpu] == 1 and
            m/\s
            irq_handler_entry\:\s+
            irq=(\d+)\s
            name=(.+)
            /xso)
        {
            $irq_unhandled[$cpu] = 0;
        }else{
            unshift @output_events, $_ ;
        }
    }

    my @tracing_off_index = grep {$output_events[$_] =~ m/${tracing_on_regex}disabled/ } 0 .. $#output_events;
    if(scalar(@tracing_off_index) > 0){
        if($tracing_off_index[-1] == $#output_events){
            splice @output_events, $tracing_off_index[-1];
        }else{
            my $last_ts = (&_ts($output_events[-1]));
            my $last_hotplug_ts = (&_ts($output_events[$tracing_off_index[-1]]));
            # if the ts that tracing_on toggled to 0 and the last ts differ within 1ms, remove these events
            if(($last_ts - $last_hotplug_ts) < 1000){
                splice @output_events, $tracing_off_index[-1];
            }
        }
    }

    # ignore the first event if it is "toggled to 1" event
    if($output_events[0] =~ m/\s
            tracing_on\:\s
            ftrace\s is\s enabled
        /xso)
    {
        shift @output_events;
    }

    unshift(@output_events, "# trimmed\n");
    return \@output_events;
}

sub _basename{
    local $_ = $_[0];
    s;.*[\\\/]([^\/\\]+)[\\\/]*$;$1;xgos;
    return $_;
}

sub _dirname{
    local $_ = $_[0];
    s;(.*)[\\\/][^\/\\]+[\\\/]*$;$1;xgos;
    return $_;
}

1;
