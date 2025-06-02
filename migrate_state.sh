#!/bin/bash

echo "=========================================="
echo "Terraform State Migration Script"
echo "=========================================="
echo "This script will migrate your existing VPC resources to the new dynamic module structure"
echo "without destroying any existing infrastructure."
echo ""
echo "Current working directory: $(pwd)"
echo ""
echo "IMPORTANT: This script will:"
echo "1. Create a backup of your current state file"
echo "2. Move resources from old module paths to new module paths"
echo "3. Verify each step with terraform plan"
echo ""
echo "Press Enter to continue or Ctrl+C to abort"
read

# Check if terraform.tfstate exists
if [ ! -f "terraform.tfstate" ]; then
    echo "ERROR: terraform.tfstate not found in current directory"
    echo "Make sure you're running this script from the root/ directory where terraform.tfstate is located"
    exit 1
fi

# Create state backup
BACKUP_FILE="terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
echo "Creating state backup: $BACKUP_FILE"
cp terraform.tfstate "$BACKUP_FILE"
echo "Backup created successfully"
echo ""

# Function to check if state move was successful
check_move() {
    if [ $? -eq 0 ]; then
        echo "✅ Success: $1"
    else
        echo "❌ Failed: $1"
        echo "Restoring backup and exiting..."
        cp "$BACKUP_FILE" terraform.tfstate
        exit 1
    fi
}

# ===========================================
# Migrate dev_vpc1
# ===========================================
echo "=========================================="
echo "Migrating dev_vpc1 resources..."
echo "=========================================="

echo "Moving IPAM allocation..."
terraform state mv 'module.dev_vpc1.aws_vpc_ipam_pool_cidr_allocation.vpc_cidr' 'module.spoke_vpcs["dev_vpc1"].aws_vpc_ipam_pool_cidr_allocation.vpc_cidr'
check_move "dev_vpc1 IPAM allocation"

echo "Moving VPC..."
terraform state mv 'module.dev_vpc1.aws_vpc.vpc' 'module.spoke_vpcs["dev_vpc1"].aws_vpc.vpc'
check_move "dev_vpc1 VPC"

echo "Moving public subnets..."
terraform state mv 'module.dev_vpc1.aws_subnet.public_subnet_a' 'module.spoke_vpcs["dev_vpc1"].aws_subnet.public_subnet[0]'
check_move "dev_vpc1 public subnet a"

terraform state mv 'module.dev_vpc1.aws_subnet.public_subnet_b' 'module.spoke_vpcs["dev_vpc1"].aws_subnet.public_subnet[1]'
check_move "dev_vpc1 public subnet b"

echo "Moving private subnets..."
terraform state mv 'module.dev_vpc1.aws_subnet.private_subnet_a' 'module.spoke_vpcs["dev_vpc1"].aws_subnet.private_subnet[0]'
check_move "dev_vpc1 private subnet a"

terraform state mv 'module.dev_vpc1.aws_subnet.private_subnet_b' 'module.spoke_vpcs["dev_vpc1"].aws_subnet.private_subnet[1]'
check_move "dev_vpc1 private subnet b"

echo "Moving route tables..."
terraform state mv 'module.dev_vpc1.aws_route_table.public_rt' 'module.spoke_vpcs["dev_vpc1"].aws_route_table.public_rt'
check_move "dev_vpc1 public route table"

terraform state mv 'module.dev_vpc1.aws_route_table.private_rt' 'module.spoke_vpcs["dev_vpc1"].aws_route_table.private_rt'
check_move "dev_vpc1 private route table"

echo "Moving route table associations..."
terraform state mv 'module.dev_vpc1.aws_route_table_association.public_rta_a' 'module.spoke_vpcs["dev_vpc1"].aws_route_table_association.public_rta[0]'
check_move "dev_vpc1 public route table association a"

terraform state mv 'module.dev_vpc1.aws_route_table_association.public_rta_b' 'module.spoke_vpcs["dev_vpc1"].aws_route_table_association.public_rta[1]'
check_move "dev_vpc1 public route table association b"

terraform state mv 'module.dev_vpc1.aws_route_table_association.private_rta_a' 'module.spoke_vpcs["dev_vpc1"].aws_route_table_association.private_rta[0]'
check_move "dev_vpc1 private route table association a"

terraform state mv 'module.dev_vpc1.aws_route_table_association.private_rta_b' 'module.spoke_vpcs["dev_vpc1"].aws_route_table_association.private_rta[1]'
check_move "dev_vpc1 private route table association b"

echo "Moving internet gateway..."
terraform state mv 'module.dev_vpc1.aws_internet_gateway.igw' 'module.spoke_vpcs["dev_vpc1"].aws_internet_gateway.igw[0]'
check_move "dev_vpc1 internet gateway"

echo "Moving routes..."
terraform state mv 'module.dev_vpc1.aws_route.public_rt_default' 'module.spoke_vpcs["dev_vpc1"].aws_route.public_rt_default[0]'
check_move "dev_vpc1 public default route"

terraform state mv 'module.dev_vpc1.aws_route.private_rt_default' 'module.spoke_vpcs["dev_vpc1"].aws_route.private_rt_default'
check_move "dev_vpc1 private default route"

echo "Moving TGW attachment..."
terraform state mv 'module.dev_vpc1.aws_ec2_transit_gateway_vpc_attachment.tgw_attachment' 'module.spoke_vpcs["dev_vpc1"].aws_ec2_transit_gateway_vpc_attachment.tgw_attachment'
check_move "dev_vpc1 TGW attachment"

terraform state mv 'module.dev_vpc1.aws_ec2_transit_gateway_route_table_association.tgw_rt_association' 'module.spoke_vpcs["dev_vpc1"].aws_ec2_transit_gateway_route_table_association.tgw_rt_association'
check_move "dev_vpc1 TGW route table association"

echo "dev_vpc1 migration completed! ✅"
echo "Checking plan for dev_vpc1..."
terraform plan -target='module.spoke_vpcs["dev_vpc1"]' -no-color | head -20

echo ""
echo "Press Enter to continue with dev_vpc2 migration..."
read

# ===========================================
# Migrate dev_vpc2
# ===========================================
echo "=========================================="
echo "Migrating dev_vpc2 resources..."
echo "=========================================="

echo "Moving IPAM allocation..."
terraform state mv 'module.dev_vpc2.aws_vpc_ipam_pool_cidr_allocation.dev_vpc2_cidr' 'module.spoke_vpcs["dev_vpc2"].aws_vpc_ipam_pool_cidr_allocation.vpc_cidr'
check_move "dev_vpc2 IPAM allocation"

echo "Moving VPC..."
terraform state mv 'module.dev_vpc2.aws_vpc.dev_vpc2' 'module.spoke_vpcs["dev_vpc2"].aws_vpc.vpc'
check_move "dev_vpc2 VPC"

echo "Moving public subnets..."
terraform state mv 'module.dev_vpc2.aws_subnet.dev_vpc2_public_subnet_a' 'module.spoke_vpcs["dev_vpc2"].aws_subnet.public_subnet[0]'
check_move "dev_vpc2 public subnet a"

terraform state mv 'module.dev_vpc2.aws_subnet.dev_vpc2_public_subnet_b' 'module.spoke_vpcs["dev_vpc2"].aws_subnet.public_subnet[1]'
check_move "dev_vpc2 public subnet b"

echo "Moving private subnets..."
terraform state mv 'module.dev_vpc2.aws_subnet.dev_vpc2_private_subnet_a' 'module.spoke_vpcs["dev_vpc2"].aws_subnet.private_subnet[0]'
check_move "dev_vpc2 private subnet a"

terraform state mv 'module.dev_vpc2.aws_subnet.dev_vpc2_private_subnet_b' 'module.spoke_vpcs["dev_vpc2"].aws_subnet.private_subnet[1]'
check_move "dev_vpc2 private subnet b"

echo "Moving route tables..."
terraform state mv 'module.dev_vpc2.aws_route_table.dev_vpc2_public_rt' 'module.spoke_vpcs["dev_vpc2"].aws_route_table.public_rt'
check_move "dev_vpc2 public route table"

terraform state mv 'module.dev_vpc2.aws_route_table.dev_vpc2_private_rt' 'module.spoke_vpcs["dev_vpc2"].aws_route_table.private_rt'
check_move "dev_vpc2 private route table"

echo "Moving route table associations..."
terraform state mv 'module.dev_vpc2.aws_route_table_association.dev_vpc2_public_rta_a' 'module.spoke_vpcs["dev_vpc2"].aws_route_table_association.public_rta[0]'
check_move "dev_vpc2 public route table association a"

terraform state mv 'module.dev_vpc2.aws_route_table_association.dev_vpc2_public_rta_b' 'module.spoke_vpcs["dev_vpc2"].aws_route_table_association.public_rta[1]'
check_move "dev_vpc2 public route table association b"

terraform state mv 'module.dev_vpc2.aws_route_table_association.dev_vpc2_private_rta_a' 'module.spoke_vpcs["dev_vpc2"].aws_route_table_association.private_rta[0]'
check_move "dev_vpc2 private route table association a"

terraform state mv 'module.dev_vpc2.aws_route_table_association.dev_vpc2_private_rta_b' 'module.spoke_vpcs["dev_vpc2"].aws_route_table_association.private_rta[1]'
check_move "dev_vpc2 private route table association b"

echo "Moving internet gateway..."
terraform state mv 'module.dev_vpc2.aws_internet_gateway.dev_vpc2_igw' 'module.spoke_vpcs["dev_vpc2"].aws_internet_gateway.igw[0]'
check_move "dev_vpc2 internet gateway"

echo "Moving routes..."
terraform state mv 'module.dev_vpc2.aws_route.dev_vpc2_public_rt_default' 'module.spoke_vpcs["dev_vpc2"].aws_route.public_rt_default[0]'
check_move "dev_vpc2 public default route"

terraform state mv 'module.dev_vpc2.aws_route.dev_vpc2_private_rt_default' 'module.spoke_vpcs["dev_vpc2"].aws_route.private_rt_default'
check_move "dev_vpc2 private default route"

echo "Moving TGW attachment..."
terraform state mv 'module.dev_vpc2.aws_ec2_transit_gateway_vpc_attachment.dev_vpc2_tgw_attachment' 'module.spoke_vpcs["dev_vpc2"].aws_ec2_transit_gateway_vpc_attachment.tgw_attachment'
check_move "dev_vpc2 TGW attachment"

terraform state mv 'module.dev_vpc2.aws_ec2_transit_gateway_route_table_association.dev_vpc2_tgw_rt_association' 'module.spoke_vpcs["dev_vpc2"].aws_ec2_transit_gateway_route_table_association.tgw_rt_association'
check_move "dev_vpc2 TGW route table association"

echo "dev_vpc2 migration completed! ✅"
echo ""
echo "Press Enter to continue with nonprod_vpc1 migration..."
read

# ===========================================
# Migrate nonprod_vpc1
# ===========================================
echo "=========================================="
echo "Migrating nonprod_vpc1 resources..."
echo "=========================================="

echo "Moving IPAM allocation..."
terraform state mv 'module.nonprod_vpc1.aws_vpc_ipam_pool_cidr_allocation.nonprod_vpc1_cidr' 'module.spoke_vpcs["nonprod_vpc1"].aws_vpc_ipam_pool_cidr_allocation.vpc_cidr'
check_move "nonprod_vpc1 IPAM allocation"

echo "Moving VPC..."
terraform state mv 'module.nonprod_vpc1.aws_vpc.nonprod_vpc1' 'module.spoke_vpcs["nonprod_vpc1"].aws_vpc.vpc'
check_move "nonprod_vpc1 VPC"

echo "Moving public subnets..."
terraform state mv 'module.nonprod_vpc1.aws_subnet.nonprod_vpc1_public_subnet_a' 'module.spoke_vpcs["nonprod_vpc1"].aws_subnet.public_subnet[0]'
check_move "nonprod_vpc1 public subnet a"

terraform state mv 'module.nonprod_vpc1.aws_subnet.nonprod_vpc1_public_subnet_b' 'module.spoke_vpcs["nonprod_vpc1"].aws_subnet.public_subnet[1]'
check_move "nonprod_vpc1 public subnet b"

echo "Moving private subnets..."
terraform state mv 'module.nonprod_vpc1.aws_subnet.nonprod_vpc1_private_subnet_a' 'module.spoke_vpcs["nonprod_vpc1"].aws_subnet.private_subnet[0]'
check_move "nonprod_vpc1 private subnet a"

terraform state mv 'module.nonprod_vpc1.aws_subnet.nonprod_vpc1_private_subnet_b' 'module.spoke_vpcs["nonprod_vpc1"].aws_subnet.private_subnet[1]'
check_move "nonprod_vpc1 private subnet b"

echo "Moving route tables..."
terraform state mv 'module.nonprod_vpc1.aws_route_table.nonprod_vpc1_public_rt' 'module.spoke_vpcs["nonprod_vpc1"].aws_route_table.public_rt'
check_move "nonprod_vpc1 public route table"

terraform state mv 'module.nonprod_vpc1.aws_route_table.nonprod_vpc1_private_rt' 'module.spoke_vpcs["nonprod_vpc1"].aws_route_table.private_rt'
check_move "nonprod_vpc1 private route table"

echo "Moving route table associations..."
terraform state mv 'module.nonprod_vpc1.aws_route_table_association.nonprod_vpc1_public_rta_a' 'module.spoke_vpcs["nonprod_vpc1"].aws_route_table_association.public_rta[0]'
check_move "nonprod_vpc1 public route table association a"

terraform state mv 'module.nonprod_vpc1.aws_route_table_association.nonprod_vpc1_public_rta_b' 'module.spoke_vpcs["nonprod_vpc1"].aws_route_table_association.public_rta[1]'
check_move "nonprod_vpc1 public route table association b"

terraform state mv 'module.nonprod_vpc1.aws_route_table_association.nonprod_vpc1_private_rta_a' 'module.spoke_vpcs["nonprod_vpc1"].aws_route_table_association.private_rta[0]'
check_move "nonprod_vpc1 private route table association a"

terraform state mv 'module.nonprod_vpc1.aws_route_table_association.nonprod_vpc1_private_rta_b' 'module.spoke_vpcs["nonprod_vpc1"].aws_route_table_association.private_rta[1]'
check_move "nonprod_vpc1 private route table association b"

echo "Moving internet gateway..."
terraform state mv 'module.nonprod_vpc1.aws_internet_gateway.nonprod_vpc1_igw' 'module.spoke_vpcs["nonprod_vpc1"].aws_internet_gateway.igw[0]'
check_move "nonprod_vpc1 internet gateway"

echo "Moving routes..."
terraform state mv 'module.nonprod_vpc1.aws_route.nonprod_vpc1_public_rt_default' 'module.spoke_vpcs["nonprod_vpc1"].aws_route.public_rt_default[0]'
check_move "nonprod_vpc1 public default route"

terraform state mv 'module.nonprod_vpc1.aws_route.nonprod_vpc1_private_rt_default' 'module.spoke_vpcs["nonprod_vpc1"].aws_route.private_rt_default'
check_move "nonprod_vpc1 private default route"

echo "Moving TGW attachment..."
terraform state mv 'module.nonprod_vpc1.aws_ec2_transit_gateway_vpc_attachment.nonprod_vpc1_tgw_attachment' 'module.spoke_vpcs["nonprod_vpc1"].aws_ec2_transit_gateway_vpc_attachment.tgw_attachment'
check_move "nonprod_vpc1 TGW attachment"

terraform state mv 'module.nonprod_vpc1.aws_ec2_transit_gateway_route_table_association.nonprod_vpc1_tgw_rt_association' 'module.spoke_vpcs["nonprod_vpc1"].aws_ec2_transit_gateway_route_table_association.tgw_rt_association'
check_move "nonprod_vpc1 TGW route table association"

echo "nonprod_vpc1 migration completed! ✅"
echo ""
echo "Press Enter to continue with nonprod_vpc2 migration..."
read

# ===========================================
# Migrate nonprod_vpc2
# ===========================================
echo "=========================================="
echo "Migrating nonprod_vpc2 resources..."
echo "=========================================="

echo "Moving IPAM allocation..."
terraform state mv 'module.nonprod_vpc2.aws_vpc_ipam_pool_cidr_allocation.nonprod_vpc2_cidr' 'module.spoke_vpcs["nonprod_vpc2"].aws_vpc_ipam_pool_cidr_allocation.vpc_cidr'
check_move "nonprod_vpc2 IPAM allocation"

echo "Moving VPC..."
terraform state mv 'module.nonprod_vpc2.aws_vpc.nonprod_vpc2' 'module.spoke_vpcs["nonprod_vpc2"].aws_vpc.vpc'
check_move "nonprod_vpc2 VPC"

echo "Moving public subnets..."
terraform state mv 'module.nonprod_vpc2.aws_subnet.nonprod_vpc2_public_subnet_a' 'module.spoke_vpcs["nonprod_vpc2"].aws_subnet.public_subnet[0]'
check_move "nonprod_vpc2 public subnet a"

terraform state mv 'module.nonprod_vpc2.aws_subnet.nonprod_vpc2_public_subnet_b' 'module.spoke_vpcs["nonprod_vpc2"].aws_subnet.public_subnet[1]'
check_move "nonprod_vpc2 public subnet b"

echo "Moving private subnets..."
terraform state mv 'module.nonprod_vpc2.aws_subnet.nonprod_vpc2_private_subnet_a' 'module.spoke_vpcs["nonprod_vpc2"].aws_subnet.private_subnet[0]'
check_move "nonprod_vpc2 private subnet a"

terraform state mv 'module.nonprod_vpc2.aws_subnet.nonprod_vpc2_private_subnet_b' 'module.spoke_vpcs["nonprod_vpc2"].aws_subnet.private_subnet[1]'
check_move "nonprod_vpc2 private subnet b"

echo "Moving route tables..."
terraform state mv 'module.nonprod_vpc2.aws_route_table.nonprod_vpc2_public_rt' 'module.spoke_vpcs["nonprod_vpc2"].aws_route_table.public_rt'
check_move "nonprod_vpc2 public route table"

terraform state mv 'module.nonprod_vpc2.aws_route_table.nonprod_vpc2_private_rt' 'module.spoke_vpcs["nonprod_vpc2"].aws_route_table.private_rt'
check_move "nonprod_vpc2 private route table"

echo "Moving route table associations..."
terraform state mv 'module.nonprod_vpc2.aws_route_table_association.nonprod_vpc2_public_rta_a' 'module.spoke_vpcs["nonprod_vpc2"].aws_route_table_association.public_rta[0]'
check_move "nonprod_vpc2 public route table association a"

terraform state mv 'module.nonprod_vpc2.aws_route_table_association.nonprod_vpc2_public_rta_b' 'module.spoke_vpcs["nonprod_vpc2"].aws_route_table_association.public_rta[1]'
check_move "nonprod_vpc2 public route table association b"

terraform state mv 'module.nonprod_vpc2.aws_route_table_association.nonprod_vpc2_private_rta_a' 'module.spoke_vpcs["nonprod_vpc2"].aws_route_table_association.private_rta[0]'
check_move "nonprod_vpc2 private route table association a"

terraform state mv 'module.nonprod_vpc2.aws_route_table_association.nonprod_vpc2_private_rta_b' 'module.spoke_vpcs["nonprod_vpc2"].aws_route_table_association.private_rta[1]'
check_move "nonprod_vpc2 private route table association b"

echo "Moving internet gateway..."
terraform state mv 'module.nonprod_vpc2.aws_internet_gateway.nonprod_vpc2_igw' 'module.spoke_vpcs["nonprod_vpc2"].aws_internet_gateway.igw[0]'
check_move "nonprod_vpc2 internet gateway"

echo "Moving routes..."
terraform state mv 'module.nonprod_vpc2.aws_route.nonprod_vpc2_public_rt_default' 'module.spoke_vpcs["nonprod_vpc2"].aws_route.public_rt_default[0]'
check_move "nonprod_vpc2 public default route"

terraform state mv 'module.nonprod_vpc2.aws_route.nonprod_vpc2_private_rt_default' 'module.spoke_vpcs["nonprod_vpc2"].aws_route.private_rt_default'
check_move "nonprod_vpc2 private default route"

echo "Moving TGW attachment..."
terraform state mv 'module.nonprod_vpc2.aws_ec2_transit_gateway_vpc_attachment.nonprod_vpc2_tgw_attachment' 'module.spoke_vpcs["nonprod_vpc2"].aws_ec2_transit_gateway_vpc_attachment.tgw_attachment'
check_move "nonprod_vpc2 TGW attachment"

terraform state mv 'module.nonprod_vpc2.aws_ec2_transit_gateway_
