#!/bin/bash

echo "127.0.1.1 $(hostname)" >> /etc/hosts

echo "Installing k3s v1.33.5+k3s1..."
export INSTALL_K3S_VERSION=v1.33.5+k3s1
export INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --node-ip=192.168.56.110"
curl -sfL https://get.k3s.io | sh -

echo "Setting up aliases"
echo "alias k='kubectl'" >> /home/vagrant/.bashrc
echo "alias c='clear'" >> /home/vagrant/.bashrc

mv /tmp/deployment.yaml /home/vagrant
mv /tmp/app1 /home/vagrant
mv /tmp/app2 /home/vagrant
mv /tmp/app3 /home/vagrant

/usr/local/bin/kubectl create configmap app1-config --from-file /home/vagrant/app1/index.html
/usr/local/bin/kubectl create configmap app2-config --from-file /home/vagrant/app2/index.html
/usr/local/bin/kubectl create configmap app3-config --from-file /home/vagrant/app3/index.html

/usr/local/bin/kubectl apply -f /home/vagrant/deployment.yaml