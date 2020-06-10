#!/bin/bash
SCRIPT=./script.sh
OUTPUT=README.md

(
	cat doc/EXPLAIN.md

	$SCRIPT --help | awk '
		/^#/	{ print $0 ; next}
				{ print "      " $0}
		'

	cat doc/CHANGELOG.md
	cat doc/INSTALL.md
	cat doc/EXAMPLES.md
	cat doc/INSPIRATION.md
) > $OUTPUT
cp $OUTPUT docs/index.md