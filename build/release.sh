#!/bin/sh

#TODO: take command line option for release number
#TODO: put build date in version info file

git checkout -b rb-0.6.0
mkdir docs
git checkout gh-pages
jekyll --safe --pygments docs
git checkout rb-0.6.0
git add docs/*
git commit -m "Built documentation for tagged release 0.6.0"
touch version_0.6.0.info
git add version_0.6.0.info
git commit -m "Added version file for tagged release 0.6.0"
rm -r build
git commit -a -m "Removed build directory, not needed for tagged release"
git tag 0.6.0
git checkout -f develop
git branch -D rb-0.6.0
