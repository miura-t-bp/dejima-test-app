// 表示されたコマンドをクリップボードにコピーする関数
function copyToClipboard(buttonElement) {
    // 親要素から <code> 要素を検索
    const codeElement = buttonElement.parentElement.querySelector("code");
    const commandText = codeElement.textContent || codeElement.innerText;

    // クリップボードにコピー
    navigator.clipboard.writeText(commandText)
        .then(() => {
            buttonElement.innerText = 'コピー済み'
            buttonElement.style.backgroundColor = "rgba(0, 123, 255, 0.3)";
        })
        .catch(err => {
            buttonElement.innerText = 'コピー失敗'
        });
}

document.addEventListener('DOMContentLoaded', function() {
    // テスト環境オプションを設定
    const envOptions = [
        { value: 'dev17', text: 'dev17' },
    ];

    // テスト環境プルダウンメニューにオプションを追加
    const selectElement = document.getElementById('env');
    envOptions.forEach(option => {
        const optionElement = document.createElement('option');
        optionElement.value = option.value;
        optionElement.text = option.text;
        selectElement.appendChild(optionElement);
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
            responseElement.style.height = "auto";
            responseElement.innerHTML = `
                <div style="display: flex; align-items: center;">
                    <pre><code>${data.cmd}</code></pre>
                    <button class="copy-button" onclick="copyToClipboard(this)">コピー</button>
                </div>
            `;
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

    // MercariUS注文作成フォーム送信時の処理
    document.getElementById('form_create_mercarius_order').addEventListener('submit', function(event) {
        event.preventDefault(); // デフォルト送信動作を防止

        // APIリクエストを実行
        callApi('http://localhost:8001/shell/create-mercarius-order/', this, 'create-mercarius-order');
    });

    // Bunjang注文作成フォーム送信時の処理
    document.getElementById('form_create_bunjang_order').addEventListener('submit', function(event) {
        event.preventDefault(); // デフォルト送信動作を防止

        // APIリクエストを実行
        callApi('http://localhost:8001/shell/create-bunjang-order/', this, 'create-bunjang-order');
    });
});
