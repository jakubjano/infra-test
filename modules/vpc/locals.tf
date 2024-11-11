locals {
  app_name_parsed = replace(lower(var.app_name), " ", "-")
}
