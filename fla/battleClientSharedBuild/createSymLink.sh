#!/bin/bash

ARGCOUNT=2
E_BADARGS=65

if [ $# -ne "$ARGCOUNT" ]
then
	echo $#
	echo "Usage: `basename $0` Gaia_Flash_Root_Dir svnrev"
	exit $E_BADARGS;
fi

GAIA_FLASH_ROOT_DIR=$1
SVNREVISION=$2

cd $GAIA_FLASH_ROOT_DIR/zomg

echo "Creating SYMLINK FOR REVISION $SVNREVISION"

ln -s ../BATTLE $SVNREVISION

git add .
git commit --message="Committing symliink for $SVNREVISION"


exit $?
