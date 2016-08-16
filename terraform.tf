# These variables are received through ENV-variables created 
# by terraform-openrc.sh, hence, run that first

variable "password" {}
variable "user_name" {}
variable "tenant_name" {}

variable "cloudconfig_server" {
  type = "string"
  default = <<EOF
#cloud-config
rancher:
  services:
    rancher-server:
      image: rancher/server
      privileged: true
      restart: always
      ports:
        - "8080:8080"
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
EOF
}

variable "cloudconfig_agent" {
  type = "string"
  default = <<EOF
#cloud-config
EOF
}

variable "ops_image" {
  type = "string"
  default = "rancheros-0.5.0"
}

variable "ops_flavor" {
  type = "string"
  default = "m1.xsmall"
}


### [Elastx Openstack] ###

provider "openstack" {
  user_name = "${var.user_name}"
  tenant_name = "${var.tenant_name}"
  password = "${var.password}"
  auth_url = "https://ops.elastx.net:5000/v2.0"
}

### [General setup] ###

resource "openstack_networking_router_v2" "router" {
  name = "ops-router"
  admin_state_up = "true"
  external_gateway = "62954df1-05bb-42e5-9960-ca921cccaeeb"
}

resource "openstack_compute_keypair_v2" "demo_keypair" {
  name = "demo-keypair"
  public_key = "${file("demo_rsa.pub")}"
}

### Should be tighten up, not let the world be able to ssh
### this is only for demonstrational purposes.

resource "openstack_compute_secgroup_v2" "ragent_sg" {
  name = "ragent-sg"
  description = "rancher agent security group"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "rserver_sg" {
  name = "rserver-sg"
  description = "rancher server security group"
  rule {
    from_port = 8080
    to_port = 8080
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 443
    to_port = 443
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "rall_sg" {

  name = "rall-sg"
  description = "rancher all security group"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 500
    to_port = 500
    ip_protocol = "udp"
    self = "true"
  }
  rule {
    from_port = 4500
    to_port = 4500
    ip_protocol = "udp"
    self = "true"
  }
}




### [networking] ###

resource "openstack_networking_network_v2" "rancher_net" {
  name = "rancher-net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "rancher_subnet" {
  name = "rancher-subnet"
  network_id = "${openstack_networking_network_v2.rancher_net.id}"
  cidr = "10.0.0.0/24"
  ip_version = 4
  enable_dhcp = "true"
}

resource "openstack_networking_router_interface_v2" "rancher-interface" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.rancher_subnet.id}"
}

resource "openstack_compute_floatingip_v2" "fip" {
  count = "2"
  pool = "ext-net-01"
}

### [Rancher server instances] ###

resource "openstack_compute_servergroup_v2" "rserver_srvgrp" {
  name = "rserver-srvgrp"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "rserver_cluster" {
  name = "rserver-${count.index+1}"
  count = "1"
  image_name = "${var.ops_image}"
  flavor_name = "${var.ops_flavor}"
  config_drive = "true"
  network = { 
    uuid = "${openstack_networking_network_v2.rancher_net.id}"
  }
  floating_ip = "${element(openstack_compute_floatingip_v2.fip.*.address, count.index)}"
  key_pair = "${openstack_compute_keypair_v2.demo_keypair.name}"
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.rserver_srvgrp.id}"
  }
  security_groups = ["${openstack_compute_secgroup_v2.rserver_sg.name}","${openstack_compute_secgroup_v2.rall_sg.name}"]
  user_data = "${var.cloudconfig_server}"
}

output "rserver-instances" {
  value = "${join( "," , openstack_compute_instance_v2.rserver_cluster.*.floating_ip ) }"
}

### [Rancher agent instances] ###

resource "openstack_compute_servergroup_v2" "ragent_srvgrp" {
  name = "ragent-srvgrp"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "ragent_cluster" {
  name = "ragent-${count.index+1}"
  count = "1"
  image_name = "${var.ops_image}"
  flavor_name = "${var.ops_flavor}"
  config_drive = "true"
  network = { 
    uuid = "${openstack_networking_network_v2.rancher_net.id}"
  }
  key_pair = "${openstack_compute_keypair_v2.demo_keypair.name}"
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.ragent_srvgrp.id}"
  }
  security_groups = ["${openstack_compute_secgroup_v2.ragent_sg.name}","${openstack_compute_secgroup_v2.rall_sg.name}"]
  user_data = "${var.cloudconfig_agent}"
}

output "ragent-instances" {
  value = "${join( "," , openstack_compute_instance_v2.ragent_cluster.*.access_ip_v4) }"
}
