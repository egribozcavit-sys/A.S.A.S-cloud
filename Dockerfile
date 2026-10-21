FROM python:3.11-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

FROM python:3.11-slim AS final
RUN adduser --disabled-password --gecos "" asas && apt-get update && apt-get install -y --no-install-recommends libpq5 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/* && rm -rf /wheels
COPY --chown=asas:asas . .
USER asas
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3000/health')"
CMD ["uvicorn", "asas_pay_main:app", "--host", "0.0.0.0", "--port", "3000", "--workers", "4", "--proxy-headers", "--forwarded-allow-ips", "*"]