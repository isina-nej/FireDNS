import json
import os
from datetime import datetime
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# Configuration
SERVICE_ACCOUNT_FILE = 'service-account.json'
SCOPES = ['https://www.googleapis.com/auth/firebase.messaging']

def get_access_token():
    """Obtain an access token using service account credentials."""
    try:
        # Check if service account file exists
        if not os.path.exists(SERVICE_ACCOUNT_FILE):
            raise FileNotFoundError(f"Service account file {SERVICE_ACCOUNT_FILE} not found")

        # Create credentials
        credentials = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE,
            scopes=SCOPES
        )

        # Refresh credentials if needed
        if credentials.expired and credentials.refresh_token:
            credentials.refresh(Request())
        
        return credentials.token

    except Exception as e:
        raise Exception(f"Failed to get access token: {str(e)}")

def main():
    # Warning: Hardcoding credentials is insecure and should be avoided
    # Consider using environment variables or a secure vault solution
    service_account_info = {
        "type": "service_account",
        "project_id": "dns-changer-a1046",
        "private_key_id": "6e74ccba0882addfdf6d297ece37c05f1e980b12",
        "private_key": "-----BEGIN PRIVATE KEY-----\n[...]\n-----END PRIVATE KEY-----\n",
        "client_email": "firebase-adminsdk-fbsvc@dns-changer-a1046.iam.gserviceaccount.com",
        "client_id": "111395549651328681820",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40dns-changer-a1046.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
    }

    try:
        # Save service account info to a temporary file
        with open(SERVICE_ACCOUNT_FILE, 'w') as f:
            json.dump(service_account_info, f)

        # Get and print access token
        token = get_access_token()
        print("\n=== Access Token ===")
        print(token)
        print("==================\n")

    except Exception as e:
        print(f"Error: {str(e)}")

    finally:
        # Clean up the service account file
        try:
            if os.path.exists(SERVICE_ACCOUNT_FILE):
                os.remove(SERVICE_ACCOUNT_FILE)
                print(f"Cleaned up {SERVICE_ACCOUNT_FILE}")
        except Exception as e:
            print(f"Error cleaning up service account file: {str(e)}")
def get_access_token():
    """Obtain an access token using service account credentials."""
    try:
        if not os.path.exists(SERVICE_ACCOUNT_FILE):
            raise FileNotFoundError(f"Service account file {SERVICE_ACCOUNT_FILE} not found")

        credentials = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE,
            scopes=SCOPES
        )

        if credentials.expired and credentials.refresh_token:
            credentials.refresh(Request())
        
        return credentials.token

    except Exception as e:
        import traceback
        print(f"Full error details: {traceback.format_exc()}")
        raise Exception(f"Failed to get access token: {str(e)}")
if __name__ == '__main__':
    main()