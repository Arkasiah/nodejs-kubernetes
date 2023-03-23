terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.48.0"
    }
  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

resource "azurerm_postgresql_server" "postrgres-server" {
  name                = "postgres-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg-maalsi.location
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name

  administrator_login          = data.azurerm_key_vault_secret.postgres-login.value
  administrator_login_password = data.azurerm_key_vault_secret.postgres-password.value

  sku_name   = "GP_Gen5_4"
  version    = "11"
  storage_mb = 640000

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  public_network_access_enabled    = true
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

resource "azurerm_service_plan" "app_plan" {
  name                = "app-plan-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = data.azurerm_resource_group.rg-maalsi.location
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_web_app" "web_app" {
  name                = "web-app-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = data.azurerm_resource_group.rg-maalsi.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {

  }
}

/*resource "azurerm_container_group" "api" {
  name                = "api-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg-maalsi.location
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  ip_address_type     = "Public"
  dns_name_label      = "api-${var.project_name}${var.environment_suffix}"
  os_type             = "Linux"
  container {
    name   = "api"
    image  = "arkasiah/api:1.0"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 3000
      protocol = "TCP"
    }

    environment_variables = {
      "PORT"        = var.api_port
      "DB_HOST"     = azurerm_postgresql_server.postgres-server.fqdn
      "DB_USERNAME" = "${data.azurerm_key_vault_secret.postgres-login.value}@${azurerm_postgresql_server.postgres-server.name}"
      "DB_PASSWORD" = data.azurerm_key_vault_secret.postgres-password.value
      "DB_DATABASE" = var.database_name
      "DB_DAILECT"  = var.database_dialect
      "DB_PORT"     = var.database_port

      "ACCESS_TOKEN_SECRET"       = data.azurerm_key_vault_secret.access-token.value
      "REFRESH_TOKEN_SECRET"      = data.azurerm_key_vault_secret.refresh-token.value
      "ACCESS_TOKEN_EXPIRY"       = var.access_token_expiry
      "REFRESH_TOKEN_EXPIRY"      = var.refresh_token_expiry
      "REFRESH_TOKEN_COOKIE_NAME" = var.refresh_token_cookie_name
    }
  }
}

resource "azurerm_container_group" "pgadmin" {
  name                = "pgadmin-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg-maalsi.location
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  ip_address_type     = "Public"
  dns_name_label      = "pgadmin-${var.project_name}${var.environment_suffix}"
  os_type             = "Linux"

  container {
    name   = "pgadmin"
    image  = "dpage/pgadmin4:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "PGADMIN_DEFAULT_EMAIL"    = data.azurerm_key_vault_secret.pgadmin-login.value
      "PGADMIN_DEFAULT_PASSWORD" = data.azurerm_key_vault_secret.pgadmin-password.value
    }
  }
}*/
#################################################################################################################################################################################################################################
/*
###############
# Database
###############

resource "azurerm_mssql_server" "sql-server" {
  name                         = "sqlsrv-${var.project_name}${var.environment_suffix}"
  resource_group_name          = data.azurerm_resource_group.rg-maalsi.name
  location                     = data.azurerm_resource_group.rg-maalsi.location
  version                      = "12.0"
  administrator_login          = data.azurerm_key_vault_secret.database-login.value
  administrator_login_password = data.azurerm_key_vault_secret.password.value
}

resource "azurerm_mssql_firewall_rule" "sql-srv" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql-server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "sql-db" {
  name           = "RabbitMqDemo"
  server_id      = azurerm_mssql_server.sql-server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  #  max_size_gb    = 2
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false
}

###############
# API Web App
###############

resource "azurerm_service_plan" "app-plan" {
  name                = "plan-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = data.azurerm_resource_group.rg-maalsi.location
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "web-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = data.azurerm_resource_group.rg-maalsi.location
  service_plan_id     = azurerm_service_plan.app-plan.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
  }

  connection_string {
    name  = "DefaultConnection"
    value = "Server=tcp:${azurerm_mssql_server.sql-server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql-db.name};Persist Security Info=False;User ID=${data.azurerm_key_vault_secret.database-login.value};Password=${data.azurerm_key_vault_secret.password.value};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    type  = "SQLAzure"
  }

  app_settings = {
    "RabbitMQ__Hostname" = azurerm_container_group.rabbitmq.fqdn,
    "RabbitMQ__Username" = data.azurerm_key_vault_secret.rabbitmq-login.value,
    "RabbitMQ__Password" = data.azurerm_key_vault_secret.rabbitmq-password.value
  }
}

###############
# RabbitMQ : Container Instance
###############

resource "azurerm_container_group" "rabbitmq" {
  name                = "aci-mq-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = data.azurerm_resource_group.rg-maalsi.location
  ip_address_type     = "Public"
  dns_name_label      = "aci-mq-${var.project_name}${var.environment_suffix}"
  os_type             = "Linux"

  container {
    name   = "rabbitmq"
    image  = "rabbitmq:3-management"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 5672
      protocol = "TCP"
    }

    ports {
      port     = 15672
      protocol = "TCP"
    }

    environment_variables = {
      "RABBITMQ_DEFAULT_USER" = data.azurerm_key_vault_secret.rabbitmq-login.value,
      "RABBITMQ_DEFAULT_PASS" = data.azurerm_key_vault_secret.rabbitmq-password.value
    }
  }
}*/
