#!/bin/bash

PERSISTENT_HDFS=/root/persistent-hdfs

# Set hdfs url to make it easier
HDFS_URL="hdfs://$PUBLIC_DNS:9010"
echo "export HDFS_URL=$HDFS_URL" >> ~/.bash_profile

pushd /root/spark-ec2/persistent-hdfs > /dev/null
source ./setup-slave.sh

for node in $SLAVES $OTHER_MASTERS; do
  echo $node
  ssh -t $SSH_OPTS root@$node "/root/spark-ec2/persistent-hdfs/setup-slave.sh" & sleep 0.3
done
wait

/root/spark-ec2/copy-dir $PERSISTENT_HDFS/conf

if [[ ! -e /vol/persistent-hdfs/dfs/name ]] ; then
  echo "Formatting persistent HDFS namenode..."
  $PERSISTENT_HDFS/bin/hadoop namenode -format
fi

echo "Starting persistent HDFS..."

# This is different depending on version.
case "$HADOOP_MAJOR_VERSION" in
  1)
    $PERSISTENT_HDFS/bin/start-dfs.sh
    ;;
  2)
    $PERSISTENT_HDFS/sbin/start-dfs.sh
    ;;
  yarn) 
    $PERSISTENT_HDFS/sbin/start-dfs.sh
    $PERSISTENT_HDFS/sbin/start-yarn.sh
    ;;
  *)
     echo "ERROR: Unknown Hadoop version"
     return -1
esac
popd > /dev/null
