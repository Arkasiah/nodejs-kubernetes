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

resource "azurerm_postgresql_firewall_rule" "firewall" {
  name                = "firewall-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  server_name         = azurerm_postgresql_server.postrgres-server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
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

resource "azurerm_container_group" "api" {
  name                = "api-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg-maalsi.location
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  ip_address_type     = "Public"
  dns_name_label      = "api-${var.project_name}${var.environment_suffix}"
  os_type             = "Linux"
  container {
    name   = "api"
    image  = "arkasiah/node-api:1.0"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 3000
      protocol = "TCP"
    }

    environment_variables = {
      "PORT"        = var.api_port
      "DB_HOST"     = azurerm_postgresql_server.postrgres-server.fqdn
      "DB_USERNAME" = "${data.azurerm_key_vault_secret.postgres-login.value}@${azurerm_postgresql_server.postrgres-server.name}"
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
}