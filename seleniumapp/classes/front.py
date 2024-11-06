# seleniumの必要なライブラリをインポート
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoAlertPresentException
from selenium.common.exceptions import NoSuchElementException

from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service

from datetime import datetime
import time
import sys
import re

LOGIN_ID = "miura_taiki_bp@tenso.com"
LOGIN_PASSWORD = "11111111"

'''
フロントエンド関連操作クラス
'''
class Frontend:

    def __init__(self, main_front_url):

        # Chromeのオプションを設定
        chrome_options = Options()
        # chrome_options.add_argument("--headless")

        # ChromeWebドライバーのインスタンスを生成
        self.driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)

        # CS・WHのURLを設定し環境を確認
        self.main_front_url = main_front_url
        self.is_local = "local" in self.main_front_url
        # confirm_env = input(f"{self.get_env()}環境で実行します。(y/n): ")
        # if confirm_env == 'y':
        #     pass
        # else:
        #     print("処理を中断します。")
        #     exit()

    def login_front(self):
        # ログインページにアクセス
        self.driver.get(self.main_front_url + "signup/login")

        # ローカル環境の場合は「この接続ではプライバシーが保護されません」の画面を突破
        if self.is_local:
            self.driver.find_element(By.ID, "details-button").click()
            self.driver.find_element(By.ID, "proceed-link").click()

        # ログイン情報を入力
        mail = self.driver.find_element(By.NAME, "login[mailAddress]")
        password = self.driver.find_element(By.NAME, "login[password]")
        mail.clear()
        password.clear()
        mail.send_keys(LOGIN_ID)
        password.send_keys(LOGIN_PASSWORD)

        # ログインボタンをクリック
        self.driver.find_element(By.ID, "login_submit").click()

    def order_mercari_item(self, item_id):
        # ログイン
        self.login_front()

        # メルカリ商品詳細ぺージにアクセス
        self.driver.get(self.main_front_url + "mercari/item/" + item_id)

        # 注文依頼ボタンをクリック
        self.driver.find_element(By.CLASS_NAME, "g-button--mercari").click()
        input()
