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
#   patch process cmd such as <...> by post-processing

use strict;
use warnings;
use vars qw($h $c $b);

sub usage{
    if($h){
        print <<USAGE
Usage: $0 <input_file>
        fix process cmd in trace raw data
        -h: show usage
        -c: console mode, input from stdin and output to stdout
        -b: backup original version with .bak
USAGE
        ;
        exit 0;
    }

}

# trim space away
sub trim{
    (local $_) = @_;
    s/\s+//g;
    return $_;
}

sub main{
    my $input_file  = $_[0]||"SYS_FTRACE" ;
    my $output_file = $input_file;
    my %proc_table;
    my ($fout, @inputs);
    my $event_count = 0;

    if( -e $input_file and !defined $c){
        #warn "$0: input=$input_file, output=$output_file\n";
        open my $fin, '<', $input_file or die "$0: unable to open $input_file\n";
        @inputs = <$fin>;
        close $fin;
        open $fout, '>', $output_file or die "$0: unable to open $output_file\n";

        if($b){
            # backup original version
            open my $backup, '>', "$input_file.bak" or die "$0: unable to open $input_file.bak\n";
            print $backup @inputs;
            close $backup;
        }
    }else{
        warn "$0: $input_file not exist and read from stdin instead\n";
        @inputs = <STDIN>;
        open $fout, ">&=STDOUT" or die "$0: unable to alias STDOUT: $!\n"
    }

    for(@inputs){

        if(!m/^.{16}\-\d+\s*\[\d+\]\s+(?:\S{4}\s+)?\d+\.\d+\:/xso){
            next;
        }

        if(m/\s
            sched_switch\:\s+
            prev_comm=(.+)\s
            prev_pid=(\d+)\s
            prev_prio=\d+\s
            prev_state=\S+\s
            ==>\s
            next_comm=(.+)\s
            next_pid=(\d+)\s
            next_prio=\d+
            /xs)
        {

            $proc_table{$2}{name} = $1;
            $proc_table{$4}{name} = $3;

        }elsif(m/\s
            sched_wakeup(?:_new)?\:\s+
            comm=(.+)\s
            pid=(\d+)\s
            prio=\d+\s
            success=1\s
            target_cpu=\d+
            /xs)
        {

            $proc_table{$2}{name} = $1;
        }elsif(m/\s
            sched_migrate_task\:\s+
            comm=(.+)\s
            pid=(\d+)\s
            prio=\d+\s
            orig_cpu=\d+\s
            dest_cpu=\d+
            /xs)
        {
            $proc_table{$2}{name} = $1;
        }

    }

    for(@inputs){
        if(m/^\s{11}\<\.\.\.\>\-([\d\s]{5})/xso){
            my $pid = &trim($1);
            if(defined $proc_table{$pid}{name}){
                s/^\s{11}\<\.\.\.\>\-[\d\s]{5}/
                    sprintf("%16s-%-5d", $proc_table{$pid}{name}, $pid)/xse;
            }
        }
        print $fout "$_";
    }
    close $fout;
}

&usage();
&main(@ARGV);
