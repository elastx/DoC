#!/bin/bash
echo -n "Please enter the rancher server IP: "
read -r RSERVER_IP
REGISTRATIONTOKEN=`curl -s -d @token.json -H "Content-Type: application/json" -X GET http://$RSERVER_IP:8080/v1/registrationToken | python -mjson.tool | grep '"token":' | awk -F "\"" '{ print $4 }'`
echo $REGISTRATIONTOKEN
sed -i -e "s/REGISTRATIONTOKEN/$REGISTRATIONTOKEN/g" vars.tf
