# 姓名判断アプリ - Kubernetes環境用Terraform設定

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

# プロバイダー設定
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# 変数定義
variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
  default     = "ai-tools-471505"
}

variable "region" {
  description = "GCPリージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "cluster_name" {
  description = "Kubernetesクラスター名"
  type        = string
  default     = "ai-tools-471505"
}

variable "app_name" {
  description = "アプリケーション名"
  type        = string
  default     = "seimei-handan"
}

# VPCネットワーク
resource "google_compute_network" "seimei_handan_vpc" {
  name                    = "seimei-handan-vpc"
  auto_create_subnetworks = false
  description             = "姓名判断アプリ用VPC"
}

# サブネット
resource "google_compute_subnetwork" "seimei_handan_subnet" {
  name          = "seimei-handan-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.seimei_handan_vpc.id

  # セカンダリIPレンジ（Pod用）
  secondary_ip_range {
    range_name    = "seimei-handan-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  # セカンダリIPレンジ（サービス用）
  secondary_ip_range {
    range_name    = "seimei-handan-services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# ファイアウォールルール
resource "google_compute_firewall" "seimei_handan_allow_internal" {
  name    = "seimei-handan-allow-internal"
  network = google_compute_network.seimei_handan_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    "10.0.0.0/24",
    "10.1.0.0/16",
    "10.2.0.0/16"
  ]
}

resource "google_compute_firewall" "seimei_handan_allow_http" {
  name    = "seimei-handan-allow-http"
  network = google_compute_network.seimei_handan_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["seimei-handan-gateway"]
}

# Cloud Storageバケット
resource "google_storage_bucket" "seimei_handan_bucket" {
  name          = "seimei-handan-bucket"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    response_header = ["Content-Type", "Authorization", "X-Requested-With"]
    max_age_seconds = 3600
  }
}

# サービスアカウント
resource "google_service_account" "seimei_handan_sa" {
  account_id   = "seimei-handan-sa"
  display_name = "姓名判断アプリ用サービスアカウント"
  description  = "Kubernetes環境用サービスアカウント"
}

# IAMロール
resource "google_project_iam_member" "seimei_handan_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.seimei_handan_sa.email}"
}

resource "google_project_iam_member" "seimei_handan_cloud_functions_invoker" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.seimei_handan_sa.email}"
}

resource "google_project_iam_member" "seimei_handan_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.seimei_handan_sa.email}"
}

# サービスアカウントキー
resource "google_service_account_key" "seimei_handan_key" {
  service_account_id = google_service_account.seimei_handan_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# 静的IPアドレス
resource "google_compute_global_address" "seimei_handan_ip" {
  name = "seimei-handan-ip"
}

# 出力値
output "vpc_name" {
  description = "VPC名"
  value       = google_compute_network.seimei_handan_vpc.name
}

output "subnet_name" {
  description = "サブネット名"
  value       = google_compute_subnetwork.seimei_handan_subnet.name
}

output "bucket_name" {
  description = "Cloud Storageバケット名"
  value       = google_storage_bucket.seimei_handan_bucket.name
}

output "service_account_email" {
  description = "サービスアカウントメールアドレス"
  value       = google_service_account.seimei_handan_sa.email
}

output "static_ip" {
  description = "静的IPアドレス"
  value       = google_compute_global_address.seimei_handan_ip.address
}

output "service_account_key" {
  description = "サービスアカウントキー（Base64エンコード）"
  value       = google_service_account_key.seimei_handan_key.private_key
  sensitive   = true
}
