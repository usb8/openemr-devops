#!/bin/bash

# Function to check the status of nodes
check_nodes() {
  kubectl get nodes | grep NotReady
}

# Function to recreate a node
recreate_node() {
  node_name=$1
  kind delete node $node_name
  kind create node --name $node_name
}

# Main loop to monitor and recreate nodes
while true; do
  not_ready_nodes=$(check_nodes)
  if [ ! -z "$not_ready_nodes" ]; then
    for node in $not_ready_nodes; do
      recreate_node $node
    done
  fi
  sleep 60
done