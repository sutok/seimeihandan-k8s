# 姓名判断アプリ - Kubernetes環境用出力定義

output "project_id" {
  description = "GCPプロジェクトID"
  value       = var.project_id
}

output "region" {
  description = "GCPリージョン"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetesクラスター名"
  value       = var.cluster_name
}

output "vpc_name" {
  description = "VPC名"
  value       = google_compute_network.seimei_handan_vpc.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.seimei_handan_vpc.id
}

output "subnet_name" {
  description = "サブネット名"
  value       = google_compute_subnetwork.seimei_handan_subnet.name
}

output "subnet_id" {
  description = "サブネットID"
  value       = google_compute_subnetwork.seimei_handan_subnet.id
}

output "subnet_cidr" {
  description = "サブネットCIDR"
  value       = google_compute_subnetwork.seimei_handan_subnet.ip_cidr_range
}

output "pods_cidr" {
  description = "Pod用CIDR"
  value       = google_compute_subnetwork.seimei_handan_subnet.secondary_ip_range[0].ip_cidr_range
}

output "services_cidr" {
  description = "サービス用CIDR"
  value       = google_compute_subnetwork.seimei_handan_subnet.secondary_ip_range[1].ip_cidr_range
}

output "bucket_name" {
  description = "Cloud Storageバケット名"
  value       = google_storage_bucket.seimei_handan_bucket.name
}

output "bucket_url" {
  description = "Cloud StorageバケットURL"
  value       = google_storage_bucket.seimei_handan_bucket.url
}

output "service_account_email" {
  description = "サービスアカウントメールアドレス"
  value       = google_service_account.seimei_handan_sa.email
}

output "service_account_id" {
  description = "サービスアカウントID"
  value       = google_service_account.seimei_handan_sa.id
}

output "static_ip" {
  description = "静的IPアドレス"
  value       = google_compute_global_address.seimei_handan_ip.address
}

output "static_ip_name" {
  description = "静的IPアドレス名"
  value       = google_compute_global_address.seimei_handan_ip.name
}

output "firewall_rules" {
  description = "ファイアウォールルール"
  value = {
    internal = google_compute_firewall.seimei_handan_allow_internal.name
    http     = google_compute_firewall.seimei_handan_allow_http.name
  }
}

output "kubectl_config_command" {
  description = "kubectl設定コマンド"
  value       = "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.region} --project ${var.project_id}"
}

output "deployment_command" {
  description = "デプロイメントコマンド"
  value       = "cd kubernetes && ./deploy.sh deploy"
}

output "status_command" {
  description = "状態確認コマンド"
  value       = "cd kubernetes && ./deploy.sh status"
}

output "logs_command" {
  description = "ログ確認コマンド"
  value       = "cd kubernetes && ./deploy.sh logs"
}
