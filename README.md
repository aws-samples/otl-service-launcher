# Outposts Test Labs (OTL) Service Launcher

***This module is intended be used exclusively with the AWS Outposts Test Labs (OTL) racks using OTL test accounts.***

AWS customers, partners, and Solutions Architects using the Outposts Test Labs (OTL) to validate applications on AWS Outposts infrastructure need a quick and easy way to provision test environments and deploy supported AWS services. This Terraform module deploys an in-region VPC spaning multiple Autonomous Zones (AZs) and extends the VPC onto the OTL Outpost associated with the deploying user's AWS account. The *main* VPC includes public and private subnets for each AZ and the Outpost. The module can optionally deploy supported AWS services on the Outpost and an additional simulated *on-premises* VPC in the Region. OTL users specify the services to deploy by enabling boolean service deployment *flags*.

Deployable Services:

* AWS Cloud9 *[bastion instances]*
* Amazon EMR
* Amazon ElastiCache Memcached
* Amazon ElastiCache Redis
* Amazon Elastic Kubernetes Service (EKS)
* Amazon Relational Database Service (RDS) MySQL
* Amazon Relational Database Service (RDS) PostgreSQL
* Simulated on-premises VPC *[routed through the AWS Outpost's Local Gateway (LGW)]*

## Usage

There are three ways to use this module:

1. As provided Terraform configuration files where you provide the **required** and *optional* variables via a **one-line Terraform CLI command**

    ```shell
    ❯ terraform apply -var 'username=<<your-username>>' \
                      -var 'profile=<<your-aws-cli-profile>>' \
                      -var 'mysql=true' \
    ```

2. As provided Terraform configuration files where you provide the **required** and *optional* variables via a **Terraform `.tfvars` file**

    ```shell
    ❯ cat otl.auto.tfvars
    username = "<<your-username>>"
    profile  = "<<your-aws-cli-profile>>"

    region_cloud9  = false
    outpost_cloud9 = false
    emr            = false
    memcached      = false
    redis          = false
    eks            = false
    mysql          = false
    postgres       = false
    on_prem_vpc    = false

    ❯ terraform apply
    ```

3. As a Terrform module that you add to your Terraform configuration files

    ```hcl
    module "otl_service_launcher" {
      source = "github.com/Outposts-Test-Lab/otl-service-launcher

      username = "<<your-username>>"
      profile  = "<<your-aws-cli-profile>>"

      region_cloud9  = false
      outpost_cloud9 = false
      emr            = false
      memcached      = false
      redis          = false
      eks            = false
      mysql          = false
      postgres       = false
      on_prem_vpc    = false
    }
    ```

## Input Variables

### Required

| Name | Description |
| ---- | ----------- |
| **username** | Your username - will be prepended to most resource names and tags to track what's yours in the Outposts Test Labs (OTL) environment. |
| **profile** | The AWS CLI profile Terraform should use to authenticate with the AWS cloud. Terraform deploys the configured resources into the account associated with this profile. You must use an AWS account associated with an OTL Outpost rack. |

## Deployed Services

### Simulated On-Premises VPC

Enabling the `on_prem_vpc` flag will deploy an additional VPC in the AWS Region. The module creates a multi-AZ VPC with two (AZs) configured with public and private subnets and pre-provisions a Virtual Private Gateway (VGW). You can manually connect the VGW to your on-premises networks and configure routing between your on-premises network, the *on-premises*, and the *main* VPC via the Outpost's LGW using the normal OTL-LGW connectivity steps.
