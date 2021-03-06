#!/usr/bin/env bash
#
# DATASTAX_VERSION specifies whether to install DSC or DSE.
# DATASTAX_RELEASE specifies which DSE/DSC version to install. If not specified - latest version is used
#

install_repo_key() {
    curl -L http://debian.datastax.com/debian/repo_key | apt-key add -
}

install_repo_dsc() {
    echo "deb http://debian.datastax.com/community stable main" \
    | tee -a /etc/apt/sources.list.d/datastax.sources.list
    install_repo_key
}

install_repo_dse() {
    if [ "x${DATASTAX_USERNAME}x" == "xx" ] || [ "x${DATASTAX_PASSWORD}x" == "xx" ]; then
        echo "[!] You have to specify DATASTAX_USERNAME and/or DATASTAX_PASSWORD environemnt variable"
        exit 1
    fi
    echo "deb http://${DATASTAX_USERNAME}:${DATASTAX_PASSWORD}@debian.datastax.com/enterprise stable main" \
    | tee -a /etc/apt/sources.list.d/datastax.sources.list
    install_repo_key
}

install_dsc() {
    apt-get update
    if [ -z $DATASTAX_RELEASE ]; then
        latest=`apt-cache madison cassandra | \
        awk -F\| '{gsub(/ /,""); print $2}' | head -1`
        dsc_latest=`echo $latest | awk -F. '{print $1$2}'`
        export DEBIAN_FRONTEND=noninteractive && \
        apt-get install -y dsc${dsc_latest} cassandra=${latest} datastax-agent
    else
        cassandra_version=`apt-cache madison cassandra | \
        awk -v release=$DATASTAX_RELEASE -F\| '{gsub(/ /,""); if (match($2, "^" release)) print $2}' | head -1`
        if [ "x${cassandra_version}x" == "xx" ]; then
            echo "[!] Error. DATASTAX_RELEASE ($DATASTAX_RELEASE) does not exist"
            exit 1
        fi
        dsc_release=`echo $cassandra_version | awk -F. '{print $1$2}'`
        export DEBIAN_FRONTEND=noninteractive && \
        apt-get install -y dsc${dsc_release} cassandra=${cassandra_version} datastax-agent
    fi
}

install_dse() {
    apt-get update
    if [ -z $DATASTAX_RELEASE ]; then
        export DEBIAN_FRONTEND=noninteractive && apt-get install -y dse-full
    else
        dse_release=`apt-cache madison dse-full | \
        awk -v release=$DATASTAX_RELEASE -F\| '{gsub(/ /,""); if (match($2, "^" release)) print $2}' | head -1`
        if [ "x${dse_release}x" == "xx" ]; then
            echo "[!] Error. DATASTAX_RELEASE ($DATASTAX_RELEASE) does not exist"
            exit 1
        fi
        export DEBIAN_FRONTEND=noninteractive && apt-get install -y dse-full=${dse_release}
    fi
}

install_opscenter() {
    apt-get update
    apt-get install -y opscenter
}

case $DATASTAX_VERSION in
"ENTERPRISE")
    install_repo_dse
    if [ ! -z $DATASTAX_OPSCENTER ] && [ "${DATASTAX_OPSCENTER}" == "YES" ]; then
        install_opscenter
    else
        install_dse
    fi
    ;;
"COMMUNITY")
    install_repo_dsc
    install_dsc
    ;;
*)
    echo "[!] Error. DATASTAX_VERSION can be either: ENTERPRISE or COMMUNITY"
    exit 1
esac

