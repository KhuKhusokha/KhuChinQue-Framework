# Stage 1: Builder stage for dependencies
FROM python:3.11-slim as builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    chromium \
    chromium-driver \
    libgl1 \
    libglib2.0-0 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Main application image
FROM python:3.11-slim

WORKDIR /app

# Install required system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    chromium \
    chromium-driver \
    libgl1 \
    libglib2.0-0 \
    ffmpeg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /app /data /logs /task_storage /n8n-local-files

# Create app directory structure
RUN mkdir -p /etc/supervisor/conf.d

# Install Python dependencies from builder stage
COPY --from=builder /root/.local /usr/local

# Add application code
COPY . /app

# Set environment variables
ENV PATH="/usr/local/bin:$PATH"
ENV PYTHONPATH=/app

# Expose ports
EXPOSE 5678 8080 3000 11434 8000

# Setup volumes
VOLUME ["/data", "/logs", "/task_storage", "/n8n-local-files"]

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Install Chrome extensions if needed
# RUN mkdir -p /opt/chrome/extensions

# Install Ollama (if not in compose)
# RUN curl -fsSL https://ollama.ai/install.sh  | sh

# Default command to start services
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
