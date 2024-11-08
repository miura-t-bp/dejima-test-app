# dejima-test-app

このアプリは `dev` 環境でのみテストを行うことができるもので、Selenium を使用して自動テストを行います。

## 特徴

- **`dev` 環境専用**：本アプリケーションは `dev` 環境でのテスト実行にのみ使用します。
- **Selenium 設定**：Selenium の環境設定は `seleniumapp/static/js/main.js` で定義している `envOptions` の配列にて行います。

## 初期設定

### Docker によるセットアップ

初回起動時にアプリケーションをビルドし、コンテナをバックグラウンドで起動します。

```bash
docker-compose up -d --build
```

### 環境設定

- テスト環境のドメインなどは、`seleniumapp/static/js/main.js` で定義している `envOptions` の配列にて設定可能です。
  
  ```javascript
  const envOptions = [
      { value: 'dev3', text: 'dev3' },
      { value: 'dev8', text: 'dev8' },
      { value: 'dev15', text: 'dev15' },
      { value: 'dev17', text: 'dev17' }
  ];
  ```

## 使用方法

1. Docker コンテナが起動していることを確認します。
2. ブラウザで `http://localhost:8001/selenium/` にアクセスし、アプリケーション画面を表示します。
3. 画面上で各フォームの入力内容を指定し、`荷物登録`や`重量・寸法登録`ボタンをクリックしてテストを実行します。
4. 実行結果が画面下部に表示され、リンクが表示されている場合はそちらから該当のページへアクセスすることができます。

## よくある問題と対処法

（後々追記）

## ローカルでのデバッグ方法

- コンテナ内部での操作が必要な場合、以下のコマンドでコンテナにアクセスできます。
  
  ```bash
  docker exec -it <コンテナ名> /bin/bash
  ```
  
  `コンテナ名` の確認には以下のコマンドが便利です。
  
  ```bash
  docker ps
  ```

