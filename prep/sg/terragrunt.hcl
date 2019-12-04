terraform {
  source = "${local.source}"
}

include {
  path = find_in_parent_folders()
}

locals {
  repo_owner = "robc-io"
  repo_name = "terraform-aws-security-group"
  repo_version = "master"
  repo_path = ""

  local_source = true
  modules_path = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${find_in_parent_folders("modules")}"

  source = local.local_source ? "${local.modules_path}/${local.repo_name}" : "github.com/${local.repo_owner}/${local.repo_name}.git//${local.repo_path}?ref=${local.repo_version}"

  name = "prep"
  description = "All traffic"

  corporate_ip = local.secrets["corporate_ip"]
  secrets = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("secrets.yaml")}"))

  # Dependencies
  vpc = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${find_in_parent_folders("vpc")}"
}

dependencies {
  paths = [local.vpc]
}

dependency "vpc" {
  config_path = local.vpc
}

inputs = {
  name = local.name

  description = local.description
  vpc_id = dependency.vpc.outputs.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port = 0
      to_port = 65535
      protocol = -1
      description = "Egress access open to all"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      description = "Security group for ssh access from coporate ip"
      cidr_blocks = local.corporate_ip == "" ? "0.0.0.0/0" : "${local.corporate_ip}/32"
    },
    {
      from_port = 7100
      to_port = 7100
      protocol = "tcp"
      description = local.description
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port = 9000
      to_port = 9000
      protocol = "tcp"
      description = "Security group json rpc traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {}
}
