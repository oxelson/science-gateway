#!/bin/bash

# https://zonca.dev/2022/03/kubernetes-jetstream2-kubespray.html

cd $HOME/jetstream_kubespray/
mkdir -p inventory/$CLUSTER && cp -LRp inventory/kubejetstream/* inventory/$CLUSTER
cd inventory/$CLUSTER

sed -i "s/149.xxx.xxx.xxx/"$IP"/g" cluster.tfvars
sed -i "s/number_of_k8s_nodes = 1/number_of_k8s_nodes = 0/g" cluster.tfvars
sed -i "s/number_of_k8s_nodes_no_floating_ip = 0/number_of_k8s_nodes_no_floating_ip = 1/g" cluster.tfvars
sed -i "s/k8s_allowed_remote_ips = \[\"0.0.0.0\/0\"\]/k8s_allowed_remote_ips =  \[\"128.117.144.0\/24\", \"149.165.152.95\"\]/g" cluster.tfvars
sed -i "s/149.xxx.xxx.xxx/"$IP"/g" group_vars/k8s_cluster/k8s-cluster.yml

bash terraform_init.sh
bash terraform_apply.sh

openstack server list

echo watch -n 15 \
     ansible -i $HOME/jetstream_kubespray/inventory/$CLUSTER/hosts -m ping all
echo Once VMs are ready:
echo kube-setup2.sh
