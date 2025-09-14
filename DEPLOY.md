GCPプロジェクトでKubernetes環境を構築する手順について、詳細にご説明いたします。

## GCPでKubernetes環境構築の手順

### 1. 事前準備

export PROJECT_ID=your_project_name
export APP_NAME=seimei-handan
export FQDN=${APP_NAME}.shinyudo.com

#### 1.1 GCPアカウントとプロジェクトの準備
```bash
# GCPにログイン
gcloud auth login

# プロジェクトを設定
gcloud config set project ${PROJECT_ID}

# 現在の設定を確認
gcloud config list
```

#### 1.2 必要なAPIの有効化
```bash
# 必要なAPIを有効化
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable certificatemanager.googleapis.com
gcloud services enable dns.googleapis.com
```

### 2. GKEクラスターの作成

#### 2.1 クラスター作成
```bash
# GKEクラスターを作成
gcloud container clusters create ${PROJECT_ID} \
  --region=asia-northeast1 \
  --machine-type=e2-micro \
  --num-nodes=1 \
  --min-nodes=1 \
  --max-nodes=3 \
  --enable-autoscaling \
  --enable-autorepair \
  --enable-autoupgrade \
  --disk-size=20GB \
  --disk-type=pd-standard \
  --image-type=COS_CONTAINERD \
  --enable-ip-alias \
  --network=default \
  --subnetwork=default \
  --enable-network-policy
```

#### 2.2 クラスター接続
```bash
# クラスターに接続
gcloud container clusters get-credentials ${PROJECT_ID} \
  --region=asia-northeast1 \
  --project=${PROJECT_ID}

# 接続確認
kubectl cluster-info
```

### 3. VPCとネットワークの設定

#### 3.1 カスタムVPCの作成（推奨）
```bash
# VPCを作成
gcloud compute networks create ${APP_NAME}-vpc \
  --subnet-mode=custom \
  --project=${PROJECT_ID}

# サブネットを作成
gcloud compute networks subnets create ${APP_NAME}-subnet \
  --network=${APP_NAME}-vpc \
  --range=10.0.0.0/24 \
  --region=asia-northeast1 \
  --secondary-range=${APP_NAME}-pods=10.1.0.0/16,${APP_NAME}-services=10.2.0.0/16 \
  --project=${PROJECT_ID}
```

#### 3.2 ファイアウォールルールの設定
```bash
# 内部通信を許可
gcloud compute firewall-rules create ${APP_NAME}-allow-internal \
  --network=${APP_NAME}-vpc \
  --allow=tcp,udp,icmp \
  --source-ranges=10.0.0.0/24,10.1.0.0/16,10.2.0.0/16 \
  --project=${PROJECT_ID}

# HTTP/HTTPS通信を許可
gcloud compute firewall-rules create ${APP_NAME}-allow-http \
  --network=${APP_NAME}-vpc \
  --allow=tcp:80,tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=${APP_NAME}-gateway \
  --project=${PROJECT_ID}
```

### 4. Cloud Storageバケットの作成

```bash
# バケットを作成
gsutil mb -l asia-northeast1 -c STANDARD gs://${APP_NAME}-bucket

# バケットの設定
gsutil uniformbucketlevelaccess set on gs://${APP_NAME}-bucket
gsutil pap set enforced gs://${APP_NAME}-bucket

# CORS設定
cat > cors.json << EOF
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "responseHeader": ["Content-Type", "Authorization", "X-Requested-With"],
    "maxAgeSeconds": 3600
  }
]
EOF
gsutil cors set cors.json gs://${APP_NAME}-bucket
```

### 5. サービスアカウントの作成

```bash
# サービスアカウントを作成
gcloud iam service-accounts create ${APP_NAME}-sa \
  --display-name="姓名判断アプリ用サービスアカウント" \
  --description="Kubernetes環境用サービスアカウント" \
  --project=${PROJECT_ID}

# 必要な権限を付与
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${APP_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${APP_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudfunctions.invoker"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${APP_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

# サービスアカウントキーを生成
gcloud iam service-accounts keys create ${APP_NAME}-key.json \
  --iam-account=${APP_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=${PROJECT_ID}
```

### 6. Kubernetes環境のデプロイ

#### 6.1 作成したマニフェストファイルを使用
```bash
# プロジェクトディレクトリに移動
cd /Users/kazuh/Documents/GitHub/seimeihandan/kubernetes

# デプロイスクリプトを実行
./deploy.sh deploy
```

#### 6.2 手動デプロイの場合
```bash
# 名前空間を作成
kubectl apply -f namespace.yaml

# 設定ファイルを適用
kubectl apply -f vpc-config.yaml
kubectl apply -f cloud-storage-config.yaml
kubectl apply -f nginx-config.yaml
kubectl apply -f cloud-functions-proxy.yaml
kubectl apply -f cloud-functions-integration.yaml
kubectl apply -f network-policy.yaml
kubectl apply -f security-policies.yaml
```

### 7. 環境の確認

```bash
# クラスターの状態確認
kubectl get nodes

# Podの状態確認
kubectl get pods -n ${APP_NAME}

# サービスの状態確認
kubectl get services -n ${APP_NAME}

# Ingressの状態確認
kubectl get ingress -n ${APP_NAME}

# 外部IPアドレスの確認
kubectl get service ${APP_NAME}-api-gateway -n ${APP_NAME}
```

### 8. ドメインとSSL証明書の設定

#### 8.1 静的IPアドレスの予約
```bash
# 静的IPアドレスを予約
gcloud compute addresses create ${APP_NAME}-ip \
  --global \
  --project=${PROJECT_ID}

# IPアドレスを確認
gcloud compute addresses describe ${APP_NAME}-ip \
  --global \
  --project=${PROJECT_ID}
```

#### 8.2 DNS設定
```bash
# ドメインのAレコードを設定（DNSプロバイダーで実行）
# seimei-handan.shinyudo.com → <静的IPアドレス>
```

#### 8.3 SSL証明書の作成
```bash
# Google管理のSSL証明書を作成
gcloud compute ssl-certificates create ${APP_NAME}-ssl-cert \
  --domains=${FQDN} \
  --global \
  --project=${PROJECT_ID}
```

### 9. 監視とログの設定

#### 9.1 Cloud Monitoringの有効化
```bash
# Monitoring APIを有効化
gcloud services enable monitoring.googleapis.com

# Logging APIを有効化
gcloud services enable logging.googleapis.com
```

#### 9.2 ログの確認
```bash
# アプリケーションログの確認
kubectl logs -l app=${APP_NAME}-functions-proxy -n ${APP_NAME}

# セキュリティログの確認
kubectl logs -l app=security-monitor -n ${APP_NAME}
```

### 10. セキュリティの強化

#### 10.1 Cloud Armorの設定
```bash
# Cloud Armorセキュリティポリシーを作成
gcloud compute security-policies create ${APP_NAME}-armor-policy \
  --description="姓名判断アプリ用セキュリティポリシー" \
  --project=${PROJECT_ID}

# 許可するIPアドレスを設定
gcloud compute security-policies rules create 1000 \
  --security-policy=${APP_NAME}-armor-policy \
  --expression="src.ip in ['14.8.39.224/32', '118.27.125.199/32']" \
  --action=allow \
  --description="許可されたIPアドレスからのアクセス" \
  --project=${PROJECT_ID}

# デフォルトルール（拒否）
gcloud compute security-policies rules create 2147483647 \
  --security-policy=${APP_NAME}-armor-policy \
  --expression="true" \
  --action=deny-403 \
  --description="その他のすべてのアクセスを拒否" \
  --project=${PROJECT_ID}
```

### 11. コスト最適化

#### 11.1 リソース制限の設定
```bash
# ノードプールの設定を確認
gcloud container node-pools list \
  --cluster=${PROJECT_ID} \
  --region=asia-northeast1

# 自動スケーリングの設定
gcloud container clusters update ${PROJECT_ID} \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=3 \
  --region=asia-northeast1
```

### 12. バックアップと災害対策

#### 12.1 設定のバックアップ
```bash
# クラスター設定のエクスポート
kubectl get all -n ${APP_NAME} -o yaml > ${APP_NAME}-backup.yaml

# 設定ファイルのバックアップ
tar -czf kubernetes-config-backup.tar.gz /Users/kazuh/Documents/GitHub/seimeihandan/kubernetes/
```

## 自動化スクリプトの使用

作成したデプロイスクリプトを使用することで、上記の手順を自動化できます：

```bash
# 環境のデプロイ
./deploy.sh deploy

# 状態確認
./deploy.sh status

# ログ確認
./deploy.sh logs

# 環境削除
./deploy.sh destroy
```

この手順に従うことで、GCP上でKubernetes環境を安全かつ効率的に構築できます。各ステップで適切な確認を行い、問題が発生した場合はログを確認してトラブルシューティングを行ってください。