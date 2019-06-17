FROM ubuntu:18.04
MAINTAINER AMIT PANDIA

RUN apt-get update 
RUN apt-get install -y net-tools 
RUN apt-get install -y iputils-ping 
RUN apt-get install -y vim 
RUN apt-get install -y tcpdump 
RUN apt-get install -y curl 
RUN apt-get install -y conntrack
RUN apt-get install -y gnupg
RUN apt-get install -y iproute2
RUN apt-get install -y apt-transport-https 
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl

COPY ./telemetry-agent /usr/bin/telemetry-agent
