FROM python:3.12-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    firefox-esr \
    imagemagick \
    ffmpeg \
    curl \
    wget \
    ca-certificates \
    fontconfig \
    fonts-liberation \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install GeckoDriver (pre-install to avoid runtime network calls)
RUN GECKODRIVER_VERSION=$(curl -sS https://api.github.com/repos/mozilla/geckodriver/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/') \
    && wget -q "https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz" -O /tmp/geckodriver.tar.gz \
    && tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/ \
    && rm /tmp/geckodriver.tar.gz \
    && chmod +x /usr/local/bin/geckodriver

# Relax ImageMagick policy for MoviePy text rendering
RUN sed -i 's/rights="none" pattern="@\*"/rights="read|write" pattern="@*"/' /etc/ImageMagick-6/policy.xml 2>/dev/null || true

WORKDIR /app

# Install Python dependencies (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Create .mp directory (overridden by volume mount at runtime)
RUN mkdir -p /app/.mp

# Make startup script executable
RUN chmod +x scripts/railway_start.sh

CMD ["bash", "scripts/railway_start.sh"]
