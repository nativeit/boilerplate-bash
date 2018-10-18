#!/usr/bin/env bash

# uncomment next line to have time prefix for every output line
#prefix_fmt='+%H:%M:%S | '
prefix_fmt=""

runasroot=-1
# runasroot = 0 :: don't check anything
# runasroot = 1 :: script MUST run as root
# runasroot = -1 :: script MAY NOT run as root

# set strict mode -  via http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# change program version to your own release logic
readonly PROGNAME=$(basename $0 .sh)
readonly PROGFNAME=$(basename $0)
readonly PROGDIR=$(cd $(dirname $0); pwd)
readonly PROGUUID=$(cat $0 | md5sum | cut -c1-8)
readonly PROGVERS="v1.2"
readonly PROGAUTH="peter@forret.com"
readonly USERNAME=$(whoami)
readonly TODAY=$(date "+%Y-%m-%d")
[[ -z "${TEMP:-}" ]] && TEMP=/tmp

### Change the next lines to reflect which flags/options/parameters you need
### flag:   switch a flag 'on' / no extra parameter / e.g. "-v" for verbose
### flag|<short>|<long>|<description>|<default>
### option: set an option value / 1 extra parameter / e.g. "-l error.log" for logging to file
### option|<short>|<long>|<description>|<default>
### param:  comes after the options
### param|<type>|<long>|<description>
### where <type> = 1 for single parameters or <type> = n for (last) parameter that can be a list

list_options() {
echo -n "
flag|h|help|show usage
flag|q|quiet|no output
flag|v|verbose|output more
flag|f|force|do not ask for confirmation
option|l|logdir|folder for log files |./log
option|t|tmpdir|folder for temp files|$TEMP/$PROGNAME
#option|u|user|username to use|$USER
#secret|p|pass|password to use
param|1|action|action to perform: LIST/...
# there can only be 1 param|n and it should be the last
param|n|files|file(s) to perform on
" | grep -v '^#'
}

#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################

PROGDATE=$(stat -c %y "$0" 2>/dev/null | cut -c1-16) # generic linux
if [[ -z $PROGDATE ]] ; then
  PROGDATE=$(stat -f "%Sm" "$0" 2>/dev/null) # for MacOS
fi

readonly ARGS="$@"
#set -e                                  # Exit immediately on error
verbose=0
quiet=0
piped=0
force=0

[[ -t 1 ]] && piped=0 || piped=1        # detect if out put is piped
[[ $(echo -e '\xe2\x82\xac') == '€' ]] && unicode=1 || unicode=0 # detect if unicode is supported

# Defaults
args=()

readonly col_reset="\033[0m"
readonly col_red="\033[1;31m"
readonly col_grn="\033[1;32m"
readonly col_ylw="\033[1;33m"

readonly nbcols=$(tput cols)
readonly wprogress=$(expr $nbcols - 5)
readonly nbrows=$(tput lines)

tmpfile=""
logfile=""

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
      s/✖/!!/g;
      s/➨/??/g;
      s/✔/  /g;
    ')
    printf '%b\n' "$prefix$message";
  else
    printf '%b\n' "$prefix$message";
  fi
}

progress() {
  ((quiet)) && return
  local message="$@"
  if ((piped)); then
    printf '%b\n' "$message";
    # \r makes no sense in file or pipe
  else

    printf '... %-${wprogress}b\r' "$message                                             ";
    # next line will overwrite this line
  fi
}
trap "die \"[$PROGNAME] stopped because [\$BASH_COMMAND] fails !\" ; " INT TERM EXIT
safe_exit() { 
  [[ -n "$tmpfile" ]] && [[ -f "$tmpfile" ]] && rm "$tmpfile"
  trap - INT TERM EXIT
  exit
}

die()       { out " ${col_red}✖${col_reset}: $@" >&2; safe_exit; }             # die with error message
alert()     { out " ${col_red}➨${col_reset}: $@" >&2 ; }                       # print error and continue
success()   { out " ${col_grn}✔${col_reset}  $@"; }
announce()  { out " ${col_grn}…${col_reset}  $@"; sleep 1 ; }
log() { if [[ $verbose -gt 0 ]] ; then
        out "${col_ylw}# $@${col_reset}"
      fi 
      }
notify()  { if [[ $? == 0 ]] ; then
        success "$@"
      else 
        alert "$@"
      fi }
escape()  { echo $@ | sed 's/\//\\\//g' ; }

lcase()   { echo $@ | awk '{print tolower($0)}' ; }
ucase()   { echo $@ | awk '{print toupper($0)}' ; }

confirm() { (($force)) && return 0; read -p "$1 [y/N] " -n 1; echo " "; [[ $REPLY =~ ^[Yy]$ ]];}

is_set()     { local target=$1 ; [[ $target -gt 0 ]] ; }
is_empty()     { local target=$1 ; [[ -z $target ]] ; }
is_not_empty() { local target=$1;  [[ -n $target ]] ; }

is_file() { local target=$1; [[ -f $target ]] ; }
is_dir()  { local target=$1; [[ -d $target ]] ; }

os_uname=$(uname -s)
os_bits=$(uname -m)
os_version=$(uname -v)

on_mac()	{ [[ "$os_uname" = "Darwin" ]] ;	}
on_linux()	{ [[ "$os_uname" = "Linux" ]] ;	}
on_ubuntu()	{ [[ -n $(echo $os_version | grep Ubuntu) ]] ;	}
on_32bit()	{ [[ "$os_bits"  = "i386" ]] ;	}
on_64bit()	{ [[ "$os_bits"  = "x86_64" ]] ;	}

usage() {
  if ((piped)); then
    out "Program: $PROGFNAME by $PROGAUTH"
    out "Version: $PROGVERS (hash $PROGUUID)"
    out "Updated: $PROGDATE"
  else
    out "Program: ${col_grn}$PROGFNAME${col_reset} by ${col_ylw}$PROGAUTH${col_reset}"
    out "Version: ${col_grn}$PROGVERS${col_reset} (hash ${col_ylw}$PROGUUID${col_reset})"
    out "Updated: ${col_grn}$PROGDATE${col_reset}"
  fi

  echo -n "Usage: $PROGNAME"
   list_options \
  | awk '
  BEGIN { FS="|"; OFS=" "; oneline="" ; fulltext="Flags, options and parameters:"}
  $1 ~ /flag/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-10s: [flag] %s [default: off]",$2,$3,$4) ;
    oneline  = oneline " [-" $2 "]"
    }
  $1 ~ /option/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [optn] %s",$2,$3,"val",$4) ;
    if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
    oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /secret/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [secr] %s",$2,$3,"val",$4) ;
      oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /param/ {
    if($2 == "1"){
          fulltext = fulltext sprintf("\n    %-10s: [parameter] %s","<"$3">",$4);
          oneline  = oneline " <" $3 ">"
     } else {
          fulltext = fulltext sprintf("\n    %-10s: [parameters] %s (1 or more)","<"$3">",$4);
          oneline  = oneline " <" $3 "> [<...>]"
     }
    }
    END {print oneline; print fulltext}
  '
}

init_options() {
    local init_command=$(list_options \
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

verify_programs(){
	log "Running on $os_uname ($os_version)"
  log "Checking programs: $(echo $*)]"
	for prog in $* ; do
		if [[ -z $(which "$prog") ]] ; then
			alert "[$PROGNAME] needs [$prog] but this program cannot be found on this $os_uname machine"
		fi
	done
}

folder_prep(){
    if [[ -n "$1" ]] ; then
        local folder="$1"
        local maxdays=365
        if [[ -n "$2" ]] ; then
            maxdays=$2
        fi
        if [ ! -d "$folder" ] ; then
            log "Create folder [$folder]"
            mkdir "$folder"
        else
            log "Cleanup folder [$folder] - delete older than $maxdays day(s)"
            find "$folder" -mtime +$maxdays -exec rm {} \;
        fi
	fi
}

expects_single_params(){
  list_options | grep 'param|1|' > /dev/null
}

expects_multi_param(){
  list_options | grep 'param|n|' > /dev/null
}

parse_options() {
    if [[ $# -eq 0 ]] ; then
       usage >&2 ; safe_exit
    fi

    ## first process all the -x --xxxx flags and options
    #set -x
    while true; do
      # flag <flag> is savec as $flag = 0/1
      # option <option> is saved as $option
      if [[ $# -eq 0 ]] ; then
        ## all parameters processed
        break
      fi
      if [[ ! $1 = -?* ]] ; then
        ## all flags/options processed
        break
      fi
      local save_option=$(list_options \
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
            die "$PROGNAME cannot interpret option [$1]"
        fi
        shift
    done

    ## then run through the given parameters
  if expects_single_params ; then
    log "Now processing single params"
    single_params=$(list_options | grep 'param|1|' | cut -d'|' -f3)
    nb_singles=$(echo $single_params | wc -w)
    log "Found $nb_singles parameters: $single_params"
    if [[ $# -eq 0 ]] ; then
      # but no single params are given
      die "$PROGNAME needs the parameter(s) [$(echo $single_params)]"
    fi

    for param in $single_params ; do
      if [[ -z $1 ]] ; then
        die "$PROGNAME needs parameter [$param]"
      fi
      log "$param=$1"
      eval $param="$1"
      shift
    done
  else 
    log "No single params to process"
    single_params=""
    nb_singles=0
  fi

  if expects_multi_param ; then
    log "Now processing multi param"
    nb_multis=$(list_options | grep 'param|n|' | wc -l)
    multi_param=$(list_options | grep 'param|n|' | cut -d'|' -f3)
    if [[ $nb_multis -gt 1 ]] ; then
      die "$PROGNAME cannot have more than 1 'multi' parameter: [$(echo $multi_param)]"
    fi
    [[ $nb_multis -gt 0 ]] && [[ $# -eq 0 ]] && die "$PROGNAME needs the (multi) parameter [$multi_param]"
    # save the rest of the params in the multi param
    if [[ -n "$*" ]] ; then
      log "multi_param=( $* )"
      eval "$multi_param=( $* )"
    fi
  else 
    log "No multi param to process"
    nb_multis=0
    multi_param=""
    [[ $# -gt 0 ]] && die "$PROGNAME cannot interpret extra parameters"
    log "$PROGNAME: all parameters have been processed"
  fi
}

[[ $runasroot == 1  ]] && [[ $UID -ne 0 ]] && die "You MUST be root to run this script"
[[ $runasroot == -1 ]] && [[ $UID -eq 0 ]] && die "You MAY NOT be root to run this script"

################### DO NOT MODIFY ABOVE THIS LINE ###################
#####################################################################

## Put your helper scripts here
run_only_show_errors(){
  tmpfile=$(mktemp)
  if ( $* ) 2>> $tmpfile >> $tmpfile ; then
    #all OK
    rm $tmpfile
    return 0
  else
    alert "[$(echo $*)] gave an error"
    cat $tmpfile
    rm $tmpfile
    return -1
  fi
}

do_that_thing(){
	return 0
	# use as 'do_that_thing && follow up with this'
}

do_the_other_thing(){
	local param1="$1"
	[[ -z "$param1" ]] && return 1
	local param2=0
	[[ -n "$2" ]] && param2="$2"
	echo "$1:$2"
	# use as 'value=$(do_the_other_thing)'
}


## Put your main script here
main() {
    log "Program: $PROGFNAME $PROGVERS ($PROGUUID)"
    log "Updated: $PROGDATE"
    if [[ -n "$tmpdir" ]] ; then
      folder_prep "$tmpdir" 1
      tmpfile=$(mktemp $tmpdir/$TODAY.XXXXXX.tmp)
      log "Temp file: $tmpfile"
    fi
    if [[ -n "$logdir" ]] ; then
      folder_prep "$logdir" 7
      logfile=$logdir/$PROGNAME.$TODAY.log
      log "Log file: $logfile"
      echo "$(date '+%H:%M:%S') | [$PROGFNAME] $PROGVERS ($PROGUUID) started" >> $logfile
    fi
    verify_programs awk curl cut date echo find grep head md5sum printf sed stat tail uname 

    action=$(ucase $action)
    case $action in
    LIST )
        on_mac && log "Running on MacOS"
        on_linux && log "Running on Linux"
        do_that_thing && do_the_other_thing "this is the output" "for you" 
        ;;
    *)
        die "Action [$action] not recognized"
    esac
}

#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################

init_options
parse_options $@
log "-------------- STARTING (main) $PROGNAME" # this will show up even if your main() has errors
main
log "---------------- FINISH (main) $PROGNAME" # a start needs a finish
safe_exit
