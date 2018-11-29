### USAGE
      Program: script.sh by peter@forret.com
      Version: v1.4 (L:458-MD:1ab427)
      Updated: 2018-11-29 17:37
      Usage: script.sh [-h] [-q] [-v] [-f] [-l <logd>] [-t <tmpd>] <action> <files …>
      Flags, options and parameters:
          -h|--help      : [flag] show usage [default: off]
          -q|--quiet     : [flag] no output [default: off]
          -v|--verbose   : [flag] output more [default: off]
          -f|--force     : [flag] do not ask for confirmation [default: off]
          -l|--logd <val>: [optn] folder for log files   [default: ./log]
          -t|--tmpd <val>: [optn] folder for temp files  [default: /tmp/script]
          <action>  : [parameter] action to perform: LIST/TEST/...
          <files>   : [parameters] file(s) to perform on (1 or more)
      
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
      * use log to information that will only be visible when -v is specified
        log "input file: [$inputname] - [$inputsize] MB"
      * use escape to extra escape '/' paths in regex
        sed 's/$(escape $path)//g'
      * use lcase and ucase to convert to upper/lower case
        param=$(lcase $param)
      * use confirm for interactive confirmation before doing something
        if ! confirm "Delete file"; then ; echo "skip deletion" ; fi
      * use on_mac/on_linux/on_ubuntu/'on_32bit'/'on_64bit' to only run things on certain platforms
        on_mac && log "Running on MacOS"
      * use folder_prep to create a folder if needed and otherwise clean up old files
        folder_prep "$logd" 7 # delete all files olders than 7 days
      * use run_only_show_errors to run a program and only show the output if there was an error
        run_only_show_errors mv $tmpd/* $outd/
### Version history
* v1.4: fix md5sum problem, add script authoring tips, automated README creation
* v1.3: robuster parameter parsing
* v1.2: better error trap and versioning info
* v1.1: better single and multi param parsing
* v1.0: first release
### Examples
These scripts were made with some version of [bash-boilerplate](https://github.com/pforret/bash-boilerplate)

* [github.com/pforret/crontask](https://github.com/pforret/crontask)
* [github.com/pforret/networkcheck](https://github.com/pforret/networkcheck)
* [github.com/cinemapub/signage_prep](https://github.com/cinemapub/signage_prep)
* send me your example repos!
### Acknowledgements
I learned a lot of tips from these sources:

* Daniel Mills, [options.bash](https://github.com/e36freak/tools/blob/master/options.bash)
* DJ Mills [github.com/e36freak](https://github.com/e36freak)
* Kfir Lavi [www.kfirlavi.com](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming)
