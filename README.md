# Bash boilerplate

## Features

* all in 1 file
* strict mode
* specify your optional/required arguments **only once** in easy-to-read format
	* flags: (optional) -f|-- force - will end up in variable $force
	* option: (optional) -k|--key [value] - will end up in variable $key
	* parameters: (obligatory) single params and/or multi-param (e.g. 'process_files file1 file2 file3')
* auto-generated -h|--help|(no parameters) usage message
* quiet (-q) mode: only see errors, e.g. for crontab use (don't show 'log' or 'out' output)
* verbose (-v) mode: see more information, for debugging (also show 'log' output) 
* colored output (green = good/red = bad/yellow = debugging) when possible.
* built-in command for normal output 'out', skipped when using option -q --quiet
* built-in command for same-line output 'progress', skipped when using option -q --quiet
* built-in command for debugging output 'log', skipped when not using option -v --verbose
* built-in command for warning output 'alert', skipped when using option -q --quiet'
* built-in command for success output 'success', skipped when using option -q --quiet'
* built-in command for graceful exit 'die'
* built-in command for requesting Y/N 'confirm', skipped when using option -f --force
* built-in commands for upper/lowercase conversion 'ucase', 'lcase'
* built-in command for checking all the programs needed for script execution 'verify_programs'
* built-in command for cleanup/initialising folders 'folder_prep'
* built-in platform/os detection: 'on_mac', 'on_linux'
## Example usage

```
Program: script.sh by peter@forret.com
Version: v1.2 (L:407|MD:d30183d8)
Updated: 2018-10-18 12:15
Usage: script.sh [-h] [-q] [-v] [-f] [-l <logdir>] [-t <tmpdir>] <action> <files> [<...>]
Flags, options and parameters:
    -h|--help      : [flag] show usage [default: off]
    -q|--quiet     : [flag] no output [default: off]
    -v|--verbose   : [flag] output more [default: off]
    -f|--force     : [flag] do not ask for confirmation [default: off]
    -l|--logdir <val>: [optn] folder for log files   [default: ./log]
    -t|--tmpdir <val>: [optn] folder for temp files  [default: /tmp/script]
    <action>  : [parameter] action to perform: LIST/...
    <files>   : [parameters] file(s) to perform on (1 or more)
```

## Functions

### Print functions

* `die()` Output message to stderr and exit with error code 1.
* `out()` Output message.
* `err()` Output message to stderr but continue running.
* `success()` Output message as a string. Both `success` and `err` will output message with a colorized symbol, as long as the script isn't piped.
* `log()` Will only output message if user has activated verbose flag.
* `progress()` Output line but do only \r, not \n so line will be overwritten by next output line.
* `notify()` Delegate the message to either `err` or `success` depending on the last return code.
* ...

### Misc helpers

* `escape()` Escape slashes in a string
* `confirm()` Prompt the user to answer Yes or No. *This will automatically return true if --force is used.* Eg.

  ```bash
  if ! confirm "Delete file"; then
    continue;
  fi
  ```

## Versions

* v1.3: robuster parameter parsing
* v1.2: better error trap and versioning info
* v1.1: better single and multi param parsing
* v1.0: first release

## Acknowledgment

* Daniel Mills, [options.bash](https://github.com/e36freak/tools/blob/master/options.bash)
* DJ Mills [github.com/e36freak](https://github.com/e36freak)
* Kfir Lavi [www.kfirlavi.com](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming)
