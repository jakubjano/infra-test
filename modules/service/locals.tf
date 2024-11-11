locals {
  app_name_parsed = replace(lower(var.app_name), " ", "-")
  api_name        = "${local.app_name_parsed}-api"

  api_static_env_vars = [
    {
      name : "PORT"
      value : "8080"
    },
    {
      "name" : "DATABASE_SSL_MODE"
      "value" : "disable"
    },
    {
      "name" : "DATABASE_MIGRATIONS_DIR"
      "value" : "/usr/local/bin/migrations"
    },
  ]
}
