FROM python:3.11-slim

# Install pipx and required system dependencies
RUN apt-get update && apt-get install -y \
    pipx \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

RUN pipx ensurepath 

# Install poetry 
RUN pip3 install poetry

# Setting the working directory 
WORKDIR /app 

# Install poetry dependencies 
COPY pyproject.toml ./ 
RUN pipx run poetry install --no-root

# Copying our application into the container 
COPY todo todo

# Running our application with proper health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:6400/api/v1/health || exit 1

# Adding a delay to our application startup and using exec form
CMD ["sh", "-c", "sleep 5 && pipx run poetry run flask --app todo run --host 0.0.0.0 --port 6400"]