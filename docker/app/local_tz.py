# localtz.py
from datetime import datetime
import pytz

LOCAL_TZ = pytz.timezone("Africa/Lagos")

def timer() -> str:
    return datetime.now(LOCAL_TZ).strftime("%Y:%m:%d_%H:%M:%S")
