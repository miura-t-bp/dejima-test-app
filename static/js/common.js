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
});
