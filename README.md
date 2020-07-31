![Bash CI](https://github.com/pforret/bash-boilerplate/workflows/Bash%20CI/badge.svg) 
![Shellcheck CI](https://github.com/pforret/bash-boilerplate/workflows/Shellcheck%20CI/badge.svg)
![version](https://img.shields.io/github/v/release/pforret/bash-boilerplate?include_prereleases)
![activity](https://img.shields.io/github/commit-activity/m/pforret/bash-boilerplate)
![license](https://img.shields.io/github/license/pforret/bash-boilerplate)
![repo size](https://img.shields.io/github/repo-size/pforret/bash-boilerplate)

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
8.	self-initialisation for new scripts (`script.sh init`)

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

### USAGE
      Program: script.sh by @email
      Version: @version (L:591-MD:e00342)
      Updated: Jun 13 10:33:50 2020
      Usage: script.sh [-h] [-q] [-v] [-f] [-l <logd>] [-t <tmpd>] <action> <output> <inputs …>
      Flags, options and parameters:
          -h|--help      : [flag] show usage [default: off]
          -q|--quiet     : [flag] no output [default: off]
          -v|--verbose   : [flag] output more [default: off]
          -f|--force     : [flag] do not ask for confirmation (always yes) [default: off]
          -l|--logd <val>: [optn] folder for log files   [default: log]
          -t|--tmpd <val>: [optn] folder for temp files  [default: .tmp]
          <action>  : [parameter] action to perform: init/list/test/...
          <output>  : [parameter] output file
          <inputs>  : [parameters] input files (1 or more)
      
### SCRIPT AUTHORING TIPS
      * use out to show any kind of output, except when option --quiet is specified
        out "User is [$USER]"
      * use progress to show one line of progress that will be overwritten by the next output
        progress "Now generating file $nb of $total ..."
      * use is_empty and is_not_empty to test for variables
        if ! confirm "Delete file"; then ; echo "skip deletion" ; fi
      * use die to show error message and exit program
        if [[ ! -f $output ]] ; then ; die "could not create output" ; fi
      * use alert to show alert message but continue
        if [[ ! -f $output ]] ; then ; alert "could not create output" ; fi
      * use success to show success message but continue
        if [[ -f $output ]] ; then ; success "output was created!" ; fi
      * use announce to show the start of a task
        announce "now generating the reports"
      * use log to show information that will only be visible when -v is specified
        log "input file: [$inputname] - [$inputsize] MB"
      * use escape to extra escape '/' paths in regex
        sed 's/$(escape $path)//g'
      * use lcase and ucase to convert to upper/lower case
        param=$(lcase $param)
      * use confirm for interactive confirmation before doing something
        if ! confirm "Delete file"; then ; echo "skip deletion" ; fi
      * use ask for interactive setting of variables
        ask NAME "What is your name" "Peter"
      * use on_mac/on_linux/'on_32bit'/'on_64bit' to only run things on certain platforms
        on_mac && log "Running on MacOS"
      * use folder_prep to create a folder if needed and otherwise clean up old files
        folder_prep "$logd" 7 # delete all files olders than 7 days

### VERSION HISTORY

* v1.7: all editable content to the front of the file
* v1.6: introduce semver versioning, Bash CI
* v1.5: fixed last shellcheck warnings - https://github.com/koalaman/shellcheck
* v1.4: fix md5sum problem, add script authoring tips, automated README creation
* v1.3: robuster parameter parsing
* v1.2: better error trap and versioning info
* v1.1: better single and multi param parsing
* v1.0: first release

 
### CREATE NEW BASH SCRIPT

#### Option 1: clone this repo
	
	git clone https://github.com/pforret/bash-boilerplate.git
	cp bash-boilerplate/script.sh my-new-script.sh

#### Option 2: create new Github repo from template
	
go to https://github.com/pforret/bash-boilerplate - press "Use this template"

#### Option 3: download the script directly

	wget https://raw.githubusercontent.com/pforret/bash-boilerplate/master/script.sh
	mv script.sh my-new-script.sh

#### Option 4: customize parameters and copy/paste
	
go to [toolstud.io/data/bash.php](https://toolstud.io/data/bash.php)

### EXAMPLES

These scripts were made with some version of [bash-boilerplate](https://github.com/pforret/bash-boilerplate)

* [github.com/pforret/crontask](https://github.com/pforret/crontask)
* [github.com/pforret/networkcheck](https://github.com/pforret/networkcheck)
* [github.com/cinemapub/signage_prep](https://github.com/cinemapub/signage_prep)
* send me your example repos!

### ACKNOWLEDGEMENTS

I learned a lot of tips from these sources:

* Daniel Mills, [e36freak](https://github.com/e36freak)
* Kfir Lavi [www.kfirlavi.com](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming)
* Aaron Maxwell [redsymbol.net](http://redsymbol.net/articles/unofficial-bash-strict-mode/)
* Bash Variables [gnu.org](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html)