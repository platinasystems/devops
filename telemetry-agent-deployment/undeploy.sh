#!/bin/bash

source ./common.sh

rm $ta_cfg_file
kubectl delete configmap $TELEMETRY_AGENT_CFG_CONFIGMAP
kubectl delete configmap $TELEMETRY_AGENT_K8S_ADMINCONF_CONFIGMAP
kubectl delete configmap $TELEMETRY_AGENT_K8S_CERT_CONFIGMAP

#echo "$deploy_template"
rm $ta_deploy_file
echo "$deploy_template" |kubectl delete -f -
