#!/bin/bash
# script is executed from repo base folder by pre-commit hook
SCRIPT=./script.sh
OUTPUT=./README.md
FOLDER=./usage
echo OUTPUT = $OUTPUT
(
	cat $FOLDER/EXPLAIN.md

	$SCRIPT --help | awk '
		/^#/	{ print $0 ; next}
				{ print "      " $0}
		'

	cat $FOLDER/CHANGELOG.md
	cat $FOLDER/INSTALL.md
	cat $FOLDER/EXAMPLES.md
	cat $FOLDER/INSPIRATION.md
) > $OUTPUT

# copy to website homepage
echo OUTPUT = docs/index.md
cp $OUTPUT docs/index.md