from fastapi import HTTPException, status


class HTTPBaseException(HTTPException):
    code: int = status.HTTP_500_INTERNAL_SERVER_ERROR
    message: str = "Internal Server Error"

    def __init__(self):
        super().__init__(status_code=self.code, detail=self.message)
