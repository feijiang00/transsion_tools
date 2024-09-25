@cd /d %~dp0
@..\prebuilt\ftracetools\perl\perl ..\prebuilt\binderparser\binder_issue_parser.pl -d %1 -out %2
