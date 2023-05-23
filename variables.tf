# Variables are declared here

variable "region" {
  default = "eu-west-1"
}

variable "availability-zones" {
  type = list(string)
}

variable "owner-name" {
  default = "Sven Erik Knop"
}

variable "owner-email" {
  default = "sven@confluent.io"
}

variable "dns-suffix" {
  default = "changeme"
  description = "Suffix for DNS entry in Route 53. No spaces!"
}

variable "purpose" {
  default = "Bootcamp"
}

variable "key-name" {
  default = "sven-bootcamp"
}

variable "zk-count" {
  type = number
}

variable "controller-count" {
  type = number
}

variable "broker-count" {
  type = number
}

variable "connect-count" {
  default = 0
}

variable "schema-count" {
  default = 0
}

variable "rest-count" {
  default = 0
}

variable "c3-count" {
  default = 0
}

variable "ksql-count" {
  default = 0
}

variable "create-monitoring-instances" {
  description = "If set, will create Prometheus and Grafana instances"
  type = bool
  default = false
}

variable "zk-instance-type" {
  default = "t3a.large"
}

variable "controller-instance-type" {
  default = "t3a.large"
}

variable "broker-instance-type" {
  default = "t3a.large"
}

variable "schema-instance-type" {
  default = "t3a.large"
}

variable "connect-instance-type" {
  default = "t3a.large"
}

variable "rest-instance-type" {
  default = "t3a.large"
}

variable "c3-instance-type" {
  default = "t3a.large"
}

variable "ksql-instance-type" {
  default = "t3a.large"
}

variable "client-instance-type" {
  default = "t3a.large"
}

variable "prometheus-instance-type" {
  default = "t3a.large"
}

variable "grafana-instance-type" {
  default = "t3a.large"
}

variable "hosted-zone-id" {
}

variable "aws-ami-id"  {
}

variable "linux-user" {
  default = "ubuntu" // ec2-user
}

variable "vpc-id" {
  type = string
}

variable "public-subnet-ids" {
  type = list(string)
}

variable "private-subnet-ids" {
  type = list(string)
}

variable "internal-vpc-security-group-id" {
  type = string
}

variable "external-vpc-security-group-id" {
  type = string
}

# ethaden

variable "public_ssh_key" {
  default = ""
  type = string
  description = "Your public SSH key. If not specified, trying to find one in HOME/.ssh"
}
variable "jumphost_instance_type" {
  default = "t2.micro"
}

variable "jumphost_disk_size_gb" {
  default = "20"
}

variable "username" {
  type = string
}
variable "instance_initial_apt_packages" {
  type = string
  default = ""
  description = "Space separated list of Ubuntu APT packages to install during initialization of the instance"
}

variable "instance_initial_snap_packages" {
  type = string
  default = ""
  description = "Space separated list of Ubuntu SNAP packages to install during initialization of the instance"
}


variable "instance_initial_classic_snap_packages" {
  type = string
  default = ""
  description = "Space separated list of Ubuntu classic SNAP packages to install during initialization of the instance (with snap install --classic)"
}

variable "zoneid_public_dns" {
    type = string
    default = "Z267DABJTL4JFI"
    description = "The ID of a public DNS zone hosted at AWS in the solution architect account"
}

variable "proxy_user" {
    type = string
    default = "admin"
    description = "The username for the http proxy"
}

variable "proxy_pass" {
    type = string
    description = "The password for the http proxy"
}
