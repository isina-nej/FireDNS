import google.auth.transport.requests
from google.oauth2 import service_account
import json

# مسیر فایل service account credentials
CREDENTIALS_PATH = 'assets/config/firebase-service-account.json'

# اسکوپ مورد نیاز برای FCM
SCOPES = ['https://www.googleapis.com/auth/firebase.messaging']

def generate_access_token():
    # خواندن credentials از فایل
    credentials = service_account.Credentials.from_service_account_file(
        CREDENTIALS_PATH,
        scopes=SCOPES
    )
    
    # به‌روزرسانی توکن
    auth_req = google.auth.transport.requests.Request()
    credentials.refresh(auth_req)
    
    print(f"Access Token: Bearer {credentials.token}")
    print(f"Expires in: {credentials.expiry}")

if __name__ == '__main__':
    generate_access_token()
