**UNDER CONSTRUCTION**

Use this on OTL test accounts.

This will create two VPCs in your account with public and private subnets. One VPC will have subnets in-region and subnets on your Outpost. The other VPC will have two subnets in-region and will come with a VGW pre-provisioned; you can manually connect the VGW to your on-prem network and from there to the Outpost's LGW using normal OTL LGW connectivity steps.

You can use boolean flags to launch Outpost-hostable services in baseline configurations. This is useful if you need to quickly test something simple.

Currently supported services:
* EKS
* ElastiCache
* EMR
* RDS
