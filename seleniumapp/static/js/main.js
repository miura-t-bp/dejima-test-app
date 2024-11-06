document.addEventListener('DOMContentLoaded', function() {

    // タブ切り替え関数
    window.openTab = function(evt, tabName) {
        var i, tabcontent, tablinks;

        // 全てのタブコンテンツを非表示にする
        tabcontent = document.getElementsByClassName("tabcontent");
        for (i = 0; i < tabcontent.length; i++) {
            tabcontent[i].style.display = "none";
        }

        // 全てのタブリンクから"active"クラスを削除する
        tablinks = document.getElementsByClassName("tablink");
        for (i = 0; i < tablinks.length; i++) {
            tablinks[i].classList.remove("active");
        }

        // 選択したタブを表示し、"active"クラスを追加する
        document.getElementById(tabName).style.display = "block";
        evt.currentTarget.classList.add("active");
    };

    // フォーム切り替え関数
    window.openForm = function(evt, formId) {
        var i, formtabcontent, formtablinks;

        // 全てのフォームタブコンテンツを非表示にする
        formtabcontent = document.getElementsByClassName("formtabcontent");
        for (i = 0; i < formtabcontent.length; i++) {
            formtabcontent[i].style.display = "none";
        }

        // 全てのフォームタブリンクから"active"クラスを削除する
        formtablinks = document.getElementsByClassName("formtablink");
        for (i = 0; i < formtablinks.length; i++) {
            formtablinks[i].classList.remove("active");
        }

        // 選択したフォームを表示し、"active"クラスを追加する
        document.getElementById(formId).style.display = "block";
        evt.currentTarget.classList.add("active");
    };

    // APIを実行する関数
    function callApi(url, body, responseElementId) {
        const csrfToken = getCSRFToken(); // CSRFトークンを取得
        const responseElement = document.getElementById(responseElementId); // レスポンス表示エリア

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
            body: body
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
                    responseElement.innerHTML += `<a href="${cs_baggage_detail_url}" target="_blank" style="display: block; margin-top: 10px;">詳細画面を開く</a>`;
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

    // テスト環境オプションを設定
    const envOptions = [
        { value: 'dev3', text: 'dev3' },
        { value: 'dev8', text: 'dev8' },
        { value: 'dev15', text: 'dev15' },
        { value: 'dev17', text: 'dev17' },
        { value: 'local', text: 'local' }
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

    // 荷物登録フォーム送信時の処理
    document.getElementById('form_regist_baggage').addEventListener('submit', function(event) {
        event.preventDefault(); // デフォルト送信動作を防止

        // APIリクエストを実行
        callApi('http://localhost:8001/selenium/regist-baggage/', JSON.stringify({
            env: document.getElementById('env').value,
            order_number: document.getElementById('order_number').value,
            service: document.getElementById('service').value,
            quantity: document.getElementById('quantity').value,
            no_weight_regist: document.getElementById('no_weight_regist').checked
        }), 'regist-baggage-response');
    });

    // 重量・寸法登録フォーム送信時の処理
    document.getElementById('form_regist_weight').addEventListener('submit', function(event) {
        event.preventDefault();

        callApi('http://localhost:8001/selenium/regist-baggage-weight/', JSON.stringify({
            env: document.getElementById('env').value,
            baggage_number: document.getElementById('baggage_number_for_regist_weight').value
        }), 'regist-baggage-weight-response');
    });

    // 同梱作業チェック完了フォーム送信時の処理
    document.getElementById('form_bundle_baggage').addEventListener('submit', function(event) {
        event.preventDefault();

        callApi('http://localhost:8001/selenium/bundle-baggage/', JSON.stringify({
            env: document.getElementById('env').value,
            bundle_baggage_number: document.getElementById('bundle_baggage_number').value
        }), 'bundle-baggage-response');
    });

    // インボイス詳細登録フォーム送信時の処理
    document.getElementById('form_invoice_detail_input').addEventListener('submit', function(event) {
        event.preventDefault();

        callApi('http://localhost:8001/selenium/invoice-detail-input/', JSON.stringify({
            env: document.getElementById('env').value,
            baggage_number: document.getElementById('baggage_number_for_invoice_detail_input').value
        }), 'invoice-detail-input-response');
    });

    // CSRFトークンを取得する関数
    function getCSRFToken() {
        return document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    }

});
