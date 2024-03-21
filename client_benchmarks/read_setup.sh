#!/bin/bash

generate_random_data() {
  rm -f temp_file
  BS=$((1048576*$1))
  dd if=/dev/urandom of=temp_file bs=$BS count=1
}

# Read parameters from user input
read -p "Enter the number of files to set up the read experiment with: " READ_SETUP_COUNT
read -p "Enter the size of each file to set up the read experiment with in MB: " READ_SETUP_SIZE

# Read the name of this node from /tmp/name.txt
node_name=$(cat /tmp/name.txt)

# Create a new file in HDFS
file_path="/read/read_file"
sudo hdfs dfs -mkdir -p /read

generate_random_data $READ_SETUP_SIZE
start_time=$(date +%s%3N)
# Set up the read experiment by writing different files to HDFS
for ((i=0; i<$READ_SETUP_COUNT; i++)); do
  if [[ $((i % 10)) == 0 ]]; then
    echo "===== Read setup $i out of $READ_SETUP_COUNT"
  fi
  sudo hdfs dfs -appendToFile temp_file $file_path"_"$i
done
end_time=$(date +%s%3N)
read_setup_time=$((end_time - start_time))
echo "===== Read setup time (ms): $read_setup_time"

# Clean up the temporary file
rm temp_file

# Log the timing information to a file
log_file="/tmp/log_benchmark_read_setup.txt"
rm -f $log_file

echo "Read setup time (ms): $read_setup_time" >> $log_file