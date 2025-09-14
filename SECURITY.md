# セキュリティガイド - 機密情報の隠蔽

## 概要

このドキュメントでは、Kubernetesマニフェストファイル内の機密情報（PROJECT_ID等）を隠蔽する方法について説明します。

## 隠蔽方法

### 1. 環境変数を使用した隠蔽

#### 1.1 環境変数ファイルの設定

```bash
# 環境変数ファイルを作成
cp env.example .env

# 実際の値を設定
vi .env
```

#### 1.2 設定例

```bash
# .env ファイルの内容
PROJECT_ID=your_actual_project_id
CLUSTER_NAME=your_actual_cluster_name
REGION=asia-northeast1
FUNCTION_URL=https://asia-northeast1-your_project_id.cloudfunctions.net/seimei-handan-api
DOMAIN_NAME=seimei-handan.shinyudo.com
ALLOWED_IPS=14.8.39.224/32,118.27.125.199/32
```

#### 1.3 マニフェストファイルの生成

```bash
# テンプレートからマニフェストファイルを生成
./generate-manifests.sh
```

### 2. Kubernetes Secretを使用した隠蔽

#### 2.1 Secretファイルの生成

```bash
# Secretファイルを生成
./generate-secrets.sh
```

#### 2.2 Pod内での使用例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: PROJECT_ID
      valueFrom:
        secretKeyRef:
          name: app-config
          key: project-id
```

### 3. 統合デプロイスクリプトの使用

```bash
# マニフェストファイルを生成
./deploy-secure.sh generate

# 環境をデプロイ
./deploy-secure.sh deploy

# 状態を確認
./deploy-secure.sh status

# ログを確認
./deploy-secure.sh logs

# 環境を削除
./deploy-secure.sh destroy
```

## セキュリティベストプラクティス

### 1. ファイルの管理

- `.env` ファイルは `.gitignore` に追加してバージョン管理から除外
- 生成されたマニフェストファイルも `.gitignore` に追加
- テンプレートファイルのみをバージョン管理に含める

### 2. アクセス制御

- 環境変数ファイルの権限を制限: `chmod 600 .env`
- サービスアカウントキーの権限を制限: `chmod 600 *.json`

### 3. 監査

- 定期的にSecretの内容を確認
- 不要なSecretは削除
- アクセスログを監視

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
# envsubstコマンドの確認
which envsubst

# テンプレートファイルの確認
cat templates/vpc-config.template.yaml

# 生成されたファイルの確認
cat vpc-config.yaml
```

### 3. Secretが正しく作成されない

```bash
# Secretの存在確認
kubectl get secrets -n seimei-handan

# Secretの内容確認
kubectl describe secret app-config -n seimei-handan

# Secretの値確認（Base64デコード）
kubectl get secret app-config -n seimei-handan -o jsonpath='{.data.project-id}' | base64 -d
```

## 参考資料

- [Kubernetes Secrets公式ドキュメント](https://kubernetes.io/docs/concepts/configuration/secret/)
- [環境変数の管理](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
- [GCP Secret Manager](https://cloud.google.com/secret-manager/docs)
