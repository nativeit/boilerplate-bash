![Bash CI](https://github.com/pforret/bash-boilerplate/workflows/Bash%20CI/badge.svg) 
![Shellcheck](https://github.com/pforret/bash-boilerplate/workflows/Shellcheck/badge.svg)
![Shellcheck2](workflows/Shellcheck/badge.svg)

### BASH BOILERPLATE

It's like a mini console framework for bash shell scripting.

Just use one of 4 methods to generate a new script, that has all the functionality to 

1.	one self-contained file, no external dependencies
2.	parse options and parameters 
3.	generate clean usage 
4.	run in silent/quiet or verbose mode
5.	create and clean up temporary folder/files
6.	better error reporting
7.	Bash CI (Github Actions)


		flag|h|help|show usage
		flag|q|quiet|no output
		flag|v|verbose|output more
		flag|f|force|do not ask for confirmation
		option|l|logd|folder for log files |log
		option|t|tmpd|folder for temp files|.tmp
		param|1|action|action to perform: LIST/TEST/...
		param|1|output|output file
		# there can only be 1 param|n and it should be the last
		param|n|inputs|input files

becomes

