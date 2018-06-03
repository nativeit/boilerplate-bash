#!/usr/bin/env bash

prefix_fmt=""
# uncomment next line to have date/time prefix for every output line
#prefix_fmt='+%Y-%m-%d %H:%M:%S :: '

runasroot=0
# runasroot = 0 :: don't check anything
# runasroot = 1 :: script MUST run as root
# runasroot = -1 :: script MAY NOT run as root

# change program version to your own release logic
readonly PROGNAME=$(basename $0 .sh)
readonly PROGDIR=$(cd $(dirname $0); pwd)
readonly PROGVERS="v1.0"
readonly PROGAUTH="peter@forret.com"
[[ -z "$TEMP" ]] && TEMP=/tmp

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
option|l|logdir|folder for log files |$PROGDIR/log
#option|t|tmpdir|folder for temp files|$TEMP/$PROGNAME
#option|u|user|username to use|$USER
#secret|p|pass|password to use
param|1|action|action to perform: LIST/...
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

# Defaults
args=()

col_reset="\033[0m"
col_red="\033[1;31m"
col_grn="\033[1;32m"
col_ylw="\033[1;33m"

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
    printf '%b\r' "$message                                             ";
    # next line will overwrite this line
  fi
}
rollback()  { die ; }
trap rollback INT TERM EXIT
safe_exit() { trap - INT TERM EXIT ; exit ; }

die()     { out " ${col_red}✖${col_reset}: $@" >&2; safe_exit; }             # die with error message
alert()   { out " ${col_red}➨${col_reset}: $@" >&2 ; }                       # print error and continue
success() { out " ${col_grn}✔${col_reset}  $@"; }
log()     { [[ $verbose -gt 0 ]] && out "${col_ylw}# $@${col_reset}";}
notify()  { [[ $? == 0 ]] && success "$@" || alert "$@"; }
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
out "Program: ${col_grn}$PROGNAME${col_reset} by ${col_ylw}$PROGAUTH${col_reset}"
out "Version: $PROGVERS - $PROGDATE"
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
	log "Running on $(/usr/bin/env bash --version | head -1)"
	log "Checking programs [$*]"
	for prog in $* ; do
		if [[ -z $(which "$prog") ]] ; then
			alert "Script needs [$prog] but this program cannot be found on this $os_uname machine"
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

parse_options() {
    if [[ $# -eq 0 ]] ; then
       usage >&2 ; safe_exit
    fi

    ## first process all the -x --xxxx flags and options
    while [[ $1 = -?* ]]; do
        # flag <flag> is savec as $flag = 0/1
        # option <option> is saved as $option
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
    single_params=$(list_options | grep 'param|1|' | cut -d'|' -f3)
    nb_singles=$(echo $single_params | wc -w)
    [[ $nb_singles -gt 0 ]] && [[ $# -eq 0 ]] && die "$PROGNAME needs the parameter(s) [$(echo $single_params)]"

    multi_param=$(list_options | grep 'param|n|' | cut -d'|' -f3)
    nb_multis=$(echo $multi_param | wc -w)
    if [[ $nb_multis -gt 1 ]] ; then
        die "$PROGNAME cannot have more than 1 'multi' parameter: [$(echo $multi_param)]"
    fi

    for param in $single_params ; do
        if [[ -z $1 ]] ; then
            die "$PROGNAME needs parameter [$param]"
        fi
        log "$param=$1"
        eval $param="$1"
        shift
    done

    [[ $nb_multis -gt 0 ]] && [[ $# -eq 0 ]] && die "$PROGNAME needs the (multi) parameter [$multi_param]"
    [[ $nb_multis -eq 0 ]] && [[ $# -gt 0 ]] && die "$PROGNAME cannot interpret extra parameters"

    # save the rest of the params in the multi param
	if [[ -s "$*" ]] ; then
		eval "$multi_param=( $* )"
	fi
}

[[ $runasroot == 1  ]] && [[ $UID -ne 0 ]] && die "You MUST be root to run this script"
[[ $runasroot == -1 ]] && [[ $UID -eq 0 ]] && die "You MAY NOT be root to run this script"

################### DO NOT MODIFY ABOVE THIS LINE ###################
#####################################################################

## Put your helper scripts here
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
	log "Start of $PROGNAME $PROGVERS ($PROGDATE)"
    [[ -n "$tmpdir" ]] && folder_prep "$tmpdir" 1
    [[ -n "$logdir" ]] && folder_prep "$logdir" 7
    verify_programs awk curl cut date echo find grep head ifconfig netstat printf sed stat tail uname 

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
log "---- START MAIN"
main
log "---- FINISH MAIN"
safe_exit
