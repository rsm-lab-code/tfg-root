
Key Components
1. IP Address Management (IPAM) System

Purpose: Acts as a central system to organize and track all IP addresses across the organization
Structure: Organizes IP addresses in a hierarchy (like folders within folders):

Top level: Global IPAM system that oversees everything
Second level: Regional pools - separate IP address spaces for each AWS region (us-west-2 and us-east-1)
Third level: Environment pools - divides each region into Production and Non-Production environments
Fourth level: Subnet pools - further subdivides environments for specific network segments



2. Virtual Private Cloud (VPC) System

Purpose: Creates isolated network environments in each region
Implementation:

Creates a Production VPC in us-west-2 (Western US)
Creates a Non-Production VPC in us-east-1 (Eastern US)
Each VPC gets its IP addresses automatically from the IPAM system
Each VPC contains two separate subnets placed in different data centers for reliability

File Structure
The code is organized into:

Root module: Controls overall configuration and connects everything together
IPAM module: Manages all IP address allocation and organization
VPC module: Creates and configures the network environments

Configuration Files

variables.tf: Defines inputs and settings like region names and account IDs
providers.tf: Establishes connections to AWS accounts and regions
main.tf: Contains the main resource definitions and module connections
outputs.tf: Defines what information is reported back after creation

How It Works

Initial Setup: The system first authenticates with AWS using role-based security
IPAM Creation: Creates the IP address management hierarchy
VPC Provisioning: Creates isolated network environments using IP addresses from IPAM
Subnet Configuration: Creates network segments within each VPC
Output Information: Reports back all resource IDs and network information
=======
# tfg-root


   
