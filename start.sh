#!/bin/bash

# Enable color output
COLOR_RESET='\033[0m'
COLOR_GREEN='\033[1;32m'
COLOR_RED='\033[1;31m'
COLOR_BLUE='\033[1;34m'
COLOR_CYAN='\033[1;36m'

# ASCII Banner
echo -e "$COLOR_CYAN"
cat << "EOF"
 ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗ ██╗   ██╗███████╗     █████╗ ██╗       ███████╗███╗   ██╗██╗   ██╗
██╔════╝██║  ██║██║████╗  ██║██╔═══██╗██║   ██║██╔════╝    ██╔══██╗██║       ██╔════╝████╗  ██║██║   ██║
██║     ███████║██║██╔██╗ ██║██║   ██║██║   ██║█████╗█████╗███████║██║       █████╗  ██╔██╗ ██║██║   ██║
██║     ██╔══██║██║██║╚██╗██║██║▄▄ ██║██║   ██║██╔══╝╚════╝██╔══██║██║       ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝
╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝╚██████╔╝███████╗    ██║  ██║██║    ██╗███████╗██║ ╚████║ ═╚████╔╝ 
 ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚══▀▀═╝  ╚═════╝ ╚══════╝    ╚═╝  ╚═╝╚═╝    ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═══╝     
EOF
echo -e "$COLOR_RESET"
echo -e "$COLOR_GREEN🚀 Starting KhuChinQue AI Framework...$COLOR_RESET"

# Check for Docker and Docker Compose
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    echo -e "$COLOR_RED⚠️ Error: Docker or Docker Compose not installed.$COLOR_RESET"
    exit 1
fi

# Create .env file only if it doesn't exist
if [ ! -f .env ]; then
    echo -e "$COLOR_BLUE📝 Creating .env file...$COLOR_RESET"
    cat > .env << EOF
# N8N Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_VERSION=latest

# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=n8n

# Ollama Configuration
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_HOST=0.0.0.0
OLLAMA_VERSION=latest

# Open WebUI Configuration
WEBUI_SECRET_KEY=$(openssl rand -hex 32)
WEBUI_JWT_SECRET_KEY=$(openssl rand -hex 32)

# Browser Configuration
CHROME_BIN=/usr/bin/chromium
DISPLAY=:99
EOF
else
    echo -e "$COLOR_GREEN✅ .env file already exists, skipping creation.$COLOR_RESET"
fi

# Create directory structure
echo -e "$COLOR_BLUE📂 Creating directories...$COLOR_RESET"
mkdir -p \
    data/{ollama,postgres,redis,n8n} \
    n8n-local-files \
    task_storage \
    logs

# Stop any orphaned containers but skip full shutdown if user wants to preserve state
read -p $'\033[1;33mDo you want to stop running containers and start fresh? (y/N): \033[0m' stop_choice
if [[ "$stop_choice" =~ ^[Yy]$ ]]; then
    echo -e "$COLOR_BLUE🛑 Stopping and removing existing containers...$COLOR_RESET"
    docker-compose down --remove-orphans
else
    echo -e "$COLOR_GREEN⏩ Skipping container shutdown. Keeping current containers running.$COLOR_RESET"
fi

# Build and start services (build only changed images if needed)
echo -e "$COLOR_BLUE🔨 Building and starting services...$COLOR_RESET"
docker-compose up -d --build

# Health checks
echo -e "$COLOR_BLUE🩺 Running health checks...$COLOR_RESET"
services=("postgres" "ollama" "n8n" "open-webui" "browser-use" "mcpo")
for service in "${services[@]}"; do
    echo -n "Checking $service... "
    if docker-compose ps | grep "$service" | grep -q "Up"; then
        echo -e "$COLOR_GREEN✓$COLOR_RESET"
    else
        echo -e "$COLOR_RED✗$COLOR_RESET"
        echo -e "$COLOR_RED⚠️ Last logs for $service:$COLOR_RESET"
        docker-compose logs "$service" | tail -n 10
    fi
done

# Initialize Ollama models asynchronously
echo -e "$COLOR_BLUE🤖 Pulling base LLM models in background...$COLOR_RESET"
(docker-compose exec -d ollama ollama pull llama2 && \
 docker-compose exec -d ollama ollama pull mistral) &

# Display access information
echo -e "\n$COLOR_BLUE🌐 Services Ready:$COLOR_RESET"
echo -e "  N8N Workflows      → $COLOR_CYANhttp://localhost:5678$COLOR_RESET"
echo -e "  Open WebUI         → $COLOR_CYANhttp://localhost:3000$COLOR_RESET"
echo -e "  Browser Automation → $COLOR_CYANhttp://localhost:8000$COLOR_RESET"
echo -e "  MCPO Proxy         → $COLOR_CYANhttp://localhost:9000$COLOR_RESET"
echo -e "  Ollama API         → $COLOR_CYANhttp://localhost:11434$COLOR_RESET"

echo -e "\n$COLOR_GREEN✅ Setup complete! Run '$COLOR_CYANdocker-compose logs -f$COLOR_GREEN' to monitor services.$COLOR_RESET"
