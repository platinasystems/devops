kubectl create -f nginx-server-deployment.yml
kubectl create -f nginx-server-service.yml

kubectl create -f nginx-client-deployment.yml  
kubectl create -f nginx-client-service.yml  
