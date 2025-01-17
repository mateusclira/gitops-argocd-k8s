data "azurerm_client_config" "current" {}
data "azurerm_subscription" "primary" {}

resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.cname}"
  location                    = var.region
  resource_group_name         = "platform-${var.cname}"
  enabled_for_disk_encryption = true
  tenant_id                   = "tenant-id"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

    access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy",
      "List",
      "Encrypt",
      "Decrypt",
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List"
    ]

    storage_permissions = [
      "Get"
    ]
  }

   access_policy {
    tenant_id = "tenant-id"
    object_id = azurerm_role_assignment.argo.principal_id

     key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy",
      "List",
      "Encrypt",
      "Decrypt"
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete"
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azuread_application" "argo_app" {
  display_name = "argo-${var.cname}"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "argo_sp" {
  client_id               = azuread_application.argo_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]
}

resource "azurerm_role_assignment" "argo" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azuread_service_principal.argo_sp.object_id
}
