#!/bin/bash

# Kubernetes Secretを生成するスクリプト

set -e

# 色付きのログ出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 環境変数ファイルの確認
if [ ! -f ".env" ]; then
    log_error ".env ファイルが見つかりません"
    log_info "env.example を .env にコピーして設定してください:"
    echo "cp env.example .env"
    echo "vi .env  # 実際の値を設定"
    exit 1
fi

# 環境変数を読み込み
source .env

# 必要な環境変数の確認
required_vars=("PROJECT_ID" "CLUSTER_NAME" "REGION" "FUNCTION_URL" "DOMAIN_NAME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        log_error "環境変数 $var が設定されていません"
        exit 1
    fi
done

log_info "環境変数を確認しました"

# Base64エンコード
PROJECT_ID_B64=$(echo -n "$PROJECT_ID" | base64)
CLUSTER_NAME_B64=$(echo -n "$CLUSTER_NAME" | base64)
REGION_B64=$(echo -n "$REGION" | base64)
FUNCTION_URL_B64=$(echo -n "$FUNCTION_URL" | base64)
DOMAIN_NAME_B64=$(echo -n "$DOMAIN_NAME" | base64)

# 環境変数をエクスポート
export PROJECT_ID_B64
export CLUSTER_NAME_B64
export REGION_B64
export FUNCTION_URL_B64
export DOMAIN_NAME_B64

# Secretファイルを生成
log_info "Secretファイルを生成中..."
envsubst < templates/secrets.template.yaml > secrets.yaml

log_success "Secretファイルが生成されました: secrets.yaml"

# 使用方法を表示
echo ""
echo "使用方法:"
echo "1. kubectl apply -f secrets.yaml"
echo "2. Pod内で環境変数として使用:"
echo "   env:"
echo "   - name: PROJECT_ID"
echo "     valueFrom:"
echo "       secretKeyRef:"
echo "         name: app-config"
echo "         key: project-id"
