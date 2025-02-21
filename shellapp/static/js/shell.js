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
    const selectElement = document.getElementById('env');

    // 初期選択肢(dev17までとローカル)
    const defaultOptions = Array.from({ length: 17 }, (_, i) => {
        const value = `dev${i + 1}`;
        return { value, text: value };
    });
    defaultOptions.push({ value: 'local', text: 'local' });

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

    // WeChat注文作成フォーム送信時の処理
    document.getElementById('form_create_wechat_order').addEventListener('submit', function(event) {
        event.preventDefault(); // デフォルト送信動作を防止

        // APIリクエストを実行
        callApi('http://localhost:8001/shell/create-wechat-order/', this, 'wechat');
    });

    // WeChat荷物決済フォーム送信時の処理
    document.getElementById('form_wechat_baggage_settlement').addEventListener('submit', function(event) {
        event.preventDefault(); // デフォルト送信動作を防止

        // APIリクエストを実行
        callApi('http://localhost:8001/shell/wechat-baggage-settlement/', this, 'wechat');
    });
});
