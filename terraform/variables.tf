# 姓名判断アプリ - Kubernetes環境用変数定義

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

variable "zone" {
  description = "GCPゾーン"
  type        = string
  default     = "asia-northeast1-a"
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

variable "environment" {
  description = "環境名"
  type        = string
  default     = "production"
}

variable "machine_type" {
  description = "ノードのマシンタイプ"
  type        = string
  default     = "e2-micro"
}

variable "min_node_count" {
  description = "最小ノード数"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "最大ノード数"
  type        = number
  default     = 3
}

variable "disk_size_gb" {
  description = "ディスクサイズ（GB）"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "ディスクタイプ"
  type        = string
  default     = "pd-standard"
}

variable "image_type" {
  description = "ノードイメージタイプ"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "enable_autoscaling" {
  description = "自動スケーリングの有効化"
  type        = bool
  default     = true
}

variable "enable_autorepair" {
  description = "自動修復の有効化"
  type        = bool
  default     = true
}

variable "enable_autoupgrade" {
  description = "自動アップグレードの有効化"
  type        = bool
  default     = true
}

variable "maintenance_window_start_time" {
  description = "メンテナンスウィンドウ開始時間"
  type        = string
  default     = "2023-01-01T00:00:00Z"
}

variable "allowed_cidr_blocks" {
  description = "許可するCIDRブロック"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "リソースタグ"
  type        = map(string)
  default = {
    Environment = "production"
    Application = "seimei-handan"
    ManagedBy   = "terraform"
  }
}
