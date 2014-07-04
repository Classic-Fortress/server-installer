#!/bin/sh

# Classic Fortress Server Installer Script (for Linux)
# by Empezar & dimman

defaultdir="~/cfortsv"

error() {
    printf "ERROR: %s\n" "$*"
    [ -n "$created" ] || {
        cd
        echo "The directory $directory is about to be removed, press ENTER to confirm or CTRL+C to exit." 
        read dummy
        rm -rf $directory
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
read directory

eval directory=$directory

[ ! -z "$directory" ] || eval directory=$defaultdir

if [ -d "$directory" ]; then
    if [ -w "$directory" ]; then
        created=0
    else
        error "You do not have write access to '$directory'. Exiting."
    fi
else
    if [ -e "$directory" ]; then
        error "'$directory' already exists but is a file, not a directory. Exiting."
        exit
    else
        mkdir -p $directory 2>/dev/null || error "Failed to create install dir: '$directory'"
        created=1
    fi
fi
if [ -w "$directory" ]
then
    cd $directory
    directory=$(pwd)
    mkdir -p ~/.cfortsv/pid
    echo $directory > ~/.cfortsv/install_dir
else
    error "You do not have write access to $directory. Exiting."
fi

# Download cfort.ini
wget --inet4-only -q -O cfort.ini https://raw.githubusercontent.com/Classic-Fortress/client-installer/master/cfort.ini || error "Failed to download cfort.ini"
[ -s "cfort.ini" ] || error "Downloaded cfort.ini but file is empty?! Exiting."

# List all the available mirrors
echo "From what mirror would you like to download Classic Fortress?"
mirrors=$(grep "[0-9]\{1,2\}=\".*" cfort.ini | cut -d "\"" -f2 | nl | wc -l)
grep "[0-9]\{1,2\}=\".*" cfort.ini | cut -d "\"" -f2 | nl
printf "Enter mirror number [random]: " 
read mirror
mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" cfort.ini | cut -d "=" -f2)
if [ -n "$mirror" && $mirrors > 1 ]; then
    echo;echo -n "* Using mirror: "
    range=$(expr$(grep "[0-9]\{1,2\}=\".*" cfort.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
    while [ -z "$mirror" ]
    do
        number=$RANDOM
        let "number %= $range"
        mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" cfort.ini | cut -d "=" -f2)
        mirrorname=$(grep "^$number=\".*" cfort.ini | cut -d "\"" -f2)
    done
    echo "$mirrorname"
else
    mirror=$(grep "^1=[fhtp]\{3,4\}://[^ ]*$" cfort.ini | cut -d "=" -f2)
fi
mkdir -p fortress id1 qtv qw qwfwd
echo;echo

# Download all the packages
echo "=== Downloading ==="
wget --inet4-only -O qsw106.zip $mirror/qsw106.zip || error "Failed to download $mirror/qsw106.zip"
wget --inet4-only -O cfortsv-gpl.zip $mirror/cfortsv-gpl.zip || error "Failed to download $mirror/cfortsv-gpl.zip"
wget --inet4-only -O cfortsv-non-gpl.zip $mirror/cfortsv-non-gpl.zip || error "Failed to download $mirror/cfortsv-non-gpl.zip"
wget --inet4-only -O cfortsv-maps.zip $mirror/cfortsv-maps.zip || error "Failed to download $mirror/cfortsv-maps.zip"
if [ $(getconf LONG_BIT) = 64 ]
then
    wget --inet4-only -O cfortsv-bin-x64.zip $mirror/cfortsv-bin-x64.zip || error "Failed to download $mirror/cfortsv-bin-x64.zip"
    [ -s "cfortsv-bin-x64.zip" ] || error "Downloaded cfortsv-bin-x64.zip but file is empty?!"
else
    wget --inet4-only -O cfortsv-bin-x86.zip $mirror/cfortsv-bin-x86.zip || error "Failed to download $mirror/cfortsv-bin-x86.zip"
    [ -s "cfortsv-bin-x86.zip" ] || error "Downloaded cfortsv-bin-x86.zip but file is empty?!"
fi

[ -s "qsw106.zip" ] || error "Downloaded qwsv106.zip but file is empty?!"
[ -s "cfortsv-gpl.zip" ] || error "Downloaded cfortsv-gpl.zip but file is empty?!"
[ -s "cfortsv-non-gpl.zip" ] || error "Downloaded cfortsv-non-gpl.zip but file is empty?!"
[ -s "cfortsv-maps.zip" ] || error "Downloaded cfortsv-maps.zip but file is empty?!"

# Download configuration files
wget --inet4-only -O fortress/fortress.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/fortress/fortress.cfg || error "Failed to download fortress/fortress.cfg"
wget --inet4-only -O qw/mvdsv.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qw/mvdsv.cfg || error "Failed to download qw/mvdsv.cfg"
wget --inet4-only -O qw/server.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qw/server.cfg || error "Failed to download qw/server.cfg"
wget --inet4-only -O qtv/qtv.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qtv/qtv.cfg || error "Failed to download qtv/qtv.cfg"
wget --inet4-only -O qwfwd/qwfwd.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qwfwd/qwfwd.cfg || error "Failed to download qwfwd/qwfwd.cfg"
wget --inet4-only -O update_binaries.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/update/update_binaries.sh || error "Failed to download update_binaries.sh"
wget --inet4-only -O update_configs.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/update/update_configs.sh || error "Failed to download update_configs.sh"
wget --inet4-only -O update_maps.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/update/update_maps.sh || error "Failed to download update_maps.sh"
wget --inet4-only -O start_servers.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/run/start_servers.sh || error "Failed to download start_servers.sh"
wget --inet4-only -O stop_servers.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/run/stop_servers.sh || error "Failed to download stop_servers.sh"
[ -s "fortress/config.cfg" ] || wget --inet4-only -O fortress/config.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/fortress/config.cfg || error "Failed to download fortress/config.cfg"
[ -s "qtv/config.cfg" ] || wget --inet4-only -O qtv/config.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qtv/config.cfg || error "Failed to download qtv/config.cfg"
[ -s "qwfwd/config.cfg" ] || wget --inet4-only -O qwfwd/config.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qwfwd/config.cfg || error "Failed to download qwfwd/config.cfg"

[ -s "fortress/fortress.cfg" ] || error "Downloaded fortress/fortress.cfg but file is empty?!"
[ -s "fortress/config.cfg" ] || error "Downloaded fortress/config.cfg but file is empty?!"
[ -s "qw/mvdsv.cfg" ] || error "Downloaded qw/mvdsv.cfg but file is empty?!"
[ -s "qw/server.cfg" ] || error "Downloaded qw/server.cfg but file is empty?!"
[ -s "qtv/config.cfg" ] || error "Downloaded qtv/config.cfg but file is empty?!"
[ -s "qtv/qtv.cfg" ] || error "Downloaded qtv/qtv.cfg but file is empty?!"
[ -s "qwfwd/config.cfg" ] || error "Downloaded qwfwd/config.cfg but file is empty?!"
[ -s "qwfwd/qwfwd.cfg" ] || error "Downloaded qwfwd/qwfwd.cfg but file is empty?!"
[ -s "update_binaries.sh" ] || error "Downloaded update_binaries.sh but file is empty?!"
[ -s "update_configs.sh" ] || error "Downloaded update_configs.sh but file is empty?!"
[ -s "update_maps.sh" ] || error "Downloaded update_maps.sh but file is empty?!"
[ -s "start_servers.sh" ] || error "Downloaded start_servers.sh but file is empty?!"
[ -s "stop_servers.sh" ] || error "Downloaded stop_servers.sh but file is empty?!"

echo

# Extract all the packages
echo "=== Installing ==="
printf "* Extracting Quake Shareware..."
(unzip -qqo qsw106.zip ID1/PAK0.PAK 2>/dev/null && echo done) || echo fail
printf "* Extracting Classic Fortress setup files (1 of 2)..."
(unzip -qqo cfortsv-gpl.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting Classic Fortress setup files (2 of 2)..."
(unzip -qqo cfortsv-non-gpl.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting Classic Fortress maps..."
(unzip -qqo cfortsv-maps.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting Classic Fortress binaries..."
if [ $(getconf LONG_BIT) = 64 ]
then
    (unzip -qqo cfortsv-bin-x64.zip 2>/dev/null && echo done) || echo fail
else
    (unzip -qqo cfortsv-bin-x86.zip 2>/dev/null && echo done) || echo fail
fi
echo

# Rename files
echo "=== Cleaning up ==="
printf "* Renaming files..."
(mv $directory/ID1/PAK0.PAK $directory/id1/pak0.pak 2>/dev/null && rm -rf $directory/ID1 && echo done) || echo fail

# Remove distribution files
printf "* Removing setup files..."
(rm -rf $directory/qsw106.zip $directory/cfortsv-gpl.zip $directory/cfortsv-non-gpl.zip $directory/cfortsv-maps.zip $directory/cfortsv-bin-x86.zip $directory/cfortsv-bin-x64.zip $directory/cfort.ini && echo done) || echo fail

# Create symlinks
printf "* Creating symlinks to configuration files..."
[ -s ~/.cfortsv/server.conf ] || ln -s $directory/fortress/config.cfg ~/.cfortsv/server.conf
[ -s ~/.cfortsv/qtv.conf ] || ln -s $directory/qtv/config.cfg ~/.cfortsv/qtv.conf
[ -s ~/.cfortsv/qwfwd.conf ] || ln -s $directory/qwfwd/config.cfg ~/.cfortsv/qwfwd.conf
echo "done"

# Convert DOS files to UNIX
printf "* Converting DOS files to UNIX..."
for file in $(find $directory -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README")
do
    [ ! -f "$file" ] || cat $file|tr -d '\015' > tmpfile
    rm $file
    mv tmpfile $file
done
echo "done"

# Set the correct permissions
printf "* Setting permissions..."
find $directory -type f -exec chmod -f 644 {} \;
find $directory -type d -exec chmod -f 755 {} \;
chmod -f +x $directory/mvdsv 2>/dev/null
chmod -f +x $directory/fortress/mvdfinish.qws 2>/dev/null
chmod -f +x $directory/qtv/qtv.bin 2>/dev/null
chmod -f +x $directory/qwfwd/qwfwd.bin 2>/dev/null
chmod -f +x $directory/*.sh 2>/dev/null
echo "done"

echo;echo "To make sure your servers are always running, type \"crontab -e\" and add the following:"
echo;echo "*/3 * * * * $directory/start_servers.sh --silent"
echo;echo "Please edit server.conf, qtv.conf and qwfwd.conf in ~/.cfortsv before continuing!"
echo;echo "Installation complete!"
echo