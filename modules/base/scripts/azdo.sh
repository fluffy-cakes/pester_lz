#!/bin/bash

set -eu -o pipefail

sudo snap install powershell --classic

mkdir /vsts
cd /vsts || exit
chown -R azdo:azdo /vsts

wget https://vstsagentpackage.azureedge.net/agent/2.172.2/vsts-agent-linux-x64-2.172.2.tar.gz
tar zxvf vsts-agent-linux-x64-2.172.2.tar.gz

./bin/Agent.Listener configure --unattended --url https://dev.azure.com/${azdo_organisation_name} --auth pat --token ${azdo_pat} --pool ${azdo_agent_pool} --agent $(hostname) --acceptTeeEula --replace

sudo ./svc.sh install
sudo ./svc.sh start

echo "OMG! I finished setting up on $(date)"