variable "aws_regions" {
  type    = list(string)
  default = ["us-west-2", "us-east-1"]
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
}

variable "root_ou_id" {
  description = "Root Organizational Unit ID"
  type        = string
}

variable "organization_id" {
  description = "AWS Organization ID for Config organization setup"
  type        = string
}

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


# SCP Configuration Variables
variable "scp_target_ou_id" {
  description = "OU ID to attach SCP policies to (empty = organization root)"
  type        = string
  default     = ""
}

variable "attach_scp_policies" {
  description = "Whether to attach SCP policies to the target OU"
  type        = bool
  default     = false
}

#Account factory variables
variable "departments" {
  description = "Set of department names to create OUs for"
  type        = set(string)
  default     = ["IT", "Finance", "HR", "Marketing", "Engineering"]
}

variable "account_requests" {
  description = "Map of new accounts to create"
  type = map(object({
    name        = string
    email       = string
    department  = string
    environment = string
    purpose     = string
    owner       = string
  }))
  default = {}
}
