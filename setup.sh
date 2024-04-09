#!/bin/bash

# Variables
# Directory name that we will use
DIRNAME=data

# Read the number of worker nodes and client nodes to know the IP addresses
NUM_WORKERS=$(cat /tmp/worker_count.txt)
NUM_CLIENTS=$(cat /tmp/client_count.txt)

# Assign IP addresses based on number workers/clients.
# Observe worker IPs are in the range [101, 101+num_workers). 
# Clients are [101+num_workers, 101+num_workers+num_clients)

# If master IP cannot be pinged, exit with an error
MASTER_IP=10.10.1.100

ping -c 1 -W 1 $MASTER_IP > /dev/null
if [[ $? -ne 0 ]]; then
  echo "Error: Could not ping $MASTER_IP"
  exit 1
fi

# Check which of the expected worker IPs are pingable
EXPECTED_WORKER_IP_LIST=()
for ((i=1; i<=NUM_WORKERS; i++)); do
  IP="10.10.1.$((100+i))"
  EXPECTED_WORKER_IP_LIST+=("$IP")
done

WORKER_IP_LIST=()

for ip in "${EXPECTED_WORKER_IP_LIST[@]}"; do
  ping -c 1 -W 1 $ip > /dev/null
  if [[ $? -eq 0 ]]; then
    WORKER_IP_LIST+=("$ip")
  fi
done

# Echo the worker IPs that are pingable
echo "Number of worker IPs that are pingable: ${#WORKER_IP_LIST[@]}"
echo "Worker IPs that are pingable:"
for ip in "${WORKER_IP_LIST[@]}"; do
  echo "$ip"
done

# Check which of the expected client IPs are pingable
EXPECTED_CLIENT_IP_LIST=()
for ((i=1; i<=NUM_CLIENTS; i++)); do
  IP="10.10.1.$((100+NUM_WORKERS+i))"
  EXPECTED_CLIENT_IP_LIST+=("$IP")
done

CLIENT_IP_LIST=()

for ip in "${EXPECTED_CLIENT_IP_LIST[@]}"; do
  ping -c 1 -W 1 $ip > /dev/null
  if [[ $? -eq 0 ]]; then
    CLIENT_IP_LIST+=("$ip")
  fi
done

# Echo the client IPs that are pingable
echo "Number of client IPs that are pingable: ${#CLIENT_IP_LIST[@]}"
echo "Client IPs that are pingable:"
for ip in "${CLIENT_IP_LIST[@]}"; do
  echo "$ip"
done


# Hostname cannot reliably be used to identify cluster since it only seems to include the cluster for the master node

# Read /tmp/hwtype.txt and save the string to the variable HWTYPE, without a newline
HWTYPE=$(cat /tmp/hwtype.txt)
NAME=$(cat /tmp/name.txt)

# Exit with an error if HWTYPE is not defined
if [[ -z $HWTYPE ]]; then
  echo "Error: HWTYPE is not defined"
  exit 1
fi


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

# Download hadoop
sudo wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz -q
sudo tar zxf hadoop-3.3.6.tar.gz
sudo rm hadoop-3.3.6.tar.gz
sudo mv hadoop-3.3.6 hadoop

# Update hadoop configuration
# Define the file path to core-site.xml
file_path="/$DIRNAME/hadoop/etc/hadoop/core-site.xml"

# Backup the original file
sudo cp "$file_path" "$file_path.backup"

# Write the new configuration
# If this doesn't work then try using <name>fs.default.name</name> instead?
sudo echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
<property>
<name>fs.defaultFS</name>
<value>hdfs://'$MASTER_IP':9000</value>
</property>
</configuration>' > "$file_path"

# Write hdfs-site.xml
file_path="/$DIRNAME/hadoop/etc/hadoop/hdfs-site.xml"
sudo mkdir -p /$DIRNAME/hadoop/data/namenode/
sudo mkdir -p /$DIRNAME/hadoop/data/datanode/
sudo echo '<configuration>
<property>
<name>dfs.namenode.name.dir</name>
<value>/'$DIRNAME'/hadoop/data/namenode/</value>
</property>
<property>
<name>dfs.datanode.data.dir</name>
<value>/'$DIRNAME'/hadoop/data/datanode/</value>
</property>
</configuration>' > "$file_path"

# Set JAVA_HOME
java_path=$(update-alternatives --display java | grep 'link currently points to' | awk '{print $5}')
JAVA_HOME=$(dirname $(dirname $java_path))

if [[ -z "$JAVA_HOME" ]]; then
    echo "JAVA_HOME could not be determined."
    exit 1
fi

hadoop_env_file="/$DIRNAME/hadoop/etc/hadoop/hadoop-env.sh"
sudo cp "$hadoop_env_file" "$hadoop_env_file.backup"
sudo sed -i "/^# export JAVA_HOME=/c\export JAVA_HOME=$JAVA_HOME" "$hadoop_env_file"

# Set all the users to root
sudo sed -i "/^# export HDFS_NAMENODE_USER=hdfs/c\export HDFS_NAMENODE_USER=\"root\"\nexport HDFS_DATANODE_USER=\"root\"\nexport HDFS_SECONDARYNAMENODE_USER=\"root\"\nexport YARN_RESOURCEMANAGER_USER=\"root\"\nexport YARN_NODEMANAGER_USER=\"root\"" "$hadoop_env_file"


# Set worker IP addresses
hadoop_workers_file="/$DIRNAME/hadoop/etc/hadoop/workers"
sudo cp "$hadoop_workers_file" "$hadoop_workers_file.backup"
# echo "$WORKER1_IP" | sudo tee "$hadoop_workers_file"
# echo "$WORKER2_IP" | sudo tee -a "$hadoop_workers_file"
# echo "$WORKER3_IP" | sudo tee -a "$hadoop_workers_file"
# Start from 1 to exclude the MASTER_IP
for ((i=1; i<=NUM_WORKERS; i++)); do
  ip="${WORKER_IP_LIST[i]}"
  if ((i == 1)); then
    echo "$ip" | sudo tee "$hadoop_workers_file"
  else
    echo "$ip" | sudo tee -a "$hadoop_workers_file"
  fi
done

# Shortcut to the hadoop bin and sbin directories
HBIN=/$DIRNAME/hadoop/bin
HSBIN=/$DIRNAME/hadoop/sbin
# fi

# Add bin and sbin directories to PATH for user and sudo
BASHRC="/users/ntharani/.bashrc"
echo 'export PATH=/data/hadoop/bin:/data/hadoop/sbin:$PATH' >> "$BASHRC"
echo "alias sudo='sudo env PATH=\$PATH'" >> "$BASHRC"

# Add the hadoop bin and sbin directories to the PATH for the root user
# Path to a temporary file
TEMP_SUDOERS=$(mktemp)

# Avoiding locale issues by ensuring C locale
export LC_ALL=C

# Check if secure_path exists and replace it or add it
if grep -q "^Defaults[[:space:]]secure_path=" /etc/sudoers; then
    # Secure_path exists, so replace it
    sed 's|^Defaults[[:space:]]secure_path=.*|Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/data/hadoop/bin"|' /etc/sudoers > "$TEMP_SUDOERS"
else
    # Secure_path doesn't exist, so append it
    cp /etc/sudoers "$TEMP_SUDOERS"
    echo 'Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/data/hadoop/bin"' >> "$TEMP_SUDOERS"
fi

# Update the sudoers file safely using visudo
visudo -c -f "$TEMP_SUDOERS" && cp "$TEMP_SUDOERS" /etc/sudoers

# Clean up the temporary file
rm -f "$TEMP_SUDOERS"

echo "sudoers has been updated."