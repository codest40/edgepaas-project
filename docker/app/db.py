from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv

load_dotenv()

# --- Determine environment ---
prod_flags = ["RENDER", "AWS", "AZURE", "GITHUB"]
is_prod = any(os.environ.get(flag, "").lower() in ("true", "yes") for flag in prod_flags)

# --- Determine DB host dynamically ---
if is_prod:
    DATABASE_URL = os.environ.get("DB_URL", "DB_URL_EXTERNAL")
else:
    # Check if we are inside Docker Compose
    in_docker = os.environ.get("DOCKER", "").lower() in ("true", "yes")
    host = os.environ.get("DEV_DB_HOST") if in_docker else "127.0.0.1"

    user = os.environ.get("DEV_DB_USER", "weather")
    password = os.environ.get("DEV_DB_PASSWORD", "weather123")
    dbname = os.environ.get("DEV_DB_NAME", "weather_app_db")
    
    DATABASE_URL = f"postgresql://{user}:{password}@{host}:5432/{dbname}"


if not DATABASE_URL:
    raise RuntimeError("DB_URL not set in environment!")

print(f"[INFO] Using {'PROD' if is_prod else 'DEV'}")
# print(f"DB URL: {DATABASE_URL}")

# --- SQLAlchemy setup ---
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
