#terraform {
  #backend "remote" {
  # organization = "rsm-lab-code"
  # workspaces {
  #   name = "tfg-multi-repo"
  # }
  #}
  #required_providers {
  # aws = {
  #   source  = "hashicorp/aws"
  #   version = "~> 5.49.0"
  # }
  # time = {
  #   source  = "hashicorp/time"
  #   version = "~> 0.9.0"
  # }
  # null = {
  #   source  = "hashicorp/null"
  #   version = "~> 3.0"
  # }
  #}
  #}

# VPC Configuration - Dynamic generation based on vpc_counts
locals {
  # Define how many VPCs you want per environment
  vpc_counts = {
   # dev     = 2  
    nonprod = 2  
    prod    = 2
  }
  
  # Map logical environments to IPAM environments
  env_to_ipam_mapping = {
    #dev     = "nonprod"  # dev uses nonprod IPAM pools
    nonprod = "nonprod" 
    prod    = "prod"
  }
  
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
  
  # Track pool usage per IPAM environment
  pool_usage = {
    for ipam_env in keys(local.pools_per_env) : ipam_env => [
      for idx, vpc in local.vpc_creation_order : vpc
      if vpc.ipam_env == ipam_env
    ]
  }
  
  # Generate VPC configurations with automatic pool assignment
  vpc_configurations = {
    for vpc in local.vpc_creation_order : vpc.vpc_name => {
      environment = vpc.environment
      ipam_pool_key = vpc.ipam_env == "prod" ? "us-west-2-prod-subnet${index(local.pool_usage[vpc.ipam_env], vpc) + 2}" : "us-west-2-${vpc.ipam_env}-subnet${index(local.pool_usage[vpc.ipam_env], vpc) + 1}"
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
  subnet_pool_id = module.ipam.subnet_pool_ids["us-west-2-prod-subnet1"]
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
  #source = "../hub/tgw"
  source = "github.com/rsm-lab-code/tfg-hub//tgw?ref=main"
  aws_regions = var.aws_regions
  amazon_side_asn = 64512
   
  #account_id
  delegated_account_id = var.delegated_account_id
 
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

  # Required parameters
  vpc_name             = each.key
  environment          = each.value.environment
  delegated_account_id = var.delegated_account_id
  ipam_pool_id         = module.ipam.subnet_pool_ids[each.value.ipam_pool_key]
   
  #defaul Availability zones
  availability_zones   = ["us-west-2a", "us-west-2b"]
  # Transit Gateway configuration
  transit_gateway_id             = module.tgw.tgw_id
  transit_gateway_route_table_id = module.tgw.route_table_ids[each.value.environment]

  # Optional overrides (spoke module provides defaults)
  vpc_cidr_netmask = try(each.value.vpc_cidr_netmask, null)  # Keep /21 as default
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

#AWS Config 
module "governance" {
source = "github.com/rsm-lab-code/governance?ref=main"

 delegated_account_id = var.delegated_account_id
 management_account_id = var.management_account_id
 organization_id = var.organization_id
 aws_regions          = var.aws_regions

 transit_gateway_arn = module.tgw.tgw_arn

 providers = {
   aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
   aws.management_account_us-west-2 = aws.management_account_us-west-2
 }
 depends_on = [module.tgw, module.spoke_vpcs]
} 

module "spoke_route_manager" {
  # source = "./modules/spoke_route_manager"  
  source = "github.com/rsm-lab-code/tfg-spoke//route_manager?ref=main"  

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
  #source = "github.com/rsm-lab-code/tfg-scps?ref=main"
  source = "./scp"
  #  for_each  = fileset(path.root, "policies/scp_target_ou/*.json")
   #  json_file = each.value
   #ou_id   = [var.scp_target_ou_id]
    ou_configurations = {
     target_ou = {
    ou_id           = var.scp_target_ou_id
    policy_directory = "policies/scp_target_ou"
    enabled         = var.attach_scp_policies
    }
    # Future OUs can be added here:
    # prod_ou = {
    #   ou_id           = var.prod_ou_id
    #   policy_directory = "policies/scp_prod_ou"
    #   enabled         = var.attach_prod_scp_policies
    # }
     }
     providers = {

     aws.management_account = aws.management_account_us-west-2
      }
}
