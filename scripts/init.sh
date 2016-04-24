#!/usr/bin/env bash
init_dsc() {

    CASSANDRA_CONFIG="/etc/cassandra/"

    # Get running container's IP
    IP=`hostname -I`

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
            sed -i -e "s/^cluster_name:.*/cluster_name: $CASSANDRA_CLUSTER_NAME/" $CASSANDRA_CONFIG/cassandra/cassandra.yaml
    fi


    # rpc_address
    sed -i -e "s/^rpc_address.*/rpc_address: $IP/" $CASSANDRA_CONFIG/cassandra/cassandra.yaml

    # listen_address
    sed -i -e "s/^listen_address.*/listen_address: $IP/" $CASSANDRA_CONFIG/cassandra/cassandra.yaml

    # seeds
    sed -i -e "s/- seeds: \"127.0.0.1\"/- seeds: \"$SEEDS\"/" $CASSANDRA_CONFIG/cassandra/cassandra.yaml

    # tokens
    if [ ! -z ${CASSANDRA_NUM_TOKENS} ]; then
        sed -i -e "s/^\(# \)num_tokens:.*/num_tokens: $CASSANDRA_NUM_TOKENS/" $CASSANDRA_CONFIG/cassandra/cassandra.yaml
    else
        if [ -z ${CASSANDRA_INITIAL_TOKEN} ]; then
            # if no INITIAL_TOKEN is provided we assume VNODES standard 256 tokens
            CASSANDRA_NUM_TOKENS="256"
            sed -i -e "s/^\(# \)num_tokens:.*/num_tokens: $CASSANDRA_NUM_TOKENS/" $CASSANDRA_CONFIG/cassandra/cassandra.yaml
        else
            sed -i -e "s/^num_tokens:/# num_tokens:/" $CASSANDRA_CONFIG/cassandra/cassandra.yaml
            sed -i -e "s/^\(# \)initial_token:.*/initial_token: $CASSANDRA_INITIAL_TOKEN/" $CASSANDRA_CONFIG/cassandra/cassandra.yaml
        fi
    fi

    /etc/init.d/datastax-agent start

    echo "Starting Cassandra on $IP..."

    exec cassandra -f
}

init_dse() {
    CASSANDRA_CONFIG="/etc/dse/cassandra/"

    # Get running container's IP
    IP=`hostname -I`

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
            sed -i -e "s/^cluster_name:.*/cluster_name: $CASSANDRA_CLUSTER_NAME/" $CASSANDRA_CONFIG/cassandra.yaml
    fi

    # rpc_address
    sed -i -e "s/^rpc_address.*/rpc_address: $IP/" $CASSANDRA_CONFIG/cassandra.yaml

    # listen_address
    sed -i -e "s/^listen_address.*/listen_address: $IP/" $CASSANDRA_CONFIG/cassandra.yaml

    # seeds
    sed -i -e "s/- seeds: \"127.0.0.1\"/- seeds: \"$SEEDS\"/" $CASSANDRA_CONFIG/cassandra.yaml

    # tokens
    if [ ! -z ${CASSANDRA_NUM_TOKENS} ]; then
        sed -i -e "s/^\(# \)num_tokens:.*/num_tokens: $CASSANDRA_NUM_TOKENS/" $CASSANDRA_CONFIG/cassandra.yaml
        sed -i -e "s/^initial_token:/# initial_token:/" $CASSANDRA_CONFIG/cassandra.yaml
    else
        if [ -z ${CASSANDRA_INITIAL_TOKEN} ]; then
            CASSANDRA_NUM_TOKENS="256"
            sed -i -e "s/^\(# \)num_tokens:.*/num_tokens: $CASSANDRA_NUM_TOKENS/" $CASSANDRA_CONFIG/cassandra.yaml
            sed -i -e "s/^initial_token:/# initial_token:/" $CASSANDRA_CONFIG/cassandra.yaml
        else
            sed -i -e "s/^num_tokens:/# num_tokens:/" $CASSANDRA_CONFIG/cassandra.yaml
            sed -i -e "s/^\(# \)initial_token:.*/initial_token: $CASSANDRA_INITIAL_TOKEN/" $CASSANDRA_CONFIG/cassandra.yaml
        fi
    fi

    /etc/init.d/datastax-agent start

    OPTS="-f"

    if [ ! -z $DSE_ANALYTICS ]; then
        OPTS="${OPTS} -k"
    fi

    if [ ! -z $DSE_SEARCH ]; then
        OPTS="${OPTS} -s"
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