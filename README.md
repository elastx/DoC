# Day of Containers 2016
# Build you own CaaS

During this session we will install Rancher using Terraform on top of Openstack.


PREP:
1. Get your Openstack credentials

2. Install Terraform https://www.terraform.io/downloads.html

3. Clone this repo

4. Test you credential by loggin in to the Openstack GUI https://ops.elastx.net

5. Add you credentials to terraform-openrc.sh



DEPLOY:
1. Source the cretentials
# cd /path/to/DoC
# . ./terraform-openrc.sh

2. See what Terraform is planning to do
# /path/to/terraform plan

3. Deploy 
# /path/to/terraform apply



RANCHEROS
1. Check what public IP the rserver instance has
# /path/to/terraform output

2. Log in to the rserver-1 instanse that is running rancheros
# ssh -i demo_rsa rancher@YOUR_IP_ADDRESS

3. Check user containers
# sudo docker ps

4. Check system containers
# sudo system-docker ps

5. Check version
# sudo os -v

6. List available OS versions
# sudo ros os list

7. If yout want to upgrade you can run
# sudo ros upgrade

8. You will find system and docker logs here
# sudo ls -l /var/log


RANCHER PREP

1. Open the Rancher UI in the web browser. You can find the URL if you run
# /path/to/terraform output rserver-url

2. Select "Add Host" > click "Save" > click on the link "Manage available machine drivers" > Active Openstack

3. Go to "INFRASTRUCTURE" > "Hosts" > "Add host" > "Other"
