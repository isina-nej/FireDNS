import time
import json
import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# Load the service account key
SERVICE_ACCOUNT_FILE = 'service-account.json'

# Define the required scopes
SCOPES = ['https://www.googleapis.com/auth/firebase.messaging']

def get_access_token():
    # Create credentials using the service account file
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=SCOPES
    )
    # Refresh the token
    request = Request()
    credentials.refresh(request)
    return credentials.token

if __name__ == '__main__':
    # First save the service account info to a file
    service_account_info = {
        "type": "service_account",
        "project_id": "dns-changer-a1046",
        "private_key_id": "6e74ccba0882addfdf6d297ece37c05f1e980b12",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC35IDM4FlxE2k0\nwKgINVTyulbVurtQzOKsMaXHRL21m80jAl4hTG+PPZ7YN2/C89mi3Yjj66IQ1INc\nlMxHnh2jNBI88tc5wE6N+Sfm6ALnib5ls781ObGOsd1+LdO0KnJkeNZwlnoOCr4m\nYLrPJm4JN0LTRwpyVXFuwWrv5F6p6+A1O2GzjW6Zx9deJm1T7Zp4aCZo9lP0UzK0\nVqnJkgTr6HzZqS4GDjcQgWa/blmObFRvatjkldEotOFGVaImOTj9ARjFR/A8RiMX\n4WuC/hIrPdODoQ/bNkFaaNQVbAmP9FD+599OrXV/sEGXongINjQ0oncu90JKikHF\nt7I5s0zfAgMBAAECggEAC2fllakl39qAdrbeYgfz/8woytmDePsES87jUlOqrdZL\nwavWn861LeRe2Yu/gSjAnny9wV+u1GFoaZ69eITpOX0abOPyqOo+VRYxPReCtDUt\nQiY4dvosz6xFKZusQZGcBixSjKnHFawUtQR56C0hIeEAe/wWvONQBYeDDpcSrti1\nznjCVuzQNZ+rFQYeGHUTPl6wWhitf01gZkkkuHg+8hxCYNB+TieYKvWN1Tr5cnAr\num/T8CVQNhmo/T9HLtRQ+vkRMeqlHS0DRcNwg6BkueO8G+byM4XFkFh8+8qx3j1t\nTgRXNknnMVpF/Bs51r6m1cz5a5Gq2D9G5py3SKZrEQKBgQD7Mmy1MEcJPjV49KFC\n5x5cLgAeIg+7N3+RAIrC/7QI4z0rzNNQhki3iEhgpZz9QKaUYxjxpM8bWYoI6fWJ\naVXxU4wLREa1wmMqLS/ZirTREbEgqZjkxT1wdQlJgdDT5VWrPM+BjHVdxYSeXNDi\nwVmX9OLN0pDv+HAn5B9Dxe62jwKBgQC7aKHyMV5YJ7eIJ5UA5hhCmhC/3zLzp3dU\nqdsXacVVeNBq8su0osZXNcoLT2SUbEC1/XJ/AMUEzueXZ5mjTU2ZXTzw811GgO6j\nnuE27+JmvJPPGFbL3WNDOBxUQ/WKsO4xQiVWgg5VQN7NSBTKY13Ea2RXhjykSTBu\nHX/NCpGssQKBgBocF6iNqBSR3sT/yHNHyqQSM/jt2WzATAYqZEH4iiISXJ1c4OoR\nyyUoiT1ieXrpaWcrFcCoPM6+89YRW3A4/rHi2T+ijSb/WYdcwwh9nmXMzPh0KGw/\nBC/YOmrlj2s2/zyZSYhRrTFeAnbjduLa7hEZZym1pVMMI7xBve4xeKqJAoGAQ4De\nxFQP/YTg0MQhIZ+/oU3JNrN4sNbjXrWH2xkYIT9RIxStVzVCZ+tSCVzhh6yual8O\nPLzUOnUkah7A8ldH2jQBXXDrahfK3Vi/GoCxdfv66Z+EtA3cUTwGyDtqWDh+s3N1\n64ERFJg3KI4MHxJHlhZwoC4T7cEHFsK9Y+eorSECgYEA38kkpD6FaBf0S7xbI1mp\nMDIxUKDuRkljQdr9T1EwxGAhW2zUJ4SESbowuG/PDjr6a4qP20ml8ESZOUYZoteh\nMAtIDKYtUtBbwb7CnsHa3ot/BYETFU+cKKi8gVq6pXcISoMjJQ9EvkQP8Nn2qvmV\nGWVnIoCRcj1pJGdKZXVXckk=\n-----END PRIVATE KEY-----\n",
        "client_email": "firebase-adminsdk-fbsvc@dns-changer-a1046.iam.gserviceaccount.com",
        "client_id": "111395549651328681820",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40dns-changer-a1046.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
    }

    # Save service account info to a file
    with open(SERVICE_ACCOUNT_FILE, 'w') as f:
        json.dump(service_account_info, f)

    try:
        token = get_access_token()
        print("\n=== Access Token ===")
        print(token)
        print("==================\n")
    except Exception as e:
        print(f"Error getting token: {str(e)}")
    finally:
        # Clean up - remove the service account file
        import os
        if os.path.exists(SERVICE_ACCOUNT_FILE):
            os.remove(SERVICE_ACCOUNT_FILE)
