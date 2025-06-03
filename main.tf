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

# VPC Configuration - Define all  VPCs in one place
locals {
  vpc_configurations = {
    /* 
    dev_vpc1 = {
      environment             = "dev"
      vpc_cidr_netmask       = 21
      subnet_prefix          = 3
      availability_zones     = ["us-west-2a", "us-west-2b"]
      ipam_pool_key         = "us-west-2-nonprod-subnet1"
      tgw_route_table_type  = "dev"
      create_igw            = true
    }
    */
    dev_vpc2 = {
      environment             = "dev"
      vpc_cidr_netmask       = 21
      subnet_prefix          = 3
      availability_zones     = ["us-west-2a", "us-west-2b"]
      ipam_pool_key         = "us-west-2-nonprod-subnet2"
      tgw_route_table_type  = "dev"
      create_igw            = true
    }
    
    nonprod_vpc1 = {
      environment             = "nonprod"
      vpc_cidr_netmask       = 21
      subnet_prefix          = 3
      availability_zones     = ["us-west-2a", "us-west-2b"]
      ipam_pool_key         = "us-west-2-nonprod-subnet3"
      tgw_route_table_type  = "nonprod"
      create_igw            = true
    }
    
    nonprod_vpc2 = {
      environment             = "nonprod"
      vpc_cidr_netmask       = 21
      subnet_prefix          = 3
      availability_zones     = ["us-west-2a", "us-west-2b"]
      ipam_pool_key         = "us-west-2-nonprod-subnet4"
      tgw_route_table_type  = "nonprod"
      create_igw            = true
    }

    prod_vpc1 = {
      environment             = "prod"
      vpc_cidr_netmask       = 21
      subnet_prefix          = 3
      availability_zones     = ["us-west-2a", "us-west-2b"]
      ipam_pool_key         = "us-west-2-prod-subnet2"
      tgw_route_table_type  = "prod"
      create_igw            = true
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
  
  #spoke_vpc_cidrs = local.all_vpc_cidrs
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
   
  #Pass Spoke VPC attachement info
  #spoke_vpc_attachments = {
  #for name, vpc in module.spoke_vpcs : name => {
  #  cidr_block    = vpc.vpc_cidr
  #  attachment_id = vpc.tgw_attachment_id
  # }
  #}

  # spoke_vpc_attachments = {}

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


# Create all VPCs dynamically using for_each
module "spoke_vpcs" {
  source = "github.com/rsm-lab-code/tfg-spoke//generic_vpc?ref=main"
  for_each = local.vpc_configurations

  # Basic configuration
  vpc_name               = each.key
  environment           = each.value.environment
  delegated_account_id  = var.delegated_account_id

  # IPAM configuration
  ipam_pool_id          = module.ipam.subnet_pool_ids[each.value.ipam_pool_key]
  vpc_cidr_netmask      = each.value.vpc_cidr_netmask
  subnet_prefix         = each.value.subnet_prefix

  # Network configuration
  availability_zones    = each.value.availability_zones
  create_igw           = each.value.create_igw

  # Transit Gateway configuration
  transit_gateway_id               = module.tgw.tgw_id
  transit_gateway_route_table_id   = module.tgw.route_table_ids[each.value.tgw_route_table_type]

  # Routes to other VPCs (excluding self)
  # spoke_vpc_routes = {
  #for name, cidr in local.all_vpc_cidrs : name => cidr
  #if name != each.key
  #}

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

#AWS Config test module
module "aws_config_test" {
 source = "github.com/rsm-lab-code/config?ref=main"
 delegated_account_id = var.delegated_account_id
 management_account_id = var.management_account_id
 organization_id = var.organization_id


 providers = {
   aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
   aws.management_account_us-west-2 = aws.management_account_us-west-2
 }
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
  dev_rt_id        = module.tgw.dev_tgw_rt_id
  nonprod_rt_id    = module.tgw.nonprod_tgw_rt_id

  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }

  depends_on = [module.spoke_vpcs, module.tgw]
}
