#!/bin/bash
sed -i -e "s/PASSWORD/$TF_VAR_password/g" add_node.json
sed -i -e "s/USER/$TF_VAR_user_name/g" add_node.json
sed -i -e "s/TENANT/$TF_VAR_tenant_name/g" add_node.json
echo -n "Please enter the rancher server IP: "
read -r RSERVER_IP
curl -d @add_node.json -H "Content-Type: application/json" -X POST http://${RSERVER_IP}:8080/v1/projects/1a5/machines
