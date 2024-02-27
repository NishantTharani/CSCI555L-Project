# Variables
# Directory name that we will use
DIRNAME=data

# TODO is there some way to get the node name and save it here? Then we can run different instructions for master/worker/client

cd /
sudo mkdir $DIRNAME
cd $DIRNAME

# Create a new filesystem using the remaining space on the system (boot) disk, at /DIRNAME
# Create a new filesystem using the remaining space on the system (boot) disk, at /DIRNAME
# The below seems unnecessary for now as we seem to be getting 68G anyway even though the docs say we should only be getting 16G?
# sudo /usr/local/etc/emulab/mkextrafs.pl /$DIRNAME

# Install java
sudo apt-get update
sudo apt-get install openjdk-8-jdk -y