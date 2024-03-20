generate_random_data() {
  rm -f temp_file
  BS=$((1048576*$1))
  dd if=/dev/urandom of=temp_file bs=$BS count=1
}

# Read parameters from user input
read -p "Enter the number of times to write: " WRITE_COUNT
read -p "Enter the size of each write: " WRITE_SIZE

read -p "Enter the number of files to set up the read experiment with: " READ_SETUP_COUNT
read -p "Enter the size of each file to set up the read experiment with in MB: " READ_SETUP_SIZE
read -p "Enter the number of times to randomly read a file: " READ_COUNT

read -p "Enter the number of times to append to a file: " APPEND_COUNT
read -p "Enter the size of each append in MB: " APPEND_SIZE


# We can just write the same random data over and over
generate_random_data 1

# Read the name of this node from /tmp/name.txt
node_name=$(cat /tmp/name.txt)

# Create a new file in HDFS
file_path="/write_read_append/test_file"
sudo hdfs dfs -mkdir -p /write_read_append
sudo hdfs dfs -touchz $file_path

# Write 100 MB to the file in distinct 1 MB writes
# We're appending here - HDFS can only append
generate_random_data $WRITE_SIZE
start_time=$(date +%s%3N)
for ((i=0; i<=$WRITE_COUNT; i++)); do
  # If i is a multiple of 10, print progress
  if [[ $((i % 10)) == 0 ]]; then
    echo "===== Write $i out of $WRITE_COUNT"
  fi
  sudo hdfs dfs -appendToFile temp_file $file_path
done
end_time=$(date +%s%3N)
write_time=$((end_time - start_time))
echo "===== Write time (ms): $write_time"

generate_random_data $READ_SETUP_SIZE
start_time=$(date +%s%3N)
# Set up the read experiment by writing 50 different files to HDFS
for ((i=0; i<$READ_SETUP_COUNT; i++)); do
  # If i is a multiple of 10, print progress
  if [[ $((i % 10)) == 0 ]]; then
    echo "===== Read setup $i out of $READ_SETUP_COUNT"
  fi
  sudo hdfs dfs -appendToFile temp_file $file_path"_read"$i
done
end_time=$(date +%s%3N)
read_setup_time=$((end_time - start_time))
echo "===== Read setup time (ms): $read_setup_time"

# Read a randomly selected file from the ones we just created, 25 times
start_time=$(date +%s%3N)
for ((i=0; i<$READ_COUNT; i++)); do
  # If i is a multiple of 5, print progress
  if [[ $((i % 10)) == 0 ]]; then
    echo "===== Read $i out of $READ_COUNT"
  fi
  sudo hdfs dfs -cat $file_path"_read"$((RANDOM % 50)) > /dev/null
done
end_time=$(date +%s%3N)
read_time=$((end_time - start_time))
echo "===== Read time (ms): $read_time"


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
log_file="/tmp/log_benchmark_read_write_append.txt"
rm -f $log_file
echo "Write time (ms): $write_time" >> $log_file
echo "Write total amount (MB): $(($WRITE_COUNT * $WRITE_SIZE))" >> $log_file
echo "Write throughput (MB/s): $(($WRITE_COUNT * $WRITE_SIZE * 1000 / $write_time))" >> $log_file

echo "Read setup time (ms): $read_setup_time" >> $log_file

echo "Read time (ms): $read_time" >> $log_file
echo "Read total amount (MB): $(($READ_COUNT * $READ_SETUP_SIZE))" >> $log_file
echo "Read throughput (MB/s): $(($READ_COUNT * $READ_SETUP_SIZE * 1000 / $read_time))" >> $log_file

echo "Append time (ms): $append_time" >> $log_file
echo "Append total amount (MB): $(($APPEND_COUNT * $APPEND_SIZE))" >> $log_file
echo "Append throughput (MB/s): $(($APPEND_COUNT * $APPEND_SIZE * 1000 / $append_time))" >> $log_file