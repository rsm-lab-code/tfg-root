variable "aws_regions" {
  type    = list(string)
  default = ["us-west-2", "us-east-1"]
}

# set in tfvars
variable "aws_region" {}

# set in tfvars
variable "root_ou_id" {}



variable "tfg_test_account1_id" {
 description = "AWS Account ID for tfg-test-account1"
 type        = string
}

variable "delegated_account_id" {
  description = "AWS Account ID for delegated account where IPAM is created"
  type        = string
}

variable "management_account_id" {
  description = "AWS Account ID for management account where Config will be created"
  type        = string
}

variable "rsm_vpn" {
  description = "IP address allowed for SSH access (CIDR notation)"
  type        = string
  default     = "66.98.96.0/20"   
}

