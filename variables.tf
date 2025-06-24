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

variable "create_root_baseline_policy" {
  description = "Create baseline security policy for organization root"
  type        = bool
  default     = true
}

variable "create_prod_controls_policy" {
  description = "Create strict controls for production OU"
  type        = bool
  default     = true
}

variable "create_nonprod_controls_policy" {
  description = "Create development controls for non-production OU"
  type        = bool
  default     = true
}

#Account factory variables

variable "account_requests" {
  description = "Map of new accounts to create"
  type = map(object({
    name        = string
    email       = string
    department  = string
    environment = string
    description     = string
  }))
  default = {}
}


variable "additional_spoke_accounts" {
  description = "Additional spoke account IDs not created by Account Factory"
  type        = list(string)
  default     = []
}
