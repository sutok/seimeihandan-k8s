# 姓名判断アプリ - Kubernetes環境

## 概要

このリポジトリは、姓名判断アプリのKubernetes環境構築用のテンプレートとマニフェストファイルを管理します。

## 特徴

- **機密情報の隠蔽**: テンプレート化により機密情報をハードコードから排除
- **セキュアなデプロイ**: Kubernetes Secretと環境変数を使用した安全なデプロイメント
- **モジュラー設計**: 各コンポーネントが独立して管理可能
- **GCP最適化**: Google Cloud Platformに特化した設定

## アーキテクチャ

```
Frontend → Cloud Armor → API Gateway → Cloud Functions → Cloud Storage
```

## ディレクトリ構成

```
kubernetes/
├── templates/                    # テンプレートファイル（バージョン管理対象）
│   ├── vpc-config.template.yaml
│   ├── cloud-functions-integration.template.yaml
│   ├── cloud-storage-config.template.yaml
│   ├── nginx-config.template.yaml
│   ├── cloud-functions-proxy.template.yaml
│   ├── security-policies.template.yaml
│   ├── network-policy.template.yaml
│   └── secrets.template.yaml
├── terraform/                    # Terraform設定
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/                      # デプロイスクリプト
│   ├── generate-manifests.sh
│   ├── generate-secrets.sh
│   └── deploy-secure.sh
├── docs/                        # ドキュメント
│   ├── README.md
│   ├── DEPLOY.md
│   ├── SECURITY.md
│   └── USAGE.md
├── env.example                  # 環境変数テンプレート
├── .gitignore                   # Git除外設定
└── namespace.yaml               # 名前空間定義
```

## 使用方法

### 1. 環境変数の設定

```bash
# 環境変数ファイルを作成
cp env.example .env

# 実際の値を設定
vi .env
```

### 2. マニフェストファイルの生成

```bash
# テンプレートからマニフェストファイルを生成
./generate-manifests.sh

# Secretファイルを生成
./generate-secrets.sh
```

### 3. 環境のデプロイ

```bash
# セキュアなデプロイスクリプトを使用
./deploy-secure.sh deploy
```

## 詳細な技術情報

詳細な技術仕様、デプロイ手順、トラブルシューティングについては、[TECHNICAL_GUIDE.md](./TECHNICAL_GUIDE.md)を参照してください。

## セキュリティ

- 機密情報は環境変数とKubernetes Secretで管理
- 生成されたマニフェストファイルはバージョン管理から除外
- テンプレートファイルのみがバージョン管理対象

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

プルリクエストやイシューの報告を歓迎します。

## サポート

問題が発生した場合は、[Issues](../../issues)で報告してください。
