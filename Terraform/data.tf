data "azurerm_resource_group" "rg-maalsi" {
  name = "rg-${var.project_name}${var.environment_suffix}"
}

data "azurerm_key_vault" "kv" {
  name                = "kp-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
}

data "azurerm_key_vault_secret" "postgres-login" {
  name = "postgres-login"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "postgres-password" {
  name = "postgres-password"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "access-token" {
  name = "access-token"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "refresh-token" {
  name = "refresh-token"
  key_vault_id = data.azurerm_key_vault.kv.id
}

