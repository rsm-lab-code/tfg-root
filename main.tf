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
  
  spoke_vpc_cidrs = {
    for k, v in module.spoke_vpcs : k => v.vpc_cidr
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
    for k, v in module.spoke_vpcs : k => {
      cidr_block    = v.vpc_cidr
      attachment_id = v.tgw_attachment_id
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
module "spoke_vpcs" {
  for_each = var.spoke_vpc_configs
  source   = "github.com/rsm-lab-code/spoke//vpc?ref=main"
  
  vpc_config = each.value
  aws_regions = var.aws_regions
  delegated_account_id = var.delegated_account_id
  ipam_pool_ids = module.ipam.subnet_pool_ids
  transit_gateway_id = module.tgw.tgw_id
  
  # Route table assignment based on environment
  transit_gateway_route_table_id = each.value.environment == "production" ? 
    module.tgw.main_rt_id : module.tgw.nonprod_tgw_rt_id
  
  # Dynamic spoke VPC routes (excludes self)
  spoke_vpc_routes = {
    for k, v in module.spoke_vpcs : k => v.vpc_cidr
    if k != each.key
  }
  
  providers = {
    aws.delegated_account_us-west-2 = aws.delegated_account_us-west-2
  }
  
  depends_on = [module.ipam, module.tgw]
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
