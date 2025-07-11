# VPC Configuration - Dynamic generation based on vpc_counts
locals {
  # Define how many VPCs you want per environment
  vpc_counts = { 
    nonprod = 2  
    prod    = 2
  }
  
  # Map logical environments to IPAM environments
  env_to_ipam_mapping = {
    nonprod = "nonprod" 
    prod    = "prod"
  }
  /*
  # Available pools per IPAM environment 
  pools_per_env = {
    nonprod = 4  # nonprod has Vpc1 through vpc4
    prod    = 4  # prod has vpc1 through vpc4
  }
  
  # Reserved pools (inspection VPC uses prod-vpc1)
  reserved_pools = {
    nonprod = []  # no reserved pools for nonprod
    prod    = [1]  # prod-vpc1 is reserved for inspection VPC
  }
  */
  # Create ordered list of all VPCs we want to create
  vpc_creation_order = flatten([
    for env, count in local.vpc_counts : [
      for i in range(1, count + 1) : {
        vpc_name = "${env}_vpc${i}"
        environment = env
        ipam_env = local.env_to_ipam_mapping[env]
      }
    ]
  ])
  /*
  # Track pool usage per IPAM environment
  pool_usage = {
    for ipam_env in keys(local.pools_per_env) : ipam_env => [
      for idx, vpc in local.vpc_creation_order : vpc
      if vpc.ipam_env == ipam_env
    ]
  }
  */
  # Generate VPC configurations with automatic pool assignment
  vpc_configurations = {
    for vpc in local.vpc_creation_order : vpc.vpc_name => {
      environment = vpc.environment
     # ipam_pool_key = vpc.ipam_env == "prod" ? "us-west-2-prod-subnet${index(local.pool_usage[vpc.ipam_env], vpc) + 2}" : "us-west-2-${vpc.ipam_env}-subnet${index(local.pool_usage[vpc.ipam_env], vpc) + 1}"
     #Direct assignment to environment pool instead of subnet pools 
     ipam_pool_key = "${var.aws_regions[0]}-${vpc.ipam_env}"

    }
  }

  # Helper to get all VPC CIDRs for routing (will be populated after VPCs are created)
  all_vpc_cidrs = {
    for name, vpc in module.spoke_vpcs : name => vpc.vpc_cidr
  }
}

# Add the IPAM module
module "ipam" {
  #source = "../ipam"
  source = "github.com/rsm-lab-code/tfg-ipam?ref=main"
  aws_regions = var.aws_regions
  delegated_account_id = var.delegated_account_id
  share_with_account_id = var.tfg_test_account1_id
  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
    aws.delegated_account_us-east-1 = aws.delegated_account_us-east-1
  }
}

# Add Inspection VPC module
module "inspection_vpc" {
  #source = "../hub/inspection_vpc"
  source = "github.com/rsm-lab-code/tfg-hub//inspection_vpc?ref=main"
  # IPAM configuration
  #subnet_pool_id = module.ipam.subnet_pool_ids["us-west-2-prod-subnet1"]
  #Use environment pool instead of subnet pool
  subnet_pool_id = module.ipam.environment_pool_ids["${var.aws_regions[0]}-prod"]
  vpc_cidr_netmask = 24
  subnet_prefix = 3
  
  #spoke vpc cidrs 
  spoke_vpc_cidrs = local.all_vpc_cidrs 

  # AWS region
  aws_regions = var.aws_regions
  #Transit gateway id
  transit_gateway_id = module.tgw.tgw_id
   
  # Account ID
  tfg_test_account1_id = var.tfg_test_account1_id
  delegated_account_id = var.delegated_account_id
  
  # Firewall endpoint IDs
  firewall_endpoint_ids = module.network_firewall.firewall_endpoint_ids

    
  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }
}

# Add Transit Gateway module
module "tgw" {
  source = "github.com/rsm-lab-code/tfg-hub//tgw?ref=main"
  aws_regions = var.aws_regions
  amazon_side_asn = 64512
   
  #account_id
  delegated_account_id = var.delegated_account_id
  management_account_id = var.management_account_id
  tfg_test_account1_id  = var.tfg_test_account1_id
  
  #Dynamic: share tgw with accounts created by account factory

  spoke_account_ids = concat(
    var.additional_spoke_accounts,  # Any manually specified accounts
    [for account in module.account_factory.created_accounts : account.id]  
  )

  organization_id      = var.organization_id 
 
  inspection_vpc_id = module.inspection_vpc.vpc_id
  inspection_subnet_ids = module.inspection_vpc.tgw_subnet_ids
  inspection_vpc_cidr = module.inspection_vpc.vpc_cidr

  tgw_route_table_ids = {
  a = module.inspection_vpc.tgw_route_tables.a
  b = module.inspection_vpc.tgw_route_tables.b
}
   
  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }

   depends_on = [module.account_factory]
}

# Add Network Firewall module
module "network_firewall" {
  #source = "../hub/network_firewall"
  source = "github.com/rsm-lab-code/tfg-hub//network_firewall?ref=main"
  # VPC and subnet configuration
  inspection_vpc_id = module.inspection_vpc.vpc_id
  firewall_subnet_ids = module.inspection_vpc.firewall_subnet_ids
  
  # account_id
  delegated_account_id = var.delegated_account_id
  
  # Firewall name
  firewall_name = "central-network-firewall"
  
  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }
}

# Create all VPCs dynamically - spoke module handles defaults
module "spoke_vpcs" {
  source = "github.com/rsm-lab-code/tfg-spoke//generic_vpc?ref=main"
  for_each = local.vpc_configurations

   #S3 bucket ARN for VPC flow logs
  enable_flow_logs       = true
  flow_logs_s3_bucket_arn = module.inspection_vpc.flow_logs_s3_bucket_arn

  # Required parameters
  vpc_name             = each.key
  environment          = each.value.environment
  delegated_account_id = var.delegated_account_id
  #ipam_pool_id         = module.ipam.subnet_pool_ids[each.value.ipam_pool_key]
  #Now points to environment pool instead of subnet pool
   ipam_pool_id         = module.ipam.environment_pool_ids[each.value.ipam_pool_key]
  #defaul Availability zones
  availability_zones   = ["us-west-2a", "us-west-2b"]
  # Transit Gateway configuration
  transit_gateway_id             = module.tgw.tgw_id
  transit_gateway_route_table_id = module.tgw.route_table_ids[each.value.environment]

  # Optional overrides (spoke module provides defaults)
  # vpc_cidr_netmask = try(each.value.vpc_cidr_netmask, null)  # Keep /21 as default
  subnet_prefix    = try(each.value.subnet_prefix, null)
  create_igw       = try(each.value.create_igw, null)

   
  # Common tags
  common_tags = {
    ManagedBy = "terraform"
  }

  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }

  depends_on = [module.ipam, module.tgw]
}

# Phase 2: CREATE INTER-VPC ROUTES SEPARATELY
resource "aws_route" "inter_vpc_routes" {
  for_each = {
    for pair in flatten([
      for vpc_name, vpc_config in local.vpc_configurations : [
        for other_vpc_name, other_vpc_config in local.vpc_configurations : {
          key                   = "${vpc_name}_to_${other_vpc_name}"
          source_vpc           = vpc_name
          destination_vpc      = other_vpc_name
          route_table_id       = module.spoke_vpcs[vpc_name].route_table_ids.public
          destination_cidr     = module.spoke_vpcs[other_vpc_name].vpc_cidr
        }
        if vpc_name != other_vpc_name  # Don't create routes to self
      ]
    ]) : pair.key => pair
  }

  provider                = aws.delegated_account_us-west-2
  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr
  transit_gateway_id     = module.tgw.tgw_id

  depends_on = [module.spoke_vpcs, module.tgw]
}


module "spoke_route_manager" {
  # source = "./modules/spoke_route_manager"  
  source = "github.com/rsm-lab-code/tfg-spoke//route_manager?ref=main"  
  
  #Disable specific vpc routes in prod and non prod tgw routes
  enable_environment_specific_routes = false
  
  spoke_vpc_attachments = {
    for name, vpc in module.spoke_vpcs : name => {
      cidr_block    = vpc.vpc_cidr
      attachment_id = vpc.tgw_attachment_id
    }
  }

  vpc_environments = {
    for name, config in local.vpc_configurations : name => config.environment
  }

  inspection_rt_id = module.tgw.inspection_rt_id
  main_rt_id       = module.tgw.main_rt_id
  nonprod_rt_id    = module.tgw.nonprod_tgw_rt_id
  prod_rt_id       = module.tgw.prod_tgw_rt_id

  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }

  depends_on = [module.spoke_vpcs, module.tgw]
}
module "scps" {
  source = "github.com/rsm-lab-code/tfg-scps?ref=main"

  # Tiered policy creation
  create_root_baseline_policy   = true
  create_prod_controls_policy   = true
  create_nonprod_controls_policy = true
  
  # Policy attachment 
  attach_root_policies    = false  
  attach_prod_policies    = true   
  attach_nonprod_policies = false    

  # OU targeting (gets OUs from account factory)
  prod_ou_id     = module.account_factory.prod_ou_id
  nonprod_ou_id  = module.account_factory.nonprod_ou_id

  providers = {
    aws.management_account = aws.management_account_us-west-2
  }
}
# Account Factory Module

module "account_factory" {
  source = "github.com/rsm-lab-code/tfg-account-factory?ref=main"

  account_requests = var.account_requests

  providers = {
    aws.management_account = aws.management_account_us-west-2
  }
}
