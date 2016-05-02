#!/usr/bin/env bash

IMAGE=$2 || "netf/datastax-docker-dse"
NUM_NODES=$1

[ -z "$CLUSTER_NAME" ] && CLUSTER_NAME="Test Cluster"

docker run -d -e CLUSTER_NAME="$CLUSTER_NAME" --name node1 $IMAGE
SEEDS=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' node1)
let n=1
while [ $n != $NUM_NODES ]; do
    let n=n+1
    docker run -d -e SEEDS=$SEEDS -e CLUSTER_NAME="$CLUSTER_NAME" --name node${n} $IMAGE
done