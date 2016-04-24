#### Description
This is docker image for DataStax Enterprise and DataStax Community Edition. 
It two types of variables:

* build time
* environemnt variables

###### Build time variables
* DATASTAX_VERSION - COMMUNITY | ENTERPRISE (default: COMMUNITY)
* DATASTAX_RELEASE - release to use (default: latest)
* DATASTAX_USERNAME - DataStax username (only required when using ENTERPRISE version)
* DATASTAX_PASSWORD - DataStax password_ (only requred when using ENTERPRISE version)

###### Environemnt variables
* DSE_ANALYTICS - enables SPARK
* DSE_SEARCH - enables SOLR
* DSE_GRAPH - not implemented
* CASSANDRA_CLUSTER_NAME - Cassandra cluster name
* CASSANDRA_SEEDS - Cassandra seeds (if not specified host IP address will be used)
* CASSANDRA_NUM_TOKENS - number of VNODEs (if not specified single token node is assumed)
* CASSANDRA_INITIAL_TOKEN - initial token used when VNODEs are not specified 

#### Build
```
docker build --build-arg DATASTAX_USERNAME="user@domain.com" --build-arg=DATASTAX_PASSWORD=secret --build-arg=DATASTAX_VERSION=ENTERPRISE -t netf/datastax-docker .
```

#### Run
```
docker run -i -d -t netf/datastax-docker
```
