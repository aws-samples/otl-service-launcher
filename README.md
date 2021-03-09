# Outposts Test Labs (OTL) Service Launcher

***This module is intended be used with the AWS Outposts Test Labs (OTL) racks using OTL test accounts. If you want to use it with your own Outpost and/or contribute code, see the instructions at the bottom of this readme.***

AWS customers, partners, and Solutions Architects using the Outposts Test Labs (OTL) to validate applications on AWS Outposts infrastructure need a quick and easy way to provision test environments and deploy supported AWS services. This Terraform module deploys an in-Region VPC spanning multiple Availability Zones (AZs) and extends the VPC onto the OTL Outpost associated with the deploying user's AWS account. The *main* VPC includes public and private subnets for each AZ and the Outpost. The module can optionally deploy supported AWS services on the Outpost and an additional simulated *on-premises* VPC in the Region. OTL users specify the services to deploy by enabling boolean service deployment *flags*.

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
                      -var 'mysql=true'
    ```

2. As provided Terraform configuration files where you provide the **required** and *optional* variables via a **Terraform `.tfvars` file**

    ```shell
    ❯ cat otl.auto.tfvars
    username = "<<your-username>>"
    profile  = "<<your-aws-cli-profile>>"

    region_cloud9           = false
    outpost_cloud9          = false
    emr                     = false 
    memcached               = false
    redis                   = false
    eks                     = false
    eks_outpost_node_group  = false
    mysql                   = false
    postgres                = false
    on_prem_vpc             = false


    ❯ terraform apply
    ```

3. As a Terrform module that you add to your Terraform configuration files

    ```hcl
    module "otl_service_launcher" {
      source = "github.com/Outposts-Test-Lab/otl-service-launcher

      username = "<<your-username>>"
      profile  = "<<your-aws-cli-profile>>"

      region_cloud9           = false
      outpost_cloud9          = false
      emr                     = false
      memcached               = false
      redis                   = false
      eks                     = false
      eks_outpost_node_group  = false
      mysql                   = false
      postgres                = false
      on_prem_vpc             = false
    }
    ```

## Input variables

### Required

| Name | Description |
| ---- | ----------- |
| **username** | Your username - will be prepended to most resource names and tags to track what's yours in the Outposts Test Labs (OTL) environment. |
| **profile** | The AWS CLI profile Terraform should use to authenticate with the AWS cloud. Terraform deploys the configured resources into the account associated with this profile. You must use an AWS account associated with an OTL Outpost rack. |

### Optional

| Name | Default | Description |
| ---- | ------- | ----------- |
| region | `"us-west-2"` | The parent region of the Outposts Test Lab (OTL) rack. The main VPC will be deployed in this region and the VPC extended to the Outpost. |
| main_vpc_cidr | `""` | The `/16` VPC CIDR block for the main VPC. By default, the module will *randomly generate* a `/16` block in the `10.0.0.0/8` network. |
| tags | `{}` | A map of tags to apply to all supported resources created by module. By default, the module tags all resources with `Username`, `CallerARN`, `OutpostName`, and `OutpostARN` tags. The default tags are merged with the tags provided by via this input variable. |

> ***Note:*** Local gateway (LGW) attachment will fail if the the `main_vpc_cidr` overlaps with a VPC already attached to the LGW. With low concurrent usage, the practice of using random `10.x.0.0/16` CIDR blocks (selecting from 256 possible blocks), and tearing down VPCs when not needed, should be sufficient to prevent overlaps without requiring the creation and maintenance of a static addressing plan. **If the module fails to deploy due to a LGW attachment failure, destroy the VPC with `terraform destroy` and try deploying it again (the module will generate a new random CIDR block).** The services deployed via the *service deployment flags* are configured with a dependence on the LGW attachment - this prevents the deployment of the services in the event the LGW attachment fails - saving you time if the VPC needs to be redeployed.

### Service deployment flags

Set these flags to true to deploy the desired services.

| Name | Default | Description |
| ---- | ------- | ----------- |
| region_cloud9 | `false` | Deploy a Cloud9 bastion in the main VPC in the Region. |
| outpost_cloud9 | `false` | Deploy a Cloud9 bastion on the Outpost. |
| emr | `false` | Deploy an EMR cluster on the Outpost. |
| memcached | `false` | Deploy an ElastiCache Memcached instance on the Outpost. |
| redis | `false` | Deploy an ElastiCache Redis instance on the Outpost. |
| eks | `false` | Deploy an EKS cluster in the main VPC in the Region. |
| eks_outpost_node_group | `false` | Deploy an EKS unmanaged node group on the Outpost and register the nodes with the EKS cluster deployed by the "eks" flag. |
| mysql | `false` | Deploy an RDS MySQL instance on the Outpost. |
| postgres | `false` | Deploy an RDS PostgreSQL instance on the Outpost. |
| on_prem_vpc | `false` | Deploy a VPC to simulate an on-premises network in the region and to enable connectivity to on-premises networks. |

## Deployed services

### Simulated on-premises VPC

*Input variables:*

| Name | Default | Description |
| ---- | ------- | ----------- |
| on_prem_vpc_cidr | `""` | A `/19` (minimum) CIDR block for the on-premises VPC. By default, the module will generate a random `/19` CIDR block in the `172.16.0.0/12` range. |

Enabling the `on_prem_vpc` flag will deploy an additional VPC in the AWS Region. The module creates a multi-AZ VPC with two (AZs) configured with public and private subnets and pre-provisions a Virtual Private Gateway (VGW). You can work with the OTL team to manually connect the VGW to your on-premises networks and configure routing between your on-premises network, the *on-premises VPC*, and the *main VPC* via the Outpost's LGW using the normal OTL-LGW connectivity steps.

### Using this repo outside of OTL

We, the maintainers, don't test this repo on Outposts outside of OTL. We also add features (such as `on_prem_vpc`) that loosely integrate with OTL-specific architecture. If you're using this repo on your own non-OTL Outpost, your mileage may vary.

That being said, this repo "should" "just work" if you set the `otl_outpost_ids` variable to a list containing your own Outpost IDs. For example:

```shell
    ❯ cat otl.auto.tfvars
    username = "<<your-username>>"
    profile  = "<<your-aws-cli-profile>>"

    region_cloud9           = false
    outpost_cloud9          = false
    emr                     = false 
    memcached               = false
    redis                   = false
    eks                     = false
    eks_outpost_node_group  = false
    mysql                   = false
    postgres                = false
    on_prem_vpc             = false

    otl_outpost_ids         = ["<<your-outpost-id>>"]

    ❯ terraform apply
    ```

### Contributing

If you find a problem, cut us an issue. If you solve a problem and/or add new functionality that you'd like to share, submit a PR! We welcome your contributions.
