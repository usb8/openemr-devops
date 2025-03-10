#!/bin/bash

# List of expected node names
expected_nodes=("kind-control-plane" "kind-worker" "kind-worker2" "kind-worker3")

# Function to check the status of nodes
check_nodes() {
  kubectl get nodes --no-headers -o custom-columns=NAME:.metadata.name
}

# Function to recreate a node
recreate_node() {
  node_name=$1
  kind delete node $node_name
  kind create node --name $node_name
}

# Main loop to monitor and recreate nodes
while true; do
  current_nodes=$(check_nodes)
  for expected_node in "${expected_nodes[@]}"; do
    if ! echo "$current_nodes" | grep -q "$expected_node"; then
      echo "Node $expected_node is missing. Recreating..."
      recreate_node $expected_node
    fi
  done
  sleep 60
done