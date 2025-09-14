#!/bin/bash

# 姓名判断アプリ - Kubernetes環境デプロイスクリプト
# プロジェクト: ai-tools-471505
# リージョン: asia-northeast1

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

# 設定値
PROJECT_ID="ai-tools-471505"
CLUSTER_NAME="ai-tools-471505"
REGION="asia-northeast1"
NAMESPACE="seimei-handan"

# 引数チェック
if [ $# -eq 0 ]; then
    echo "使用方法: $0 [deploy|destroy|status|logs]"
    echo ""
    echo "コマンド:"
    echo "  deploy  - 環境をデプロイ"
    echo "  destroy - 環境を削除"
    echo "  status  - 環境の状態を確認"
    echo "  logs    - ログを表示"
    exit 1
fi

# GCP認証確認
check_auth() {
    log_info "GCP認証を確認中..."
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "GCPにログインしていません。'gcloud auth login'を実行してください。"
        exit 1
    fi
    log_success "GCP認証OK"
}

# プロジェクト設定
set_project() {
    log_info "プロジェクトを設定中..."
    gcloud config set project $PROJECT_ID
    log_success "プロジェクト設定完了: $PROJECT_ID"
}

# クラスター接続確認
check_cluster() {
    log_info "Kubernetesクラスター接続を確認中..."
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Kubernetesクラスターに接続できません。"
        log_info "以下のコマンドでクラスターに接続してください:"
        echo "gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID"
        exit 1
    fi
    log_success "クラスター接続OK"
}

# 必要なAPIの有効化
enable_apis() {
    log_info "必要なAPIを有効化中..."
    apis=(
        "container.googleapis.com"
        "compute.googleapis.com"
        "storage.googleapis.com"
        "cloudfunctions.googleapis.com"
        "certificatemanager.googleapis.com"
        "dns.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        log_info "有効化中: $api"
        gcloud services enable $api --project=$PROJECT_ID
    done
    log_success "API有効化完了"
}

# デプロイ実行
deploy() {
    log_info "Kubernetes環境をデプロイ中..."
    
    # 名前空間作成
    log_info "名前空間を作成中..."
    kubectl apply -f namespace.yaml
    
    # 設定ファイルを適用
    log_info "設定ファイルを適用中..."
    kubectl apply -f vpc-config.yaml
    kubectl apply -f cloud-storage-config.yaml
    kubectl apply -f nginx-config.yaml
    kubectl apply -f cloud-functions-proxy.yaml
    kubectl apply -f cloud-functions-integration.yaml
    # Cloud StorageはFunctionsからのみアクセスするため、Kubernetes内での管理は不要
    # kubectl apply -f cloud-storage-bucket.yaml
    # kubectl apply -f cloud-storage-pod.yaml
    kubectl apply -f network-policy.yaml
    kubectl apply -f security-policies.yaml
    
    # デプロイメント完了まで待機
    log_info "デプロイメント完了まで待機中..."
    kubectl wait --for=condition=available --timeout=300s deployment/seimei-handan-functions-proxy -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/security-monitor -n $NAMESPACE
    
    log_success "デプロイ完了！"
    
    # サービス情報を表示
    show_status
}

# 環境削除
destroy() {
    log_warning "Kubernetes環境を削除中..."
    
    # リソースを削除
    kubectl delete -f security-policies.yaml --ignore-not-found=true
    kubectl delete -f network-policy.yaml --ignore-not-found=true
    # Cloud StorageはFunctionsからのみアクセスするため、Kubernetes内での管理は不要
    # kubectl delete -f cloud-storage-pod.yaml --ignore-not-found=true
    # kubectl delete -f cloud-storage-bucket.yaml --ignore-not-found=true
    kubectl delete -f cloud-functions-integration.yaml --ignore-not-found=true
    kubectl delete -f cloud-functions-proxy.yaml --ignore-not-found=true
    kubectl delete -f nginx-config.yaml --ignore-not-found=true
    kubectl delete -f cloud-storage-config.yaml --ignore-not-found=true
    kubectl delete -f vpc-config.yaml --ignore-not-found=true
    kubectl delete -f namespace.yaml --ignore-not-found=true
    
    log_success "環境削除完了"
}

# 状態確認
show_status() {
    log_info "環境の状態を確認中..."
    
    echo ""
    echo "=== 名前空間 ==="
    kubectl get namespaces | grep $NAMESPACE || echo "名前空間が見つかりません"
    
    echo ""
    echo "=== Pods ==="
    kubectl get pods -n $NAMESPACE
    
    echo ""
    echo "=== Services ==="
    kubectl get services -n $NAMESPACE
    
    echo ""
    echo "=== Ingress ==="
    kubectl get ingress -n $NAMESPACE
    
    echo ""
    echo "=== Network Policies ==="
    kubectl get networkpolicies -n $NAMESPACE
    
    echo ""
    echo "=== 外部IPアドレス ==="
    EXTERNAL_IP=$(kubectl get service seimei-handan-api-gateway -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "未設定")
    if [ "$EXTERNAL_IP" != "未設定" ] && [ -n "$EXTERNAL_IP" ]; then
        echo "API Gateway: http://$EXTERNAL_IP"
        echo "ヘルスチェック: http://$EXTERNAL_IP/health"
    else
        echo "外部IPアドレスが設定されていません"
    fi
}

# ログ表示
show_logs() {
    log_info "ログを表示中..."
    
    echo ""
    echo "=== Functions Proxy ログ ==="
    kubectl logs -l app=seimei-handan-functions-proxy -n $NAMESPACE --tail=50
    
    # Cloud StorageはFunctionsからのみアクセスするため、Kubernetes内でのログは不要
    # echo ""
    # echo "=== Storage Manager ログ ==="
    # kubectl logs -l app=seimei-handan-storage-manager -n $NAMESPACE --tail=50
    
    echo ""
    echo "=== Security Monitor ログ ==="
    kubectl logs -l app=security-monitor -n $NAMESPACE --tail=50
}

# メイン処理
main() {
    case $1 in
        deploy)
            check_auth
            set_project
            check_cluster
            enable_apis
            deploy
            ;;
        destroy)
            check_auth
            set_project
            check_cluster
            destroy
            ;;
        status)
            check_auth
            set_project
            check_cluster
            show_status
            ;;
        logs)
            check_auth
            set_project
            check_cluster
            show_logs
            ;;
        *)
            log_error "不明なコマンド: $1"
            echo "使用方法: $0 [deploy|destroy|status|logs]"
            exit 1
            ;;
    esac
}

# 実行
main $1
