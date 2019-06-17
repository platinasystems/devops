#!/bin/bash

source ./common.sh

#echo "$ta_cfg_cfgmp_template"
echo "$ta_cfg_cfgmp_template" > ${ta_cfg_file}
echo "$TELEMETRY_AGENT_DEFAULT_LOGLEVEL" > ${ta_loglvl_file}

kubectl create clusterrolebinding cluster-system-anonymous --clusterrole=cluster-admin --user=system:anonymous --serviceaccount=kube-system:default
kubectl create configmap ${TELEMETRY_AGENT_CFG_CONFIGMAP} --from-file="${ta_cfg_cfgmp_dir}"
kubectl create configmap ${TELEMETRY_AGENT_K8S_ADMINCONF_CONFIGMAP} --from-file="$ta_k8s_adminconf_file"

if [[ -f $ta_k8s_ca_pem_file ]];then
	kubectl create configmap ${TELEMETRY_AGENT_K8S_CERT_CONFIGMAP} --from-file="$ta_k8s_ca_pem_file"
elif [[ -f $ta_k8s_ca_crt_file ]];then
	kubectl create configmap ${TELEMETRY_AGENT_K8S_CERT_CONFIGMAP} --from-file="$ta_k8s_ca_crt_file"
else
	echo "failed to create $TELEMETRY_AGENT_K8S_CERT_CONFIGMAP configmap. either $ta_k8s_ca_pem_file or $ta_k8s_ca_crt_file file should be present"
fi

#echo "$deploy_template"
echo "$deploy_template" > ${ta_deploy_file}
echo "$deploy_template" |kubectl create -f -
