#!/bin/bash

IMAGE=
NAMESPACE=default
NAME=telemetry-agent
VIP=
KAFKA=false
ADMINCONF=/etc/kubernetes/admin.conf
CACERTFILE=/etc/kubernetes/ssl/ca.crt
CAPEMFILE=/etc/kubernetes/ssl/ca.pem
CAFILE=
if [[ -f ${CACERTFILE} ]];then
	CAFILE=${CACERTFILE}
elif [[ -f ${CAPEMFILE} ]];then
	CAFILE=${CAPEMFILE}
else
	echo "no CA cert file found.."
	exit 1
fi
function usage(){
	echo "Usage: ${BASH_SOURCE[0]} [-d [-i|-n|-k]|-u|-h]"
	echo "options:"
	echo "	-d, --deploy			deploy/redeploy ${NAME}"
	echo "	   -i, --image			docker image name of ${NAME}"
	echo "	   -n, --namespace		namespace for ${NAME}"
	echo "	   -k, --kafka			enable kafka if option is provided"
	echo "	   -e, --vip			vip/external IP of service ${NAME}"
	echo "	-u, --undeploy			undeploy ${NAME}"
	echo "	-s, --status			show status of ${NAME}"
	echo "	-t, --token			${NAME} access token"
	echo "	-h, --help			display this help and exit"
	exit
}
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}
function parseDeployArgs(){
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
			"-e"|"--vip")
				VIP=$2
				shift 2
				;;
			"-k"|"--kafka")
				KAFKA=true
				shift 1
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
        if [[ ${#VIP} -gt 0 ]];then
		if ! valid_ip ${VIP}; then
			echo "ERROR: valid VIP should be passed"
			usage
		fi
	fi
}
function parseUndeployArgs(){
	while [[ $# -gt 0 ]];do
		case $1 in
			*)
				echo "unknown: $1"
				usage
				;;
		esac
	done
}
function isExists(){
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
	git diff > ./telemetry-agent_previous_changes.diff
	git checkout .
	if [[ ${#VIP} -gt 0 ]];then
		sed -i "s|spec:.*|spec:\n  externalIPs:\n  - ${VIP}|g" ./templates/service.yaml
	fi
	sed -i "s|IMAGE: .*|IMAGE: ${IMAGE}|g" ./values.yaml
	sed -i "s|TELEMETRY_AGENT_NAMESPACE: .*|TELEMETRY_AGENT_NAMESPACE: ${NAMESPACE}|g" ./values.yaml
	sed -i "s|\"KafkaEnable\": .*|\"KafkaEnable\": ${KAFKA},|g" ./templates/configmap.yaml
	sed -i "s|\"K8sNodeStatsEnable\": .*|\"K8sNodeStatsEnable\": ${KAFKA},|g" ./templates/configmap.yaml
	sed -i "s|\"K8sPodStatsEnable\": .*|\"K8sPodStatsEnable\": ${KAFKA},|g" ./templates/configmap.yaml
	sed -i "s|\"K8sSvcStatsEnable\": .*|\"K8sSvcStatsEnable\": ${KAFKA},|g" ./templates/configmap.yaml

	echo "installing helm-chart"
	helm install -n $NAME --set-file adminConf=${ADMINCONF},caCrt=${CAFILE} . > /dev/null
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
	echo "undeploying ${NAME}"
	helm delete --purge ${NAME}
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
	cd $(dirname ${BASH_SOURCE[0]})
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
