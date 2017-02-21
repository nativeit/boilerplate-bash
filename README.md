# Bash boilerplate

## Features

* specify your variables only once
	* flags: (optional) -f|-- force - will end up in $force
	* option: (optional) -k|--key [value] - will end up in $key
	* parameters: (obligatory)
* auto-generate -h|--help usage message
* Quiet/verbose mode
* Confirmation or forced mode
* Works with color output (green = good/red = bad) when possible.

## Example usage

```
### Program: script.sh by peter@forret.com
### Version: v1.0 - Feb 12 18:01:12 2017
### Usage: script.sh [-h] [-q] [-v] [-f] [-u <user>] [-p <pass>] <action> <file> [<...>]
### Flags, options and parameters:
    -h|--help      : [flag] show usage [default: off]
    -q|--quiet     : [flag] no output [default: off]
    -v|--verbose   : [flag] output more [default: off]
    -f|--force     : [flag] do not ask for confirmation [default: off]
    -u|--user <val>: [optn] username to use  [default: pforret]
    -p|--pass <val>: [secr] password to use
    <action>  : [parameter] action to perform: LIST/...
    <file>    : [parameter] file(s) to perform on (1 or more)
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

### Misc helpers

* `escape()` Escape slashes in a string
* `confirm()` Prompt the user to answer Yes or No. *This will automatically return true if --force is used.* Eg.

  ```bash
  if ! confirm "Delete file"; then
    continue;
  fi
  ```

## Acknowledgment

* Daniel Mills, [options.bash](https://github.com/e36freak/tools/blob/master/options.bash)
* DJ Mills [github.com/e36freak](https://github.com/e36freak)
* Kfir Lavi [www.kfirlavi.com](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming)
