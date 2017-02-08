# Bash boilerplate

## Features

* Interactive mode
* Quiet mode
* CLI options parser supporting `-n --name --name=Oxy --name Oxy`
* Also supports bundling of flags. ie. `-vf` instead of `-v -f`
* Helper functions for printing messages.
* Automatically remove color escape codes if the script is piped.

## Functions

### Print functions

* `die()` Output message to stderr and exit with error code 1.
* `out()` Output message.
* `err()` Output message to stderr but continue running.
* `success()` Output message as a string. Both `success` and `err` will output message with a colorized symbol, as long as the script isn't piped.
* `log()` Will only output message if user has activated verbose flag.
* `notify()` Delegate the message to either `err` or `success` depending on the last return code. *Remember this function needs to be called once a return code is available.* Eg.

  ```bash
  foobar; notify "foobar copied files"

  notify "foobar copied files" $(foobar)
  ```

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
