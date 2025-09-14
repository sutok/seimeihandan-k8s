# 使用方法ガイド - 機密情報の隠蔽

## 概要

このドキュメントでは、機密情報を隠蔽したKubernetes環境の使用方法について説明します。

## 前提条件

- GCPアカウントとプロジェクトが設定済み
- Kubernetesクラスターが作成済み
- `gcloud` と `kubectl` がインストール済み

## セットアップ手順

### 1. 環境変数の設定

```bash
# 環境変数ファイルを作成
cp env.example .env

# 実際の値を設定
vi .env
```

### 2. 設定例

```bash
# .env ファイルの内容例
PROJECT_ID=your_actual_project_id
CLUSTER_NAME=your_actual_cluster_name
REGION=asia-northeast1
FUNCTION_URL=https://asia-northeast1-your_project_id.cloudfunctions.net/seimei-handan-api
DOMAIN_NAME=seimei-handan.shinyudo.com
ALLOWED_IPS=your_allowed_ips_here
```

### 3. マニフェストファイルの生成

```bash
# テンプレートからマニフェストファイルを生成
./generate-manifests.sh

# Secretファイルを生成
./generate-secrets.sh
```

### 4. 環境のデプロイ

```bash
# セキュアなデプロイスクリプトを使用
./deploy-secure.sh deploy
```

## ファイル構成

### テンプレートファイル（バージョン管理対象）
```
templates/
├── vpc-config.template.yaml
├── cloud-functions-integration.template.yaml
├── cloud-storage-config.template.yaml
├── nginx-config.template.yaml
├── cloud-functions-proxy.template.yaml
├── security-policies.template.yaml
├── network-policy.template.yaml
└── secrets.template.yaml
```

### 生成されたファイル（バージョン管理対象外）
```
kubernetes/
├── vpc-config.yaml
├── cloud-functions-integration.yaml
├── cloud-storage-config.yaml
├── nginx-config.yaml
├── cloud-functions-proxy.yaml
├── security-policies.yaml
├── network-policy.yaml
├── secrets.yaml
└── .env
```

## コマンド一覧

### マニフェストファイルの生成
```bash
# すべてのマニフェストファイルを生成
./generate-manifests.sh

# Secretファイルを生成
./generate-secrets.sh
```

### 環境の管理
```bash
# 環境をデプロイ
./deploy-secure.sh deploy

# 状態を確認
./deploy-secure.sh status

# ログを確認
./deploy-secure.sh logs

# 環境を削除
./deploy-secure.sh destroy
```

## セキュリティの確認

### 1. 機密情報の確認
```bash
# 生成されたファイルに機密情報が含まれていないか確認
grep -r "ai-tools-471505" . --exclude-dir=templates --exclude-dir=terraform
```

### 2. Secretの確認
```bash
# Secretが正しく作成されているか確認
kubectl get secrets -n seimei-handan

# Secretの内容確認（Base64デコード）
kubectl get secret app-config -n seimei-handan -o jsonpath='{.data.project-id}' | base64 -d
```

## トラブルシューティング

### 1. 環境変数が読み込まれない
```bash
# 環境変数ファイルの存在確認
ls -la .env

# 環境変数の内容確認
cat .env

# 環境変数の読み込み確認
source .env && echo $PROJECT_ID
```

### 2. テンプレートの置換が正しく動作しない
```bash
# テンプレートファイルの確認
cat templates/vpc-config.template.yaml

# 生成されたファイルの確認
cat vpc-config.yaml
```

### 3. デプロイが失敗する
```bash
# クラスター接続の確認
kubectl cluster-info

# Podの状態確認
kubectl get pods -n seimei-handan

# エラーログの確認
kubectl logs -l app=seimei-handan-functions-proxy -n seimei-handan
```

## ベストプラクティス

### 1. ファイルの管理
- `.env` ファイルは絶対にバージョン管理に含めない
- 生成されたマニフェストファイルもバージョン管理に含めない
- テンプレートファイルのみをバージョン管理に含める

### 2. セキュリティ
- 環境変数ファイルの権限を制限: `chmod 600 .env`
- 定期的にSecretの内容を確認
- 不要なSecretは削除

### 3. 運用
- 環境変数を変更した場合は、マニフェストファイルを再生成
- デプロイ前に生成されたファイルの内容を確認
- 定期的にセキュリティログを監視

## 参考資料

- [Kubernetes Secrets公式ドキュメント](https://kubernetes.io/docs/concepts/configuration/secret/)
- [環境変数の管理](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
- [GCP Secret Manager](https://cloud.google.com/secret-manager/docs)
