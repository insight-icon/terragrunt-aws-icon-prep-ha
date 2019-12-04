 terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-autoscaling.git"
}

include {
  path = find_in_parent_folders()
}

locals {
  group_vars = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("group.yaml")}"))
  secrets = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("secrets.yaml")}"))

  name = local.group_vars["group"]

  # Dependencies
  vpc = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${find_in_parent_folders("vpc")}"
  sg = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${find_in_parent_folders("sg")}"
  ami = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${find_in_parent_folders("packer-ami")}"
  user_data = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${find_in_parent_folders("user-data")}"
}

dependencies {
  paths = [local.vpc, local.iam, local.sg]
}

dependency "vpc" {
  config_path = local.vpc
}

dependency "sg" {
  config_path = local.sg
}

dependency "ami" {
  config_path = local.ami
}

dependency "user_data" {
  config_path = local.user_data
}


inputs = {
  name = "citizen"
  lc_name = "citizen"
  asg_name = "p-rep-sentry-asg"

  spot_price = "1"

  key_name = "prep"

  user_data = dependency.user_data.outputs.user_data

  image_id = dependency.ami.outputs.ami_id

  instance_type = "c5.large"
  security_groups = [
    dependency.sg.outputs.this_security_group_id]

  root_block_device = [
    {
      volume_size = "8"
      volume_type = "gp2"
    }
  ]

  ebs_block_device = [
    {
      device_name           = "/dev/xvdf"
      volume_type           = "gp2"
      volume_size           = "130"
      delete_on_termination = true
    },
  ]

  vpc_zone_identifier = dependency.vpc.outputs.private_subnets

  health_check_type = "EC2"

  min_size = 1
  max_size = 3
  desired_capacity = 1
  wait_for_capacity_timeout = 0

  tags = []
}

