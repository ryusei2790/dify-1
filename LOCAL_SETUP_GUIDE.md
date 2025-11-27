# Dify ローカル環境セットアップ完全ガイド

Docker起動からDifyログインまでの全手順を詳しく説明します。

## 📋 前提条件

- Docker Desktop がインストールされている
- Docker Desktop が起動している
- 8GB以上のメモリ推奨

## 🚀 完全セットアップ手順

### ステップ1: Docker Desktop起動確認

```bash
# Docker Desktop が起動しているか確認
docker --version
docker compose version

# Docker が応答するか確認
docker ps
```

**期待される出力:**
```
Docker version 24.x.x
Docker Compose version v2.x.x
```

### ステップ2: Difyディレクトリに移動

```bash
cd /Users/ryusei/dev-environment/dify/docker
```

### ステップ3: 環境設定ファイル確認

```bash
# .envファイルが存在するか確認
ls -la .env

# もし存在しない場合は作成
cp .env.example .env
```

### ステップ4: Dockerコンテナ起動

```bash
# バックグラウンドで全サービスを起動
docker compose up -d
```

**起動プロセス:**
1. Dockerイメージのダウンロード（初回のみ、数分かかります）
2. コンテナの作成
3. ネットワークの作成
4. サービスの起動

**起動完了の確認:**
```bash
docker compose ps
```

**期待される出力（全てのSTATUSがUp）:**
```
NAME                     STATUS
docker-api-1             Up
docker-db_postgres-1     Up (healthy)
docker-nginx-1           Up
docker-plugin_daemon-1   Up
docker-redis-1           Up (healthy)
docker-sandbox-1         Up (healthy)
docker-ssrf_proxy-1      Up
docker-weaviate-1        Up
docker-web-1             Up
docker-worker-1          Up
docker-worker_beat-1     Up
```

### ステップ5: ログで起動状態確認

```bash
# 全体のログ確認（最後の50行）
docker compose logs --tail=50

# APIサーバーのログ確認
docker compose logs api --tail=20

# Nginxのログ確認
docker compose logs nginx --tail=20
```

**正常起動時のログ例:**
```
api-1    | [INFO] Starting gunicorn
api-1    | [INFO] Listening at: http://0.0.0.0:5001
nginx-1  | [notice] start worker processes
```

### ステップ6: ブラウザでアクセス

以下のいずれかのURLをブラウザで開きます：

- **http://localhost**
- **http://127.0.0.1**
- **http://localhost:80**

### ステップ7: 初回セットアップ（管理者アカウント作成）

ブラウザで初めてアクセスすると、**セットアップ画面**が表示されます。

#### 7-1. 言語選択
- 日本語または English を選択

#### 7-2. 管理者アカウント作成画面

以下の情報を入力：

| 項目 | 説明 | 例 |
|------|------|-----|
| **メールアドレス** | 管理者のメールアドレス | admin@example.com |
| **名前** | 管理者の表示名 | Admin User |
| **パスワード** | ログイン用パスワード（8文字以上） | SecurePass123! |
| **パスワード確認** | パスワード再入力 | SecurePass123! |

#### 7-3. 「続ける」をクリック

アカウント作成が完了すると、自動的にDifyのダッシュボードにログインされます。

### ステップ8: Difyダッシュボード確認

初回ログイン後、以下が表示されます：

1. **ウェルカム画面** または **チュートリアル**
2. **スタジオ（Studio）**: アプリケーション作成画面
3. **ナレッジ（Knowledge）**: RAGデータソース管理
4. **ツール**: 外部ツール連携
5. **設定**: システム設定

### ステップ9: テストアプリ作成（オプション）

#### 簡単なチャットボット作成:

1. 「スタジオ」→「空のアプリを作成」
2. アプリタイプ: 「チャットアシスタント」選択
3. 名前: 「テストボット」と入力
4. 「作成」をクリック
5. プロンプト入力欄に以下を入力:
   ```
   あなたは親切なアシスタントです。
   ユーザーの質問に丁寧に答えてください。
   ```
6. 「公開」をクリック
7. 右側のプレビューでテスト

## 🔄 日常的な起動・停止手順

### 起動（2回目以降）

```bash
cd /Users/ryusei/dev-environment/dify/docker
docker compose up -d
```

起動後、**1-2分待ってから** http://localhost にアクセス

### 停止

```bash
cd /Users/ryusei/dev-environment/dify/docker
docker compose down
```

**データは保持されます**（ボリュームが削除されないため）

### 完全削除（データも削除）

```bash
# ⚠️ 警告: 全データが削除されます
docker compose down -v
```

## 🐛 トラブルシューティング

### 問題1: ブラウザで接続できない

**確認事項:**
```bash
# 1. コンテナが起動しているか
docker compose ps

# 2. nginxが80番ポートでListenしているか
docker compose ps nginx

# 3. ポートが使用されているか
lsof -i :80

# 4. nginxログ確認
docker compose logs nginx
```

**解決策:**
- 他のアプリが80番ポートを使用している場合は停止
- Dockerを再起動
- コンテナを再起動: `docker compose restart`

### 問題2: "502 Bad Gateway"エラー

**原因:** APIサーバーがまだ起動中

**解決策:**
```bash
# APIサーバーのログ確認
docker compose logs api

# "Listening at: http://0.0.0.0:5001" が表示されるまで待つ
# 通常1-2分かかります
```

### 問題3: データベースエラー

**解決策:**
```bash
# データベースコンテナの再起動
docker compose restart db_postgres

# データベースログ確認
docker compose logs db_postgres

# healthyステータスになるまで待つ
docker compose ps db_postgres
```

### 問題4: 既存のコンテナとポート競合

**解決策:**
```bash
# 80番ポートを使用しているプロセスを確認
lsof -i :80

# 他のDockerコンテナを確認
docker ps -a

# 不要なコンテナを停止
docker stop <container_id>
```

### 問題5: ログイン画面が表示されない

**解決策:**
```bash
# ブラウザのキャッシュをクリア
# Chrome: Cmd+Shift+R (Mac) / Ctrl+Shift+R (Windows)

# プライベートブラウジングモードで試す

# 別のブラウザで試す
```

## 📊 リソース使用量確認

```bash
# コンテナのリソース使用状況
docker stats

# ディスク使用量
docker system df
```

## 🔐 セキュリティ（ローカル開発）

ローカル開発環境では以下がデフォルト:

- **Database Password**: difyai123456
- **Redis Password**: difyai123456
- **Secret Key**: sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U

⚠️ **本番環境ではこれらを必ず変更してください**

## 📝 よく使うコマンド

```bash
# サービス一覧
docker compose ps

# 特定サービスのログ
docker compose logs -f api        # APIサーバー
docker compose logs -f web        # フロントエンド
docker compose logs -f worker     # バックグラウンドワーカー
docker compose logs -f db_postgres # データベース

# サービスの再起動
docker compose restart api
docker compose restart nginx

# 特定サービスのみ起動/停止
docker compose up -d nginx
docker compose stop worker

# コンテナ内でコマンド実行
docker compose exec api bash
docker compose exec db_postgres psql -U postgres dify

# イメージの更新
docker compose pull
docker compose up -d

# ボリューム確認
docker volume ls | grep docker
```

## 🎯 次のステップ

1. **LLMプロバイダー設定**
   - 設定 → モデルプロバイダー
   - OpenAI, Anthropic, Azure OpenAI などを設定

2. **最初のアプリケーション作成**
   - チャットボット
   - テキスト生成
   - エージェント

3. **ナレッジベース作成**
   - PDFアップロード
   - Webページ取り込み
   - RAG (Retrieval-Augmented Generation) 設定

4. **APIキー発行**
   - 設定 → API Keys
   - 外部アプリケーションからの呼び出し

## 📞 サポート

問題が解決しない場合:

1. [Dify公式ドキュメント](https://docs.dify.ai/)
2. [GitHub Issues](https://github.com/langgenius/dify/issues)
3. [Discord コミュニティ](https://discord.gg/dify)

## ✅ セットアップ完了チェックリスト

- [ ] Docker Desktop が起動している
- [ ] `docker compose ps` で全サービスが Up
- [ ] http://localhost にアクセスできる
- [ ] 管理者アカウントを作成した
- [ ] ダッシュボードにログインできた
- [ ] テストアプリを作成できた（オプション）

全てチェックが付いたら、セットアップ完了です！🎉
