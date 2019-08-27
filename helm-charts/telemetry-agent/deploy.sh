#!/bin/bash

IMAGE=
NAMESPACE=default
NAME=telemetry-agent

function usage(){
	echo "Usage: ${BASH_SOURCE[0]} [-d [-i|-n]|-u|-h]"
	echo "options:"
	echo "	-d, --deploy			deploy/redeploy ${NAME}"
	echo "	   -i, --image			docker image name of ${NAME}"
	echo "	   -n, --namespace		namespace for ${NAME}"
	echo "	-u, --undeploy			undeploy ${NAME}"
	echo "	-s, --status			show status of ${NAME}"
	echo "	-t, --token			${NAME} access token"
	echo "	-h, --help			display this help and exit"
	exit
}
parseDeployArgs(){
	while [[ $# -gt 0 ]];do
		case $1 in
			"-i"|"--image")
				IMAGE=$2
				shift 2
				;;
			"-n"|"--namespace")
				NAMESPACE=$2
				shift 2
				;;
			*)
				echo "unknown: $1"
				usage
				;;
		esac
	done
	if [[ ${#IMAGE} -eq 0 ]];then
		echo "ERROR: valid image name should be passed"
		usage
	fi
}
parseUndeployArgs(){
	while [[ $# -gt 0 ]];do
		case $1 in
			*)
				echo "unknown: $1"
				usage
				;;
		esac
	done
}
isExists(){
	if [[ $(helm list|grep "${NAME}"|wc -l) -eq 0 ]];then 
		return 0 
	else 
		return 1
	fi
}
function deploy(){
	namespaceArg=
	choice=
	parseDeployArgs $@
	isExists
	if [[ $? -eq 1 ]];then
		echo -e "Redeploy: ${NAME} deployment already running. Do you want to continue?(y/n): \c"
		read choice
		if [[ "$choice" == "no" || "$choice" == "n" || "$choice" == "NO" || "$choice" == "N" ]];then
			exit
		fi
		echo "redeploying ${NAME}"
		undeploy
		sleep 2
	fi
	sed -i "s|IMAGE: .*|IMAGE: ${IMAGE}|g" ./values.yaml
	sed -i "s|TELEMETRY_AGENT_NAMESPACE: .*|TELEMETRY_AGENT_NAMESPACE: ${NAMESPACE}|g" ./values.yaml
	sed -i 's|"KafkaEnable": .*|"KafkaEnable": false,|g' ./templates/configmap.yaml
	if [[ ${#NAMESPACE} -ne 0 ]];then
		namespaceArg="--namespace $NAMESPACE"
	fi
	if [[ `kubectl get namespace|grep ${NAMESPACE}|wc -l` -eq 0 ]];then
		kubectl create namespace $NAMESPACE
	fi
	kubectl create configmap telemetry-agent-k8s-adminconf --from-file=/etc/kubernetes/admin.conf $namespaceArg
	kubectl create configmap telemetry-agent-k8s-cert --from-file=/etc/kubernetes/ssl/ca.crt $namespaceArg
	echo "installing helm-chart"
	helm install ${namespaceArg} -n $NAME . > /dev/null
	echo "waiting for 5 sec"
	sleep 5
	echo "status:"
	echo ""
	status
	echo ""
	echo -e "telemetry-agent service Access Token: \c"
	getTelemetryToken
}
function undeploy(){
	choice=
	parseUndeployArgs $@
	isExists
	if [[ $? -eq 0 ]];then 
		echo "nothing to undeploy"
		exit 1
	fi	
	echo -e "Undeploy: Do you want to continue?(y/n): \c"
	read choice
	if [[ "$choice" == "no" || "$choice" == "n" || "$choice" == "NO" || "$choice" == "N" ]];then
		exit 1
	fi
	namespace=`kubectl get svc --all-namespaces|grep ${NAME}|awk -F" " '{print $1}'`
	namespaceArg="-n $namespace"
	echo "undeploying ${NAME}"
	helm delete --purge ${NAME}
	kubectl delete configmap telemetry-agent-k8s-adminconf $namespaceArg
	kubectl delete configmap telemetry-agent-k8s-cert $namespaceArg
}
function status(){
	kubectl get pods,svc --all-namespaces -o wide|grep "${NAME}"
}
function getTelemetryToken(){
	namespace=`kubectl get svc --all-namespaces|grep ${NAME}|awk -F" " '{print $1}'`
	namespaceArg="-n $namespace"
	kubectl describe secret $(kubectl get secret $namespaceArg|grep user|cut -d " " -f1) $namespaceArg|grep "token:"|awk -F" " '{print $2}'
}
main(){
	if [[ $(which kubectl|wc -l) -eq 0 ]];then
		echo "kubectl is missing."
		exit 1
	fi	
	job=
	if [[ $# -ge 1 ]];then
		case $1 in
			"-h"|"--help")
				job=usage
				shift
				;;
			"-d"|"--deploy")
				job=deploy
				shift
				;;
			"-u"|"--undeploy")
				job=undeploy
				shift
				;;
			"-s"|"--status")
				job=status
				shift
				;;
			"-t"|"--token")
				job=getTelemetryToken
				shift	
				;;
			*)
				echo "unknown: $1"
				job=usage
				;;
		esac
	else
		echo "ERROR: not enough arguments"
		job=usage
	fi
	$job $@
}
main $@
