# =============================================================================
# Cultivation World Simulator Dockerfile
# Multi-stage build: Node.js for frontend + Python for backend
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build Frontend
# -----------------------------------------------------------------------------
FROM docker.m.daocloud.io/node:20-alpine AS frontend-builder

WORKDIR /app/web

# Copy frontend package files
COPY web/package*.json ./

# Install dependencies
RUN npm ci --prefer-offline

# Copy frontend source
COPY web/ ./

# Build frontend
RUN npm run build

# -----------------------------------------------------------------------------
# Stage 2: Python Runtime
# -----------------------------------------------------------------------------
FROM docker.m.daocloud.io/python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Copy Python requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY src/ ./src/
COPY static/ ./static/
COPY assets/ ./assets/
COPY pyproject.toml ./

# Copy built frontend from stage 1
COPY --from=frontend-builder /app/web/dist ./web/dist

# Create saves directory
RUN mkdir -p saves

# Expose port
EXPOSE 8002

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Run the server
# Note: Changed host to 0.0.0.0 to allow external connections in Docker
CMD ["python", "-c", "import uvicorn; from src.server.main import app; uvicorn.run(app, host='0.0.0.0', port=8002)"]
