#!/bin/bash
#
# A lot of this is based on options.bash by Daniel Mills.
# @see https://github.com/e36freak/tools/blob/master/options.bash
# @see http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(cd $(dirname $0); pwd)
readonly PROGVERS="v0.1"
readonly PROGDATE=""
readonly ARGS="$@"
timeprefix=1

################### DO NOT MODIFY BELOW THIS LINE ################### 
set -e                                  # Exit immediately on error
[[ -t 1 ]] && piped=0 || piped=1        # detect if out put is piped

# Defaults
force=0
quiet=0
debug=0
verbose=0
interactive=0
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
      s/✖/Error:/g;
      s/✔/Success:/g;
    ')
    printf '%b\n' "$prefix$message";
  else
    printf '%b\n' "$prefix$message";
  fi
}
die()     { out "$@"; exit 1; } >&2                   # die with error message
err()     { out " \033[1;31m✖\033[0m  $@"; } >&2      # print error and continue
success() { out " \033[1;32m✔\033[0m  $@"; }
log()     { (($verbose)) && out "$@"; }
notify()  { [[ $? == 0 ]] && success "$@" || err "$@"; }
escape()  { echo $@ | sed 's/\//\\\//g'; }         # escape / as \/

confirm() { (($force)) && return 0; read -p "$1 [y/N] " -n 1; [[ $REPLY =~ ^[Yy]$ ]];}

is_empty()     { local target=$1 ; [[ -z $target ]] ; }
is_not_empty() { local target=$1;  [[ -n $target ]] ; }

is_file() { local target=$1; [[ -f $target ]] ; }
is_dir()  { local target=$1; [[ -d $target ]] ; }

rollback()  { die ; }
trap rollback INT TERM EXIT
safe_exit() { trap - INT TERM EXIT ; exit ; }

################### DO NOT MODIFY ABOVE THIS LINE ################### 

# Chaneg the next lines to refelct which flags/options/parameters you need
defvars(){
#type|short|long|description|default value
# flag: has no value: -h
# option: has 1 value: -l error.log
# secret: is a secret option: -p <password>
# param: comes after the options
  echo -n "
flag|h|help|show usage
flag|i|interactive|prompt for values
flag|q|quiet|no output
flag|v|debug|output even more
flag|v|verbose|output more
option|l|logfile|log to this file
option|u|username|username to use|$USER
param|input|input file
param|output|output file
secret|p|password|password to use
"
}
interactive_opts=(username password)

usage() {
echo "===== $PROGNAME $PROGVERS"
echo -n "Usage: $PROGNAME"
defvars \
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
  fulltext = fulltext "\n    <" $2 ">  : " $3; 
  if($4!=""){fulltext = fulltext "  [default: " $4 "]"; }
  oneline  = oneline " <" $2 ">"
  }
  END {print oneline; print fulltext}
'
}


#################################################################################################
# Put your script here
main() {
  out "regular output"
  err "error output"
  success "success output"
}
#################################################################################################

# }}}
# Boilerplate {{{

# Prompt the user to interactively enter desired variable values. 
prompt_options() {
  local desc=
  local val=
  for val in ${interactive_opts[@]}; do
    [[ $(eval echo "\$$val") ]] && continue

    desc=$(defvars | awk -v val=$val '
      BEGIN  { FS="|"; OFS=" ";}
      $3 ~ val { print $4  }
    ')
    [[ ! "$desc" ]] && continue

    echo -n "$desc: "

    if [[ $val == "password" ]]; then
      stty -echo; read password; stty echo
      echo
    else
      eval "read $val"
    fi
  done
}

# Print help if no arguments were passed.
[[ $# -eq 0 ]] && set -- "--help"
# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) 
      usage >&2; safe_exit ;;
    --version) 
      out "$PROGNAME $PROGVERS"; safe_exit ;;
    -u|--username) 
      shift; username=$1 ;;
    -p|--password) 
      shift; password=$1 ;;
    -v|--verbose) 
      verbose=1 ;;
    -q|--quiet) 
      quiet=1 ;;
    -i|--interactive) 
      interactive=1 ;;
    -f|--force) 
      force=1 ;;
    -d|--debug) 
      set -ex ;;
    --endopts) shift; break ;;
    *) die "invalid option: $1" ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

# Uncomment this line if the script requires root privileges.
# [[ $UID -ne 0 ]] && die "You need to be root to run this script"
# [[ $UID -eq 0 ]] && die "You cannot be root to run this script"

if ((interactive)); then
  prompt_options
fi

main

safe_exit
