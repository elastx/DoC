variable "rserver_count" {
  type = "string"
  default = "1"
}

variable "ragent_count" {
  type = "string"
  default = "0"
}

variable "registrationtoken" {
  type = "string"
  default = "REGISTRATIONTOKEN"
}

variable "ops_image" {
  type = "string"
  default = "rancheros-0.5.0"
}

variable "ops_flavor" {
  type = "string"
  default = "m1.small.doc"
}

