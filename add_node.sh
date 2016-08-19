#!/bin/bash
echo -n "Please enter the rancher server IP: "
read -r RSERVER_IP
curl -d @add_node.json -H "Content-Type: application/json" -X POST http://${RSERVER_IP}:8080/v1/projects/1a5/machines
