#!/bin/sh

if test $# -lt 1; then
	echo "Useage: ./release.sh {tag name}"
else
	tagName=$1
	releaseBranch="rb-$tagName"
	versionFile="version_$tagName.info"

	# Ensure we run from the correct directory (one above this one)
	SCRIPT=`readlink -f $0`
	SCRIPTPATH=`dirname $SCRIPT`
	ROOTPATH="$SCRIPTPATH/../"
	cd $ROOTPATH

	echo "======================================"
	echo "Creating release branch $releaseBranch"
	echo "======================================"
	git checkout -b $releaseBranch

	echo "."
	echo "."
	echo "==========================================================="
	echo "Building documentation using Jekyll and the gh-pages branch"
	echo "==========================================================="
	mkdir docs
	git checkout gh-pages
	jekyll --safe --pygments docs

	echo "."
	echo "."
	echo "======================================"
	echo "Commiting docs into the release branch"
	echo "======================================"
	git checkout $releaseBranch
	git add docs/*
	git commit -m "Built documentation for tagged release $tagName"

	echo "."
	echo "."
	echo "============================================================"
	echo "Creating release info file and commiting into release branch"
	echo "============================================================"
	date +"Built on %Y-%m-%d %r" > $versionFile
	git add $versionFile
	git commit -m "Added version file for tagged release $tagName"


	echo "."
	echo "."
	echo "============================================="
	echo "Removing build directory from release branch"
	echo "============================================="
	rm -r build
	git commit -a -m "Removed build directory, not needed for tagged release"

	echo "."
	echo "."
	echo "==============================================="
	echo "Tagging release and removing the release branch"
	echo "==============================================="
	git tag $tagName
	git checkout $tagName
	git branch -D $releaseBranch

	echo "."
	echo "."
	echo "=================================================================================="
	echo "All done. The tag is now checked out, ready for release (git push origin $tagName)"
	echo "=================================================================================="
fi

exit 0;
