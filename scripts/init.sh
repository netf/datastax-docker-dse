#!/usr/bin/env bash

_create_dirs() {
    for dir in $@
    do
        mkdir -p $dir && chown -R cassandra:cassandra $dir
    done
}

init_dsc() {
    # Get running container's IP
    IP=`hostname -i`

    CASSANDRA_CONFIG="/etc/cassandra/cassandra.yaml"

    if [ -z "${CASSANDRA_DATA_DIR}" ]; then
        CASSANDRA_DATA_DIR="/cassandra"
    fi

    if [ -z "${CASSANDRA_LOG_DIR}" ]; then
        CASSANDRA_LOG_DIR="/cassandra-logs"
    fi

    # create dirs
    _create_dirs /cassandra /cassandra-logs

    # Setup seeds
    if [ ! -z ${CASSANDRA_SEEDS} ]; then
        SEEDS="${CASSANDRA_SEEDS}"
    else
        SEEDS="${IP}"
    fi

    # Setup cluster name
    if [ -z "${CASSANDRA_CLUSTER_NAME}" ]; then
            echo "No cluster name specified, preserving default one"
    else
            sed -i -e "s/^cluster_name:.*/cluster_name: $CASSANDRA_CLUSTER_NAME/" $CASSANDRA_CONFIG
    fi

    # Data dir
    sed -i -e "s|/var/lib/cassandra/|${DATA_DIR}/|g" $CASSANDRA_CONFIG

    # Log dir
    echo "JVM_OPTS=\$JVM_OPTS -Dcassandra.logdir=$LOGS_DIR" >> $CASSANDRA_ENV


    # rpc_address
    sed -i -e "s/^rpc_address.*/rpc_address: $IP/" $CASSANDRA_CONFIG

    # listen_address
    sed -i -e "s/^listen_address.*/listen_address: $IP/" $CASSANDRA_CONFIG

    # seeds
    sed -i -e "s/- seeds: \"127.0.0.1\"/- seeds: \"$SEEDS\"/" $CASSANDRA_CONFIG

    # tokens
    if [ ! -z ${CASSANDRA_NUM_TOKENS} ]; then
        sed -i -e "s/^\(# \)num_tokens:.*/num_tokens: $CASSANDRA_NUM_TOKENS/" $CASSANDRA_CONFIG
    else
        if [ -z ${CASSANDRA_INITIAL_TOKEN} ]; then
            # if no INITIAL_TOKEN is provided we assume VNODES standard 256 tokens
            CASSANDRA_NUM_TOKENS="256"
            sed -i -e "s/^\(# \)num_tokens:.*/num_tokens: $CASSANDRA_NUM_TOKENS/" $CASSANDRA_CONFIG
        else
            sed -i -e "s/^num_tokens:/# num_tokens:/" $CASSANDRA_CONFIG
            sed -i -e "s/^\(# \)initial_token:.*/initial_token: $CASSANDRA_INITIAL_TOKEN/" $CASSANDRA_CONFIG
        fi
    fi

    /etc/init.d/datastax-agent start

    echo "Starting Cassandra on $IP..."

    exec cassandra -f
}

init_dse() {
    # Get running container's IP
    IP=`hostname -i`

    CASSANDRA_CONFIG="/etc/dse/cassandra/cassandra.yaml"
    SPARK_ENV="/etc/dse/spark/spark-env.sh"

    if [ -z "${CASSANDRA_DATA_DIR}" ]; then
        CASSANDRA_DATA_DIR="/cassandra"
    fi

    if [ -z "${CASSANDRA_LOG_DIR}" ]; then
        CASSANDRA_LOG_DIR="/cassandra-logs"
    fi

    if [ -z "${SPARK_DATA_DIRS}" ]; then
        SPARK_DATA_DIRS="${CASSANDRA_DATA_DIR}/spark/worker ${CASSANDRA_DATA_DIR}/spark/rdd"
    fi

    if [ -z "${SPARK_LOG_DIR}" ]; then
        SPARK_LOG_DIR="${CASSANDRA_LOG_DIR}/spark/worker"
    fi

    # create dirs
    _create_dirs $CASSANDRA_DATA_DIR $CASSANDRA_LOG_DIR $SPARK_DATA_DIRS $SPARK_LOG_DIR

    # Setup seeds
    if [ ! -z ${CASSANDRA_SEEDS} ]; then
        SEEDS="${CASSANDRA_SEEDS}"
    else
        SEEDS="${IP}"
    fi

    # Setup cluster name
    if [ -z "${CASSANDRA_CLUSTER_NAME}" ]; then
            echo "No cluster name specified, preserving default one"
    else
            sed -i -e "s/^cluster_name:.*/cluster_name: $CASSANDRA_CLUSTER_NAME/" $CASSANDRA_CONFIG
    fi

    # Data dir
    sed -i -e "s|/var/lib/cassandra/|${CASSANDRA_DATA_DIR}/|g" $CASSANDRA_CONFIG
    sed -i -- "s|/var/lib/spark/|${CASSANDRA_DATA_DIR}/spark/|g" $SPARK_ENV
    sed -i -- "s|/var/log/spark/|${CASSANDRA_LOG_DIR}/spark/|g" $SPARK_ENV

   # rpc_address
    sed -i -e "s/^rpc_address.*/rpc_address: $IP/" $CASSANDRA_CONFIG

    # listen_address
    sed -i -e "s/^listen_address.*/listen_address: $IP/" $CASSANDRA_CONFIG

    # seeds
    sed -i -e "s/- seeds: \"127.0.0.1\"/- seeds: \"$SEEDS\"/" $CASSANDRA_CONFIG

    # tokens
    if [ ! -z ${CASSANDRA_NUM_TOKENS} ]; then
        sed -i -e "s/^\(# \)num_tokens:.*/num_tokens: $CASSANDRA_NUM_TOKENS/" $CASSANDRA_CONFIG
        sed -i -e "s/^initial_token:/# initial_token:/" $CASSANDRA_CONFIG
    else
        if [ -z ${CASSANDRA_INITIAL_TOKEN} ]; then
            CASSANDRA_NUM_TOKENS="256"
            sed -i -e "s/^\(# \)num_tokens:.*/num_tokens: $CASSANDRA_NUM_TOKENS/" $CASSANDRA_CONFIG
            sed -i -e "s/^initial_token:/# initial_token:/" $CASSANDRA_CONFIG
        else
            sed -i -e "s/^num_tokens:/# num_tokens:/" $CASSANDRA_CONFIG
            sed -i -e "s/^\(# \)initial_token:.*/initial_token: $CASSANDRA_INITIAL_TOKEN/" $CASSANDRA_CONFIG
        fi
    fi

    /etc/init.d/datastax-agent start

    OPTS="-f"

    if [ ! -z $DSE_ANALYTICS ]; then
        OPTS="-f -k"
    fi

    if [ ! -z $DSE_SEARCH ]; then
        OPTS="-f -s"
    fi

    echo "Starting DSE on $IP"
    exec dse cassandra ${OPTS}


}

init() {

if [ -d /etc/dse ] && [ -x /usr/bin/dse ]; then
    init_dse
elif [ -d /etc/cassandra ] && [ -x /usr/bin/cassandra ]; then
    init_dsc
else
    echo "[!] Either DSE nor Cassandra is installed. Weird"
    exit 1
fi

}

init