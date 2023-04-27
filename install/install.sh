#! /bin/bash

mkdir -p rosa/rosa_install
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.12.14.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux-4.12.14.tar.gz
tar -xvf openshift-client-linux-4.12.14.tar.gz
tar -xvf openshift-install-linux-4.12.14.tar.gz
rm -rf openshift-install-linux* openshift-client* README.md
sudo mv oc kubectl openshift-install /usr/local/bin/