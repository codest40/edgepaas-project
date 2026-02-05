import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv
load_dotenv()

# Use DATABASE_URL from environment (GitHub secret in CI/CD)
DATABASE_URL = os.getenv("DATABASE_URL", "DB_URL_EXTERNAL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not set in environment!")

# SQLAlchemy setup
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

print(f"[INFO(db)] Detected DB: {DATABASE_URL}")
