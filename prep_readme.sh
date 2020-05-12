OUTPUT=README.md

(
./script.sh --help | awk '
/^#/	{ print $0 ; next}
		{ print "      " $0}
'
echo ""
echo "### VERSION HISTORY"
cat doc/versions.txt

echo ""
echo "### CREATE NEW BASH SCRIPT"
cat doc/install.txt

echo ""
echo "### EXAMPLES"
cat doc/examples.txt

echo ""
echo "### ACKNOWLEDGEMENTS"
cat doc/inspiration.txt
) > $OUTPUT
