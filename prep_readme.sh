OUTPUT=README.md

(
./script.sh --help | awk '
/^#/	{ print $0 ; next}
		{ print "      " $0}
'
echo "### Version history"
cat doc/versions.txt
echo "### Examples"
cat doc/examples.txt
echo "### Acknowledgements"
cat doc/inspiration.txt
) > $OUTPUT
