#!/bin/bash

# AnyKernel Installer Zips building solution (AnyKernel)
# By Artx/Stayn <jesusgabriel.91@gmail.com>

# ---------------------------
# Identify the Module:
# ---------------------------
# MODULE_NAME=MakeAnykernel
# MODULE_VERSION=1.0
# MODULE_DESCRIPTION="AnyKernel Installer building Module for KB-E by Artx"
# MODULE_PRIORITY=5
# MODULE_FUNCTION_NAME=anykernel
# ---------------------------

# Path variable
AKFOLDER=$KDPATH/anykernelfiles
AKOUT=$KDPATH/out/anykernel

# If the anykernelfiles folder is missing for the current
# kernel, prompt for its configuration
if [ ! -d $AKFOLDER ]; then
  # AnyKernel Required Data by User
  echo " "
  echo -e "$THEME$BLD - Choose an option for AnyKernel Installer: "
  echo " "
  echo -e "$WHITE   1) Download the AnyKernel Source and use it"
  echo -e "   2) Manually set the AnyKernel files"
  echo " "
  until [ "$AKBO" = "1" ] || [ "$AKBO" = "2" ]; do
    read -p "   Your option [1/2]: " AKBO
    if [ "$AKBO" != "1" ] && [ "$AKBO" != "2" ]; then
      echo " "
      echo -e "$RED$BLD - Error, invalid option, try again..."
      echo -e "$WHITE"
    fi
    if [ "$AKBO" = "1" ]; then
      echo -ne "$THEME$BLD - Downloading AnyKernel Source..."
      git clone https://github.com/osm0sis/AnyKernel2.git $AKFOLDER &> /dev/null
      echo -e "$WHITE Done"
    fi
    if [ "$AKBO" = "2" ]; then
      mkdir $AKFOLDER
    fi
  done
  unset AKBO
fi

# Enable/Disable Kernel Update
if [ ! -f $KDPATH/akconfig ]; then
  echo " "
  touch $KDPATH/akconfig
  echo -ne "$WHITE   Automatically update the Kernel image while building the AnyKernel? [Y/N]: "
  read anykernel_kupdate
  if [ "$anykernel_kupdate" = "Y" ] || [ "$anykernel_kupdate" = "y" ]; then
    echo "export enable_kupdate=y" >> $KDPATH/akconfig
  fi
  echo -e "$RATT"
fi

function anykernel() {
# Read version
readfromdevice version
# Load AK Config file
source $KDPATH/akconfig
# Tittle
echo -ne "$THEME$BLD"
echo -e "     _            _  __                 _ "
echo -e "    /_\  _ _ _  _| |/ /___ _ _ _ _  ___| | "
echo -e "   / _ \| ' \ || | ' </ -_) '_| ' \/ -_) | "
echo -e "  /_/ \_\_||_\_, |_|\_\___|_| |_||_\___|_| "
echo -e "             |__/                         "
echo " "
echo -e "$THEME$BLD   --------------------------$WHITE"
echo -e "$WHITE - AnyKernel Installer Building Script  $RATT$WHITE"
export DATE=`date +%Y-%m-%d`
echo -e "   Kernel:$THEME$BLD $KERNELNAME$WHITE; Variant:$THEME$BLD $VARIANT$WHITE; Date:$THEME$BLD $DATE$WHITE"

# Setup MakeAnykernel
checkfolders --silent
# Check MakeAnykerel out folder
if [ ! -d $AKOUT ]; then
  mkdir $AKOUT
fi

# Check Zip Tool
checkziptool &> /dev/null
# Check buildkernel.sh KBUILDFAILED variable
if [ "$KBUILDFAILED" = "1" ]; then
  echo -e "$RED$BLD   Warning:$WHITE the previous kernel were not built successfully"
  read -p "Ignore this warning and continue? [Y/N]: " CAB           # KBUILDFAILED tell us if the lastest kernel
  if [ "$CAB" = "y" ] || [ "$CAB" = "Y" ]; then                     # building failed, but, we still have the
    echo -e "$WHITE   Using last built Kernel for $VARIANT..."      # last successfully built kernel so this will
  else                                                              # ask the user if he wants to continue building
    echo -e "$WHITE   Aborting..."                                  # the anykernel installer, if not, exit the
    echo -e "$THEME$BLD   --------------------------$WHITE"         # module.
    cd $CDF
    return 1
  fi
fi
# Update Kernel image and DTB when its enabled
if [ "$enable_kupdate" = "y" ]; then
  # Starting the real process!
  # -----------------------
  # Kernel Update
  selectimage
  if [ "$selected_image" = "none" ] || [ -z "$selected_image" ]; then
    echo -e "$RED$BLD Error:$WHITE Kernel is not built, aborting..."
    return 1
  else
    cp $KOUT/$selected_image $AKFOLDER/
  fi
  echo -e "$WHITE$BLD   Kernel Updated. $selected_image Automatically selected"
  if [ -f $DTOUT/$VARIANT ]; then
    cp $DTOUT/$VARIANT $AKFOLDER/dtb
    echo -e "$WHITE$BLD   DTB Updated"
    echo -e "   Done"
  fi
  # -----------------------
else
  echo -e "$WHITE   Automatic Kernel update disabled"
fi

# Make the kernel installer zip
export ZIPNAME="$KERNELNAME"-v"$VERSION"-"$ARCH"-"$RELEASETYPE"-"$TARGETANDROID"_"$VARIANT".zip
KREVF=$KDPATH/$KERNELNAME.rev
if [ $RELEASETYPE = "Beta" ]; then
  if [ ! -f $KREVF ]; then
    touch $KREVF
    echo 0 > $KREVF
  fi
  REVN=$(cat $KREVF)
  REVSUM=$((1+REVN))
  export REV=$REVSUM
  echo $REV > $KREVF
  export ZIPNAME="$KERNELNAME"-v"$VERSION"-"$ARCH"-"$RELEASETYPE"-Rev"$REV"-"$TARGETANDROID"_"$VARIANT".zip
fi
echo -e "$THEME$BLD   Zip Name: $WHITE$ZIPNAME"
echo -ne "$WHITE$BLD   Building Flasheable zip for $VARIANT...$RATT$WHITE"
cd $AKFOLDER
zip -r9 $ZIPNAME * &> /dev/null
mv $ZIPNAME $AKOUT/
echo -e "$THEME$BLD Done!$RATT"
echo -e "$THEME$BLD   --------------------------$WHITE"
}
export -f anykernel; log -f anykernel $KBELOG
