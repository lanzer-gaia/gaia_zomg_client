#!/bin/bash

ARGCOUNT=3
E_BADARGS=65

if [ $# -ne "$ARGCOUNT" ]
then
	echo $#
	echo $1
	echo $2
	echo $3
	echo "Usage: `basename $0` bin-copy-loc Git-repo-root svnrev"
	exit $E_BADARGS;
fi

BIN_COPY_LOC=$1
GIT_REPO_ROOT=$2
SVNREVISION=$3

cd $GIT_REPO_ROOT

# [rc] Removed the git pull because it's being handled by pullWebAndImages

echo "COPYING NEWLY BUILT BATTLE FILES"
cp -r ${BIN_COPY_LOC}/* .

echo "GIT ADD"
git add .

if [ $? -ne 0 ]
then
	echo "GIT ADD FAILED"
	exit $?
fi


echo "GIT -- DELETING FILES"
git ls-files -z --deleted | git update-index -z --remove --stdin
if [ $? -ne 0 ]
then
	echo "GIT DELETE FAILED"
	exit $?
fi


echo "GIT COMMIT"
git commit --message="Committing zOMG client build to Git based on svn revision $SVNREVISION."

if [ $? -ne 0 ]
then
	echo "GIT COMMIT FAILED"
	exit $?
fi

exit $?
