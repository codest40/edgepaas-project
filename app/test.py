import os, sys
from dotenv import load_dotenv
load_dotenv()

DATABASE_URL = os.getenv("DB_URL","")
if not DATABASE_URL:
  print("No DB URL Found")
  sys.exit()
else:
  print("DB Found!")

