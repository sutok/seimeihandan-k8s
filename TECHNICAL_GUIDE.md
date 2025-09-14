# 姓名判断アプリ - Kubernetes環境構築ガイド

## 概要

このドキュメントでは、GCP上でKubernetesを使用してAPI Gateway、Cloud Armor、VPC、Functions、Cloud Storageを利用した環境を構築する手順を説明します。

## アーキテクチャの特徴

- **Cloud Armor**: API Gatewayの前段で動作し、DDoS攻撃や悪意のあるトラフィックをブロック
- **API Gateway**: 負荷分散とSSL終端を提供
- **Cloud Functions**: ビジネスロジックを実行し、Cloud Storageに直接アクセス
- **Cloud Storage**: Functionsからのみアクセス可能で、Kubernetes内での直接管理は不要

## アーキテクチャ

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Cloud Armor   │    │   API Gateway   │
│   (React)       │───▶│  (Security)     │───▶│ (LoadBalancer)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │  Cloud Functions│
                                               │   (Python)      │
                                               └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │  Cloud Storage  │
                                               │   (Bucket)      │
                                               └─────────────────┘
```

## 前提条件

- GCPアカウントを持っていること
- Kubernetesクラスターが作成済みであること
- `gcloud` CLIがインストールされていること
- `kubectl` CLIがインストールされていること

## 設定値

| 項目 | 値 |
|------|-----|
| プロジェクトID | your_project_name |
| クラスター名 | your_project_name |
| リージョン | asia-northeast1 |
| 名前空間 | <your_app_name> |
| API Gateway名 | <<your_app_name>>-gateway |
| Cloud Armorポリシー名 | <<your_app_name>>-armor-policy |
| VPC名 | <<your_app_name>>-vpc |
| Functions名 | <<your_app_name>>-functions |
| Cloud Storageバケット名 | <<your_app_name>>-bucket |

## ファイル構成

```
kubernetes/
├── namespace.yaml                    # 名前空間定義
├── vpc-config.yaml                  # VPC設定
├── cloud-storage-config.yaml        # Cloud Storage基本設定
├── nginx-config.yaml                # Nginx設定
├── cloud-functions-proxy.yaml       # Cloud Functions連携
├── cloud-functions-integration.yaml # Cloud Functions統合設定
├── cloud-storage-bucket.yaml        # Cloud Storageバケット設定
├── cloud-storage-pod.yaml           # Cloud Storage管理Pod
├── network-policy.yaml              # ネットワークポリシー
├── security-policies.yaml           # セキュリティポリシー
├── deploy.sh                        # デプロイスクリプト
└── README.md                        # このファイル
```

## デプロイ手順

### 1. 事前準備

```bash
# GCPにログイン
gcloud auth login

# プロジェクトを設定
gcloud config set project ai-tools-471505

# クラスターに接続
gcloud container clusters get-credentials ai-tools-471505 \
  --region asia-northeast1 \
  --project ai-tools-471505
```

### 2. 環境デプロイ

```bash
# デプロイスクリプトを実行
./deploy.sh deploy
```

### 3. 状態確認

```bash
# 環境の状態を確認
./deploy.sh status

# ログを確認
./deploy.sh logs
```

### 4. 環境削除

```bash
# 環境を削除
./deploy.sh destroy
```

## セキュリティ設定

### Cloud Armorポリシー

- 許可するIPアドレス範囲の設定
- レート制限の適用
- DDoS保護の有効化
- 地理的制限（日本からのアクセスのみ）
- 悪意のあるUser-Agentのブロック

### ネットワークポリシー

- Pod間通信の制限
- 外部通信の制御
- 必要なポートのみ開放

## コスト最適化

### リソース設定

- ノード数: 最小1台、最大3台
- マシンタイプ: e2-micro（最小限のコスト）
- ディスクサイズ: 20GB
- ディスクタイプ: pd-standard

### 自動スケーリング

- 水平Pod自動スケーリング（HPA）の設定
- クラスター自動スケーリングの有効化

## 監視とログ

### ログ収集

- アプリケーションログ
- セキュリティログ
- アクセスログ

### 監視項目

- Podの状態
- サービスの可用性
- リソース使用量
- セキュリティイベント

## トラブルシューティング

### よくある問題

1. **Podが起動しない**
   ```bash
   kubectl describe pod <pod-name> -n <<your_app_name>>
   kubectl logs <pod-name> -n <<your_app_name>>
   ```

2. **サービスにアクセスできない**
   ```bash
   kubectl get services -n <your_app_name>
   kubectl get ingress -n <your_app_name>
   ```

3. **セキュリティポリシーが適用されない**
   ```bash
   kubectl get networkpolicies -n <your_app_name>
   kubectl describe networkpolicy <policy-name> -n <your_app_name>
   ```

### ログ確認

```bash
# 全Podのログ
kubectl logs -l app=<your_app_name>-functions-proxy -n <your_app_name>

# 特定のPodのログ
kubectl logs <pod-name> -n <your_app_name> -f
```

## メンテナンス

### 定期メンテナンス

1. ログローテーションの確認
2. リソース使用量の監視
3. セキュリティアップデートの適用
4. バックアップの確認

### アップデート手順

1. 新しいイメージのビルド
2. 設定ファイルの更新
3. 段階的デプロイ
4. 動作確認

## 参考資料

- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/)
- [GKE公式ドキュメント](https://cloud.google.com/kubernetes-engine/docs)
- [Cloud Armor公式ドキュメント](https://cloud.google.com/armor/docs)
- [Cloud Functions公式ドキュメント](https://cloud.google.com/functions/docs)
- [Cloud Storage公式ドキュメント](https://cloud.google.com/storage/docs)
