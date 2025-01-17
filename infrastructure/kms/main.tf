resource "azurerm_key_vault_key" "kms" {
  name         = "kms-${var.cname}"
  key_vault_id = var.akv_id
  key_type     = "RSA"
  key_size     = 2048
  
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P365D"
    notify_before_expiry = "P29D"
  }
}