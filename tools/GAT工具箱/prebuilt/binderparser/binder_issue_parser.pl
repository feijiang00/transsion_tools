######
#
#       Filename:  binder_issue_parser.pl
#       Author: Lili Li
#       Data 2013-07-18
#
#       Interface:   
#           (flag) = &binder_issue_parser(db_dir, pid)
#           flag is 0 if ok; flag is err_code if failed.
#
#       @Interface change:
#           perl binder_issue_parser.pl  "extract db firetory" "exception process pid"
#           return 0 if ok; else fail.
#           
#       @example
#           perl binder_issue_parser.pl -d E:\CR\mtklog\aee_exp\db.00\db.00.dbg.DEC -p 1795
#            
#       Other behavior:
#       Besides, the script will write all_logs into db_dir\binder_analysis_info.log.
#       If write log fail, the script just keeps silen. 
#
#       History: 
# 		2013-07-18 test version v0.0
#####

#!/usr/bin/perl
use warnings;
use strict;

################### step 1: define global variables ###########################
#define the error code
my ($ERR_OK,$ERR_DIR,$ERR_FILE_NOEXIST,$ERR_OPEN_FILE,$ERR_PARSE_FILE,$ERR_WRITE_FILE, $ERR_ARGV) = 0..12;
my @err_code_meaning = ("OK", "input dir error", "db file not exist", "open file fail", "parse file fail", 
                        "write file fail", "argu error");

#the following files which contain binder debug infomation are from db_dir
my @db_files=qw/ZZ_INTERNAL
		__exp_main.txt
		SYS_KERNEL_LOG
		SYS_BINDER_INFO		
		SYS_BINDER_MEM_USED
		SYS_ANDROID_LOG
		SYS_PROCESSES_AND_THREADS
		SWT_JBT_TRACES
		SYS_MTK_VM_TRACES
		SYS_MTK_VM_TRACES_1
		SYS_BINDER_BACKTRACE/;

my @files_exist = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

my $binder_sop_link = "http://teams.mediatek.inc/sites/MBJ_WCTRD2_PS/System%20Service/Shared%20Documents/Public/Document/SOP/Binder_issue_analysis_SOP.pptx";
my $ANR_link = "http://wiki/display/Android/ANR";

my $ANR_parser = "\\\\glbfs14\\sw_releases\\Wireless_Global_Tools\\Tool_Release\\Debugging Tool\\GAT\\AF7\\anr_analyzer\\ANR_Analyzer.exe";
my $header = "binder:";
my %excep_classes = (
		"kernel" => "Kernel API Dump",
		"old_kernel" => "Kernel Module",
		"ANR" => "ANR",
		"SWT" => "SWT",
		"NE" => "Native (NE)",
		"JE" => "Java (JE)");

my %binder_err_pattern = (
		"size_info" => "allowed size",
		"buf_fail" => "buffer allocation failed on",
		"buf_fail2" => "binder_alloc_buf failed",
		"buf_size_fail" => "binder_alloc_buf size",
		"async_runout" => "no async space left",
		"buf_runout" => "no address space",
		"pends" => "pending transactions",
		"old_pends" => "pending transations",
		"buf_check_n" => "binder:check=0,success=1",
		"buf_check_y" => "binder:check=1,success=1",
		"total" => "total pending trans:",
		"largest" => "the largest pending trans is:",
		"no_vma" => "no vma",
		"invalid_fd" => "got transaction with invalid fd",
		"fd_over" => "no unused fd available",
		"null_target" => "target_proc is NULL",
		"cmd_err" => "unknown command");

my @buf_fail_reason = qw/small_pending
			large_sending
			unknown/;
my %binder_log_pattern = (
		"exit_with" => "exits with system_server DeathNotify",
		"exit_without" => "exits W/O system_server DeathNotify");

my @binder_tran_stack = qw/
		           incoming transaction
			   outgoing transaction
			   pending transaction/;
my @timeout_reason = qw/
		       read
		       exec
		       rrply/;
my @call_type = qw/call
		   async
		   reply/;
my @time_type = qw/over
		   total/;

my %binder_info = (
		   "failed_trans" => "BINDER FAILED TRANSACTION LOG",
	   	   "timeout_trans" => "BINDER TIMEOUT LOG",
	   	   "trans_log" => "BINDER TRANSACTION LOG",
	   	   "proc_trans" => "BINDER TRANSACTIONS",
	   	   "proc_stats" => "BINDER STATS");
my ($info_failed, $info_timeout, $info_transact, $info_proc, $info_all) = (1, 2, 4, 8, 15);
#	$log_type: 
#		1: failed
#		2: timeout
#		4: transaction
#		8: proc transactions
#		15: all
################### step 2: check and extract input parameters ##########################
my $db_dir = ".\\";
my $cmd_pid = 0;
my $manually = 0;
my $arg_num = @ARGV;
my $out_file = undef;
#print "[Info]: arg number $arg_num\n";
if ($arg_num > 0)
{
	while ($_ = shift @ARGV)
	{
		chomp;
		if (($_ eq "-h") || ($_ eq "--help"))
		{
			my ($help_info) = &Display_Help_Info;
			print $help_info;
			exit $ERR_OK;
		}
		elsif ($_ eq "-a")
		{
			last;
		}
#		elsif ($_ eq "-m")
#		{
#			$manually = 1;
#		}
		elsif ($_ eq "-d")
		{
			$db_dir = shift(@ARGV);
			if (!(-e $db_dir))
			{
				printf STDERR "[Parameter error]:$db_dir doesn't exist or is empty $_\n";
				exit $ERR_ARGV;
			}
		}
		elsif (($_ eq "-o") or ($_ eq "-out"))
		{
			$out_file = shift(@ARGV);
		}
		elsif ($_ eq "-p")
		{
			$cmd_pid = shift(@ARGV);
			$manually = 1;
			if ($cmd_pid < 0)
			{
				printf STDERR "[Parameter error]: $cmd_pid is a invalid pid\n";
				exit $ERR_ARGV;
			}
		}
	}
}

my $out_put_file = undef;
if (defined($out_file))
{
	$out_put_file = $out_file;
}
else
{
	$out_put_file = "$db_dir\\binder_analysis_info.log";
}

my $main_logs = "";
################## step 3: the main function to parse db folder ######################
my ($flag) =
&Parse_db_dir($db_dir, $out_put_file, $manually, $cmd_pid);

if ($flag == $ERR_OK)
{
	print "[Success]: please refer to $out_put_file\n";
	exit $ERR_OK;
}
else
{
	print STDERR "[Error]: $0 error code $flag $err_code_meaning[$flag]\n";
	exit $flag;
}

sub Parse_db_dir
{
	my $db_dir = shift;
	my $output = shift;
	my $manually = shift;
	my $cmd_pid = shift;

	my $all_logs;
	my $err_code = $ERR_OK;
	my $logs = "";
	my $index = 0;
	my $is_db = undef;
	my $file_full_name;

	## open output fd
	my $ok = open FDOUT, ">>", $output;
	if (!$ok)
	{
		print STDERR "[Error]: Can not open $output: $!\n";
		return ($ERR_WRITE_FILE);
	}
	$all_logs = "[Start!]============================================================\n";	

	# use Cwd;
	# my $abs_dir = getcwd; #get current abs path
	# check parse folder

	($err_code, $is_db, $logs) = &Check_Parse_Folder($db_dir);
	$all_logs .= $logs;
	if ($err_code ne $ERR_OK)
	{
		print STDERR "[Error]: Input db_path error\n";
		return ($err_code);
	}

	# parse mobilelog
	if ($is_db == 0)
	{
		($err_code, $logs) = &Parse_Mobilelog($db_dir, $cmd_pid);
		$all_logs .= $logs;
	}
	# parse db files
	elsif ($is_db == 1)
	{
		foreach $file_full_name (@db_files) 
		{
			$file_full_name = $db_dir . "\\" . $file_full_name;
			if (-s $file_full_name) 
			{
				$db_files[$index] = $file_full_name;
				$files_exist[$index] = 1;
			}
			else 
			{
				print "[Info]: $file_full_name is empty or not exist\n"
			}
			$index++;
		}

		## automatically parse exception class and exception process
		if ($manually == 0) # $cmd_pid = undef
		{

			## parse ZZ_INTERNAL to get basic exception info
			my($return_flag, $excep_class, $excep_pid, $excep_tid, $logs) = &Parse_ZZ();
			$all_logs .= $logs;
			if ($return_flag ne $ERR_OK)
			{
				$err_code = $return_flag;
				return ($err_code);
			}
			if (($excep_class ne $excep_classes{"kernel"}) and ($excep_class ne $excep_classes{"old_kernel"}))
			{
				$all_logs .= "[Info]: exception class is $excep_class, exception process is $excep_pid.\n";
			}
			if (($excep_pid le 0) and ($excep_class ne $excep_classes{"kernel"}) and ($excep_class ne $excep_classes{"old_kernel"}))
			{
				$all_logs .= "[Debug]: parse ZZ_INTERNAL and get invalid excep_pid $excep_pid\n";#debug
				$all_logs .= "         pls use \"-p pid\" to assign a process pid to parse binder info!\n";
				$all_logs .= "         pls use \"-h or --help\" for more help information!\n";
			}	
			## parse different db file for different exception type	
			if (($excep_class eq $excep_classes{"kernel"}) ||
				($excep_class eq $excep_classes{"old_kernel"}))
			{
				$all_logs .= "\n\n[Info]:================= Start Analyze Kernel Warning! ====================\n";
				$all_logs .= "[Basic Knowledge]: This exception is triggered in kernel while binder buffer allocation due to buffer runs out\n";
				$all_logs .= "            pls note that buffer always allocate from receiver\n";
				$all_logs .= "            Buffer size budget is 2 MB / process, async buffer budget is 1MB / process\n";
				$all_logs .= "            total buffer size is 2MB / process\n";
				my $sub_logs = "";
				($return_flag, $sub_logs) = &Analysis_Kernel_Warning($excep_pid, $cmd_pid);
				$all_logs .= $sub_logs;
				$err_code = $return_flag;
			}
			elsif ($excep_class eq $excep_classes{"ANR"})
			{
				my $sub_logs = "";
				($return_flag, $sub_logs) = &Analysis_ANR($excep_pid);
				$all_logs .= $sub_logs;
				$err_code = $return_flag;
			}
			elsif ($excep_class eq $excep_classes{"SWT"})
			{
				my $sub_logs = "";
				($return_flag, $sub_logs) = &Analysis_SWT($excep_pid);
				$all_logs .= $sub_logs;
				$err_code = $return_flag;
			}
			else 
			{
				my $sub_logs = "[Info]:================= Start Analyze $excep_class! ====================\n";
				($return_flag, $sub_logs) = &Parse_Assigned_PID($excep_pid);
				$all_logs .= $sub_logs;
				$all_logs .= "[Info]:================= End Analyze $excep_class! ====================\n";
				$err_code = $return_flag;
			}
		}
		## just parse binder db file for user assigned process
		elsif (($manually == 1) && defined($cmd_pid))
		{
			my $sub_logs = "";
			($err_code, $sub_logs) = &Parse_Assigned_PID($cmd_pid);
			$all_logs .= $sub_logs;
		}
		else
		{
			my ($help_info) = &Display_Help_Info;
			print STDERR "[Error]: input error! pls follow the help info:\n";
			print "$help_info\n";
			$err_code = $ERR_ARGV;
		}
	}
	$all_logs .= "[Done!]=====================================================\n";
	print FDOUT $main_logs;
	print FDOUT $all_logs;
	close FDOUT;
	return ($err_code);
}
################## step 4: the main function to parse exception type and exception process######################
##($return_flag, $excep_class, $excep_pid) = &Parse_ZZ();
sub Parse_ZZ
{
	my $parse_pid = 0;
	my $err_code = 0;
	my $err_msg = undef;
	my $logs = "";

	# content formant of ZZ_INTERNAL for NE flow
	# Exception Class(%s),excep_pid(%d),excep_tid(%d),99,/data/core/,Exception Level(%d),Exception Type,Exception Process,Time
	if ($files_exist[0])# ZZ_INTERNAL
	{
		my $success = open FD_INTER, "<", $db_files[0];
		if (!$success)
		{
			$err_code = $ERR_OPEN_FILE;
			$err_msg = "[Error]: open $db_files[0] fail! err $success\n";
			$logs .= $err_msg;
			print STDERR $err_msg;
			return ($err_code, undef, undef, undef, $logs);
		}
		my @excep_details = split(',', <FD_INTER>);
		#$logs = "[Info]: exception detarils @excep_details\n"; #debug
		#$logs = "[Info]: exception type is $excep_details[0]\n";
		return ($ERR_OK, $excep_details[0], $excep_details[1], $excep_details[2], $logs);
	}
	else
	{
		$err_code = $ERR_FILE_NOEXIST;
		$err_msg = "[Error]: $0 file $db_files[0] $err_code_meaning[$err_code]\n";
		print STDERR $err_msg;
		$logs .= $err_msg;
		return ($err_code, undef, undef, undef, $logs);
	}

}
################## step 5: parse different file for different exception type ######################
#($return_flag, $logs) = &Analysis_Kernel_Warning($excep_pid, $cmd_pid);
sub Analysis_Kernel_Warning
{
	my $excep_pid = shift;# for kernel warning exception type, $excep_pid = 0, it is useless.
	my $cmd_pid = shift;

	my $logs = "";
	my $return_flag = $ERR_OK;
	my $sender_pid = undef;
	my $sender_tid = undef;
	my $receiver_pid = undef;# receiver process is the key process that we shold check
	my $large_receiver_pid = undef;
	my $real_abnormal_pid = undef;# current sender / current receiver / the process who allocate large buffer before this allocation fail
	#my $check_receiver = 0;
	my $pending_num = undef;
	my $trans_size = undef;
	my $call = undef;
	my $history_large = 0;
	my %binder_buf_pattern = (
		"small_pend" => "small trans pending, check receiver",
		"large_pend" => "large data size,check sender",
		"check_hist" => "binder:check=1,success=1",
		"check_curr" => "binder:check=1,success=0");
	
	if ($files_exist[1]) # __exp_main.txt
	{
		my $ok = open FD_EXP_MAIN, "<", $db_files[1];
		my $exception = undef;
		my $line = undef;
		my $auto_dispatch = 0;
		my $sub_logs;
		my $err;
		while ($line = <FD_EXP_MAIN>)
		{
			## binder info format: binder:check=%d,success=%d,id=%d,call=%s,type=%s,from=%d,tid=%d,name=%s,to=%d,name=%s,tid=%d,name=%s,size=%d,node=%d,handle=%d,dex=%u,auf=%d,start=%lu.%03ld,android=%d-%02d-%02d %02d:%02d:%02d.%03lu\n 

			if (($line =~ /$binder_buf_pattern{"check_curr"}.*/s) || ($line =~ /$binder_buf_pattern{"check_hist"}.*/s))
			{
				if ($line =~ /$binder_buf_pattern{"check_hist"}.*/s)
				{
					$history_large = 1;
				}
				$exception = $line;
				my ($sender_temp, $receiver_temp, $size_temp) = (split(",", $exception))[5,8,12];
				$sender_pid = (split("=",$sender_temp))[1];
				$large_receiver_pid = (split("=", $receiver_temp))[1];
				$trans_size = (split("=", $size_temp))[1];
				$logs .= "[Info]: check binder trans: $exception\n"; #debug
				#$logs .= "[Debug]: sender $sender_pid receiver $large_receiver_pid size $trans_size\n";
				$auto_dispatch = 1;
			}
			# small size trans pending too much
			elsif(($pending_num, $receiver_pid) = ($line =~ /(\d+)\s$binder_buf_pattern{"small_pend"}\s(\d+)/)) # exg:876 small trans pending, check receiver 1752(ndroid.contacts)!
			{
				$main_logs .= "[Root Cause]: $receiver_pid pending too much($pending_num) small size transactions!\n";
				$main_logs .= "		      pls refer to $binder_sop_link session: Issue category->SOP->Buffer allocate failure CR auto dispatch\n\n"; 
				$logs .= "[Analysis]: receiver $receiver_pid pending too much($pending_num) small size transaction\n";
				$logs .= "	      there might 3 causes:\n";
				$logs .= "		  1). $receiver_pid is blocked by a transaction, please check:\n";
				$logs .= "			SYS_BINDER_INFO \"BINDER TIMEOUT LOG\" get process timeout log\n";
				$logs .= "			SYS_BINDER_INFO \"BINDER TRANSACTIONS\" \"proc $receiver_pid\" get incoming/outgoing/pending transaction log\n";
				$logs .= "			SYS_KERNEL_LOG get binder timeout log\n";
				$logs .= "		  2). $receiver_pid got bad performance and can not execut binder call efficiently. In this case please check your performance\n";
				$logs .= "		  3). sender processes call $receiver_pid too frequently, please check SYS_KERNEL_LOG or SYS_BINDER_INFO to find out sender process\n";
				$real_abnormal_pid = $receiver_pid;
				#$check_receiver = 1;
				my $log_type = $info_failed | $info_timeout | $info_proc;
				($err, $sub_logs) = &Parse_Binder_Info($receiver_pid, $log_type);
				$logs .= $sub_logs;
				if ($err)
				{
					$logs .= "[Error]: $0: call Parse_Binder_Info and got error: $err_code_meaning[$err]\n";
				}
				($err, $sub_logs) = &Parse_Kernel_Log($db_files[2], $receiver_pid, $sender_pid, $buf_fail_reason[0]);
				$logs .= $sub_logs;
				if ($err)
				{
					$logs .= "[Error]: $0: call Parse_Kernel_Log and got error: $err_code_meaning[$err]\n";
				}
				$return_flag = $err;
				last;
			}
			# trans data size is too large
			elsif(($sender_pid) = ($line =~ /^$binder_buf_pattern{"large_pend"}\s(\d+)/))# exg:large data size,check sender 559(system_server)!
			{
				$real_abnormal_pid = $sender_pid;
				$main_logs .= "[Root Cause]: $sender_pid send too much data($trans_size)!\n";
				$main_logs .= "		     pls refer to $binder_sop_link session: Issue category->SOP->Buffer allocate failure CR auto dispatch\n\n";
				$logs .= "[Analysis]: $sender_pid send too much data($trans_size) to $large_receiver_pid;pls $sender_pid split your data and send it by several binder transactions\n";
				$logs .= "            CR dispatch rule: allocate size > threshold, aee show sender name and dump sender backtrace.\n";
				$logs .= "	                        allocate size < threshold && have large pending transaction£¬aee show sender name of this large pending transaction.\n";
				$logs .= "	                        Threshold = buffer_size/16.\n";
				if ($history_large)
				{
					$logs .= "[Analysis]: The largest data transaction is not current fail transaction, no sender backtrace.\n";
				}
				#$check_receiver = 0;
				my $log_type = $info_failed | $info_timeout | $info_proc;
				($err, $sub_logs) = &Parse_Binder_Info($large_receiver_pid, $log_type);
				$logs .= $sub_logs;
				if ($err)
				{
					$logs .= "[Error]: $0: call Parse_Binder_Info and got error: $err_code_meaning[$err]\n";
				}
				($err, $sub_logs) = &Parse_Kernel_Log($db_files[2], $large_receiver_pid, $sender_pid, $buf_fail_reason[1]);
				$logs .= $sub_logs;
				if ($err)
				{
					$logs .= "[Error]: $0: call Parse_Kernel_Log and got error: $err_code_meaning[$err]\n";
				}
				$return_flag = $err;
				last;
			}
		}
		close FD_EXP_MAIN;
		if ($auto_dispatch == 0)
		{
			my ($flag, $sub_logs) = &Parse_Kernel_Log($db_files[2], $receiver_pid, undef, $buf_fail_reason[2]);
			$logs .= $sub_logs;
		}
		$logs .= "\n[Analysis]: more binder buffer analysis info please refer to $binder_sop_link session Issue category->SOP->Buffer allocate failure CR auto dispatch\n\n";
		$return_flag = $ERR_OK;
	}
	elsif (defined($cmd_pid) and ($cmd_pid > 1))
	{
		my ($flag, $sub_logs) = &Parse_Kernel_Log($db_files[2], $cmd_pid, undef, $buf_fail_reason[2]);
		$logs .= $sub_logs;
		$return_flag = $flag;
	}
	else
	{
		$logs .= "[Error]: $0: file $db_files[1] not exist\n";#debug
		$return_flag = $ERR_FILE_NOEXIST;
	}
	$logs .= "[Info]:================= End Analyze Kernel Warning! ====================\n";
	return ($return_flag, $logs);
}
##==================================================================================================
##	($return_flag, $logs) = &Analysis_ANR($excep_pid);
sub Analysis_ANR
{
	my $excep_pid = shift;

	my $return_flag = $ERR_OK;
	my $err_code = $ERR_OK;
	my $sub_logs = "";
	my $logs = "[Info]:================= Start Analyze ANR! ====================\n";

	$logs .= "[Basic Knowledge]:You can find ANR related information from Wiki: $ANR_link\n";
	$logs .= "			pls use ANR Analyzer for this issue firstly\n";
	$logs .= "			1. path: $ANR_parser\n";
	$logs .= "			2. If you need help, please contact with ANR Support PIC from Wiki\n";
	$logs .= "[Analysis]: If ANR is caused by remote binder call, the remote service might be blocked or had bad performance.\n";
	$logs .= "			Pls search binder timeout log from SYS_BINDER_INFO & SYS_KERNEL_LOG to find out the service name and check its behavior!\n";
	$logs .= "			For ANR binder log format and SOP, pls refer to $binder_sop_link session Binder Log -> Log details & Issue category->SOP->ANR\n\n";
	my $log_type = $info_timeout | $info_proc;
	($err_code, $sub_logs) = &Parse_Binder_Info($excep_pid, $log_type);
	$logs .= $sub_logs;
	if ($err_code ne $ERR_OK)
	{
		$return_flag = $err_code;
	}
	($err_code, $sub_logs) = &Parse_Kernel_Log($db_files[2], $excep_pid);
	$return_flag += $err_code;
	$logs .= $sub_logs;
	$logs .= "[Info]:================= End Analyze ANR! ====================\n";

	if ($return_flag ne $ERR_OK)
	{
		$return_flag = $ERR_PARSE_FILE;
	}
	return ($return_flag, $logs);
}
##===================================================================================================
#	($return_flag, $logs) = &Analysis_SWT($excep_pid);
sub Analysis_SWT
{
	my $excep_pid = shift;

	my $return_flag = $ERR_OK;
	my $sub_logs = "";
	my $logs = "\n[Info]:================= Start Analyze SWT! ====================\n";
	my $log_type = $info_timeout | $info_proc;
	$logs .= "[Analysis]: GAT auto parser will analysis this type of exception and output analysis info to __exp_main.txt\n";
	$logs .= "	      If SWT is caused by binder transaction timeout, pls search binder timeout log from SYS_BINDER_INFO & SYS_KERNEL_LOG\n";
	$logs .= "	      for binder timeout log format, pls refer to $binder_sop_link session Binder Log -> Log details & Issue category->SOP->ANR\n\n";
	($return_flag, $sub_logs) = &Parse_Kernel_Log($db_files[2], $cmd_pid);
	$logs .= $sub_logs;
	if ($return_flag)
	{
		$logs .= "[Error]: $0: call Parse_Kernel_Log and got error: $err_code_meaning[$return_flag]\n";
	}
	($return_flag, $sub_logs) = &Parse_Binder_Info($excep_pid, $log_type);
	$logs .= $sub_logs;
	if ($return_flag)
	{
		$logs .= "[Error]: $0: call Parse_Binder_Info and got error: $err_code_meaning[$return_flag]\n";
	}
	$logs .= "[Info]:================= End Analyze SWT! ====================\n";
	return ($return_flag, $logs);
}
############################## step 6. parse user assigned pid #################################
#	($err_code, $sub_logs) = &Parse_Assigned_PID($cmd_pid);
sub Parse_Assigned_PID
{
	my $cmd_pid = shift;

	my $return_flag = $ERR_OK;
	my $sub_logs = "";
	my $main_logs = "";
	my $log_type = $info_failed | ($info_timeout | $info_proc);
	my $logs = "[Info]:================= Start Analyze binder info for $cmd_pid! ====================\n";

	($return_flag, $sub_logs) = &Parse_Kernel_Log($db_files[2], $cmd_pid);
	$logs .= $sub_logs;
	if ($return_flag)
	{
		$logs .= "[Error]: $0: call Parse_Kernel_Log and got error: $err_code_meaning[$return_flag]\n";
	}
	($return_flag, $sub_logs) = &Parse_Binder_Info($cmd_pid, $log_type);
	$logs .= $sub_logs;
	if ($return_flag)
	{
		$logs .= "[Error]: $0: call Parse_Binder_Info and got error: $err_code_meaning[$return_flag]\n";
	}
	($return_flag, $sub_logs) = &Parse_Binder_Mem($cmd_pid);
	$logs .= $sub_logs;
	if ($return_flag)
	{
		$logs .= "[Error]: $0: call Parse_Binder_Mem and got error: $err_code_meaning[$return_flag]\n";
	}
	$logs .= "[Info]:================= End Analyze binder info for $cmd_pid! ====================\n";

	($main_logs) = &Parse_Root_Cause($logs);
	return ($ERR_OK, $main_logs);
}
############################## step7. implement other sub function #########################################################
#	($err_code, $logs) = &Parse_Mobilelog($db_dir, $cmd_pid);
sub Parse_Mobilelog
{
	my $db_dir = shift;
	my $cmd_pid = shift;
	#parse mobilelog
	my @kfiles;
	my $tmp_file = undef;
	my $logs = "";
	my $main_logs = "";
	my $err_code = $ERR_OK;

	opendir FD_MLOG, $db_dir or die "[Error]: Can not open $db_dir: $!\n";

	if (!defined($cmd_pid))
	{
		my $err_msg = "[Error]: parsing mobilelog, pls use \"-p pid\" to input your pid.\n";
		print STDERR $err_msg;
		$logs .= $err_msg; 
		$err_code = $ERR_ARGV;
		return ($err_code, $logs);
	}
	#$logs .= "[Info]: pls refer to $binder_sop_link for more help!\n";
	foreach $tmp_file (readdir FD_MLOG)
	{
		next if $tmp_file eq "." or $tmp_file eq "..";
		if ($tmp_file =~/APLog\w+/)
		{
			$tmp_file = "$db_dir\\$tmp_file";
			opendir FD_LOG, $tmp_file or die "[Error]: Can not open $tmp_file: $!\n";
			foreach my $log_file (readdir FD_LOG)
			{
				next if $tmp_file eq "." or $tmp_file eq "..";
				if ($log_file =~/kernel_log/)
				{
					$log_file = "$tmp_file\\$log_file";
					push (@kfiles, $log_file);
					#print "[Info]: kernel log file $log_file\n";
				}
			}
		}
		elsif ($tmp_file =~/kernel_log/)
		{
			$tmp_file = "$db_dir\\$tmp_file";
			push (@kfiles, $tmp_file);
		}
	}
	#print "[Debug]: @kfiles\n";#debug
	my $err = $ERR_OK;
	my $sub_log;
	my $tmp = undef;
	foreach $tmp (@kfiles)
	{
		($err, $sub_log) = &Parse_Kernel_Log($tmp, $cmd_pid);
		
		$err_code += $err;
		$logs .= $sub_log;
	}
	if ($err_code > 0)
	{
		$err_code = $ERR_PARSE_FILE;
	}
	($main_logs) = &Parse_Root_Cause($logs);
	return ($err_code, $main_logs);
}
## ====================================================================================================##
#	($flag, $sub_logs) = &Parse_Kernel_Log($db_files[2], $receiver_pid, $sender_pid, $buf_fail_reason[0], $check_receiver);
sub Parse_Kernel_Log
{
	my $kernel_path = shift;
	my $receiver_pid = shift;
	my $sender_pid = shift;
	my $reason = shift;
	
	my $from_pid = undef;
	my $from_tid = undef;
	my $to_pid = undef;
	my $to_tid = undef;
	my $process_exit = 0;
	my $binder_proc_exit = 0;
	my $type = undef;
	my $to_reason = undef;

	my $logs = "\n";
	my $return_flag = $ERR_OK;

	if (!defined($receiver_pid) or ($receiver_pid < 1))
	{
		$receiver_pid = "\\d\+";
	}
	my $cmd_pid = $receiver_pid;

	#$logs .= "[Debug]:parse kernel log argv: $kernel_path, $receiver_pid, $sender_pid, $reason\n";#debug
	if (! -e $kernel_path)
	{
		$return_flag = $ERR_FILE_NOEXIST;
		$logs .= "[Error]: $0 $kernel_path dot exist!\n";
		return ($return_flag, $logs);
	}

	my @path = split("\\\\", $kernel_path);
	my $last_path = $path[-1];
	$logs .= "[Info]:======== Start parsing $last_path =================\n";
	my $ok = open FD_KERNEL, "<", $kernel_path;
	if (!$ok)
	{
		$logs .= "[Error]: $kernel_path exist but open fail!\n";
		$logs .= "[Info]: =========== Exit parsing $last_path ============\n";
		$return_flag = $ERR_OPEN_FILE;
		return ($return_flag, $logs);
	}

	my $kline = undef;
	my $temp_line = undef;
	while ($kline = <FD_KERNEL>)
	{

		#parse buffer fail info
		#binder: 1795: binder_alloc_buf size 1046588 failed, no async space left (1044480)
		if ($kline =~ /.*$header\s+$receiver_pid.*$binder_err_pattern{"async_runout"}/)
		{
			$logs .= $kline;
		}
		#binder: 1795: binder_alloc_buf size 1046588 failed, no address space
		elsif ($kline =~ /.*$header\s+$receiver_pid.*$binder_err_pattern{"buf_runout"}/)
		{
			$logs .= $kline;
		}
		#binder: 1752: got transaction with too large size async alloc size 556096-4 allowed size 524244
		elsif ($kline =~ /.*$header\s$receiver_pid.*$binder_err_pattern{"size_info"}\s*\d+/s)
		{
			$logs .= $kline;
		}
		#binder: buffer allocation failed on 1724:0 async from 622:1999 size 567988
		elsif (($to_pid, $temp_line) = ($kline =~ /.*$header\s+$binder_err_pattern{"buf_fail"}\s+($receiver_pid)(.*)/))
		{
			$logs .= $kline;
			#$logs .= "[Analysis]: It means allocate buffer on remote(receiver) process $to_pid failed!\n\n";
			if (($from_pid, $from_tid) = ($temp_line =~ /.*from\s+(\d+):(\d+)/))
			{
				if ($from_pid > 0)
				{
					$logs .= "[Analysis]: This is the first allocation failed exception on $to_pid which should be checked\n\n";
				}
				#elsif ($from_pid == -1)
				#{
				#	$logs .= "[Analysis]: This is not the first allocation failed exception on $to_pid, just for reference\n\n";
				#}
			}
		}
		elsif ($kline =~ /.*$header\s+$receiver_pid\s+$binder_err_pattern{"buf_size_fail"}/)
		{
			$logs .= $kline;
		}
		#binder: 1752:0 pending transactions:
		elsif (($kline =~ /.*$header\s$receiver_pid:0\s$binder_err_pattern{"pends"}:/s) ||
			($kline =~ /.*$header\s$receiver_pid:0\s$binder_err_pattern{"old_pends"}:/s))
		{
			$logs .= $kline;
		}
		#binder: 336659 sync  exec 6284:6304 to 6263:6638 () dex 3 size 336:0 auf 1 start 4747.943 android 2013-04-07 19:15:48.315 # old style
		elsif ($kline =~ /.*$header\s+\d+\s+\w+\s+\w+\s+\d+:\d+\s+to\s+$receiver_pid:\d+\s+\(\w*\)\s+dex\s+\d+\s+size\s+\d+:\d+/)
		{
			$logs .= $kline;
		}
		#binder:check=0,success=1,id=304643,call=sync,type=reply,from=635,tid=635,name=system_server,to=1752,name=ndroid.contacts,tid=1769,name=,size=8,node=0,handle=-1,dex=0,auf=1,start=1377.289, 
		elsif ($kline =~ /.*$binder_err_pattern{buf_check_n}.*to=$receiver_pid.*/s)
		{
			$logs .= $kline;
			#$logs .= "[Analysis]: check=0,success=1 means this binder transaction allocated buffer successly, we just refer to it for buffer usage.\n";
		}
		elsif ($kline =~ /.*$binder_err_pattern{buf_check_y}.*to=$receiver_pid.*/s)
		{
			$logs .= $kline;
			$logs .= "[Analysis]: check=1,success=1 means this binder transaction allocated buffer successly, but it's data size is too large which result in binder call fail for the following binder user.\n\n";
		}
		#binder: 1752:0 total pending trans: 6(0 large isze)
		elsif ($kline =~/.*$header\s?$receiver_pid:0\s*to=\s*(\d+)/s)
		{
			$logs .= $kline;
		}
		elsif (defined($reason) && ($reason eq $buf_fail_reason[1]))
		{
			if ($kline =~/.*$header.*$receiver_pid:0\s*$binder_err_pattern{"largest"}/s)
			{
				$logs .= $kline;
			}
		}
		#binder: 1752: binder_alloc_buf, no vma
		elsif (($to_pid) = ($kline =~ /.*$header\s+($receiver_pid):\s+.*$binder_err_pattern{"no_vma"}/))
		{
			$logs .= $kline;
			$logs .= "[Analysis]: can not find vma of $to_pid\; it may had exit before this binder call.\n";
			$logs .= "	      there are 2 causes:\n";
			$logs .= "		1). you didn't register deathnotify of $to_pid.\n";
			$logs .= "		2). this process had just exit before you call it.\n";
			$logs .= "            pls refer to $binder_sop_link session: Issue category->Case sharing->Death notification\n";
		}

		# parse other error
		elsif (!defined($reason))
		{
			#binder: 191:371 got transaction with invalid fd, -1 
			if(($from_pid, $from_tid) = ($kline =~ /.*$header\s+($cmd_pid):(\d+)\s+$binder_err_pattern{"invalid_fd"}.*/))
			{
				$logs .= $kline;
				$logs .= "[Analysis]:It means process $from_pid:$from_tid shared an invalid file;\n";
				$logs .= "           It could be fd leak or error fd usage, pls check source code between $from_pid:$from_tid and receiver.
				\n";
			}
			#binder: 273:458 no unused fd available, -24
			elsif (($from_pid, $from_tid) = ($kline =~ /.*$header\s+($cmd_pid):(\d+).*$binder_err_pattern{fd_over}.*/))
			{
				$logs .= $kline;
				$logs .= "[Analysis]: It mean $from_pid:$from_tid shared an valid file; but receiver have run out it's fd limitation\n";
				$logs .= "	      It might be fd leak on the receiver, please check failed transaction log for more info\n";
				$logs .= "	      pls refer to binder issue analysis sop session case sharing->main log error\n";
			}
			#binder: 237:458 target_proc is NULL
			elsif (($from_pid, $from_tid) = ($kline  =~ /.*$header\s+($cmd_pid):(\d+)\s+$binder_err_pattern{"null_target"}.*/))
			{
				$logs .= $kline;
				$logs .= "[Analysis]: It means $from_pid:$from_tid start a binder call; however, the remote process had exit\n\n";
			}
			elsif (($to_pid) = ($kline =~ /.*$header\s+($cmd_pid):\s+$binder_err_pattern{"buf_fail2"}.*/))
			{
				$logs .= $kline;
				$logs .= "[Analysis]: It means fail to allocate buffer on $to_pid!\n";
			}

			#[4905:roid.music:main][4905:roid.music:main] exit
			elsif (($cmd_pid =~ /\d+/) and ($kline =~ /.*\[$cmd_pid:[\w\/:\.\-\d]+\]\s+exit\s/))
			{
				$logs .= $kline;
				$process_exit = 1;
			}
			#[3724:kworker/u:3]binder: 12164:screencap exits with system_server DeathNotify
			elsif ($kline =~ /.*$header\s+$cmd_pid:[\w\/:\.\-\d]+\s+$binder_log_pattern{"exit_with"}/)
			{
				$logs .= $kline;
				$binder_proc_exit = 1;
			}
			#[3724:kworker/u:3]binder: 12164:screencap exits W/O system_server DeathNotify
			elsif ($kline =~ /.*$header\s+$cmd_pid:[\w\/:\.\-\d]+\s+$binder_log_pattern{"exit_without"}/)
			{
				$logs .= $kline;
				$binder_proc_exit = 1;
			}
			#binder: 70069 exec 629:629 to 135:1040 over 4.000 sec () dex_code 3 start_at 702.066 android 2013-06-01 01:44:40.538
			#binder: 34044 exec 1724:1816 to 911:922 total 40.788 sec () dex_code 1 start_at 124.052 android 2012-01-01 08:00:47.393
			elsif ((($to_reason, $from_pid, $from_tid, $to_pid, $to_tid, $type) = ($kline =~ /.*$header\s+\d+\s+(\w+)\s+($cmd_pid):(\d+)\s+to\s+(\d+):(\d+)\s+(\w+)\s+[\d\.]+\s+sec/)) &&
				($to_reason ~~ @timeout_reason) && ($type ~~ @time_type))
			{
				my $sub_flag = $ERR_OK;
				my $sub_logs = undef;
				$logs .= $kline;
				if ($to_reason eq $timeout_reason[0])
				{
					$logs .= "[Analysis]: Receiver $to_pid:$to_tid read this binder call timeout, pls check it\n\n";
					#($sub_flag, $sub_logs) = &Parse_Kernel_Log($db_files[2], $to_pid);
					#$logs .= $sub_logs;
				}
				elsif ($to_reason eq $timeout_reason[1])
				{
					$logs .= "[Analysis]: Receiver $to_pid:$to_tid got binder call from $from_pid:$from_tid but execution timeout, pls check $to_pid:$to_tid\n\n";
				}
				elsif ($to_reason eq $timeout_reason[2])
				{
					$logs .= "[Analysis]: $to_pid:$to_tid had execute completely and sent reply, but $from_pid:$from_tid read this reply timeout; pls check $cmd_pid:$from_tid\n\n";
				}
			}
			elsif ((($to_reason, $type) = ($kline =~ /.*$header\s+\d+\s+(\w+)\s+\d+:\d+\s+to\s+$cmd_pid:\d+\s+(\w+)\s+[\d\.]+\s+sec/)) &&
				($to_reason ~~ @timeout_reason) && ($type ~~ @time_type))
			{
				$logs .= $kline;
			}
			elsif (($from_pid, $from_tid) = ($kline =~ /.*$header\s+($cmd_pid):(\d)+\s+$binder_err_pattern{"cmd_err"}/))
			{
				$logs .= $kline;
				$logs .= "[Analysis]: It means $from_pid:$from_tid binder call with a wrong command code, pls check your user space code!\n\n";
			}
		}
#		}
#		# parse kernel log for old branch
#		elsif ($receiver_pid == 0)
#		{
#			foreach my $pattern(%binder_log_pattern)
#			{
#				if ($kline =~ /.*$header.*$pattern/)
#				{
#					$logs .= $kline;
#				}
#			}
#		}
	}
	$logs .= "[Info]:======== End parsing $last_path ==================\n";
	close FD_KERNEL;

	return ($return_flag, $logs);
}
## ====================================================================================================##
#	($return_flag, $sub_logs) = &Parse_Binder_Info($excep_pid, $log_type);
#	$log_type: 
#		1: failed
#		2: timeout
#		4: transaction
#		8: proc transactions
#		15: all
sub Parse_Binder_Info
{
	my $excep_pid = shift;
	my $log_type = shift;
	my $return_flag = $ERR_OK;
	my $excep_tid;
	my $from_pid;
	my $from_tid;
	my $to_pid;
	my $to_tid;
	my $logs = "";
	my $failed_logs = "";
	my $timeout_logs = "";
	my $trans_logs = "";
	my $process_logs = "";
	my $analysis_logs = "";

	if ($files_exist[3] == 0)
	{
		$return_flag = $ERR_FILE_NOEXIST;
		$logs .= "[Error]: $0 file $db_files[3] not exist\n";
		return ($return_flag, $logs);
	}

	$logs .= "\n[Info]:======== Start parsing SYS_BINDER_INFO =================\n";
	my $ok = open FD_BINDER, "<", $db_files[3];
	if (!$ok)
	{
		$logs .= "[Error]: $db_files[3] exist but open fail! err $ok\n";
		$logs .= "[Info]: =========== Exit parsing SYS_BINDER_INFO ============\n\n";
		$return_flag = $ERR_OPEN_FILE;
		return ($return_flag, $logs);
	}
	my $bline = undef;
	my $tmp_logs = "";
	while ($bline = <FD_BINDER>)
	{
		my $type = undef;
		my $reason = undef;
		my $sub_flag = $ERR_OK;
		my $sub_logs = "";
		my $sub_log_type = undef;

		# parse failed transaction
		if ($log_type & $info_failed)
		{
			if ($bline =~ /-+\s+$binder_info{"failed_trans"}\s+-+/)
			{
				$tmp_logs .= "\n\n[Info]: Start parse failed transaction log for $excep_pid!\n";
			}
			elsif ((($type) = ($bline =~ /\d+:\s+(\w+)\s+from\s+$excep_pid:\d+.*/)) && ($type ~~ @call_type))
			{
				$tmp_logs .= $bline;
			}
			elsif ((($type) = ($bline =~ /\d+:\s+(\w+)\s+from\s+\d+:\d+\s+to\s+$excep_pid:\d+.*/)) && ($type ~~ @call_type))
			{
				$tmp_logs .= $bline;
			}
		}
		if ($bline =~ /-+\s+$binder_info{"timeout_trans"}\s+-+/)
		{
			$failed_logs .= $tmp_logs;
			if ($log_type & $info_timeout)
			{
				$tmp_logs = "\n\n[Info]: Start parse timeout transaction log for $excep_pid!\n";
			}
			else
			{
				$tmp_logs = "";
			}
		}
		#parse timeout log
		if ($log_type & $info_timeout)
		{
			#2:exec 9283:9283 to 138:138 spends 4000 ms () dex_code 3 start_at 218167.808 android 2013-05-07 08:01:25.741
			if ((($reason, $excep_tid, $to_pid, $to_tid) = ($bline =~ /\d+:(\w+)\s+$excep_pid:(\d+)\s+to\s+(\d+):(\d+)\s+spends\s+\d+\s+ms.*/)) &&
				($reason ~~ @timeout_reason))
			{
				$tmp_logs .= $bline;
				if ($reason eq $timeout_reason[0])
				{
					$tmp_logs .= "[Analysis]: This binder call is waiting for $to_pid:$to_tid to read up. pls check if $to_pid:$to_tid was blocked or too busy!\n\n";
					#$sub_log_type = $info_timeout | $info_proc;
					#($sub_flag, $sub_logs) = &Parse_Binder_Info($to_pid, $sub_log_type);
					#$tmp_logs .= $sub_logs;
				}
				elsif ($reason eq $timeout_reason[1])
				{
					$tmp_logs .= "[Analysis]: This binder call is waiting for $to_pid:$to_tid to executing complete. pls check if $to_pid:$to_tid was blocked or couldn't get enough CPU resource!\n\n";
					#$sub_log_type = $info_timeout | $info_proc;
					#($sub_flag, $sub_logs) = &Parse_Binder_Info($to_pid, $sub_log_type);
					#$tmp_logs .= $sub_logs;
				}
				elsif ($reason eq $timeout_reason[2])
				{
					$tmp_logs .= "[Analysis]: This binder call is completed, but $excep_pid didn't read reply in time. pls check if $excep_pid was blocked or too busy!\n\n";
				}
			}
			elsif ((($reason, $from_pid, $from_tid, $excep_tid) = ($bline =~ /\d+:(\w+)\s+(\d+):(\d+)\s+to\s+$excep_pid:(\d+)\s+spends\s+\d+\s+ms.*/)) &&
				($reason ~~ @timeout_reason))
			{
				$tmp_logs .= $bline;
				if ($reason eq $timeout_reason[0])
				{
					$tmp_logs .= "[Analysis]: This binder call is waiting for $excep_pid:$excep_tid to read up. pls check if $excep_pid:$excep_tid was blocked or too busy!\n\n";
				}
				elsif ($reason eq $timeout_reason[1])
				{
					$tmp_logs .= "[Analysis]: This binder call is waiting for $excep_pid:$excep_tid to executing complete. pls check if $excep_pid:$excep_tid was blocked or couldn't get enough CPU resource!\n\n";
				}
				elsif ($reason eq $timeout_reason[2])
				{
					$tmp_logs .= "[Analysis]: This binder call is completed, but $from_pid:$from_tid didn't read reply in time. pls check $from_pid!\n\n";
				}
			}
		}
		if ($bline =~/-+\s+$binder_info{"trans_log"}\s+-+/)
		{
			$timeout_logs .= $tmp_logs;
			if ($log_type & $info_transact)
			{
				$tmp_logs = "\n\n[Info]: Start parse transaction log for $excep_pid!\n";
			}
			else
			{
				$tmp_logs = "";
			}
		}
		# parse binder transaction log
		if ($log_type & $info_transact)
		{
			#32250: call  from 688:688 to 132:0 node 4659 handle 42 () size 128:4 (fd 55) dex 4 start 74.554557 android 2013-07-17 19:13:35.183 read 74.554662 end 74.554984 total 0.426846ms
			if ((($type, $excep_tid, $to_pid, $to_tid) = ($bline =~/\d+:\s+(\w+)\s+from\s+$excep_pid:(\d+)\s+to\s+(\d+):(\d+).*/)) &&
				($type ~~ @call_type))
			{
				$tmp_logs .= $bline;
			}
			if ((($type, $from_pid,$from_tid, $excep_tid) = ($bline =~/\d+:\s+(\w+)\s+from\s+(\d+):(\d+)\s+to\s+$excep_pid:(\d+).*/)) &&
				($type ~~ @call_type))
			{
				$tmp_logs .= $bline;
			}
		}
		if ($bline =~/-+\s+$binder_info{"proc_trans"}\s+-+/)
		{
			$trans_logs .= $tmp_logs;
			if ($log_type & $info_proc)
			{
				$tmp_logs = "\n\n[Info]: Start parse executing & pending transactions for $excep_pid!\n";
			}
			else
			{
				$tmp_logs = "";
			}
		}
		# parse binder proc executing & pending transactions
		if ($log_type & $info_proc)
		{
			#outgoing transaction 22195516: c3402d80 from 9283:9283 to 138:138 code 3 flags 10 pri 0 r1 node 22194137 size 80:0 data e3000124
			if (($from_pid, $from_tid, $to_pid, $to_tid) = ($bline =~/$binder_tran_stack[1]\s+\d+:\s+\w+\s+from\s+(\d+):(\d+)\s+to\s+(\d+):(\d+).*/))
			{
				if (($from_pid eq $excep_pid) || ($to_pid eq $excep_pid)
					|| (($from_pid eq 0) && ($from_tid eq 0)) || (($to_pid eq 0) && ($to_tid eq 0)))
				{
					$tmp_logs .= $bline;
					$tmp_logs .= "[Analysis]: This binder call is waiting for $to_pid:$to_tid to executing complete.\n\n";
				}
			}
			#incoming transaction 22195516: c3402d80 from 9283:9283 to 138:138 code 3 flags 10 pri 0 r1 node 22194137 size 80:0 data e3000124`
			if (($from_pid, $from_tid, $to_pid, $to_tid) = ($bline =~/$binder_tran_stack[0]\s+\d+:\s+\w+\s+from\s+(\d+):(\d+)\s+to\s+(\d+):(\d+).*/))
			{
				if (($from_pid eq $excep_pid) || ($to_pid eq $excep_pid)
					|| (($from_pid eq 0) && ($from_tid eq 0)) || (($to_pid eq 0) && ($to_tid eq 0)))
				{
					$tmp_logs .= $bline;
					$tmp_logs .= "[Analysis]:This binder call is waiting for $to_pid:$to_tid to executing complete.\n\n";
				}
			}
			#pending transaction 173620: c6c44240 from 0:0 to 2870:0 code 16 flags 10 pri 0 r1 node 173599 size 80:4 data d620005c
			if (($from_pid, $from_tid, $to_pid, $to_tid) = ($bline =~ /$binder_tran_stack[2]\s+\d+:\s+\w+\s+from\s+(\d+):(\d+)\s+to\s+(\d+):(\d+).*/))
			{
				if (($from_pid eq $excep_pid) || ($to_pid eq $excep_pid)
					|| (($from_pid eq 0) && ($from_tid eq 0)) || (($to_pid eq 0) && ($to_tid eq 0)))
				{
					$tmp_logs .= $bline;
					$tmp_logs .= "[Analysis]: This binder call is pending on $to_pid\'s todo list; check $excep_pid.\n\n";
				}
			}
		}
		if ($bline =~/-+\s+$binder_info{"proc_stats"}\s+-+/)
		{
			$process_logs .= $tmp_logs;
			$tmp_logs = "[Info]:======== End parsing SYS_BINDER_INFO =================\n\n";
			last;
		}
	}
	if ($log_type & $info_failed)
	{
		$logs .= $failed_logs;
	}
	if ($log_type & $info_timeout)
	{
		$logs .= $timeout_logs;
	}
	if ($log_type & $info_proc)
	{
		$logs .= $process_logs;
	}
	if ($log_type & $info_transact)
	{
		$logs .= $trans_logs;
	}
	close FD_BINDER;
	return ($return_flag, $logs);
}

##=========================================================================================##
#	($return_flag, $sub_logs) = &Parse_Binder_Mem($cmd_pid);
sub Parse_Binder_Mem
{
	my $cmd_pid = shift;

	my $err_code = $ERR_OK;
	my $logs = "\n";

	if ($files_exist[4])
	{
		my $ok = open FD_MEM, "<", $db_files[4];
		if (!$ok)
		{
			$err_code = $ERR_OPEN_FILE;
			$logs .= "[Error]: $db_files[4] exist but open fail\n";
			return ($err_code, $logs);
		}

		$logs .= "[Info]: binder physical memory usage:\n";
		my $line = undef;
		my $cmd_peak = undef;
		my $max_peak = 0;
		my $max_line = undef;
		my $max_pid = undef;
		my $temp_peak = 0;
		my $temp_line = undef;
		my $temp_pid = undef;
		while ($line = <FD_MEM>)
		{
			if ($line =~ /^page_used:\d+\[\d+MB\]$/)
			{
				$logs .= $line;
			}
			elsif ($line =~ /^page_used_peak:\d+\[\d+MB\]$/)
			{
				$logs .= $line;
			}
			elsif (($temp_pid, $temp_peak) = ($line =~ /proc\s(\d+).*page_used_peak:(\d+)/))
			{
				if ($temp_pid eq $cmd_pid)
				{
					$cmd_peak = $temp_peak;
					$logs .= "current process usage:" . $line;
				}
				if ($temp_peak > $max_peak)
				{
					$max_pid = $temp_pid;
					$max_peak = $temp_peak;
					$max_line = $line;
				}
			}
		}
		$logs .= "max usage is: $max_line\n";
		return ($err_code, $logs);
	}
	else
	{
		return ($err_code, $logs);
	}
}
##=========================================================================================##
#	($err_code, $is_db, $logs) = &Check_Parse_Folder($db_dir);
sub Check_Parse_Folder
{
	my $dir = shift @_;
	my $is_db = undef;
	my $err_code = $ERR_OK;
	my $logs = "";

	if ($dir eq ".\\")
	{
		opendir FD_DB, $dir or die "[Error]: Can not open current folder $db_dir: $!\n";
		foreach my $file (readdir FD_DB)
		{
			if ($file ~~ @db_files)
			{
				$is_db = 1;
				$logs .= "[Info]: Input path is db folder!\n";
				return ($err_code, $is_db, $logs);
			}
			elsif ($file =~ /kernel_log/)
			{
				$is_db = 0;
				$logs .= "[Info]: Input path is mobilelog folder!\n";
				return ($err_code, $is_db, $logs);
			}
		}
		close FD_DB;
	}
	elsif ($db_dir =~ /.dbg/)
	{
		$is_db = 1;
		return ($err_code, $is_db, $logs);
	}
	elsif (($db_dir =~ /mobilelog/) or ($db_dir =~ /APLog/))
	{
		$is_db = 0;
		return ($err_code, $is_db, $logs);
	}
	else 
	{
		my $err_msg = "[Error]: $0: input folder is not mobilelog or db folder\n";
		print STDERR $err_msg;
		$logs .= $err_msg;
		$err_code = $ERR_DIR;
		return ($ERR_DIR, $is_db, $logs)
	}
}

##====================================================================================##
#
sub Parse_Root_Cause
{
	my $logs = shift;
	my $err_logs = undef;
	my $main_logs = "";
	my @temp = split("\n",$logs);
	foreach (@temp)
	{
		chomp($_);
		if ($_ =~ /$binder_err_pattern{"buf_fail"}/)
		{
			$err_logs = "[Root Cause]: allocate binder buffer failed!\n";
			$err_logs .= "              Pls refer to $binder_sop_link session: Issue category->SOP->Buffer allocate failure CR auto dispatch\n\n";
			$err_logs .= $_;
			$err_logs .= "\n";
			last;
		}
		elsif (($_ =~ /$binder_err_pattern{"invalid_fd"}/) or ($_ =~ /$binder_err_pattern{"fd_over"}/))
		{
			$err_logs = "[Root Cause]: share fd error!\n";
			$err_logs .= "              Pls refer to $binder_sop_link session: Issue category->Case sharing->Main log error->case A/B\n\n";
			$err_logs .= $_;
			$err_logs .= "\n";
			last;
		}
		elsif ($_ =~ /$binder_err_pattern{"null_target"}/)
		{
			$err_logs = "[Root Cause]: remote binder call exit process!\n";
			$err_logs .= "              Pls refer to $binder_sop_link for more help\n\n";
			$err_logs .= $_;
			$err_logs .= "\n";
			last;
		}
	}
	if (!defined($err_logs))
	{
		$err_logs = "Pls refer to $binder_sop_link!\n";
	}
	$main_logs .= $err_logs;
	$main_logs .= $logs;
	return ($main_logs);
}

##======================================================================================##
#	($help_info) = Display_Help_Info
sub Display_Help_Info
{
	my $template = <<"__TEMPLATE";
Usage: perl binder_issue_parser.pl [Options] [-d db_path] [-p parse_pid] [-o output_file]
[Options]: default is -a
	   -a		[For Kernel API Dump]Automatically parse exception class and exception process pid; no need to input parse_pid.
	   -h   	Display this help screen.
	   --help	Display this help screen.
[Parameters]: 
           db_path	Your extracted db folder path or mobilelog path;default is current folder; can be omited.
	   parse_pid	User assigned process pid which will be parsed; can be omited.
	   output_file  All binder auto-analysis information and related binder log will output to this file; can be omited.
[Examples]:
	   perl binder_issue_parser.pl -p 559
	   perl binder_issue_parser.pl -d E:\\CR\\xxxx\\db.00\\db.00.dbg.DEC -p 559
	   perl binder_issue_parser.pl -d E:\\CR\\xxxx\\mtklog\\mobilelog\\APLog_2013_0101_000714 -p 559
	   perl binder_issue_parser.pl -d E:\\CR\\xxxx\\db.00\\db.00.dbg.DEC -p 559 -o E:\\CR\\xxxx\\db.00\\db.00.dbg.DE\\binder_output.txt
[Output]: 
	MediatekLogView will automatically generate it to db.XX\\YMD_HMS_XXX\\db.XX.dbg.DEC\\parser\\binder_analysis.bat.txt.
		exg: db.00\\20130808_094027_570\\db.00.dbg.DEC\\parser\\binder_analysis.bat.txt.
	For manually usage: 
		If you didn't assigned it, output file will be db_path\\binder_analysis_info.log.
		If you assigne it, pls input output full path and file name.
[Output log level]: 
	   [Info]	normal log 
	   [Debug]	use for debug
	   [Error]	error msg
	   [Analysis]	auto analysis information which is usefull for issue debug
	   [Root Cause] the main auto-analysis result for user
__TEMPLATE
	return $template;
}

