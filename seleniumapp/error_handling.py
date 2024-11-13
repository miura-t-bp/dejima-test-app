import traceback
import re

def handle_no_such_element_exception(driver):
    """
    NoSuchElementExceptionを通常の例外として発生させる

    Args:
        driver (WebDriver): 現在のSelenium WebDriverインスタンス

    Raises:
        Exception: NoSuchElementExceptionの詳細なメッセージを含む例外
    """
    # エラートレースを文字列で取得し、正規表現でエラーメッセージを抽出
    match = re.search(r"NoSuchElementException: Message: no such element: (.*)", traceback.format_exc())

    # エラーメッセージを作成
    error_message = (
        f"NoSuchElementExceptionが発生しました。message:{match.group(1)} current_url:{driver.current_url}"
        if match else
        f"NoSuchElementException current_url:{driver.current_url}"
    )

    # 例外を発生させる
    raise Exception(error_message)
