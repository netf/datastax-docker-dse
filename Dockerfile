##
##    DSE/DSC
##
##

FROM ubuntu
MAINTAINER Piotr Wreczycki

# Datastax build arguments
ARG DATASTAX_VERSION="COMMUNITY"
ARG DATASTAX_RELEASE
ARG DATASTAX_USERNAME
ARG DATASTAX_PASSWORD

# DSE configuration settings
ENV DSE_ANALYTICS ""
ENV DSE_SEARCH ""
ENV DSE_GRAPH ""

# Cassandra configuration settings
ENV CASSANDRA_CLUSTER_NAME ""
ENV CASSANDRA_SEEDS ""
ENV CASSANDRA_NUM_TOKENS ""
ENV CASSANDRA_INITIAL_TOKEN ""


# Add PPA for the necessary JDK
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee /etc/apt/sources.list.d/webupd8team-java.list
RUN echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
RUN apt-get update

# Install other packages
RUN export DEBIAN_FRONTEND=noninteractive && apt-get install -y curl

# Preemptively accept the Oracle License
RUN echo "oracle-java8-installer	shared/accepted-oracle-license-v1-1	boolean	true" > /tmp/oracle-license-debconf
RUN /usr/bin/debconf-set-selections /tmp/oracle-license-debconf
RUN rm /tmp/oracle-license-debconf

# Install the JDK
RUN apt-get update
RUN export DEBIAN_FRONTEND=noninteractive && apt-get install -y oracle-java8-installer oracle-java8-set-default

# Install DSE/DSC
ADD scripts/install.sh /tmp
RUN chmod 755 /tmp/install.sh && /tmp/install.sh && rm -f /tmp/install.sh

# Needed for Datastax agent
RUN locale-gen en_US en_US.UTF-8

VOLUME ["/logs", "/data"]

# Cassandra
EXPOSE 7199 7000 7001 9160 9042
# Solr
EXPOSE 8983 8984
# Spark
EXPOSE 4040 7080 7081 7077
# Hadoop
EXPOSE 8012 9290 50030 50060
# Hive/Shark
EXPOSE 10000
# DataStax agent
EXPOSE 61621

ADD scripts/init.sh /usr/local/bin/init.sh
RUN chmod 755 /usr/local/bin/init.sh

USER root
ENTRYPOINT ["init.sh"]
