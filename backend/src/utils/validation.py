import re


def validate_username(username: str) -> bool:
    return len(username) >= 8


def validate_user_password(password: str) -> bool:
    if not password:
        return False
    if len(password) < 8:
        return False
    if not re.search(r"[A-Z]", password):
        return False
    if not re.search(r"[a-z]", password):
        return False
    if not re.search(r"[0-9]", password):
        return False
    return True
