#!/bin/bash

generate_random_data() {
  rm -f temp_file
  BS=$((1048576*$1))
  dd if=/dev/urandom of=temp_file bs=$BS count=1
}

# Read parameters from user input
read -p "Enter the number of times to append to a file: " APPEND_COUNT
read -p "Enter the size of each append in MB: " APPEND_SIZE

# Read the name of this node from /tmp/name.txt
node_name=$(cat /tmp/name.txt)

# Create a new file in HDFS
file_path="/append/append_file"
sudo hdfs dfs -mkdir -p /append
sudo hdfs dfs -touchz $file_path

# Record append 1 MB to the file, 50 times
generate_random_data $APPEND_SIZE
start_time=$(date +%s%3N)
for ((i=0; i<$APPEND_COUNT; i++)); do
  # If i is a multiple of 10, print progress
  if [[ $((i % 10)) == 0 ]]; then
    echo "===== Append $i out of $APPEND_COUNT"
  fi
  # generate_random_data
  sudo hdfs dfs -appendToFile temp_file $file_path
done
end_time=$(date +%s%3N)
append_time=$((end_time - start_time))
echo "===== Append time (ms): $append_time"

# Clean up the temporary file
rm temp_file

# Log the timing information to a file
log_file="/tmp/log_benchmark_append.txt"
rm -f $log_file
echo "Append time (ms): $append_time" >> $log_file
echo "Append total amount (MB): $(($APPEND_COUNT * $APPEND_SIZE))" >> $log_file
echo "Append throughput (MB/s): $(($APPEND_COUNT * $APPEND_SIZE * 1000 / $append_time))" >> $log_file