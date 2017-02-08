#!/bin/bash

readonly PROGVERS="v0.2"
prefix_fmt=""
# uncomment next line to have date/time prefix for every output line
#prefix_fmt='+%Y-%m-%d %H:%M:%S :: '

runasroot=0
# runasroot = 0 :: don't check anything
# runasroot = 1 :: script MUST run as root
# runasroot = -1 :: script MAY NOT run as root

### Change the next lines to reflect which flags/options/parameters you need
### flag:   switch a flag 'on' / no extra parameter / e.g. "-v" for verbose
# flag|<short>|<long>|<description>|<default>

### option: set an option value / 1 extra parameter / e.g. "-l error.log" for logging to file
# option|<short>|<long>|<description>|<default>

### param:  comes after the options
#param|<type>|<long>|<description>
# where <type> = 1 for single parameters or <type> = n for (last) parameter that can be a list
list_options() {
echo -n '
flag|h|help|show usage
flag|q|quiet|no output
flag|v|verbose|output more
option|s|speed|transfer speed (slow/fast)|fast
param|1|output|action to: ARCHIVE/SEARCH/RESTORE/CONFIG
param|n|input|input file or folder
'
}

#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(cd $(dirname $0); pwd)
PROGDATE=$(stat -c %y "$PROGDIR/$PROGNAME" 2>/dev/null | cut -c1-16) # generic linux
if [[ -z $LINUXDATE ]] ; then
  PROGDATE=$(stat -f "%Sm" "$PROGDIR/$PROGNAME" 2>/dev/null) # for MacOS
fi

readonly ARGS="$@"
set -e                                  # Exit immediately on error
verbose=0
quiet=0
piped=0
[[ -t 1 ]] && piped=0 || piped=1        # detect if out put is piped

# Defaults
args=()

out() {
  ((quiet)) && return
  local message="$@"
  local prefix=""
  if [[ -n $prefix_fmt ]]; then
    prefix=$(date "$prefix_fmt")
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
log()     { [[ $verbose -gt 0 ]] && out "$@";}
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
BEGIN { FS="|"; OFS=" "; oneline="" ; fulltext="List of options:"}
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
        #log "init_options: $(echo "$init_command" | wc -l) options/flags initialised"
        eval "$init_command"
   fi
}

parse_options() {
    if [[ $# -eq 0 ]] ; then
       usage >&2 ; safe_exit
    fi

    ## first process all the -x --xxxx flags and options
    while [[ $1 = -?* ]]; do
        # flag <flag> is savec as $flag = 0/1
        # option <option> is saved as $option
       save_option=$(list_options \
        | awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" ";}
        $1 ~ /flag/   &&  "-"$2 == opt {print $3"=1"}
        $1 ~ /flag/   && "--"$3 == opt {print $3"=1"}
        $1 ~ /option/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /option/ && "--"$3 == opt {print $3"=$2; shift"}
        ')
        if [[ -n "$save_option" ]] ; then
            #log "parse_options: $save_option"
            eval $save_option
        else
            die "Cannot interpret option [$1]"
        fi
        shift
    done

    ## then run through the given parameters
    while [[ -n $1 ]]; do
       # single parameter <single> is saved as $single
        save_option=$(list_options \
        | awk '
        BEGIN { FS="|"; OFS=" "; }
        $1 ~ /param/ &&  $2 ~ /1/ {print $3 "=$1; shift; "}
        ')
        if [[ -n "$save_option" ]] ; then
            out "parse_options: $save_option"
            eval $save_option
        else
            die "Cannot interpret option [$1]"
        fi
        shift
    done

    while [[ -n $1 ]]; do
       # multiple parameter <multi> is saved as $multi[1] $multi[2] ...
        save_option=$(list_options \
        | awk '
        BEGIN { FS="|"; OFS=" "; counter=0}
        $1 ~ /param/ &&  $2 ~ /n/ {counter=counter+1; print $3 "[" counter "] =$1; MULTI" counter "=\"$" counter "\"; shift; "}
        ')
        if [[ -n "$save_option" ]] ; then
            #log "parse_options: $save_option"
            eval $save_option
        else
            die "Cannot interpret option [$1]"
        fi
        shift
    done
}

[[ $runasroot == 1  ]] && [[ $UID -ne 0 ]] && die "You MUST be root to run this script"
[[ $runasroot == -1 ]] && [[ $UID -eq 0 ]] && die "You MAY NOT be root to run this script"

################### DO NOT MODIFY ABOVE THIS LINE ###################
#####################################################################

## Put your script here
main() {
  if [[ $help == 1 ]] ; then
    usage >&2 ; safe_exit
  fi
  out "this is input: [$input]"
  err "error output"
  success "success output"
}

#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################

init_options
parse_options $@
main
safe_exit
