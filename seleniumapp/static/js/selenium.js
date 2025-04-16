document.addEventListener('DOMContentLoaded', function() {
    const selectElement = document.getElementById('env');

    // 初期選択肢(dev17まで)
    const defaultOptions = Array.from({ length: 17 }, (_, i) => {
        const value = `dev${i + 1}`;
        return { value, text: value };
    });

    // localStorage から選択肢をロードする
    function loadOptions() {
        const savedOptions = localStorage.getItem('envOptions');
        if (savedOptions) {
            return JSON.parse(savedOptions);
        }
        return defaultOptions; // 保存されたデータがない場合はデフォルト選択肢を使用
    }

    // 選択肢を保存する
    function saveOptions(options) {
        localStorage.setItem('envOptions', JSON.stringify(options));
    }

    // プルダウンメニューに選択肢を反映
    function populateOptions(options) {
        selectElement.innerHTML = ''; // 既存の選択肢をクリア
        options.forEach(option => {
            const optionElement = document.createElement('option');
            optionElement.value = option.value;
            optionElement.text = option.text;
            selectElement.appendChild(optionElement);
        });
    }

    // 選択肢を追加する
    window.addOption = function() {
        const dev = document.getElementById('newOptionValue').value.trim();

        if (dev) {
            const options = loadOptions();
            options.push({ value: dev, text: dev }); // 選択肢を追加
            saveOptions(options); // 保存
            populateOptions(options); // 更新
            document.getElementById('newOptionValue').value = '';
        } else {
            alert('追加する環境を入力してください。');
        }
    };

    // 選択肢を削除する
    window.removeSelectedOption = function() {
        const selectedIndex = selectElement.selectedIndex;

        if (selectedIndex >= 0) {
            const options = loadOptions();
            options.splice(selectedIndex, 1); // 選択肢を削除
            saveOptions(options); // 保存
            populateOptions(options); // 更新
        } else {
            alert('削除する選択肢を選んでください。');
        }
    };

    // ページロード時に選択肢を復元
    populateOptions(loadOptions());

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

    // ショピング代理購入フォーム送信時の処理
    document.getElementById('form_proxy_shopping').addEventListener('submit', function(event) {
        event.preventDefault();

        callApi('http://localhost:8001/selenium/proxy-shopping/', this, 'proxy-shopping-response');
    });

    // インボイス詳細登録フォーム送信時の処理
    document.getElementById('form_invoice_detail_input').addEventListener('submit', function(event) {
        event.preventDefault();

        callApi('http://localhost:8001/selenium/invoice-detail-input/', this, 'invoice-detail-input-response');
    });
});
