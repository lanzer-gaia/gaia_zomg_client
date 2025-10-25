#!/bin/bash

ARGCOUNT=1
E_BADARGS=65

if [ $# -ne "$ARGCOUNT" ]
then
	echo "Usage: `basename $0` Git-repo-root"
	exit $E_BADARGS;
fi

GIT_REPO_ROOT=$1

cd $GIT_REPO_ROOT
git repack -a -d

if [ $? -ne "0" ]
then
	echo "GIT REPACK FAILED: $GIT_REPO_ROOT"
	exit $?
fi

git prune

if [ $? -ne "0" ]
then
	echo "GIT PRUNE FAILED: $GIT_REPO_ROOT"
	exit $?
fi

exit $?
