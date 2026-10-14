# --- बिल्ड का चरण ---
FROM python:3.12-slim AS builder

WORKDIR /app

# वर्चुअल परिवेश बनाएँ.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
# && से कमांड क्रम से चलाएँ.
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# --- चलाने का चरण ---
FROM python:3.12-slim AS runner
WORKDIR /app

# बिल्ड चरण से पूरा वर्चुअल परिवेश कॉपी करें.
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# एप्लिकेशन कोड रखें.
COPY . /app/

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]