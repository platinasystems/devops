FROM ubuntu:latest
MAINTAINER AMIT PANDIA

# install necessary packages
RUN apt-get update
RUN apt-get install -y net-tools
RUN apt-get install -y iputils-ping
RUN apt-get install -y tcpdump
RUN apt-get install -y iperf

# get iperf-server init script
ADD iperf_init.sh /etc/init.d/iperf_init.sh

# run the script when a container is created
CMD ["/bin/bash", "/etc/init.d/iperf_init.sh"]

