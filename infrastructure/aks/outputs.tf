resource "local_file" "kubeconfig" {
  depends_on   = [azurerm_kubernetes_cluster.main]
  filename     = "kubeconfig"
  content      = azurerm_kubernetes_cluster.main.kube_config_raw
}

output "id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.main.kube_config_raw
}

output "client_key" {
  value = azurerm_kubernetes_cluster.main.kube_config.0.client_key
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate
}

output "host" {
  value = azurerm_kubernetes_cluster.main.kube_config.0.host
}