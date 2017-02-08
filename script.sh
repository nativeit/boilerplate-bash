#!/bin/bash

## Uncomment this line if the script requires root privileges.
# [[ $UID -ne 0 ]] && die "You need to be root to run this script"
# [[ $UID -eq 0 ]] && die "You cannot be root to run this script"

## Uncomment if you want every output line to be prefixed with date & time
timeprefix=0
#set -ex
## Change the next lines to reflect which flags/options/parameters you need
#type|short|long|description|default value
# flag: has no value: "-h" for help
# option: has 1 value: "-l error.log" for logging to file
# param: comes after the options (param has no default value!)
#param|X|name|description where X = 1 for single parameters or X = n for (last) parameter that can be a list
list_options() {
echo -n '
flag|h|help|show usage
flag|q|quiet|no output
flag|v|verbose|output more
option|s|speed|transfer speed (slow/fast)|fast
param|1|action|action to: ARCHIVE/SEARCH/RESTORE/CONFIG
param|n|input|input file or folder
'
}

################### DO NOT MODIFY BELOW THIS LINE ###################
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(cd $(dirname $0); pwd)
readonly PROGVERS="v0.1"
readonly PROGDATE=$(stat -c %y "$PROGDIR/$PROGNAME" | cut -c1-16)
readonly ARGS="$@"
set -e                                  # Exit immediately on error
verbose=0
quiet=0
piped=0
[[ -t 1 ]] && piped=0 || piped=1        # detect if out put is piped

# Defaults
timeformat='+%Y-%m-%d %H:%M:%S :: '
args=()

out() {
  ((quiet)) && return
  local message="$@"
  local prefix=""
  if ((timeprefix)); then
    prefix=$(date "$timeformat")
  fi
  if ((piped)); then
    message=$(echo $message | sed '
      s/\\[0-9]\{3\}\[[0-9]\(;[0-9]\{2\}\)\?m//g;
      s/✖/ERROR:/g;
      s/✔/OK   :/g;
    ')
    printf '%b\n' "$prefix$message";
  else
    printf '%b\n' "$prefix$message";
  fi
}
die()     { out "$@" >&2; exit 1; }                   # die with error message
err()     { out " \033[1;31m✖\033[0m  $@" >&2 ; }     # print error and continue
success() { out " \033[1;32m✔\033[0m  $@"; }
log()     { (($verbose)) && out "$@"; }
notify()  { [[ $? == 0 ]] && success "$@" || err "$@"; }
escape()  { echo $@ | sed 's/\//\\\//g'; }         # escape / as \/

confirm() { (($force)) && return 0; read -p "$1 [y/N] " -n 1; [[ $REPLY =~ ^[Yy]$ ]];}

is_set()     { local target=$1 ; [[ $target -gt 0 ]] ; }
is_empty()     { local target=$1 ; [[ -z $target ]] ; }
is_not_empty() { local target=$1;  [[ -n $target ]] ; }

is_file() { local target=$1; [[ -f $target ]] ; }
is_dir()  { local target=$1; [[ -d $target ]] ; }

rollback()  { die ; }
trap rollback INT TERM EXIT
safe_exit() { trap - INT TERM EXIT ; exit ; }

usage() {
echo "===== $PROGNAME $PROGVERS - $PROGDATE"
echo -n "Usage: $PROGNAME"
 list_options \
| awk '
BEGIN { FS="|"; OFS=" "; oneline=" " ; fulltext="List of options:"}
$1 ~ /flag/  {
  fulltext = fulltext "\n    -"$2 "|--"$3  " : " $4 ;
  if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
  oneline  = oneline " [-" $2 "]"
  }
$1 ~ /option/  {
  fulltext = fulltext "\n    -"$2 "|--"$3  " <" $3 "> : " $4 ;
  if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
  oneline  = oneline " [-" $2 " <" $3 ">]"
  }
$1 ~ /secret/  {
  fulltext = fulltext "\n    -"$2 "|--"$3  " <" $3 "> : " $4 " (password)";
    oneline  = oneline " [-" $2 " <" $3 ">]"
  }
$1 ~ /param/ {
  if($2 == "1"){
        fulltext = fulltext "\n    <" $3 ">  : " $4;
        oneline  = oneline " <" $3 ">"
   } else {
        fulltext = fulltext "\n    <" $3 ">  : " $4 " (can be a list)";
        oneline  = oneline " <" $3 "> [<...>]"
   }
  }
  END {print oneline; print fulltext}
'
}

init_options() {
    init_command=$(list_options \
    | awk '
    BEGIN { FS="|"; OFS=" ";}
    $1 ~ /flag/   && $5 == "" {print $3"=0; "}
    $1 ~ /flag/   && $5 != "" {print $3"="$5"; "}
    $1 ~ /option/ && $5 == "" {print $3"=\" \"; "}
    $1 ~ /option/ && $5 != "" {print $3"="$5"; "}
    ')
    if [[ -n "$init_command" ]] ; then
        out "init_options: $(echo "$init_command" | wc -l) options/flags initialised"
        eval "$init_command"
        set +ex
   fi
}

parse_options() {
    if [[ $# -eq 0 ]] ; then
       usage >&2 ; safe_exit
    fi

    ## first process all the -x --xxxx flags and options
    while [[ $1 = -?* ]]; do
        save_option=$(list_options \
        | awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" ";}
        $1 ~ /flag/   &&  "-"$2 == opt {print $3"=1"}
        $1 ~ /flag/   && "--"$3 == opt {print $3"=1"}
        $1 ~ /option/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /option/ && "--"$3 == opt {print $3"=$2; shift"}
        ')
        if [[ -n "$save_option" ]] ; then
            log "parse_options: $save_option"
            eval $save_option
        else
            die "Cannot interpret option [$1]"
        fi
        shift
    done

    ## then run through the parameters
    while [[ -n $1 ]]; do
        save_option=$(list_options \
        | awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" "; counter=0}
        $1 ~ /param/ &&  $2 ~ /1/ {counter=counter+1; print $2"=\"$" counter "\"; PARAM" counter "=\"$" counter "\";"}
        ')
        if [[ -n "$save_option" ]] ; then
            log "parse_options: $save_option"
            eval $save_option
        else
            die "Cannot interpret option [$1]"
        fi
        shift
    done
    param_command=$(list_options \
    | awk '
    BEGIN { FS="|"; OFS=" "; counter=0}
    $1 ~ /param/  {counter=counter+1; print $2"=\"$" counter "\"; PARAM" counter "=\"$" counter "\";"}
    ')
    if [[ -n "$param_command" ]] ; then
        out "parse_params: $(echo $param_command | wc -l) params set"
        out "parse_params: $param_command"
        eval $param_command
    fi
}


################### DO NOT MODIFY ABOVE THIS LINE ###################


## Put your script here
main() {
  if [[ $help == 1 ]] ; then
    usage >&2 ; safe_exit
  fi
  out "this is input: [$input]"
  err "error output"
  success "success output"
}
#################################################################################################

# first initialize all flags and options
init_options

# then parse the options that were given on command line
parse_options $@

# run the main program
main

safe_exit
