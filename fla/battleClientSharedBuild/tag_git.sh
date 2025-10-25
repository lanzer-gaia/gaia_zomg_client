#!/bin/bash

ARGCOUNT=2
E_BADARGS=65

if [ $# -ne "$ARGCOUNT" ]
then
	echo $#
	echo $1
	echo "Usage: `git-repo-root tag-name(revision)`"
	exit $E_BADARGS;
fi

GIT_REPO_ROOT=$1
SVNREVISION=$2

cd $GIT_REPO_ROOT

echo "GIT TAG"
git tag -a $SVNREVISION -m "Adding git tag $SVNREVISION after commit."
if [ $? -ne 0 ]
then
	echo "TAGGING FAILED"
	exit $?
fi

exit $?
