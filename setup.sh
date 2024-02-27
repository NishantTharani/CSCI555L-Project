# Variables
# Directory name that we will use
DIRNAME=data

# Get the hostname
hostname=$(hostname)

# Check if the hostname ends with .utah.cloudlab.us
if [[ $hostname == *".utah.cloudlab.us" ]]; then
  cluster="UTAH"
else
  cluster="UNDEFINED"
fi

# If cluster is UNDEFINED, print an error and exit
if [[ $cluster == "UNDEFINED" ]]; then
  echo "Error: Cluster is UNDEFINED"
  exit 1
fi

# Try to get the IP address of the interface named enp1s0d1
ip_address=$(ifconfig enp1s0d1 | grep 'inet ' | awk '{print $2}')

# Check if the ip_address variable is empty
if [[ -z $ip_address ]]; then
  echo "Error: Interface enp1s0d1 does not have an IP address or does not exist"
  exit 1
fi

# If the script reaches this point, the ip_address variable
# should contain the IP address of the interface enp1s0d1
echo "IP Address of enp1s0d1: $ip_address"


sudo mkdir -p /$DIRNAME
cd /$DIRNAME

# Create a new filesystem using the remaining space on the system (boot) disk, at /DIRNAME
# Create a new filesystem using the remaining space on the system (boot) disk, at /DIRNAME
# The below seems unnecessary for now as we seem to be getting 68G anyway even though the docs say we should only be getting 16G?
# sudo /usr/local/etc/emulab/mkextrafs.pl /$DIRNAME

# Install java
sudo apt-get update
# Sleep for a bit to let apt-get get its act together
sleep 2
sudo apt-get install openjdk-8-jdk -y

sudo mkdir -p /$DIRNAME/hadoop
cd /$DIRNAME/hadoop

# Download hadoop
sudo wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
sudo tar zvxf hadoop-3.3.6.tar.gz
sudo rm hadoop-3.3.6.tar.gz

