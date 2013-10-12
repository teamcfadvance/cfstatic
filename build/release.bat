@echo off
set olddir=%CD%

if "%1"=="" goto blank
goto setupvars

:setupvars
set scriptdir=%~dp0
set rootdir=%scriptdir%\..\
set tagName=%1
set releaseBranch=rb-%tagName%
set versionFile=version_%tagName%.info
chdir %rootdir%
goto checkoutnewreleasebranch

:checkoutnewreleasebranch
echo ======================================
echo Creating release branch $releaseBranch
echo ======================================
call git checkout -b %releaseBranch%
goto builddocs

:builddocs
echo .
echo .
echo ===========================================================
echo Building documentation using Jekyll and the gh-pages branch
echo ===========================================================
call mkdir docs
call git checkout gh-pages
call jekyll --safe --pygments docs

goto done

:blank
echo Useage: ./release.sh {tag name}
goto done

:done
chdir %olddir%
pause