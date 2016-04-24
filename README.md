**Build** 
`docker build --build-arg DATASTAX_USERNAME="user@domain.com" --build-arg=DATASTAX_PASSWORD=secret --build-arg=DATASTAX_VERSION=ENTERPRISE -t netf/datastax-docker .`

**Run**
`docker run -i -d -t netf/datastax-docker`
