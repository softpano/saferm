#!/bin/bash
#: safer_install.sh -- a simple installer for saferm
#: Nikolai Bezroukov, 2019.
#: Version 1.0
#:
#: to get help use
#:     saferm_install.sh -h
#:
#: Invocation:
#:     saferm_install.sh  [BIN_DIR] [DOT_FILE] [DEBUG_LEVEL]
#:
#: There are 3 parameters for this utility (oll optional):
#:
#: where:
#:    BIN_DIR -- binary directgory to copy the script .Default is /usr/bin
#:    DOT_FILE  -- dot file to which ass alias. Default is /etc/profile.d/local.sh
#:    DEBUG_LEVEL -- numeric constant (0 or 1). If 1 no write operations are performed (dry run)
#:
#: If run as not root user ownership of saferm is set to the current user.
#:
# ====================================================================================
# 1.0 bezroun 2019/02/20  initial implementation
# 1.0 bezroun 2019/02/21  Diagnistics imporoved. Debug level intruduced
# ====================================================================================

VERSION='1.0'
DEBUG=0

BIN_DIR='/usr/bin' # default directory to copy saferm script
DOT_FILE='/etc/profile.d/sh.local' # default dot file to add alias rm
WHICH=which
USER=`whoami`
#
# Produce banner
#
PREFIX='Saferm install'
echo $PREFIX Version $VERSION

if (( $#==3 )) ; then
   DEBUG=$3
   echo "Running in debug mode"
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
     echo "[FAILURE] The first parameter ( $1 ) is not a directory, or it does not yet exists. Exiting $PREFIX..."
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
     echo "[FAILURE] The second parameter $2 is not a filed. Exiting $PREFIX..."
     exit 255
  fi
fi

TREE=`which tree`
if [[ -z "$TREE" ]] ; then
   echo "$PREFIX: Installing  tree via yum..."
   $YUM install tree
   TREE=`which tree`
   if [[ -z "$TREE" ]] ; then
      echo "[FAILURE]: unable to install tree. Exiting $PREFIX..."
      exit 255
   fi
fi

if [[ -f ./saferm ]] ; then
    $CP -v ./saferm $BIN_DIR/saferm
   if [[ ! -f "$BIN_DIR/saferm" ]] ; then
      echo "[FAILURE] can't copy saferm to $BIN_DIR directory"
      exit 255
   else
      ll_results=`ls -l $BIN_DIR/saferm`
      echo "[OK] Result of ls -l $BIN_DIR/saferm command: $ll_results ..."
   fi
   $CHMOD 755 $BIN_DIR/saferm
   uid=`id -u`
   if (( uid > 0 )) ; then
      # make the script owned by the user
      $CHOWN $USER $BIN_DIR/saferm
   else
      $CHOWN root:root $BIN_DIR/saferm
   fi

fi

if (( DEBUG == 0 )) ; then
   if ! grep "$BIN_DIR/saferm" $DOT_FILE ; then
      echo alias rm="$BIN_DIR/saferm" >> $DOT_FILE
      echo "[OK] Alias rm was added to $DOT_FILE  ..."
   else
      echo "[OK] alias already exists. You need to check and possibly correct the file $DOT_FILE manually"
   fi
fi
