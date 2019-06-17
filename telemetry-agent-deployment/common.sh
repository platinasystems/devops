#!/bin/bash

IMAGE="amitpandia/telemetry-agent:v0.7"
K8S_APISERVER_IP=10.99.0.1
K8S_APISERVER_PORT=443

TOPIC_PODDETAILS=podDetails-2
TOPIC_SVCDETAILS=svcDetails-2
TOPIC_NODEDETAILS=nodeDetails-2
TOPIC_DEPLOYMENTDETAILS=deploymentDetails
TOPIC_APPDETAILS=appDetails
TOPIC_FLOWSTATS=flowStats
TOPIC_DUMMYSTATS=dummyStats
TOPIC_VARNISHSTATS=varnishStats

TELEMETRY_AGENT_DEFAULT_LOGLEVEL=error
TELEMETRY_AGENT_CFG_CONFIGMAP=telemetry-agent-config-test
TELEMETRY_AGENT_K8S_ADMINCONF_CONFIGMAP=telemetry-agent-k8s-adminconf-test
TELEMETRY_AGENT_K8S_CERT_CONFIGMAP=telemetry-agent-k8s-cert-test

TELEMETRY_AGENT_DAEMONSET_NAME=telemetry-agent-daemonset-test
TELEMETRY_AGENT_SELECTOR_APP_NAME=telemetry-agent-test
TELEMETRY_AGENT_CONTAINER_NAME=telemetry-agent-container-test

ta_cfg_cfgmp_dir="./configs"
ta_cfg_file=${ta_cfg_cfgmp_dir}/config.cfg
ta_cfg_template_file=${ta_cfg_file}.template
ta_loglvl_file=${ta_cfg_cfgmp_dir}/loglevel
ta_varnish_file=${ta_cfg_cfgmp_dir}/varnishstats.txt
ta_k8s_adminconf_file=/etc/kubernetes/admin.conf
ta_k8s_ca_pem_file=/etc/kubernetes/ssl/ca.pem
ta_k8s_ca_crt_file=/etc/kubernetes/ssl/ca.crt
ta_deploy_file="./deploy.yaml"
ta_deploy_template_file="${ta_deploy_file}.template"
ta_pcc_cfg_file=/etc/pcc/node_profile.json

ta_cfg_cfgmp_template=`cat ${ta_cfg_template_file}|sed -e "
s|{{K8S_APISERVER_IP}}|${K8S_APISERVER_IP}|g
s|{{K8S_APISERVER_PORT}}|${K8S_APISERVER_PORT}|g
s|{{TOPIC_PODDETAILS}}|${TOPIC_PODDETAILS}|g;
s|{{TOPIC_SVCDETAILS}}|${TOPIC_SVCDETAILS}|g;
s|{{TOPIC_NODEDETAILS}}|${TOPIC_NODEDETAILS}|g;
s|{{TOPIC_DEPLOYMENTDETAILS}}|${TOPIC_DEPLOYMENTDETAILS}|g;
s|{{TOPIC_APPDETAILS}}|${TOPIC_APPDETAILS}|g;
s|{{TOPIC_FLOWSTATS}}|${TOPIC_FLOWSTATS}|g;
s|{{TOPIC_DUMMYSTATS}}|${TOPIC_DUMMYSTATS}|g;
s|{{TOPIC_VARNISHSTATS}}|${TOPIC_VARNISHSTATS}|g;
"`
deploy_template=`cat ${ta_deploy_template_file}|sed -e "
s|{{TELEMETRY_AGENT_DAEMONSET_NAME}}|${TELEMETRY_AGENT_DAEMONSET_NAME}|g
s|{{TELEMETRY_AGENT_SELECTOR_APP_NAME}}|${TELEMETRY_AGENT_SELECTOR_APP_NAME}|g
s|{{TELEMETRY_AGENT_CONTAINER_NAME}}|${TELEMETRY_AGENT_CONTAINER_NAME}|g
s|{{IMAGE}}|${IMAGE}|g;
s|{{KAFKA_IP}}|${KAFKA_IP}|g;
s|{{KAFKA_HOSTNAME}}|${KAFKA_HOSTNAME}|g;
s|{{TELEMETRY_AGENT_CFG_CONFIGMAP}}|${TELEMETRY_AGENT_CFG_CONFIGMAP}|g;
s|{{TELEMETRY_AGENT_K8S_ADMINCONF_CONFIGMAP}}|${TELEMETRY_AGENT_K8S_ADMINCONF_CONFIGMAP}|g;
s|{{TELEMETRY_AGENT_K8S_CERT_CONFIGMAP}}|${TELEMETRY_AGENT_K8S_CERT_CONFIGMAP}|g;
"`
