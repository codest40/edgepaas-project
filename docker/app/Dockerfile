FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .

# Upgrade pip
RUN python -m pip install --upgrade pip setuptools wheel

# Install requirements
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN chmod +x entrypoint.sh
CMD ["./entrypoint.sh"]
