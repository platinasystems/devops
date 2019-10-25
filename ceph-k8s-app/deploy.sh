sudo kubectl create -f pv-volume.yaml
sudo kubectl create -f pv-claim.yaml
sudo kubectl create -f pv-pod.yaml
kubectl get pv ceph-pv-volume
kubectl get pvc ceph-pv-claim
watch -n 0.1 "sudo kubectl get pods"
