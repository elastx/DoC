variable "rserver_count" {
  type = "string"
  default = "1"
}

variable "ragent_count" {
  type = "string"
  default = "1"
}

variable "registrationtoken" {
  type = "string"
  default = "2ADE1DE9B955FC8E1595:1471532400000:YDPdQ6BYLoBnfejy93ytkWss"
}

variable "ops_image" {
  type = "string"
  default = "rancheros-0.5.0"
}

variable "ops_flavor" {
  type = "string"
  default = "m1.small"
}

