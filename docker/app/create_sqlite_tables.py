from models import Base
from db import engine
import os

if os.environ.get("USE_SQLITE", "false") == "true" or os.environ.get("FINAL_DB_MODE") == "sqlite_only":
    print("[INFO] Creating tables for SQLite...")
    Base.metadata.create_all(bind=engine)
    print("[INFO] SQLite tables created ✅")
