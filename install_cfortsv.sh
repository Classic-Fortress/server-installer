#!/bin/sh

# Classic Fortress Server Installer Script (for Linux)
# by Empezar & dimman

defaultdir="~/cfortsv"

error() {
    printf "ERROR: %s\n" "$*"
    [ -n "$created" ] || {
        cd
        echo "The directory $installdir is about to be removed, press ENTER to confirm or CTRL+C to exit."
        read dummy
        rm -rf $installdir
    }
    exit 1
}

# Check if unzip is installed
which unzip >/dev/null || error "The package 'unzip' is not installed. Please install it and run the installation again."

# Check if curl is installed
which curl >/dev/null || error "The package 'curl' is not installed. Please install it and run the installation again."

echo
echo "Welcome to the Classic Fortress Server installation"
echo "==================================================="
echo
echo "Press ENTER to use [default] option."
echo

# Create the Classic Fortress folder
printf "Where do you want to install Classic Fortress? [$defaultdir]: " 
read installdir

eval installdir=$installdir

[ ! -z "$installdir" ] || eval installdir=$defaultdir

if [ -d "$installdir" ]; then
    if [ -w "$installdir" ]; then
        created=0
    else
        error "You do not have write access to '$installdir'. Exiting."
    fi
else
    if [ -e "$installdir" ]; then
        error "'$installdir' already exists but is a file, not a directory. Exiting."
        exit
    else
        mkdir -p $installdir 2>/dev/null || error "Failed to create install dir: '$installdir'"
        created=1
    fi
fi
if [ -w "$installdir" ]; then
    eval confdir="~/.cfortsv"
    mkdir -p $confdir
    cd $installdir
    installdir=$(pwd)
    echo $installdir > $confdir/install_dir
    echo;echo "* Installing Classic Fortress into: $installdir"
    echo
else
    error "You do not have write access to $installdir. Exiting."
fi

# Download cfort.ini
wget --inet4-only -q -O cfort.ini https://raw.githubusercontent.com/Classic-Fortress/client-installer/master/cfort.ini || error "Failed to download cfort.ini"
[ -s "$installdir/cfort.ini" ] || error "Downloaded cfort.ini but file is empty?! Exiting."

# List all the available mirrors
echo "From what mirror would you like to download Classic Fortress?"
mirrors=$(grep "[0-9]\{1,2\}=\".*" cfort.ini | cut -d "\"" -f2 | nl | wc -l)
grep "[0-9]\{1,2\}=\".*" cfort.ini | cut -d "\"" -f2 | nl
printf "Enter mirror number [random]: " 
read mirror
mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" cfort.ini | cut -d "=" -f2)
if [ -n "$mirror" ] && [ $mirrors > 1 ]; then
    range=$(expr$(grep "[0-9]\{1,2\}=\".*" cfort.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
    while [ -z "$mirror" ]
    do
        number=$RANDOM
        let "number %= $range"
        mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" cfort.ini | cut -d "=" -f2)
        mirrorname=$(grep "^$number=\".*" cfort.ini | cut -d "\"" -f2)
    done
else
    mirror=$(grep "^1=[fhtp]\{3,4\}://[^ ]*$" cfort.ini | cut -d "=" -f2)
    mirrorname=$(grep "^1=\".*" cfort.ini | cut -d "\"" -f2)
fi
echo;echo "* Using mirror: $mirrorname"
mkdir -p $installdir/fortress $installdir/id1 $installdir/qtv $installdir/qw $installdir/qwfwd
echo

# Download all the packages
echo "=== Downloading ==="
wget --inet4-only -O $installdir/qsw106.zip $mirror/qsw106.zip || error "Failed to download $mirror/qsw106.zip"
wget --inet4-only -O $installdir/cfortsv-gpl.zip $mirror/cfortsv-gpl.zip || error "Failed to download $mirror/cfortsv-gpl.zip"
wget --inet4-only -O $installdir/cfortsv-non-gpl.zip $mirror/cfortsv-non-gpl.zip || error "Failed to download $mirror/cfortsv-non-gpl.zip"
wget --inet4-only -O $installdir/cfortsv-maps.zip $mirror/cfortsv-maps.zip || error "Failed to download $mirror/cfortsv-maps.zip"
if [ $(getconf LONG_BIT) = 64 ]
then
    wget --inet4-only -O $installdir/cfortsv-bin-x64.zip $mirror/cfortsv-bin-x64.zip || error "Failed to download $mirror/cfortsv-bin-x64.zip"
    [ -s "$installdir/cfortsv-bin-x64.zip" ] || error "Downloaded cfortsv-bin-x64.zip but file is empty?!"
else
    wget --inet4-only -O $installdir/cfortsv-bin-x86.zip $mirror/cfortsv-bin-x86.zip || error "Failed to download $mirror/cfortsv-bin-x86.zip"
    [ -s "$installdir/cfortsv-bin-x86.zip" ] || error "Downloaded cfortsv-bin-x86.zip but file is empty?!"
fi

[ -s "$installdir/qsw106.zip" ] || error "Downloaded qwsv106.zip but file is empty?!"
[ -s "$installdir/cfortsv-gpl.zip" ] || error "Downloaded cfortsv-gpl.zip but file is empty?!"
[ -s "$installdir/cfortsv-non-gpl.zip" ] || error "Downloaded cfortsv-non-gpl.zip but file is empty?!"
[ -s "$installdir/cfortsv-maps.zip" ] || error "Downloaded cfortsv-maps.zip but file is empty?!"

# Download configuration files
wget --inet4-only -O $installdir/fortress/fortress.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/fortress/fortress.cfg || error "Failed to download fortress/fortress.cfg"
wget --inet4-only -O $installdir/qw/mvdsv.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qw/mvdsv.cfg || error "Failed to download qw/mvdsv.cfg"
wget --inet4-only -O $installdir/qw/server.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qw/server.cfg || error "Failed to download qw/server.cfg"
wget --inet4-only -O $installdir/qtv/qtv.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qtv/qtv.cfg || error "Failed to download qtv/qtv.cfg"
wget --inet4-only -O $installdir/qwfwd/qwfwd.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qwfwd/qwfwd.cfg || error "Failed to download qwfwd/qwfwd.cfg"
wget --inet4-only -O $installdir/update_binaries.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/update/update_binaries.sh || error "Failed to download update_binaries.sh"
wget --inet4-only -O $installdir/update_configs.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/update/update_configs.sh || error "Failed to download update_configs.sh"
wget --inet4-only -O $installdir/update_maps.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/update/update_maps.sh || error "Failed to download update_maps.sh"
wget --inet4-only -O $installdir/start_servers.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/run/start_servers.sh || error "Failed to download start_servers.sh"
wget --inet4-only -O $installdir/stop_servers.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/run/stop_servers.sh || error "Failed to download stop_servers.sh"
[ -s "$confdir/server.conf" ] || wget --inet4-only -O $confdir/server.conf https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/fortress/config.cfg || error "Failed to download fortress/config.cfg"
[ -s "$confdir/qtv.conf" ] || wget --inet4-only -O $confdir/qtv.conf https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qtv/config.cfg || error "Failed to download qtv/config.cfg"
[ -s "$confdir/qwfwd.conf" ] || wget --inet4-only -O $confdir/qwfwd.conf https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qwfwd/config.cfg || error "Failed to download qwfwd/config.cfg"

[ -s "$installdir/fortress/fortress.cfg" ] || error "Downloaded fortress/fortress.cfg but file is empty?!"
[ -s "$installdir/qw/mvdsv.cfg" ] || error "Downloaded qw/mvdsv.cfg but file is empty?!"
[ -s "$installdir/qw/server.cfg" ] || error "Downloaded qw/server.cfg but file is empty?!"
[ -s "$installdir/qtv/qtv.cfg" ] || error "Downloaded qtv/qtv.cfg but file is empty?!"
[ -s "$installdir/qwfwd/qwfwd.cfg" ] || error "Downloaded qwfwd/qwfwd.cfg but file is empty?!"
[ -s "$installdir/update_binaries.sh" ] || error "Downloaded update_binaries.sh but file is empty?!"
[ -s "$installdir/update_configs.sh" ] || error "Downloaded update_configs.sh but file is empty?!"
[ -s "$installdir/update_maps.sh" ] || error "Downloaded update_maps.sh but file is empty?!"
[ -s "$installdir/start_servers.sh" ] || error "Downloaded start_servers.sh but file is empty?!"
[ -s "$installdir/stop_servers.sh" ] || error "Downloaded stop_servers.sh but file is empty?!"
[ -s "$confdir/server.conf" ] || error "Downloaded ~/.cfortsv/server.conf but file is empty?!"
[ -s "$confdir/qtv.conf" ] || error "Downloaded ~/.cfortsv/qtv.cfg but file is empty?!"
[ -s "$confdir/qwfwd.conf" ] || error "Downloaded ~/.cfortsv/qwfwd.cfg but file is empty?!"

# Extract all the packages
echo "=== Installing ==="
printf "* Extracting Quake Shareware..."
(unzip -qqo $installdir/qsw106.zip ID1/PAK0.PAK 2>/dev/null && echo done) || echo fail
printf "* Extracting Classic Fortress setup files (1 of 2)..."
(unzip -qqo $installdir/cfortsv-gpl.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting Classic Fortress setup files (2 of 2)..."
(unzip -qqo $installdir/cfortsv-non-gpl.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting Classic Fortress maps..."
(unzip -qqo $installdir/cfortsv-maps.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting Classic Fortress binaries..."
if [ $(getconf LONG_BIT) = 64 ]
then
    (unzip -qqo $installdir/cfortsv-bin-x64.zip 2>/dev/null && echo done) || echo fail
else
    (unzip -qqo $installdir/cfortsv-bin-x86.zip 2>/dev/null && echo done) || echo fail
fi
echo

# Rename files
echo "=== Cleaning up ==="
printf "* Renaming files..."
(mv $installdir/ID1/PAK0.PAK $installdir/id1/pak0.pak 2>/dev/null && rm -rf $installdir/ID1 && echo done) || echo fail

# Remove distribution files
printf "* Removing setup files..."
(rm -rf $installdir/qsw106.zip $installdir/cfortsv-gpl.zip $installdir/cfortsv-non-gpl.zip $installdir/cfortsv-maps.zip $installdir/cfortsv-bin-x86.zip $installdir/cfortsv-bin-x64.zip $installdir/cfort.ini && echo done) || echo fail

# Create symlinks
printf "* Creating symlinks to configuration files..."
[ -L "$installdir/fortress/config.cfg" ] || ln -s $confdir/server.conf $installdir/fortress/config.cfg
[ -L "$installdir/qtv/config.cfg" ] || ln -s $confdir/qtv.conf $installdir/qtv/config.cfg
[ -L "$installdir/qwfwd/config.cfg" ] || ln -s $confdir/qwfwd.conf $installdir/qwfwd/config.cfg
echo "done"

# Convert DOS files to UNIX
printf "* Converting DOS files to UNIX..."
for file in $(find $installdir -type f -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README" && find $confdir -type f -iname "*.cfg")
do
    [ ! -f "$file" ] || cat $file|tr -d '\015' > tmpfile
    rm $file
    mv tmpfile $file
done
echo "done"

# Set the correct permissions
printf "* Setting permissions..."
find $installdir -type f -exec chmod -f 644 {} \;
find $installdir -type d -exec chmod -f 755 {} \;
chmod -f +x $installdir/mvdsv 2>/dev/null
chmod -f +x $installdir/fortress/mvdfinish.qws 2>/dev/null
chmod -f +x $installdir/qtv/qtv.bin 2>/dev/null
chmod -f +x $installdir/qwfwd/qwfwd.bin 2>/dev/null
chmod -f +x $installdir/*.sh 2>/dev/null
echo "done"

echo;echo "To make sure your servers are always running, type \"crontab -e\" and add the following:"
echo;echo "*/3 * * * * $installdir/start_servers.sh --silent"
echo;echo "Please edit server.conf, qtv.conf and qwfwd.conf in ~/.cfortsv/ before continuing!"
echo;echo "Installation complete!"
echo