#!/bin/bash

# writes an image (i.e. ISO, img) to a device (i.e. CDROM, USB Drive)

# Get and parse options
OPTS=$(getopt -o s:d:nvh --long src:,dest:,dry-run,verbose,help -n 'ddp' -- "$@")

if [ $? != 0 ]; then
    echo "Failed parsing options." >&2
    exit 1
fi

echo "$OPTS"
eval set -- "$OPTS"

DRY_RUN=false
VERBOSE=false
HELP=false

while true; do
  case "$1" in
    -s | --src )
        SRC=$SRC
        shift
        ;;
    -d | --dest )
        DEST=$DEST
        shift
        ;;
    -n | --dry-run )
        DRY_RUN=true
        shift
        ;;
    -v | --verbose )
        VERBOSE=true
        shift
        ;;
    -h | --help )
        HELP=true
        exit 0
        ;;
    -- )
        shift
        break
        ;;
    * )
        echo "Unknown error. Exiting..."
        exit 1
        ;;
  esac
done

# Test for and get the size of the source file
if [ -s $SRC ]; then
    SRC_SIZE=$(ls -l $SRC | cut -d' ' -f 2)
    if [ $VERBOSE ]; then
        echo -n "Writing $SRC_SIZE bytes from source file $SRC "
    fi
else
    echo "Source file does not exist or is zero bytes.  Exiting..."
    exit 1
fi

# Test for the existence of the destination device
if [ -b $DEST ]; then
    if [ $VERBOSE ]; then
        echo "to device $DEST"
    fi
else
    echo "Destination device is not inserted.  Exiting..."
    exit 1
fi

# Write the image file to the device
echo "dd if=$SRC | pv -pterb -s $SRC_SIZE | dd of=$DEST"
