# Day of Containers 2016
## Build you own CaaS

During this session we will install Rancher using Terraform on top of Openstack.


## PREP:
1. Get your Openstack credentials

2. Install Terraform https://www.terraform.io/downloads.html

3. Clone this repo
git@github.com:elastx/DoC.git

4. Test you credential by loggin in to the Openstack GUI https://ops.elastx.net


## DEPLOY:
1. Source the cretentials

`cd /path/to/DoC`

`. ./terraform-openrc.sh`

2. See what Terraform is planning to do

`/path/to/terraform plan`

3. Deploy 

`/path/to/terraform apply`



## RANCHEROS
1. Check what public IP the rserver instance has

`/path/to/terraform output`

2. Log in to the rserver-1 instanse that is running rancheros but first fix the key file permissions

`chmod 600 demo_rsa`

`ssh -i demo_rsa rancher@YOUR_IP_ADDRESS`

3. Check user containers

` sudo docker ps`

4. Check system containers

` sudo system-docker ps`

5. Check version

` sudo ros -v`

6. List available OS versions

` sudo ros os list`

7. If you want to upgrade you can run

` sudo ros upgrade`

8. You will find system and docker logs here

` sudo ls -l /var/log`


##RANCHER PREP

1. Open the Rancher UI in the web browser. You can find the URL if you run

` /path/to/terraform output rserver-url`

2. Select "Add Host" > click "Save" > click on the link "Manage available machine drivers" > Active Openstack


##RANCHER ADD HOSTS
1. Go to "INFRASTRUCTURE" > "Hosts" > "Add host" > "Other"

Either enter all the information here to add a node or we could use the api with a script we prepared see point 2.

2. Use the below script to add a host usinmg the API.

` less add_node.sh`

` less add_node.json`
` ./add_node.sh`

3. Add two additional nodes using Terraform

Get the registration token and add it to the vars.tf file. I have prepared a script for that so you can just run

`./get_token.sh`

Check that you got a token in the vars.tf file.

4. Change the ragent_count in vars.tf to "2"

`vi vars.tf`

5. Deploy the new hosts with Terraform

`/path/to/terraform plan`

`/path/to/terraform apply`


##DEPLOY AND TEST STACK 
1. In the GUI go to "CATALOG" > "Worpress" > "Launch"

2. Access the workpress site when done and also check where the containers are located.

3. Log on to the host where the wordpress container is running and force remove the container.

` ssh -i demo_rsa core/rancher@HOST_IP`

` docker ps`

` docker rm -f CONTAINER_ID`

4. Check what happens with the container

##DEPLOY AND TEST STACK AGAIN 
1. Download the Rancher CLI, you will find the download link in the bottom right corner in the Rancher GUI

2. Generate API keys

In the GUI go to "API" > "Add Environment API Key"

3. Set environment variables to make it easy to run the CLI

`  . rancher-openrc.sh`

4. Deploy a Wordpress stack with the CLI

` cd wp-stack`

` /path/to/rancher-compose up`

When the stack is up you can do ctrl-c to stop the log output

5. Check where the wp-stack wordpress container is running and shutdown that host.

Log in to the Openstack GUI and go to "Compute" > "Instances" > select "Shut of instance" in the instance drop down meny 

6. Check the result in Rancher

7. Start the instance again and check what happens

8. Do the same on the host that is running the workpress stack wordpress container.

9. Check the results


##MISC RANCHER TASKS
1. Add a load balancer to a stack

2. Enable access control

3. Add a label on a host

4. Add a container that must run on the host with the label you just configured

5. Open a container shell in the GUI

6. Upgrade a container and then do a roleback


RUN OTHER FRAMEWORKS
1. Remove all the current stacks and containers.

2. Edit the default envrionment under "Manage environments" and select the framwork that you would like to test

