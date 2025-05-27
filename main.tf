terraform {
  #backend "remote" {
  # organization = "rsm-lab-code"
  # workspaces {
  #   name = "tfg-multi-repo"
  # }
  #}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
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
#locals block to manage all spoke VPC CIDRs:
locals {
  all_vpc_cidrs = {
    dev_vpc1     = module.vpc.vpc_cidr
    dev_vpc2     = module.dev_vpc2.vpc_cidr
    nonprod_vpc1 = module.nonprod_vpc1.vpc_cidr
    nonprod_vpc2 = module.nonprod_vpc2.vpc_cidr
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
  
  spoke_vpc_cidrs = {
    dev_vpc1     = module.vpc.vpc_cidr
    dev_vpc2     = module.dev_vpc2.vpc_cidr
    nonprod_vpc1 = module.nonprod_vpc1.vpc_cidr
    nonprod_vpc2 = module.nonprod_vpc2.vpc_cidr
    # Add any future VPCs here
  }

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
    spoke_vpc_attachments = {
    dev_vpc1 = {
      cidr_block    = module.vpc.vpc_cidr
      attachment_id = module.vpc.tgw_attachment_id
    }
    dev_vpc2 = {
      cidr_block    = module.dev_vpc2.vpc_cidr
      attachment_id = module.dev_vpc2.tgw_attachment_id
    }
    nonprod_vpc1 = {
      cidr_block    = module.nonprod_vpc1.vpc_cidr
      attachment_id = module.nonprod_vpc1.tgw_attachment_id
    }
    nonprod_vpc2 = {
      cidr_block    = module.nonprod_vpc2.vpc_cidr
      attachment_id = module.nonprod_vpc2.tgw_attachment_id
    }
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


# Add Spoke VPC module
module "vpc" {
  #source = "../spoke/vpc"
  source = "github.com/rsm-lab-code/tfg-spoke//dev_vpc1?ref=main"

  #VPC name
  vpc_name = "dev_vpc1"

  # Account IDs
  delegated_account_id = var.delegated_account_id

  # IPAM pool IDs
  ipam_pool_ids = module.ipam.subnet_pool_ids

   # CIDR allocation settings
  vpc_cidr_netmask = 21
  subnet_prefix = 3
  
  # Transit Gateway ID and route table
  transit_gateway_id = module.tgw.tgw_id
  transit_gateway_route_table_id = module.tgw.dev_tgw_rt_id
  
  #other spoke vpc routes
    spoke_vpc_routes = {
    dev_vpc2     = module.dev_vpc2.vpc_cidr
    nonprod_vpc1 = module.nonprod_vpc1.vpc_cidr
    nonprod_vpc2 = module.nonprod_vpc2.vpc_cidr
  }

  providers = {
  aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
   
  }
}


module "dev_vpc2" {
  source = "github.com/rsm-lab-code/tfg-spoke//dev_vpc2?ref=main"
  #source = "./spoke/dev_vpc2"

  # Account IDs
  delegated_account_id = var.delegated_account_id

  # IPAM pool IDs
  ipam_pool_ids = module.ipam.subnet_pool_ids

  # CIDR allocation settings
  vpc_cidr_netmask = 21
  subnet_prefix = 3

  # Transit Gateway ID and route table
  transit_gateway_id = module.tgw.tgw_id
  transit_gateway_route_table_id = module.tgw.dev_tgw_rt_id
  
  #Other spoke vpc routes
    spoke_vpc_routes = {
    dev_vpc1     = module.vpc.vpc_cidr
    nonprod_vpc1 = module.nonprod_vpc1.vpc_cidr
    nonprod_vpc2 = module.nonprod_vpc2.vpc_cidr
  }


  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }
}

module "nonprod_vpc1" {
  source = "github.com/rsm-lab-code/tfg-spoke//nonprod_vpc1?ref=main"
  #source = "./spoke/nonprod_vpc1"

  # Account IDs
  delegated_account_id = var.delegated_account_id

  # IPAM pool IDs
  ipam_pool_ids = module.ipam.subnet_pool_ids

  # CIDR allocation settings
  vpc_cidr_netmask = 21
  subnet_prefix = 3

  # Transit Gateway ID and route table
  transit_gateway_id = module.tgw.tgw_id
  transit_gateway_route_table_id = module.tgw.nonprod_tgw_rt_id
   
  #Other Spoke VPC routes

    spoke_vpc_routes = {
    dev_vpc1     = module.vpc.vpc_cidr
    dev_vpc2     = module.dev_vpc2.vpc_cidr
    nonprod_vpc2 = module.nonprod_vpc2.vpc_cidr
  }

  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }
}


module "nonprod_vpc2" {
  source = "github.com/rsm-lab-code/tfg-spoke//nonprod_vpc2?ref=main"
  #source = "./spoke/nonprod_vpc2"

  # Account IDs
  delegated_account_id = var.delegated_account_id

  # IPAM pool IDs
  ipam_pool_ids = module.ipam.subnet_pool_ids

  # CIDR allocation settings
  vpc_cidr_netmask = 21
  subnet_prefix = 3

  # Transit Gateway ID and route table
  transit_gateway_id = module.tgw.tgw_id
  transit_gateway_route_table_id = module.tgw.nonprod_tgw_rt_id

  #Other Spoke VPC routes
    spoke_vpc_routes = {
    dev_vpc1     = module.vpc.vpc_cidr
    dev_vpc2     = module.dev_vpc2.vpc_cidr
    nonprod_vpc1 = module.nonprod_vpc1.vpc_cidr
  }
  
  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }
}

