
variable "env" {
  description = " Deployment Environment"
  type        = string
  default     = "dev-rosa"
}

data "local_file" "ssh_key_pub" {
  filename = pathexpand("~/.ssh/id_rsa.pub")
}

data "local_file" "ssh_key_priv" {
  filename = pathexpand("~/.ssh/id_rsa")
}

variable "created_by" {
  description = "Creator"
  type        = string
  default     = "developer"
}

locals {
  vpc_cidr_block = "${var.subnet_block_prefix}0/${var.vpc_cidr_mask}"
  vpc_name       = "${var.env}-vpc"
  subnet_count   = length(var.priv_subnet_azs)
  newbits        = format(var.subnet_blocks - var.vpc_cidr_mask)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "subnet_block_prefix" {
  description = "AWS VPC CIDR block Prefix"
  default     = "192.168.0."
}

variable "subnet_blocks" {
  description = "Subnet mask for subnets created from VPC CIDR block"
  default     = "20"
}

variable "vpc_cidr_mask" {
  description = "VPC CIDR block subnet mask"
  default     = "16"
}

variable "priv_subnet_azs" {
  description = "Availability zones withing the region"
  type        = list(string)
  default = [
    "us-east-1a"
    , "us-east-1b"
    , "us-east-1c"
    , "us-east-1d"
    , "us-east-1f"
  ]
}

variable "rt_name" {
  description = "Name for the route table of the webserver vpc"
  type        = string
  default     = "web_server"
}

variable "ec2_ami" {
  description = "AMI of EC2 Instance"
  type        = string
  default     = "ami-02396cdd13e9a1257"
}

variable "ec2_instance_type" {
  description = "Type of EC2 Instance"
  type        = string
  default     = "t2.micro"
}

variable "ec2_instance_name" {
  description = "Name of EC2 Instance"
  type        = string
  default     = "deployment_jump_svr"
}

variable "ec2_inbound_network" {
  description = "Source network for connection to EC2 Instance"
  default = [
    "142.161.182.102/32"
  ]
}