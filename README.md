### USAGE
      Program: script.sh by peter@forret.com
      Version: v1.6.0 (L:511-MD:758253)
      Updated: 2020-06-10 15:03
      Usage: script.sh [-h] [-q] [-v] [-f] [-l <logd>] [-t <tmpd>] <action> <output> <inputs …>
      Flags, options and parameters:
          -h|--help      : [flag] show usage [default: off]
          -q|--quiet     : [flag] no output [default: off]
          -v|--verbose   : [flag] output more [default: off]
          -f|--force     : [flag] do not ask for confirmation [default: off]
          -l|--logd <val>: [optn] folder for log files   [default: log]
          -t|--tmpd <val>: [optn] folder for temp files  [default: .tmp]
          <action>  : [parameter] action to perform: LIST/TEST/...
          <output>  : [parameter] output file
          <inputs>  : [parameters] input files (1 or more)
      
### SCRIPT AUTHORING TIPS
      * use out to show any kind of output, except when option --quiet is specified
        out "User is [$USERNAME]"
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
      * use on_mac/on_linux/'on_32bit'/'on_64bit' to only run things on certain platforms
        on_mac && log "Running on MacOS"
      * use folder_prep to create a folder if needed and otherwise clean up old files
        folder_prep "$logd" 7 # delete all files olders than 7 days
      * use run_only_show_errors to run a program and only show the output if there was an error
        run_only_show_errors mv $tmpd/* $outd/

### VERSION HISTORY
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

#### Option 2: download the script directly

        wget https://raw.githubusercontent.com/pforret/bash-boilerplate/master/script.sh
        mv script.sh my-new-script.sh

#### Option 3: customize parameters and copy/paste
	
	using [toolstud.io/data/bash.php](https://toolstud.io/data/bash.php)

### EXAMPLES
These scripts were made with some version of [bash-boilerplate](https://github.com/pforret/bash-boilerplate)

* [github.com/pforret/crontask](https://github.com/pforret/crontask)
* [github.com/pforret/networkcheck](https://github.com/pforret/networkcheck)
* [github.com/cinemapub/signage_prep](https://github.com/cinemapub/signage_prep)
* send me your example repos!

### ACKNOWLEDGEMENTS
I learned a lot of tips from these sources:

* Daniel Mills, [options.bash](https://github.com/e36freak/tools/blob/master/options.bash)
* DJ Mills [github.com/e36freak](https://github.com/e36freak)
* Kfir Lavi [www.kfirlavi.com](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming)
