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
#   convert SYS_FTRACE into systrace html file

use strict;
use vars qw($s $h);

BEGIN {
    my $is_linux = $^O =~ /linux/;
    eval <<'USE_LIB' if($is_linux);
        use FindBin;
        use lib "$FindBin::Bin/lib/mediatek/";
USE_LIB
    eval 'use ftrace_parsing_utils;';
}
my $script_name = &_basename($0);
my @default_scripts_folders = (
    $s,
    ".",
    "./systrace",
    &_dirname($0)."/systrace",
    &_dirname($0),
);

sub usage {
    print <<USAGE
Usage: $script_name [-s=<folder>] <input_file> <output_file>
        convert ftrace into systrace-style format html file
        -h: show suage
        -s: specify the folder that contains html/javascript files, . by default
USAGE
    ;
}

# parameters: basename, folder1, folder2...
# return the file content if folderX/basename exists
sub read_file_content_if_exists{
    local $_ ;
    local $/ = undef;

    my ($basename, @folders) = @_;
    my $fullname ;
    for my $folder(@folders){
        $folder =~ s/[\/\\]+$//o;
        $fullname = "$folder/$basename";
        if(-e $fullname){
            last;
        }
    }

    if(-e $fullname ){
        warn "$basename: $fullname\n";
    }else{
        die "$script_name: fail to find $basename";
    }

    open my $fin, '<', $fullname or die "$script_name: unable to open $fullname\n";
    my $content = <$fin>;
    close $fin;
    return $content;
}

sub main{
    local $_;
    my ($input_file, $output_file) = ($_[0]||"SYS_FTRACE", $_[1]||"trace.html");
    our ($prefix_html, $suffix_html, $style_css, $script_js, $trace) ;

    if($h){
        &usage();
        exit 0;
    }

    open my $fin,   '<', $input_file or die "$script_name: unable to open $input_file\n";
    open my $fout,  '>', $output_file or die "$script_name: unable to open $output_file\n";

    $prefix_html = &read_file_content_if_exists("prefix.html", @default_scripts_folders);
    $suffix_html = &read_file_content_if_exists("suffix.html", @default_scripts_folders);
    $style_css = sprintf "<style type=\"text/css\">%s</style>",
                &read_file_content_if_exists("style.css", @default_scripts_folders);
    $script_js = sprintf "<script language=\"javascript\">%s</script>",
                &read_file_content_if_exists("script.js", @default_scripts_folders);

    $trace = join("\n", (map {
        s!(?:\\n\\)?[\r\n]+$!\\n\\!go;
        s;\bsched_wakeup_new\b;sched_wakeup;g;
        $_;
    } grep {
        m[
            \b(?:
                sched_wakeup(?:_new)?       |
                sched_switch                |
                ext4_sync_file_enter        |
                ext4_sync_file_exit         |
                block_rq_issue              |
                block_rq_complete           |
                cpu_idle					|
                cpu_frequency				|
                workqueue_execute_start		|
                workqueue_execute_end		|
                tracing_mark_write			|
                graph_ent					|
                graph_ret
            )\:\s
        ]xgso
    } <$fin>));

    close $fin;

    printf $fout $prefix_html, $style_css, $script_js, '';
    printf $fout "$trace\n$suffix_html\n";
    close $fout;

    # for(<>){
    #     s#(?:\\n\\)?[\r\n]+$##xsgo;
    #     m/\b(?:
    #             sched_wakeup(?:_new)?     |
    #             sched_switch              |
    #             ext4_sync_file_enter      |
    #             ext4_sync_file_exit       |
    #             block_rq_issue            |
    #             block_rq_complete         |
    #             cpu_idle					|
    #             cpu_frequency				|
    #             workqueue_execute_start		|
    #             workqueue_execute_end		|
    #             tracing_mark_write			|
    #             graph_ent					|
    #             graph_ret
    #         )\:\s
    #         /xgso
    #     ){
    #         s;\bsched_wakeup_new\b;sched_wakeup;g;
    #         print "$_\\n\\\n";
    #     }
    # }
}

&main(@ARGV);
