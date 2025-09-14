# 姓名判断アプリ - Kubernetes環境 Makefile

.PHONY: help setup generate deploy destroy status logs clean

# デフォルトターゲット
help:
	@echo "利用可能なコマンド:"
	@echo "  setup     - 環境をセットアップ"
	@echo "  generate  - マニフェストファイルを生成"
	@echo "  deploy    - 環境をデプロイ"
	@echo "  destroy   - 環境を削除"
	@echo "  status    - 環境の状態を確認"
	@echo "  logs      - ログを表示"
	@echo "  clean     - 生成されたファイルを削除"

# 環境セットアップ
setup:
	@echo "環境をセットアップ中..."
	@if [ ! -f .env ]; then \
		cp env.example .env; \
		echo "環境変数ファイルを作成しました: .env"; \
		echo "実際の値を設定してください: vi .env"; \
	else \
		echo "環境変数ファイルは既に存在します: .env"; \
	fi
	@chmod +x *.sh
	@echo "セットアップ完了"

# マニフェストファイルの生成
generate: setup
	@echo "マニフェストファイルを生成中..."
	@./generate-manifests.sh
	@./generate-secrets.sh
	@echo "生成完了"

# 環境のデプロイ
deploy: generate
	@echo "環境をデプロイ中..."
	@./deploy-secure.sh deploy

# 環境の削除
destroy:
	@echo "環境を削除中..."
	@./deploy-secure.sh destroy

# 状態確認
status:
	@echo "環境の状態を確認中..."
	@./deploy-secure.sh status

# ログ表示
logs:
	@echo "ログを表示中..."
	@./deploy-secure.sh logs

# 生成されたファイルの削除
clean:
	@echo "生成されたファイルを削除中..."
	@rm -f vpc-config.yaml
	@rm -f cloud-functions-integration.yaml
	@rm -f cloud-storage-config.yaml
	@rm -f nginx-config.yaml
	@rm -f cloud-functions-proxy.yaml
	@rm -f security-policies.yaml
	@rm -f network-policy.yaml
	@rm -f secrets.yaml
	@echo "削除完了"

# 完全なクリーンアップ
clean-all: clean
	@echo "完全なクリーンアップ中..."
	@rm -f .env
	@echo "完全なクリーンアップ完了"
