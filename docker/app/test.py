import os, sys
from dotenv import load_dotenv
load_dotenv()
from wait_for_db import DATABASE_URL

if not DATABASE_URL:
  print("No DB URL Found")
  sys.exit()
else:
  print(f"DB Found! : {DATABASE_URL}")

