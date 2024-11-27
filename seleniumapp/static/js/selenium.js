document.addEventListener('DOMContentLoaded', function() {
    // テスト環境オプションを設定
    const envOptions = [
        { value: 'dev5', text: 'dev5' },
        { value: 'dev8', text: 'dev8' },
        { value: 'dev15', text: 'dev15' },
        { value: 'dev17', text: 'dev17' }
    ];

    // テスト環境プルダウンメニューにオプションを追加
    const selectElement = document.getElementById('env');
    envOptions.forEach(option => {
        const optionElement = document.createElement('option');
        optionElement.value = option.value;
        optionElement.text = option.text;
        selectElement.appendChild(optionElement);
    });

    // サービスプルダウンの選択肢
    const serviceOptions = [
        { value: '-1', text: '--- 未選択 ---' },
        { value: 'wechat', text: 'WeChat' },
        { value: 'mercarius', text: 'MercariUS' }
    ];

    // サービスプルダウンメニューにオプションを追加
    const serviceSelectElement = document.getElementById('service');
    serviceOptions.forEach(option => {
        const optionElement = document.createElement('option');
        optionElement.value = option.value;
        optionElement.text = option.text;
        serviceSelectElement.appendChild(optionElement);
    });

    // APIを実行する関数
    function callApi(url, form, responseElementId) {
        const csrfToken = getCSRFToken(); // CSRFトークンを取得
        const responseElement = document.getElementById(responseElementId); // レスポンス表示エリア

        // フォームデータを取得
        const formData = new FormData(form);
        const body = Object.fromEntries(formData.entries());

        // 共通の項目を追加
        body.env = document.getElementById('env').value;

        // 結果表示エリアをリセット
        responseElement.innerText = '';
        responseElement.classList.remove('success', 'error');

        // ローディングスピナーを表示
        document.getElementById('loading-spinner').style.display = 'inline-block';

        // APIリクエストを送信
        fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRFToken': csrfToken
            },
            body: JSON.stringify(body)
        })
        .then(response => response.json())
        .then(data => {
            if (data.error == null) {
                let cs_baggage_detail_url = null;
                if (data.cs_baggage_detail_url != null) {
                    cs_baggage_detail_url = data.cs_baggage_detail_url;
                    delete data.cs_baggage_detail_url;
                }
                responseElement.classList.add('success');
                responseElement.innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
                if (cs_baggage_detail_url != null) {
                    responseElement.innerHTML += `<a href="${cs_baggage_detail_url}" target="_blank" style="display: block; margin-top: 10px;">CS荷物詳細画面を開く</a>`;
                }
            } else {
                responseElement.classList.add('error');
                responseElement.innerText = data.error;
            }
        })
        .catch(error => {
            responseElement.classList.add('error');
            responseElement.innerText = 'APIエラー: ' + error.message;
        })
        .finally(() => {
            // ローディングスピナーを非表示
            document.getElementById('loading-spinner').style.display = 'none';
        });
    }

    // CSRFトークンを取得する関数
    function getCSRFToken() {
        return document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    }

    // 荷物登録フォーム送信時の処理
    document.getElementById('form_regist_baggage').addEventListener('submit', function(event) {
        event.preventDefault(); // デフォルト送信動作を防止

        // APIリクエストを実行
        callApi('http://localhost:8001/selenium/regist-baggage/', this, 'regist-baggage-response');
    });

    // 重量・寸法登録フォーム送信時の処理
    document.getElementById('form_regist_weight').addEventListener('submit', function(event) {
        event.preventDefault();

        callApi('http://localhost:8001/selenium/regist-baggage-weight/', this, 'regist-baggage-weight-response');
    });

    // 同梱作業チェック完了フォーム送信時の処理
    document.getElementById('form_bundle_baggage').addEventListener('submit', function(event) {
        event.preventDefault();

        callApi('http://localhost:8001/selenium/bundle-baggage/', this, 'bundle-baggage-response');
    });

    // インボイス詳細登録フォーム送信時の処理
    document.getElementById('form_invoice_detail_input').addEventListener('submit', function(event) {
        event.preventDefault();

        callApi('http://localhost:8001/selenium/invoice-detail-input/', this, 'invoice-detail-input-response');
    });
});
