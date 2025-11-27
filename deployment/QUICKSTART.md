# Dify GCP Deployment - Quick Start Guide

このガイドでは、最小限のステップでDifyをGCP Compute Engineにデプロイします。

## 前提条件

- GCPプロジェクトとbilling有効化済み
- `gcloud` CLI インストール済み
- `terraform` インストール済み
- 独自ドメイン（SSL証明書用）

## デプロイ手順（10分）

### 1. GCP認証

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### 2. 環境変数設定

```bash
export PROJECT_ID="your-gcp-project-id"
export ZONE="us-central1-a"
export INSTANCE_NAME="dify-server"
export DOMAIN="dify.yourdomain.com"
```

### 3. シークレット生成

```bash
cd deployment
./scripts/setup-secrets.sh
```

### 4. 環境設定ファイル編集

`.env.production` を編集：

```bash
vim .env.production
```

以下を更新：
```env
DOMAIN_NAME=dify.yourdomain.com
CONSOLE_API_URL=https://dify.yourdomain.com
CONSOLE_WEB_URL=https://dify.yourdomain.com
SERVICE_API_URL=https://dify.yourdomain.com
APP_API_URL=https://dify.yourdomain.com
APP_WEB_URL=https://dify.yourdomain.com
FILES_URL=https://dify.yourdomain.com
CERTBOT_EMAIL=your-email@example.com
WEB_API_CORS_ALLOW_ORIGINS=https://dify.yourdomain.com
CONSOLE_CORS_ALLOW_ORIGINS=https://dify.yourdomain.com
```

### 5. Terraform設定

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

以下を更新：
```hcl
project_id  = "your-gcp-project-id"
region      = "us-central1"
zone        = "us-central1-a"
domain_name = "dify.yourdomain.com"
email       = "your-email@example.com"
```

### 6. インフラ構築

```bash
terraform init
terraform apply
```

Terraform出力から静的IPアドレスを取得：
```bash
terraform output static_ip_address
```

### 7. DNS設定

ドメインのDNS設定でAレコードを追加：
- **ホスト名**: `dify` (または `@` if using root domain)
- **タイプ**: A
- **値**: Terraformで取得した静的IP

DNS伝播待ち（最大48時間、通常は数分〜数時間）

### 8. デプロイ実行

```bash
cd ..
./scripts/deploy.sh deploy
```

### 9. アクセス確認

ブラウザで以下にアクセス：
- HTTP: `http://[STATIC_IP]` （即座にアクセス可能）
- HTTPS: `https://dify.yourdomain.com` （DNS伝播後）

初回アクセス時に管理者アカウントを作成します。

## デプロイ後の管理

### ステータス確認

```bash
./scripts/deploy.sh status
```

### ログ確認

```bash
# 全サービスのログ
./scripts/deploy.sh logs

# 特定サービスのログ
./scripts/deploy.sh logs api
./scripts/deploy.sh logs nginx
```

### サービス再起動

```bash
./scripts/deploy.sh restart
```

### SSHアクセス

```bash
./scripts/deploy.sh ssh
```

### バックアップ

```bash
./scripts/backup.sh
```

## トラブルシューティング

### インスタンスにアクセスできない

ファイアウォールルールを確認：
```bash
gcloud compute firewall-rules list --filter="name~dify"
```

### SSL証明書が取得できない

1. DNS設定が正しいか確認
2. ドメインがインスタンスIPを指しているか確認：
   ```bash
   dig dify.yourdomain.com
   ```
3. Certbotログを確認：
   ```bash
   ./scripts/deploy.sh logs nginx
   ```

### コンテナが起動しない

ログを確認：
```bash
./scripts/deploy.sh ssh
cd /opt/dify/docker
docker compose ps
docker compose logs
```

## 次のステップ

### セキュリティ強化

1. SSH アクセス制限：
   ```bash
   # 特定IPのみ許可
   gcloud compute firewall-rules update dify-server-allow-ssh \
     --source-ranges=YOUR_IP/32
   ```

2. Cloud Armor DDoS保護有効化

3. VPCファイアウォール設定

### パフォーマンス最適化

1. インスタンスタイプ変更（必要に応じて）：
   ```bash
   cd terraform
   # terraform.tfvarsでmachine_typeを変更
   terraform apply
   ```

2. データベースチューニング（`.env.production`）：
   ```env
   POSTGRES_SHARED_BUFFERS=512MB
   POSTGRES_EFFECTIVE_CACHE_SIZE=2GB
   ```

### 監視設定

1. Cloud Monitoring ダッシュボード作成
2. アラート設定（CPU、メモリ、ディスク使用率）
3. ログベースのメトリクス設定

### バックアップ自動化

インスタンス上でcron設定：
```bash
./scripts/deploy.sh ssh
crontab -e

# 毎日午前2時にバックアップ
0 2 * * * cd /opt/dify/docker && docker compose exec -T db_postgres pg_dump -U postgres dify > /mnt/dify-data/backups/backup_$(date +\%Y\%m\%d).sql
```

## コスト最適化

### 開発/テスト環境

- インスタンスを使用しない時は停止：
  ```bash
  gcloud compute instances stop dify-server --zone=us-central1-a
  ```

- 起動：
  ```bash
  gcloud compute instances start dify-server --zone=us-central1-a
  ```

### 本番環境

- Committed Use Discounts（長期契約割引）の利用
- Preemptible VM（非本番環境のみ）
- Cloud SQLとCloud Memorystoreの検討（マネージドサービス）

## サポート

問題が発生した場合：

1. [Dify公式ドキュメント](https://docs.dify.ai/)
2. [Dify GitHub Issues](https://github.com/langgenius/dify/issues)
3. [GCP サポート](https://cloud.google.com/support)

## まとめ

基本的なデプロイフローは以上です。本番環境では：
- 定期的なバックアップ
- セキュリティアップデート
- モニタリング設定
- コスト管理

これらを適切に設定することをお勧めします。
