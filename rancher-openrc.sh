#
# Source this before running rancher-compose  
#
echo -n "Please enter the Rancher URL: "
read -r URL
export RANCHER_URL=$URL

echo -n "Please enter your Rancher access key: "
read -r ACCESS_KEY
export RANCHER_ACCESS_KEY=$ACCESS_KEY

echo -n "Please enter your Rancher secret: "
read -r SECRET_KEY
export RANCHER_SECRET_KEY=$SECRET_KEY

