locals {
  app_name_parsed = replace(lower(var.app_name), " ", "-")

  bastion_host_ami = "ami-0eb01a520e67f7f20"
}
