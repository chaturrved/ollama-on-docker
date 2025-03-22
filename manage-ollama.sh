#!/usr/bin/env bash
set -euo pipefail

# manage-ollama.sh - Management script for Ollama Docker deployments
# 
# This script provides functionality to manage Ollama Docker deployments
# with different hardware configurations and actions.

# Default values
CONFIG="m2-mac"
ACTION=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="${SCRIPT_DIR}/configs"
DOCKER_COMPOSE_CMD="docker compose"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage information
usage() {
  echo -e "${BLUE}Ollama Docker Management Script${NC}"
  echo
  echo "Usage: $0 -c <config> -a <action>"
  echo
  echo "Options:"
  echo "  -c, --config <config>    Configuration type (m2-mac, 16gb-pc, gpu-server)"
  echo "  -a, --action <action>    Action to perform (start, stop, status, cleanup, pull-models)"
  echo "  -h, --help               Display this help message"
  echo
  echo "Examples:"
  echo "  $0 -c m2-mac -a start"
  echo "  $0 -c 16gb-pc -a status"
  echo "  $0 -c gpu-server -a stop"
  exit 1
}

# Function to validate configuration
validate_config() {
  local config=$1
  if [[ ! -f "${CONFIGS_DIR}/${config}.yml" ]]; then
    echo -e "${RED}Error: Configuration '${config}' not found.${NC}"
    echo -e "Available configurations:"
    for config_file in "${CONFIGS_DIR}"/*.yml; do
      echo -e "  - $(basename "${config_file}" .yml)"
    done
    exit 1
  fi
}

# Function to validate action
validate_action() {
  local action=$1
  local valid_actions=("start" "stop" "status" "cleanup" "pull-models")
  
  if [[ ! " ${valid_actions[*]} " =~ " ${action} " ]]; then
    echo -e "${RED}Error: Invalid action '${action}'.${NC}"
    echo -e "Valid actions: ${valid_actions[*]}"
    exit 1
  fi
}

# Function to check Docker and Docker Compose
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH.${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
  fi

  # Check if Docker is running
  if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker daemon is not running.${NC}"
    echo "Please start Docker and try again."
    exit 1
  fi

  # Check Docker Compose version
  if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
  elif docker-compose --version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
  else
    echo -e "${RED}Error: Docker Compose is not installed.${NC}"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
  fi
}

# Function to check GPU support for gpu-server configuration
check_gpu_support() {
  if [[ "$CONFIG" == "gpu-server" ]]; then
    if ! command -v nvidia-smi &> /dev/null; then
      echo -e "${YELLOW}Warning: nvidia-smi not found. GPU support may not be available.${NC}"
    elif ! nvidia-smi &> /dev/null; then
      echo -e "${YELLOW}Warning: nvidia-smi failed. NVIDIA drivers may not be properly installed.${NC}"
    fi
    
    # Check NVIDIA Container Toolkit
    if ! docker info | grep -q "Runtimes:.*nvidia"; then
      echo -e "${YELLOW}Warning: NVIDIA Container Toolkit not detected in Docker.${NC}"
      echo "For GPU support, please install NVIDIA Container Toolkit:"
      echo "https://github.com/NVIDIA/nvidia-docker"
    fi
  fi
}

# Function to start Ollama
start_ollama() {
  echo -e "${BLUE}Starting Ollama with ${CONFIG} configuration...${NC}"
  ${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" up -d
  echo -e "${GREEN}Ollama started successfully!${NC}"
  echo
  echo -e "Access services at:"
  echo -e "  - Ollama API: ${BLUE}http://localhost:11434${NC}"
  echo -e "  - Web UI: ${BLUE}http://localhost:3000${NC}"
  
  if [[ "$CONFIG" == "16gb-pc" || "$CONFIG" == "gpu-server" ]]; then
    echo -e "  - PostgreSQL: ${BLUE}localhost:5432${NC}"
  fi
  
  if [[ "$CONFIG" == "gpu-server" ]]; then
    echo -e "  - Grafana: ${BLUE}http://localhost:3001${NC}"
    echo -e "  - Prometheus: ${BLUE}http://localhost:9090${NC}"
  fi
}

# Function to stop Ollama
stop_ollama() {
  echo -e "${BLUE}Stopping Ollama with ${CONFIG} configuration...${NC}"
  ${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" down
  echo -e "${GREEN}Ollama stopped successfully!${NC}"
}

# Function to check Ollama status
status_ollama() {
  echo -e "${BLUE}Checking Ollama status with ${CONFIG} configuration...${NC}"
  ${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" ps
  
  # Check if containers are running
  if ${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" ps | grep -q "Up"; then
    echo -e "${GREEN}Ollama is running.${NC}"
  else
    echo -e "${YELLOW}Ollama is not running.${NC}"
  fi
}

# Function to clean up Ollama (including volumes)
cleanup_ollama() {
  echo -e "${YELLOW}Warning: This will remove all containers and volumes for ${CONFIG} configuration.${NC}"
  read -p "Are you sure you want to continue? (y/n): " confirm
  
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo -e "${BLUE}Cleaning up Ollama with ${CONFIG} configuration...${NC}"
    ${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" down -v
    echo -e "${GREEN}Ollama cleaned up successfully!${NC}"
  else
    echo -e "${BLUE}Cleanup cancelled.${NC}"
  fi
}

# Function to pull recommended models
pull_models() {
  echo -e "${BLUE}Pulling recommended models for ${CONFIG} configuration...${NC}"
  
  # Start Ollama if not running
  if ! ${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" ps | grep -q "Up"; then
    echo -e "${YELLOW}Ollama is not running. Starting it first...${NC}"
    ${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" up -d
    # Wait for Ollama to start
    echo -e "Waiting for Ollama to start..."
    sleep 10
  fi
  
  # Pull models based on configuration
  case "$CONFIG" in
    "m2-mac")
      echo -e "Pulling models for M2 MacBook Air..."
      docker exec -it $(${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" ps -q ollama) ollama pull mistral
      ;;
    "16gb-pc")
      echo -e "Pulling models for 16GB PC..."
      docker exec -it $(${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" ps -q ollama) ollama pull mistral
      docker exec -it $(${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" ps -q ollama) ollama pull llama2
      ;;
    "gpu-server")
      echo -e "Pulling models for GPU Server..."
      docker exec -it $(${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" ps -q ollama) ollama pull mistral
      docker exec -it $(${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" ps -q ollama) ollama pull llama2
      docker exec -it $(${DOCKER_COMPOSE_CMD} -f "${CONFIGS_DIR}/${CONFIG}.yml" ps -q ollama) ollama pull mixtral
      ;;
  esac
  
  echo -e "${GREEN}Models pulled successfully!${NC}"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      CONFIG="$2"
      shift 2
      ;;
    -a|--action)
      ACTION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}"
      usage
      ;;
  esac
done

# Check if required arguments are provided
if [[ -z "$ACTION" ]]; then
  echo -e "${RED}Error: Action is required.${NC}"
  usage
fi

# Main execution
check_docker
validate_config "$CONFIG"
validate_action "$ACTION"
check_gpu_support

# Perform the requested action
case "$ACTION" in
  "start")
    start_ollama
    ;;
  "stop")
    stop_ollama
    ;;
  "status")
    status_ollama
    ;;
  "cleanup")
    cleanup_ollama
    ;;
  "pull-models")
    pull_models
    ;;
esac

exit 0