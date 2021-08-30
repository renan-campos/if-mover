#! /bin/bash 

if [ -z $INTERFACE ]
then
  echo "Expecting INTERFACE environment variable to be set"
  exit 1
fi

if [ -z $IP_ADDR ]
then
  echo "Expecting IP_ADDR environment variable to be set"
  exit 1
fi

if [ -z $IP_PREFIX ]
then
  echo "Expecting IP_PREFIX environment variable to be set"
  exit 1
fi

if [ -z $NETWORK_NAME ]
then
  echo "Expecting NETWORK_NAME environment variable to be set"
  exit 1
fi

# Find the namespace that the IP belongs to
NET_NS=$(for id in $(ip netns show | cut -d " " -f 1 ) ; do ip netns exec $id ip addr show | grep -q $IP_ADDR/ && echo $id && break; done)
if [ -z $NET_NS ]
then
  echo "Multus network namespace not found"
  exit 1
fi

# Find the host network namespace
HOST_NS=$(for id in $(ip netns show | cut -d " " -f 1 ) ; do ip netns exec $id ip link show | grep -q tun0 && echo $id && break; done)
if [ -z $HOST_NS ]
then
  echo "Host network namespace not found"
  exit 1
fi

# Move interface from holder namespace to host namespace
ip netns exec $NET_NS ip link set net1 netns $HOST_NS || { echo "Error moving interface"; exit 1; }

# Change interface name
# Some network names are too long to be interface names, hard-coding name for now.
#INTERFACE_NAME=${NETWORK_NAME}-link
# TODO: Handle interface name collisions
INTERFACE_NAME=multus-link
ip netns exec $HOST_NS ip link set net1 name $INTERFACE_NAME || { echo "Error changing interface name"; exit 1; }

# Setup IP configuration
ip netns exec $HOST_NS ip addr add $IP_ADDR/$IP_PREFIX dev $INTERFACE_NAME || { echo "Error configing IP"; exit 1; }

# Turn on interface
ip netns exec $HOST_NS ip link set $INTERFACE_NAME up || { echo "Error starting interface"; exit 1; }
