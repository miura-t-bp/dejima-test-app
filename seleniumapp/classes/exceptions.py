class ScreenError(Exception):
    """
    画面上に表示されるエラーメッセージ例外として扱うためのクラス
    """

    def __init__(self, message, current_url=None):
        super().__init__(message)
        self.current_url = current_url

    def __str__(self):
        base_message = super().__str__()
        res = f"画面上にエラーメッセージが表示されています。message:{base_message}"
        if self.current_url:
            res += f" current_url:{self.current_url}"
        return res
