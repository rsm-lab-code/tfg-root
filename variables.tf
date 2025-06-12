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


#SCP variable for multi OU
variable "ou_scp_configurations" {
  description = "SCP configurations for different OUs"
  type = map(object({
    ou_id                      = string
    create_iam_controls_policy = bool
    create_data_storage_policy = bool
    create_logging_policy      = bool
    create_monitoring_policy   = bool
    create_networking_policy   = bool
    attach_policies           = bool
  }))
  default = {}
}
