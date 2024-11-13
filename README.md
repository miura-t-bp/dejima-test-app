# dejima-test-app

このアプリは `dev` 環境でのみテストを行うことができるもので、Selenium を使用して自動テストを行います。

## 特徴

- **`dev` 環境専用**：本アプリケーションは `dev` 環境でのテスト実行にのみ使用します。
- **Selenium 設定**：Selenium の環境設定は `seleniumapp/static/js/main.js` で定義されている `envOptions` 配列にて行います。

## 初期設定

### Docker によるセットアップ

初回起動時にアプリケーションをビルドし、コンテナをバックグラウンドで起動します。

```bash
docker-compose up -d --build
```

### 環境設定

- テスト環境のドメインなどは、`seleniumapp/static/js/main.js` で定義されている `envOptions` 配列で設定可能です。

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
4. 実行結果が画面下部に表示され、リンクも表示されている場合はそちらから該当のページへアクセスすることができます。

### エラーが起きた場合

エラーが起きた場合は、以下の`ログ関連 > ログ確認方法`を参考に、エラーログを確認してください。

## ログ関連

本アプリでは、`logs` フォルダにログレベルごとにファイルを分けて出力しています。

### ログの種類

- **DEBUG ログ**
  - デバッグの際に使用します。出力先：`logs/debug.log`
- **INFO ログ**
  - テストの実行状況を記録します。出力先：`logs/info.log`
- **ERROR ログ**
  - エラー内容を記録します。出力先：`logs/error.log`

<details><summary><strong>ログ確認方法</strong></summary>
<br>
実行状況をリアルタイムで確認したい場合、以下のコマンドを使用してください。

```bash
tail -f logs/debug.log   # DEBUGログの確認
tail -f logs/info.log    # INFOログの確認
tail -f logs/error.log   # ERRORログの確認
```
</details>

<details><summary><strong>ログ出力方法</strong></summary>
<br>
アプリケーション内でのログの使用例は以下の通りです。各関数内で <code>logger</code> を使って適切なレベルのログを出力できます。

```python
def regist_baggage(data):
    logger.debug("regist_baggage 関数が呼び出されました")
    logger.info(f"登録するデータ: {data}")
    try:
        # 登録処理などを実装
        pass
    except Exception as e:
        logger.error(f"エラーが発生しました: {e}")

```
</details>

## よくある問題と対処法

（後々追記予定）
