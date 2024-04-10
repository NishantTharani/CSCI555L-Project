#!/bin/bash

generate_random_data() {
  rm -f temp_file
  BS=$((1048576*$1))
  dd if=/dev/urandom of=temp_file bs=$BS count=1
}

# Read parameters from user input
read -p "Enter the number of times to write: " WRITE_COUNT
read -p "Enter the size of each write (in MB): " WRITE_SIZE

# Read the name of this node from /tmp/name.txt
node_name=$(cat /tmp/name.txt)

# Create a new file in HDFS using the node name
file_path="/write/"$node_name
sudo hdfs dfs -mkdir -p /write
sudo hdfs dfs -rm $file_path
sudo hdfs dfs -touchz $file_path

# Write 100 MB to the file in distinct 1 MB writes
# We're appending here - HDFS can only append
generate_random_data $WRITE_SIZE
start_time=$(date +%s%3N)
for ((i=0; i<$WRITE_COUNT; i++)); do
  # If i is a multiple of 10, print progress
  if [[ $((i % 10)) == 0 ]]; then
    echo "===== Write $i out of $WRITE_COUNT"
  fi
  sudo hdfs dfs -appendToFile temp_file $file_path
done
end_time=$(date +%s%3N)
write_time=$((end_time - start_time))
echo "===== Write time (ms): $write_time"

# Clean up the temporary file
rm temp_file

# Log the timing information to a file
log_file="/tmp/log_benchmark_write.txt"
rm -f $log_file
echo "Write time (ms): $write_time" >> $log_file
echo "Write total amount (MB): $(($WRITE_COUNT * $WRITE_SIZE))" >> $log_file
echo "Write throughput (MB/s): $(($WRITE_COUNT * $WRITE_SIZE * 1000 / $write_time))" >> $log_file
