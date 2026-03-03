# Build Stage
FROM python:3.11-slim as builder

WORKDIR /app
COPY requirements.txt .

# Install dependencies into a virtualenv to keep the final image clean
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

# Final Stage (Distroless-like principles for security)
FROM python:3.11-slim

# Create a non-root user for security (Running as root in K8s is a bad practice)
RUN groupadd -r appgroup && useradd -r -g appgroup -s /sbin/nologin appuser

WORKDIR /app

# Copy the virtualenv from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY ./app /app/app

# Set correct permissions
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose the API port
EXPOSE 8000

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1

# Run Uvicorn wrapped with Datadog APM tracer
CMD ["ddtrace-run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
