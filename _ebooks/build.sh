#!/bin/sh

# Ensure we run from the correct directory (this one)
SCRIPT=`readlink -f $0`
SCRIPTPATH=`dirname $SCRIPT`
cd $SCRIPTPATH

echo "========================================"
echo "Copying site pages from gh-pages site..."
cp ../*.md ./
echo "...done."
echo "========================================"

echo "========================================"
echo "Building pages using jekyll..."
jekyll
echo "...done."
echo "========================================"

echo "========================================"
echo "Turning into single .html page..."

echo '<html> <head> <title>CfStatic - User Guide</title> <meta name="description" content="CfStatic, CSS and JavaScript control for CFML applications"> <meta name="author" content="Dominic Watson"> <meta http-equiv="Content-Language" content="en"> </head> <body>' > book.html
echo '<a id="index-html"></a>' >> book.html
cat _site/index.html >> book.html
echo '<a id="quick-start-html"></a>' >> book.html
cat _site/quick-start.html >> book.html
echo '<a id="full-guide-html"></a>' >> book.html
cat _site/full-guide.html >> book.html
echo '<a id="downloads-html"></a>' >> book.html
cat _site/downloads.html >> book.html
echo '<a id="contributing-html"></a>' >> book.html
cat _site/contributing.html >> book.html
echo "</body> </html>" >> book.html
echo "...done."
echo "========================================"

echo "========================================"
echo "Converting links to be internal..."
sed -e 's/"[a-z\-]\+\.html#/"#/g' book.html > tmp && mv tmp book.html
sed -e 's/"\([a-z\-]\+\)\.html/"#\1-html/g' book.html > tmp && mv tmp book.html
echo "...done."
echo "========================================"

echo "========================================"
echo "Trimming down code blocks..."
sed -r 's/&lt;\/?cfscript&gt;\s+?//g' book.html > tmp && mv tmp book.html
sed -r "s/<code class='[a-z]+'>/<code>/g" book.html > tmp && mv tmp book.html
sed -r ':a;N;$!ba;s/<pre>\n/<pre>/g' book.html > tmp && mv tmp book.html
sed -r ':a;N;$!ba;s/<code>\n/<code>/g' book.html > tmp && mv tmp book.html
sed -r 's/<pre>\s+/<pre>/g' book.html > tmp && mv tmp book.html
sed -r 's/<code>\s+/<code>/g' book.html > tmp && mv tmp book.html
sed -r 's/\s+<\/pre>/<\/pre>/g' book.html > tmp && mv tmp book.html
sed -r 's/\s+<\/code>/<\/code>/g' book.html > tmp && mv tmp book.html
sed -r ':a;N;$!ba;s/\n<\/code>/<\/code>/g' book.html > tmp && mv tmp book.html
sed -r ':a;N;$!ba;s/\n<\/pre>/<\/pre>/g' book.html > tmp && mv tmp book.html
echo "...done."
echo "========================================"


echo "========================================"
echo "Building eBooks using Calibre..."
ebook-convert book.html ./cfstatic.mobi --max-levels=0 --chapter-mark=none --page-breaks-before='//h1' --cover=./cover.png --level1-toc="//h:h1" --level2-toc="//h:h2"
#ebook-convert ./book.html cfstatic.epub --extra-css ./css/epub.css --use-auto-toc --margin-left 10.0 --margin-right 10.0 --pretty-print --no-default-epub-cover
#ebook-convert ./book.html cfstatic.pdf  --extra-css ./css/pdf.css  --use-auto-toc --margin-left 10.0 --margin-right 10.0
echo "...done."
echo "========================================"


echo "========================================"
echo "Cleaning up generated files..."
rm ./*.md
rm ./book.html
rm -r _site
echo "...done."
echo "========================================"

exit 0;