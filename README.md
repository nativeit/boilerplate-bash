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
===== script.sh v0.2 - Feb 11 22:43:34 2017
Usage: script.sh [-h] [-q] [-v] [-f] [-s <speed>] <action> <file> [<...>]
List of options:
    -h|--help : show usage
    -q|--quiet : no output
    -v|--verbose : output more
    -f|--force : do not ask for confirmation
    -s|--speed <speed> : choose speed fast or slow  [default: slow]
    <action>  : action to perform: LIST/...
    <file>  : file(s) to perform on (can be a list)
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
