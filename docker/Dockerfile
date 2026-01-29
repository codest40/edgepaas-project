FROM python:3.11-slim

# ----------------------------
# Working directory
# ----------------------------
WORKDIR /app

# ----------------------------
# Copy requirements & install
# ----------------------------
COPY ./app/requirements.txt .

RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# ----------------------------
# Copy app code
# ----------------------------
COPY ./app .

RUN chmod +x entrypoint.sh

# ----------------------------
# Entrypoint
# ----------------------------
CMD ["./entrypoint.sh"]
