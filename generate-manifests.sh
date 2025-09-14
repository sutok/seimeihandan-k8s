#!/bin/bash

# テンプレートからマニフェストファイルを生成するスクリプト

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
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
if [ -f ".env" ]; then
    source .env
else
    log_error ".env ファイルが見つかりません"
    exit 1
fi

# 必要な環境変数の確認
required_vars=("PROJECT_ID" "CLUSTER_NAME" "REGION" "FUNCTION_URL" "DOMAIN_NAME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        log_error "環境変数 $var が設定されていません"
        exit 1
    fi
done

log_info "環境変数を確認しました"
log_info "PROJECT_ID: $PROJECT_ID"
log_info "CLUSTER_NAME: $CLUSTER_NAME"
log_info "REGION: $REGION"

# テンプレートディレクトリの作成
mkdir -p templates

# テンプレートファイルのリスト
templates=(
    "vpc-config.template.yaml"
    "cloud-functions-integration.template.yaml"
    "cloud-storage-config.template.yaml"
    "nginx-config.template.yaml"
    "cloud-functions-proxy.template.yaml"
    "security-policies.template.yaml"
    "network-policy.template.yaml"
)

# 各テンプレートファイルを処理
for template in "${templates[@]}"; do
    if [ -f "templates/$template" ]; then
        output_file=$(echo "$template" | sed 's/.template//')
        log_info "生成中: $output_file"
        
        # 環境変数を置換してファイルを生成
        # envsubstが利用できない場合は、sedを使用
        if command -v envsubst >/dev/null 2>&1; then
            envsubst < "templates/$template" > "$output_file"
        else
            # sedを使用して環境変数を置換
            sed -e "s/\${PROJECT_ID}/$PROJECT_ID/g" \
                -e "s/\${CLUSTER_NAME}/$CLUSTER_NAME/g" \
                -e "s/\${REGION}/$REGION/g" \
                -e "s/\${FUNCTION_URL}/$FUNCTION_URL/g" \
                -e "s/\${DOMAIN_NAME}/$DOMAIN_NAME/g" \
                -e "s/\${ALLOWED_IPS}/$ALLOWED_IPS/g" \
                "templates/$template" > "$output_file"
        fi
        
        log_success "生成完了: $output_file"
    else
        log_warning "テンプレートファイルが見つかりません: templates/$template"
    fi
done

log_success "すべてのマニフェストファイルが生成されました"

# 生成されたファイルの一覧を表示
echo ""
echo "生成されたファイル:"
ls -la *.yaml | grep -v template
