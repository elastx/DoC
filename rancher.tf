# These variables are received through ENV-variables created 
# by terraform-openrc.sh, hence, run that first

variable "password" {}
variable "user_name" {}
variable "tenant_name" {}

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
    from_port = 80
    to_port = 89
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
    from_port = 2376
    to_port = 2376
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 500
    to_port = 500
    ip_protocol = "udp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 4500
    to_port = 4500
    ip_protocol = "udp"
    cidr = "0.0.0.0/0"
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

resource "openstack_compute_floatingip_v2" "fip_s" {
  count = "${var.rserver_count}"
  pool = "ext-net-01"
}

resource "openstack_compute_floatingip_v2" "fip_a" {
  count = "${var.ragent_count}"
  pool = "ext-net-01"
}

### [Rancher server instances] ###

resource "openstack_compute_servergroup_v2" "rserver_srvgrp" {
  name = "rserver-srvgrp"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "rserver_cluster" {
  name = "rserver-${count.index+1}"
  count = "${var.rserver_count}"
  image_name = "${var.ops_image}"
  flavor_name = "${var.ops_flavor}"
  config_drive = "true"
  network = { 
    uuid = "${openstack_networking_network_v2.rancher_net.id}"
  }
  floating_ip = "${element(openstack_compute_floatingip_v2.fip_s.*.address, count.index)}"
  key_pair = "${openstack_compute_keypair_v2.demo_keypair.name}"
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.rserver_srvgrp.id}"
  }
  security_groups = ["${openstack_compute_secgroup_v2.rserver_sg.name}","${openstack_compute_secgroup_v2.rall_sg.name}"]
  user_data = <<EOF
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
        - /.ssh:/.ssh
write_files:
  - path: /.ssh/demo_rsa
    permissions: "0600"
    owner: root
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEA2Cdz6Yj7uJaR49mzEjZuNwgipcTqdp5086fVgbRjxx8kxWYL
      LaIBQgHh16PnB6vFSpltvtEqlpqqcJrVdO5qwbq+auI4MiBgD/gfO/LlRTUwNk6X
      AdxDjxUfh1Y79+0tG0RZZTCBg1MkAn2SWW3+DXXZCks3z0u8YVxgB4IA31qpUtVD
      PnOSjVKooEyjav+NVau4bpPfrPcfTGCb5vvXGd4JfUMQeEe24wkbCIgodLhsJVSy
      f8dZTV1dGt4vzt3uxmTulLMifFdXsPzpJwG7YArubQvNjaouO9z8wemac3C3u4jc
      p37FTy6dAa3zuNVtPJAzMyc96lFUs23pBdjQPwIDAQABAoIBAQCjLa2IuNvnLuw2
      CYvxDNxJeT/GyxCBuf/qTWKWR1sn4G//AZkguvOeJBOdmmN33AnV1lwOOJOhHGPd
      HFZWrwIy/EpyIBNybBR5GcRimmzQwWWDKfM/+UubQcQKhGRDN27c7c1a4bJ0NJiz
      tJ5+GtY2zSeraLtaJ/+vtG/eWxtTgRdEEnElOPgBWxvee4sjFTMPOQ6msjK9GtuA
      C9vdCIDdPXbdXwJrlME3MHrCbqhD6LXBj8a8CRKEMLX+IX2d0CXsGea89+XVr0Vx
      RYTzHavslQJ+svp9GRnpNh6p8Nl9xEJSCOY4asE2v3ZgYjmH8vkCs9pGqtgJq03e
      m26B3aWxAoGBAPc/eT1GruW5vZPLpAMfuuV2+yrAs21SmcEBiJlc0Y7p5v/gsMAs
      lDx34dNNTb9ZliV/y1aE6BL5CCkHj3WE4sp4FfkCqWungkR87EpgxUsfIFfgHSv3
      F3ZvTMyh+vj8izloYFtoAAQ6JCqKUkKlFeNNPpf2XAjellioEtdcldrZAoGBAN/O
      NhLaibJobTJLopb0zv2ghk+UAtPvIkza+RBjA6f4gTunRc/wLopUddzvAr3T2jmj
      D3tJH+OPeWhCZYhDEb/1dKutMIXOh4l5tNjeUxYZk4Y/ab46SoKYUV9MfabzgtrQ
      gVd1YCURf4Ff0Sjol3gQe1USJCKA6BIk9kHFQ6TXAoGBAMM4KOBLCRl1+MvThKK6
      0PURZuuwz3tINwJ/1X1SHlx7Lttma+iwyjKcbYBLj1HAyJ6/MqwTsLIaU2kiARHH
      ZNJ80syUX3UTA/ZTtLZdhin0X7NCz4XBSZNH+hmw49rofH1NfpdtnGW6CohUQvNA
      KfIZMY0HBlAyf/9sZcQJ5ICxAoGAblEG9mQiW3591LzTd/VT0lC945vhiPXmwltt
      SVaFBtbHXNAm6UhKqITZU/28LDWw65gkmXCB93lRLsMLqQ7mQOiMidLkiBA1Xt5O
      9lcgPVR+Ez5OsSWqdJUAByl9Bj4h0hnUp3eD3MGzR+IjBzce8l+ta1F13kwMGGV/
      vQuvPCECgYAuUVtfOBwrBjWr47/D8tYVjUVQ4CihINd4ljqVU9zhXJpnnegFB4kA
      CNlNsVPcYZcItNuVGnK6oC1FngEogKr3BgTUxMz9wnytJPvKGnIHSRW5boV0WP1Y
      3fbluVeCtGCQWJ/uG4ypyvRe11V/MzCjDx9gk7tEXEXjGUkW4modsQ==
      -----END RSA PRIVATE KEY-----
EOF
}

output "rserver-instances" {
  value = "${join( "," , openstack_compute_instance_v2.rserver_cluster.*.floating_ip ) }"
}

output "rserver-url" {
  value = "http://${openstack_compute_instance_v2.rserver_cluster.0.floating_ip}:8080"
}

### [Rancher agent instances] ###

resource "openstack_compute_servergroup_v2" "ragent_srvgrp" {
  name = "ragent-srvgrp"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "ragent_cluster" {
  name = "ragent-${count.index+1}"
  count = "${var.ragent_count}"
  image_name = "${var.ops_image}"
  flavor_name = "${var.ops_flavor}"
  config_drive = "true"
  network = { 
    uuid = "${openstack_networking_network_v2.rancher_net.id}"
  }
  floating_ip = "${element(openstack_compute_floatingip_v2.fip_a.*.address, count.index)}"
  key_pair = "${openstack_compute_keypair_v2.demo_keypair.name}"
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.ragent_srvgrp.id}"
  }
  security_groups = ["${openstack_compute_secgroup_v2.ragent_sg.name}","${openstack_compute_secgroup_v2.rall_sg.name}"]
  user_data = <<EOF
#cloud-config
rancher:
  services:
    rancher-agent1:
      image: rancher/agent
      privileged: true
      command: http://${openstack_compute_instance_v2.rserver_cluster.0.floating_ip}:8080/v1/scripts/${var.registrationtoken}
      restart: always
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
EOF
}

output "ragent-instances" {
  value = "${join( "," , openstack_compute_instance_v2.ragent_cluster.*.floating_ip ) }"
}
