import os
import requests

def lambda_handler(event, context):
    private_ip = os.environ["PRIVATE_APP_IP"]
    url = f"http://{private_ip}/"  # or specific port/path
    resp = requests.get(url)

    return {
        'status': str(resp.status_code),
        'statusDescription': resp.reason,
        'headers': {
            'content-type': [{'key': 'Content-Type', 'value': 'text/html'}]
        },
        'body': resp.text
    }
