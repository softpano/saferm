#!/bin/bash
#: safer_install.sh -- a simple installer for saferm
#: Nikolai Bezroukov, 2019.
#: Version 1.0
#:
#: to get help use
#:     saferm_install.sh -h
#:
#: Invocation:
#:     saferm.sh  [BIN_DIR] [DOT_FILE] [debug_level]
#:
#: There are 3 parameters for this utility (oll optional):
#:
#: where:
#:    BIN_DIR -- binary directgory to copy the script .Default is /usr/bin
#:    DOT_FILE  -- dot file to which ass alias. Default is /etc/profile.d/local.sh
#:
#: If debug_level is set to integer greater then 0 script the scitp prints log and echo command. No command is executed.
#:
# ====================================================================================
# 1.0 bezroun 2019/02/20  initial implementation
# ====================================================================================

VERSION='1.0'
DEBUG=1

BIN_DIR='/usr/bin' # default directory to copy saferm script
DOT_FILE='/etc/profile.d/sh.local' # default dot file to add alias rm
WHICH=which
USER=`whoami`
#
# Produce banner
#
PREFIX='Saferm install'
echo $PREFIC Version $VERSION

if (( $#==3 )) ; then
   DEBUG=$3
fi

if (( DEBUG > 0 )) ; then
   WHICH='echo echo'
fi

CP=`$WHICH cp`
YUM=`$WHICH yum`
CHMOD=`$WHICH chmod`
CHOWN=`$WHICH chown`

if [[ $1 == '-h' ]] ||  (( $#>3 )) ; then
   egrep '^#:' $0
   exit
fi

#
# Process the first parameter, if it was supplied
#

if (( $#>=1 )) ; then
  if [[ -d $1 ]] ; then
      BIN_DIR=$1
  else
     echo "$PREFIX: supplied first parameter is not a directory. Exiting..."
     exit 255
  fi
fi

#
# Process the second parameter, if it was supplied
#
if (( $# == 2 )) ; then
  if [[ -f $2 ]] ; then
     DOT_FILE=$2
  else
     echo "$PREFIX: supplied second parameter is not a filed. Exiting..."
     exit 255
  fi
fi

TREE=`which tree`
if [[ -z "$TREE" ]] ; then
   $YUM install tree
   TREE=`which tree`
   if [[ -z "$TREE" ]] ; then
      echo "$PREFIX: unable to install tree. Exiting..."
      exit 255
   fi
fi

if [[ -f ./saferm ]] ; then
   $CP -v ./saferm $BIN_DIR/saferm
   if [[ ! -f "$BIN_DIR/saferm" ]] ; then
      echo "$PREFIX: can't copy saferm to $BIN_DIR directory"
      exit 255
   fi
   $CHMOD 755 $BIN_DIR/saferm
   $CHOWN $USER:root $BIN_DIR/saferm
fi

if (( DEBUG == 0 )) ; then
   if ! grep "$BIN_DIR/saferm" $DOT_FILE ; then
      echo alias rm="$BIN_DIR/saferm" >> $DOT_FILE
   else
      echo "$PREFIX: alias already exists."
   fi
fi
