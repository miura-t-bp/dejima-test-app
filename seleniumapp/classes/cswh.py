# seleniumの必要なライブラリをインポート
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoAlertPresentException
from selenium.common.exceptions import NoSuchElementException

from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service

from datetime import datetime
import time
import sys
import re
import os

from .exceptions import ScreenError
from seleniumapp.error_handling import handle_no_such_element_exception

LOGIN_ID = "stgcs01@buyee.jp"
LOGIN_PASSWORD = "11111111"

'''
CS・WH関連操作クラス
'''
class CsWh:

    def __init__(self, env):

        # Chromeのオプションを設定
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--disable-extensions")
        chrome_options.add_argument("--disable-software-rasterizer")
        chrome_options.add_argument("--remote-debugging-port=9222")

        # ChromeWebドライバーのインスタンスを生成
        self.driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)

        # CS・WHのURLを設定
        if env == "local":
            self.main_cs_url = "https://cs.dejima.local/"
            self.main_wh_url = "https://warehouse.dejima.local/"
            self.is_local = True
        else:
            self.main_cs_url = "https://cs." + env + ".buyee.jp/"
            self.main_wh_url = "https://warehouse." + env + ".buyee.jp/"
            self.is_local = False

        self.is_logged_in_cs = False
        self.is_logged_in_wh = False

    def login_cs(self):
        """
        CS管理画面にログインする。
        """
        # ログインページにアクセス
        self.driver.get(self.main_cs_url + "index.php/")

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
        self.driver.find_element(By.XPATH, "//input[@value='ログイン (Login)']").click()

        # ログイン済みフラグを立てる
        self.is_logged_in_cs = True

    def login_wh(self):
        """
        WH管理画面にログインする。
        """
        # ログインページにアクセス
        self.driver.get(self.main_wh_url + "login")

        # ローカル環境の場合は「この接続ではプライバシーが保護されません」の画面を突破
        if self.is_local:
            self.driver.find_element(By.ID, "details-button").click()
            self.driver.find_element(By.ID, "proceed-link").click()

        # ログイン情報を入
        mail = self.driver.find_element(By.NAME, "login[mailAddress]")
        password = self.driver.find_element(By.NAME, "login[password]")
        mail.clear()
        password.clear()
        mail.send_keys(LOGIN_ID)
        password.send_keys(LOGIN_PASSWORD)

        # ログインボタンをクリック
        self.driver.find_element(By.XPATH, "//input[@value='ログイン (Log in)']").click()

        # ログイン済みフラグを立てる
        self.is_logged_in_wh = True

    def get_latest_order_number_by_service(self, service: str) -> str:
        """
        指定されたサービス注文の注文番号を取得する
        - 注文ステータスが代理購入済み国内配送番号確定待ちの注文を取得

        Args:
            service (str): サービス名

        Returns:
            str: 注文番号
        """

        # CS管理画面にログイン
        if not self.is_logged_in_cs:
            self.login_cs()

        # メルカリ注文検索ページにアクセス
        self.driver.get(self.main_cs_url + "shopping/mercariSearch")

        # 引数で受け取ったサービスの注文にチェック
        check_box_name = "search[is_" + service + "_order]"
        self.driver.find_element(By.NAME, check_box_name).click()
        # 注文ステータスに代理購入済み国内配送番号確定待ちを選択
        status_select = Select(self.driver.find_element(By.ID, "search_status"))
        status_select.select_by_value("35")
        # 並び替えに降順を選択
        sort_select = Select(self.driver.find_element(By.NAME, "search[sort]"))
        sort_select.select_by_value("1")

        # 検索ボタンをクリック
        self.driver.find_element(By.CLASS_NAME, "search_order_btn").click()

        # 検索結果のテーブルを取得
        table = self.driver.find_element(By.ID, "data_table")
        first_row = table.find_element(By.XPATH, "./tbody/tr[2]")
        order_number_column = first_row.find_element(By.XPATH, "./td[2]/a")

        # 最新の注文番号
        return order_number_column.text

    def get_latest_order_numbers_by_service(self, service: str, quantity: int) -> list:
        """
        指定されたサービス注文の注文番号を複数取得しリストで返す
        - 注文ステータスが代理購入済み国内配送番号確定待ちの注文を取得

        Args:
            service  (str): サービス名
            quantity (int): 取得する注文番号の個数

        Returns:
            order_numbers: 注文番号のリスト
        """

        # CS管理画面にログイン
        if not self.is_logged_in_cs:
            self.login_cs()

        # メルカリ注文検索ページにアクセス
        self.driver.get(self.main_cs_url + "shopping/mercariSearch")

        # 引数で受け取ったサービスの注文にチェック
        check_box_name = "search[is_" + service + "_order]"
        self.driver.find_element(By.NAME, check_box_name).click()
        # 注文ステータスに代理購入済み国内配送番号確定待ちを選択
        status_select = Select(self.driver.find_element(By.ID, "search_status"))
        status_select.select_by_value("35")
        # 並び替えに降順を選択
        sort_select = Select(self.driver.find_element(By.NAME, "search[sort]"))
        sort_select.select_by_value("1")

        # 検索ボタンをクリック
        self.driver.find_element(By.CLASS_NAME, "search_order_btn").click()

        # 検索結果のテーブルを取得
        table = self.driver.find_element(By.ID, "data_table")

        # 指定された個数分の注文番号を上から取得
        order_numbers = []
        for i in range(2, quantity + 2):
            row = table.find_element(By.XPATH, "./tbody/tr[" + str(i) + "]")
            order_number_column = row.find_element(By.XPATH, "./td[2]/a")
            order_numbers.append(order_number_column.text)

        # 注文番号のリストを返す
        return order_numbers

    def get_latest_order_number_by_member_id(self, member_id: int) -> str:
        """
        最新の指定された会員IDの注文番号を取得する
        - 注文ステータスが代理購入済み国内配送番号確定待ちの注文を取得

        Args:
            service (int): 会員ID

        Returns:
            str: 注文番号
        """

        # CS管理画面にログイン
        if not self.is_logged_in_cs:
            self.login_cs()

        # メルカリ注文検索ページにアクセス
        self.driver.get(self.main_cs_url + "shopping/mercariSearch")

        # 指定の会員IDを入力
        member_id_input = self.driver.find_element(By.ID, "search_member_id")
        member_id_input.clear()
        member_id_input.send_keys(member_id)
        # 注文ステータスに代理購入済み国内配送番号確定待ちを選択
        status_select = Select(self.driver.find_element(By.ID, "search_status"))
        status_select.select_by_value("35")
        # 並び替えに降順を選択
        sort_select = Select(self.driver.find_element(By.NAME, "search[sort]"))
        sort_select.select_by_value("1")

        # 検索ボタンをクリック
        self.driver.find_element(By.CLASS_NAME, "search_order_btn").click()

        # 検索結果のテーブルを取得
        table = self.driver.find_element(By.ID, "data_table")
        first_row = table.find_element(By.XPATH, "./tbody/tr[2]")
        order_number_column = first_row.find_element(By.XPATH, "./td[2]/a")

        # 最新の注文番号
        return order_number_column.text

    def cart_order(self):
        """
        ステータスが代理購入待ちであるMercariUSの注文詳細画面を開く
        """

        # CS管理画面にログイン
        if not self.is_logged_in_cs:
            self.login_cs()

        # メルカリ注文検索ページにアクセス
        self.driver.get(self.main_cs_url + "shopping/mercariSearch")

        # MercariUSの注文にチェック
        check_box_name = "search[is_mercarius_order]"
        self.driver.find_element(By.NAME, check_box_name).click()
        # 注文ステータスに代理購入待ちを選択
        status_select = Select(self.driver.find_element(By.ID, "search_status"))
        status_select.select_by_value("31")
        # 並び替えに降順を選択
        sort_select = Select(self.driver.find_element(By.NAME, "search[sort]"))
        sort_select.select_by_value("1")

        # 検索ボタンをクリック
        self.driver.find_element(By.CLASS_NAME, "search_order_btn").click()

        # 検索結果のテーブルを取得
        table = self.driver.find_element(By.ID, "data_table")
        first_row = table.find_element(By.XPATH, "./tbody/tr[2]")
        order_number_column = first_row.find_element(By.XPATH, "./td[2]/a")

        # 注文詳細画面に遷移
        order_number_column.click()
        input()

    def invoice_detail_input(self, baggage_number) -> None:
        """
        インボイス詳細登録を行う（DHL）

        Args:
            baggage_number (str): インボイス詳細登録を行う荷物番号

        Returns:
            None: なし

        Raises:
            Exception: インボイス詳細登録が失敗した場合、エラーメッセージと共に例外を発生させます。
        """
        try:
            # CS管理画面にログイン
            if not self.is_logged_in_cs:
                self.login_cs()

            # インボイス詳細登録画面にアクセス
            self.driver.get(self.main_cs_url + "index.php/baggage/invoiceDetailInput/baggageno/" + baggage_number)
            time.sleep(2)

            # 郵便番号を入力
            zipcode_input = self.driver.find_element(By.NAME, "invoice[dhlZipCode]")
            zipcode_input.clear()
            zipcode_input.send_keys("110")

            # 確認ボタンをクリック
            self.driver.find_element(By.ID, "btn_dhl_confirm").click()

            # 郵便番号の選択肢の要素を取得し、一番上の要素を選択
            dhl_zipcode_select = Select(self.driver.find_element(By.ID, "select_dhl_post"))
            time.sleep(2)
            dhl_zipcode_select.select_by_index(0)

            # 登録ボタンをクリック
            self.driver.find_element(By.XPATH, "//input[@value='登録']").click()

            # エラーメッセージが表示されていないか確認
            try:
                err_message = self.driver.find_element(By.CLASS_NAME, "error_message")
                raise ScreenError(err_message.text, self.driver.current_url)
            except NoSuchElementException:
                pass

        except NoSuchElementException as e:
            handle_no_such_element_exception(self.driver)
        except Exception as e:
            raise

    def regist_baggage(self, order_number, baggage_number = None) -> str:
        """
        日野倉庫で荷物登録を行う
        - 登録する荷物の荷物番号の日付の部分は登録時の日付、下四桁は注文番号の下四桁を使用

        Args:
            order_number   (str): 荷物登録する注文の注文番号
            baggage_number (str): 荷物登録時に使用する荷物番号

        Returns:
            str : 荷物登録した荷物の荷物番号

        Raises:
            Exception: 荷物登録が失敗した場合、エラーメッセージと共に例外を発生させます。
        """
        try:
            # WH管理画面にログイン
            if not self.is_logged_in_wh:
                self.login_wh()

            # 荷物登録用検索画面にアクセス
            self.driver.get(self.main_wh_url + "index.php/regist/search")

            # 荷物番号が指定されいない場合は注文番号から生成
            baggage_number = baggage_number if baggage_number else "W" + datetime.now().strftime("%y%m%d") + order_number[-4:]

            # 荷物登録画面のN注文番号の検索フォームに注文番号を入力
            input_element = self.driver.find_element(By.XPATH, "//input[@name='registSearch[order_number]' and @value='" + order_number[0] + "']")
            input_element.clear()
            input_element.send_keys(order_number)

            # 検索ボタンをクリック
            td_element = input_element.find_element(By.XPATH, "./ancestor::td")
            td_element.find_element(By.XPATH, "./following-sibling::td//input[@value='検索']").click()

            # 荷物登録済みアラートが表示されていないか確認
            try:
                alert = self.driver.find_element(By.CLASS_NAME, "baggage_partial_alert")
                raise ScreenError("この注文は荷物登録済みです。", self.driver.current_url)
            except NoSuchElementException:
                pass

            # 荷物登録
            self.driver.find_element(By.NAME, "registBaggage[baggage_number]").send_keys(baggage_number)
            self.driver.find_element(By.ID, "regist_btn").click()

            # アラートがでたらOKをクリック
            try:
                alert = self.driver.switch_to.alert
                alert.accept()
            except NoAlertPresentException:
                pass

            return baggage_number

        except NoSuchElementException as e:
            handle_no_such_element_exception(self.driver)
        except Exception as e:
            raise

    def regist_weight(self, baggage_number, weight_gram=500, length_mm=100, width_mm=100, height_mm=100) -> None:
        """
        指定された荷物番号の荷物の重量・寸法登録を行う
        - エラーメッセージが表示されている場合は、例外を発生させて終了

        Args:
            baggage_number (str): 重量・寸法登録する注文の注文番号
            weight_gram    (int): 重量（グラム）
            length_mm      (int): 縦（ミリ）
            width_mm       (int): 横（ミリ）
            height_mm      (int): 高さ（ミリ）

        Returns:
            None: なし

        Raises:
            Exception: 重量・寸法登録が失敗した場合、エラーメッセージと共に例外を発生させます。
        """
        try:
            # WH管理画面にログイン
            if not self.is_logged_in_wh:
                self.login_wh()

            # 重力・寸法登録画面にアクセス
            self.driver.get(self.main_wh_url + "index.php/measurement/baggageNumberInput")

            # 重力・寸法登録
            baggage_number_input = self.driver.find_element(By.NAME, "readBaggageNumber[baggage_number]")
            baggage_number_input.send_keys(baggage_number)
            baggage_number_input.send_keys(Keys.RETURN)

            time.sleep(2)

            weight_gram_input = self.driver.find_element(By.NAME, "registerWeight[weight_gram]")
            weight_gram_input.send_keys(weight_gram)  # 重量
            self.driver.find_element(By.NAME, "registerWeight[size_long_mm]").send_keys(length_mm)  # 縦
            self.driver.find_element(By.NAME, "registerWeight[size_wide_mm]").send_keys(width_mm)  # 横
            self.driver.find_element(By.NAME, "registerWeight[size_height_mm]").send_keys(height_mm)  # 高さ
            weight_gram_input.send_keys(Keys.RETURN)

            # エラーメッセージが表示されていないか確認
            try :
                error_list = self.driver.find_element(By.CLASS_NAME, "error_list")
                for error in error_list.find_elements(By.TAG_NAME, "p"):
                    if error.text:
                        raise ScreenError(error.text, self.driver.current_url)
            except NoSuchElementException:
                pass

        except NoSuchElementException as e:
            handle_no_such_element_exception(self.driver)
        except Exception as e:
            raise

    def bundle_baggage(self, bundle_baggage_number) -> None:
        """
        指定された同梱荷物の同梱作業チェックを行う
        - 同梱完了にする
        - 重量・寸法登録は行わない

        Args:
            bundle_baggage_number (str): 同梱作業を行う荷物番号

        Returns:
            None: なし

        Raises:
            Exception: 同梱作業チェックが失敗した場合、エラーメッセージと共に例外を発生させます。
        """
        try:
            # WH管理画面にログイン
            if not self.is_logged_in_wh:
                self.login_wh()

            # 同梱作業チェック画面にアクセス
            self.driver.get(self.main_wh_url + "index.php/bundle/baggage")

            # 同梱荷物番号を入力
            bundle_baggage_number_input = self.driver.find_element(By.NAME, "bundleBaggageNumber[baggage_number]")
            bundle_baggage_number_input.send_keys(bundle_baggage_number)
            bundle_baggage_number_input.send_keys(Keys.RETURN)

            # 画面遷移待ち
            time.sleep(1)

            try:
                # 被同梱荷物番号を取得
                div_element = self.driver.find_element(By.ID, "view_bundled_baggage_number")
                div_text = div_element.text
                bundled_baggage_numbers = re.findall(r'W\d+', div_text)
                for bundled_baggage_number in bundled_baggage_numbers:
                    bundled_baggage_number_input = self.driver.find_element(By.NAME, "bundleBaggage[bundle_baggage_number]")
                    bundled_baggage_number_input.send_keys(bundled_baggage_number)
                    bundled_baggage_number_input.send_keys(Keys.RETURN)
            except NoSuchElementException:
                pass

            # 画面遷移待ち
            time.sleep(1)

            # 同梱作業を完了
            self.driver.find_element(By.XPATH, "//input[@value='同梱完了する (Bundling Complete)']").click()

            # 同梱完了した荷物番号を入力
            complete_baggage_number_input = self.driver.find_element(By.ID, "baggage_number")
            complete_baggage_number_input.send_keys(bundle_baggage_number)
            complete_baggage_number_input.send_keys(Keys.RETURN)

        except NoSuchElementException as e:
            handle_no_such_element_exception(self.driver)
        except Exception as e:
            raise

    def get_baggage_status_and_detail_url(self, baggage_number) -> (str, str):
        """
        指定された荷物番号のCS荷物詳細画面から荷物のステータスとURLを取得する

        Args:
            baggage_number (str): 荷物番号

        Returns:
            str: 荷物ステータス
            str: CS荷物詳細画面のURL
        """

        # WH管理画面にログイン
        if not self.is_logged_in_cs:
            self.login_cs()

        # 荷物詳細画面にアクセス
        self.driver.get(self.main_cs_url + "index.php/baggage/detail/baggageno/" + baggage_number)

        # 荷物のステータスを取得
        status = self.driver.find_element(By.ID, "header_baggage_status").text

        # 荷物の詳細画面のURLを取得
        detail_url = self.driver.current_url

        return status, detail_url
