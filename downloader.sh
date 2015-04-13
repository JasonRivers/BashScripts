#!/bin/bash
set -e

# This script is useful when you have set times of the day that downloading
# is cheap.
# This file will read "download.list" line by line and download each one.
# Use cron to tell when this file should be run.

## Settings

# Where to save the files
DOWNLOAD_LOCATION="${HOME}/Downloads/nightly"

# Log file - Output will be sent out to STDOUT and the logfile
LOGFILE="${HOME}/Downloads/nightly/downloads.log"

# Where the download list is, if not specified it will look for download.list
# in the same directory as this script
DOWNLOAD_LIST=""

# get iplayer location
GETIPLAYER=$(which get_iplayer)
#youtube-dl location
YOUTUBEDL=$(which youtube-dl)
#youtube-dl location
WGET=$(which wget)

## Functions

gethttpftp() {
  URL=$1
  FILENAME=$2
  USERNAME=$3
  PASSWORD=$4
  if ! [ "" = "$FILENAME" ] ; then
    OPTS=" -O $FILENAME"
  fi
  if ! [ "" = "$USERNAME" ] ; then
    OPTS="$OPTS --user=$USERNAME"
  fi
  if ! [ "" = "$PASSWORD" ] ; then
    OPTS="$OPTS --password=$PASSWORD"
  fi
  echo "Downloading $URL using wget to $DOWNLOAD_LOCATION"
  $WGET -c -q $OPTS $URL
}

getyoutube() {
  URL=$1
  FILENAME=$2
  USERNAME=$3
  PASSWORD=$4

  if ! [ "" = "$FILENAME" ] ; then
    OPTS=" -O $FILENAME"
  fi
  if ! [ "" = "$USERNAME" ] ; then
    OPTS="$OPTS -u $USERNAME"
  fi
  if ! [ "" = "$PASSWORD" ] ; then
    OPTS="$OPTS -p $PASSWORD"
  fi
  echo "Downloading $URL using youtube-dl to $DOWNLOAD_LOCATION"
  $YOUTUBEDL -c -q $OPTS $URL
  
}

getiplayer() {
  DOWNLOAD=$1
  FILENAME=$2
  CHANNEL=$3

  if [ "`echo $DOWNLOAD | grep http`" ]; then
    echo "Downloading $DOWNLOAD using get_iplayer to $DOWNLOAD_LOCATION"
    if ! [ "" = "$FILENAME" ]; then
      $OPTS="$OPTS -o $FILENAME"
    fi
    $GETIPLAYER --modes=best $OPTS --url $DOWNLOAD
  else
    # We'll search for the program name, if it finds a match we'll download it
    # extra options are ignored at this point and it's assumed the line contains
    # only the name of the program that one wishes to download.
    $GETIPLAYER $@ | awk '/^[0-9]+:/ {print $0}' | sed 's/^\([0-9]*\):/\1/;s/,.*//' | while read DLID NAME; do
      echo "Downloading $NAME using iplayer"
      $GETIPLAYER -g $DLID >/dev/null 2>&1
    done

  fi
  

}

(
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "" = "$DOWNLOADLIST" ]; then
  DOWNLOAD_LIST=$DIR/download.list
fi

mkdir -p $DOWNLOAD_LOCATION
cd $DOWNLOAD_LOCATION

cat $DOWNLOAD_LIST | grep -v "^#" | cat -n | sed 's/#.*//' | while read LNO TYPE DOWNLOAD OPTS ; do

  case $TYPE in
    iplayer)
      getiplayer $DOWNLOAD $OPTS
      ;;
    youtube)
      getyoutube $DOWNLOAD $OPTS
      ;;
    http|ftp)
      gethttpftp $DOWNLOAD $OPTS
      ;;
    *)
        if ! [ "" = "$TYPE" ]; then
          if [ "`echo $TYPE | grep youtube`" ] ; then
            getyoutube $TYPE $DOWNLOAD $OPTS # send all options
          elif [ "`echo $TYPE | grep iplayer`" ] ; then
            getiplayer $TYPE $DOWNLOAD $OPTS # send all options
          elif [ "`echo $TYPE | grep ^http`" ] || [ "`echo $TYPE | grep ^ftp`" ]; then
            gethttpftp $TYPE $DOWNLOAD $OPTS # send all options
          else
            2>&1 echo "Skipping invalid line $TYPE $DOWNLOAD $OPTS"
          fi
        fi
        ;;
  esac


done

) | tee $LOGFILE 2>&1
