#!/bin/sh

#################################################
## CLASSIC FORTRESS SERVER INSTALLATION SCRIPT ##
#################################################

######################
##  INITIALIZATION  ##
######################

# functions
error() {
    echo
    printf "%s\n" "$*"

    [ -d $tmpdir ] && rm -rf $tmpdir

    exit 1
}
iffailed() {
    [ $fail -eq 1 ] && {
        echo "fail"
        printf "%s\n" "$*"
        exit 1
    }

    return 1
}

# initialize variables
eval settingsdir="~/.cfortsv"
eval tmpdir="~/.cfortsv_install"
defaultdir="~/cfortsv"
github=https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master
fail=0

# initialize folders
rm -rf $tmpdir 2>/dev/null || error "ERROR: Could not remove temporary directory '$tmpdir'. Perhaps you have some permission problems."
mkdir $tmpdir 2>/dev/null || error "ERROR: Could not create setup folder '$tmpdir'. Perhaps you have some permission problems."
mkdir -p $tmpdir/game/fortress $tmpdir/game/id1 $tmpdir/game/qtv $tmpdir/game/qw $tmpdir/game/qwfwd $tmpdir/settings

# check if unzip and curl are installed
[ `which unzip` ] || error "ERROR: The package 'unzip' is not installed. Please install it and run the installation again."
[ `which curl` ] || error "ERROR: The package 'curl' is not installed. Please install it and run the installation again."

# download cfort.ini
curl --silent --output $tmpdir/cfort.ini https://raw.githubusercontent.com/Classic-Fortress/client-installer/master/cfort.ini || \
    error "ERROR: Failed to download 'cfort.ini' (mirror information) from remote server. Try again later."

[ -s "$tmpdir/cfort.ini" ] || error "ERROR: Downloaded 'cfort.ini' but file is empty. Try again later."

######################
## FOLDER SELECTION ##
######################

# select install directory
printf "Where do you want to install Classic Fortress server? [$defaultdir]: "
read installdir
eval installdir=$installdir

# use default install directory if user did not input a directory
[ -z "$installdir" ] && eval installdir=$defaultdir

# check if selected directory is writable and isn't a file
[ -f $installdir ] && error "ERROR: '$installdir' already exists and is a file, not a directory. Exiting."
[ ! -w ${installdir%/*} ] && error "ERROR: You do not have write access to '$installdir'. Exiting."

######################
## MIRROR SELECTION ##
######################

echo
echo "Using directory '$installdir'"
echo
echo "Select a download mirror:"

# print mirrors and number them
grep "[0-9]\{1,2\}=\".*" $tmpdir/cfort.ini | cut -d "\"" -f2 | nl

printf "Enter mirror number [random]: "

# read user's input
read mirror

# get mirror address from cfort.ini
mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" $tmpdir/cfort.ini | cut -d "=" -f2)

# count mirrors
mirrors=$(grep "[0-9]=\"" $tmpdir/cfort.ini | wc -l)

[ -z $mirror ] && [ $mirrors -gt 1 ] && {

    # calculate range (amount of mirrors + 1)
    range=$(expr$(grep "[0-9]=\"" $tmpdir/cfort.ini | nl | tail -n1 | cut -f1) + 1)

    while [ -z "$mirror" ]; do

        # generate a random number
        number=$RANDOM

        # divide the random number with the calculated range and put the remainder in $number
        let "number %= $range"

        # get the nth mirror using the random number
        mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" $tmpdir/cfort.ini | cut -d "=" -f2)

    done

} || mirror=$(grep "^1=[fhtp]\{3,4\}://[^ ]*$" $tmpdir/cfort.ini | cut -d "=" -f2)

######################
##     DOWNLOAD     ##
######################

echo
printf "Downloading files.."

# detect system architecture
[ $(getconf LONG_BIT) = 64 ] && arch=x64 || arch=x86

# download game data
curl --silent --output $tmpdir/qsw106.zip $mirror/qsw106.zip && printf "." || fail=1
curl --silent --output $tmpdir/cfortsv-gpl.zip $mirror/cfortsv-gpl.zip && printf "." || fail=1
curl --silent --output $tmpdir/cfortsv-non-gpl.zip $mirror/cfortsv-non-gpl.zip && printf "." || fail=1
curl --silent --output $tmpdir/cfortsv-maps.zip $mirror/cfortsv-maps.zip && printf "." || fail=1
curl --silent --output $tmpdir/cfortsv-bin.zip $mirror/cfortsv-bin-$arch.zip && printf "." || fail=1

# check if files contain anything
[ -s $tmpdir/qsw106.zip ] || fail=1
[ -s $tmpdir/cfortsv-gpl.zip ] || fail=1
[ -s $tmpdir/cfortsv-non-gpl.zip ] || fail=1
[ -s $tmpdir/cfortsv-maps.zip ] || fail=1
[ -s $tmpdir/cfortsv-bin.zip ] || fail=1

iffailed "Could not download game files. Try again later." || printf "."

# download configuration files
curl --silent --output $tmpdir/game/fortress/fortress.cfg $github/config/fortress/fortress.cfg && printf "." || fail=1
curl --silent --output $tmpdir/game/qw/mvdsv.cfg $github/config/qw/mvdsv.cfg && printf "." || fail=1
curl --silent --output $tmpdir/game/qw/server.cfg $github/config/qw/server.cfg && printf "." || fail=1
curl --silent --output $tmpdir/game/qtv/qtv.cfg $github/config/qtv/qtv.cfg && printf "." || fail=1
curl --silent --output $tmpdir/game/qwfwd/qwfwd.cfg $github/config/qwfwd/qwfwd.cfg && printf "." || fail=1
curl --silent --output $tmpdir/game/getmap.sh $github/update/getmap.sh && printf "." || fail=1
curl --silent --output $tmpdir/game/update_binaries.sh $github/update/update_binaries.sh && printf "." || fail=1
curl --silent --output $tmpdir/game/update_configs.sh $github/update/update_configs.sh && printf "." || fail=1
curl --silent --output $tmpdir/game/update_maps.sh $github/update/update_maps.sh && printf "." || fail=1
curl --silent --output $tmpdir/game/start_servers.sh $github/run/start_servers.sh && printf "." || fail=1
curl --silent --output $tmpdir/game/stop_servers.sh $github/run/stop_servers.sh && printf "." || fail=1
curl --silent --output $tmpdir/settings/server.conf $github/config/fortress/config.cfg && printf "." || fail=1
curl --silent --output $tmpdir/settings/qtv.conf $github/config/qtv/config.cfg && printf "." || fail=1
curl --silent --output $tmpdir/settings/qwfwd.conf $github/config/qwfwd/config.cfg && printf "." || fail=1

iffailed "Could not download configuration files. Try again later."

[ -s $tmpdir/game/fortress/fortress.cfg ] || fail=1
[ -s $tmpdir/game/qw/mvdsv.cfg ] || fail=1
[ -s $tmpdir/game/qw/server.cfg ] || fail=1
[ -s $tmpdir/game/qtv/qtv.cfg ] || fail=1
[ -s $tmpdir/game/qwfwd/qwfwd.cfg ] || fail=1
[ -s $tmpdir/game/getmap.sh ] || fail=1
[ -s $tmpdir/game/update_binaries.sh ] || fail=1
[ -s $tmpdir/game/update_configs.sh ] || fail=1
[ -s $tmpdir/game/update_maps.sh ] || fail=1
[ -s $tmpdir/game/start_servers.sh ] || fail=1
[ -s $tmpdir/game/stop_servers.sh ] || fail=1
[ -s $tmpdir/settings/server.conf ] || fail=1
[ -s $tmpdir/settings/qtv.conf ] || fail=1
[ -s $tmpdir/settings/qwfwd.conf ] || fail=1

iffailed "Some of the downloaded files didn't contain any data. Try again later." || echo "done"

######################
##   INSTALLATION   ##
######################

printf "Installing files.."

unzip -qqo $tmpdir/qsw106.zip -d $tmpdir/game/ ID1/PAK0.PAK 2>/dev/null && printf "." || fail=1
unzip -qqo $tmpdir/cfortsv-gpl.zip -d $tmpdir/game/ 2>/dev/null && printf "." || fail=1
unzip -qqo $tmpdir/cfortsv-non-gpl.zip -d $tmpdir/game/ 2>/dev/null && printf "." || fail=1
unzip -qqo $tmpdir/cfortsv-maps.zip -d $tmpdir/game/ 2>/dev/null && printf "." || fail=1
unzip -qqo $tmpdir/cfortsv-bin.zip -d $tmpdir/game/ 2>/dev/null && printf "." || fail=1

iffailed "Could not unpack setup files. Something might be wrong with your installation directory."

# rename pak0.pak
(mv $tmpdir/game/ID1/PAK0.PAK $tmpdir/game/id1/pak0.pak 2>/dev/null && rm -rf $tmpdir/game/ID1) || fail=1

iffailed "Could not rename pak0.pak. Something might be wrong with your installation directory." || printf "."

# convert dos file endings to unix
for file in $(find $tmpdir -type f -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README"); do
    [ -f $file ] && cat $file | tr -d '\015' > $tmpdir/dos2unix 2>/dev/null || fail=1
    (rm $file && mv $tmpdir/dos2unix $file 2>/dev/null) || fail=1
done

iffailed "Could not convert files to unix line endings. Perhaps you have some permission problems." || printf "."

# set permissions
find $tmpdir/game -type f -exec chmod -f 644 {} \;
find $tmpdir/game -type d -exec chmod -f 755 {} \;
chmod -f +x $tmpdir/game/mvdsv 2>/dev/null || fail=1
chmod -f +x $tmpdir/game/fortress/mvdfinish.qws 2>/dev/null || fail=1
chmod -f +x $tmpdir/game/qtv/qtv.bin 2>/dev/null || fail=1
chmod -f +x $tmpdir/game/qwfwd/qwfwd.bin 2>/dev/null || fail=1
chmod -f +x $tmpdir/game/*.sh 2>/dev/null || fail=1

iffailed "Could not give game files the appropriate permissions. Perhaps you have some permission problems." || printf "."

# copy game dir to install dir
mkdir -p $installdir
cp -a $tmpdir/game/* $installdir/ 2>/dev/null || fail=1

iffailed "Could not move Classic Fortress server to '$installdir'. Perhaps you have some permission problems." || printf "."

# move settings to settings dir
mkdir -p $settingsdir
mv -n $tmpdir/settings/* $settingsdir/ 2>/dev/null || fail=1

iffailed "Could not move Classic Fortress server settings to '$settingsdir'. Perhaps you have some permission problems." || printf "."

# write install directory to install_dir
echo $installdir > $settingsdir/install_dir 2>/dev/null || fail=1

iffailed "Could not save install directory information to '$settingsdir/install_dir'. Perhaps you have some permission problems." || printf "."

# create symlinks
[ ! -L $installdir/fortress/config.cfg ] && (ln -s $settingsdir/server.conf $installdir/fortress/config.cfg 2>/dev/null || fail=1)
[ ! -L $installdir/qtv/config.cfg ] && (ln -s $settingsdir/qtv.conf $installdir/qtv/config.cfg 2>/dev/null || fail=1)
[ ! -L $installdir/qwfwd/config.cfg ] && (ln -s $settingsdir/qwfwd.conf $installdir/qwfwd/config.cfg 2>/dev/null || fail=1)

iffailed "Could not create symlinks to configuration files. Perhaps you have some permission problems." || printf "."

# remove temporary directory
rm -rf $tmpdir 2>/dev/null || fail=1

iffailed "Could not remove temporary directory. Perhaps you have some permission problems." || echo "done"

echo
echo "SUCCESS! Please edit server.conf, qtv.conf and qwfwd.conf in ~/.cfortsv/ before continuing!"
