##
##    Cassandra
##
##

FROM ubuntu
MAINTAINER Piotr Wreczycki, piotr.wreczycki@datastax.com

# Datastax build arguments
ARG DATASTAX_VERSION="COMMUNITY"
ARG DATASTAX_RELEASE
ARG DATASTAX_USERNAME
ARG DATASTAX_PASSWORD

RUN env

ENV CLUSTERNAME ""
ENV ANALYTICS ""
ENV SEARCH ""
ENV GRAPH ""

# Add PPA for the necessary JDK
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee /etc/apt/sources.list.d/webupd8team-java.list
RUN echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
RUN apt-get update

# Install other packages
RUN apt-get install -y curl jq python-dev python-pip libyaml-dev

# Install python modules
RUN pip install python-etcd pyyaml

# Preemptively accept the Oracle License
RUN echo "oracle-java8-installer	shared/accepted-oracle-license-v1-1	boolean	true" > /tmp/oracle-license-debconf
RUN /usr/bin/debconf-set-selections /tmp/oracle-license-debconf
RUN rm /tmp/oracle-license-debconf

# Install the JDK
RUN apt-get update
RUN apt-get install -y oracle-java8-installer oracle-java8-set-default

# Install Cassandra
ADD scripts/install.sh /tmp
RUN chmod 755 /tmp/install.sh && /tmp/install.sh && rm -f /tmp/install.sh

# Start the datastax-agent
#RUN service datastax-agent start

# Cassandra
EXPOSE 7199 7000 7001 9160 9042
# Search
EXPOSE 8983 8984
# Analytics
EXPOSE 4040 7080 7081 7077 8012 9290 10000 50030 50060
# DataStax agent
EXPOSE 61621

USER root
CMD ["cassandra","-f","-p","/var/run/cassandra.pid"]
