# Ollama Docker Deployment

This repository contains Docker Compose configurations and management scripts for running Ollama in different environments. It provides optimized setups for various hardware configurations, from MacBooks to GPU servers.

## 🚀 Features

- Multiple hardware-optimized configurations
- Easy-to-use management scripts
- Volume persistence
- Optional monitoring stack
- Web UI interface
- Database integration (PostgreSQL)

## 📁 Directory Structure

```
ollama/
├── configs/
│   ├── m2-mac.yml        # Configuration for M2 MacBook (8GB RAM)
│   ├── 16gb-pc.yml      # Configuration for 16GB RAM PCs
│   └── gpu-server.yml   # Configuration for GPU servers
├── manage-ollama.sh     # Management script
└── README.md           # This file
```

## 💻 Hardware Configurations

### M2 MacBook Air (8 GB)
- Minimal setup optimized for lower RAM
- Memory limits for stability
- SQLite for data storage
- Suitable for smaller models like Mistral

### 16 GB PC
- PostgreSQL database included
- Higher memory allocation
- Suitable for medium-sized models
- Basic monitoring

### GPU Server
- Full GPU support enabled
- Prometheus/Grafana monitoring
- PostgreSQL database
- Suitable for large models
- No memory restrictions

## 🛠️ Quick Start

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ollama-docker
cd ollama-docker
```

2. Make the management script executable:
```bash
chmod +x manage-ollama.sh
```

3. Start Ollama with your preferred configuration:
```bash
./manage-ollama.sh -c <config-type> -a start
```

## 📝 Usage

### Management Script

The `manage-ollama.sh` script provides several commands:

```bash
# Start services
./manage-ollama.sh -c m2-mac -a start

# Check status
./manage-ollama.sh -c m2-mac -a status

# Stop services
./manage-ollama.sh -c m2-mac -a stop

# Clean up (removes volumes)
./manage-ollama.sh -c m2-mac -a cleanup

# Pull recommended models
./manage-ollama.sh -c m2-mac -a pull-models
```

Available configurations:
- `m2-mac`
- `16gb-pc`
- `gpu-server`

### Accessing Services

- Ollama API: `http://localhost:11434`
- Web UI: `http://localhost:3000`
- PostgreSQL (16 GB+ configurations): `localhost:5432`
- Grafana (GPU server): `http://localhost:3001`
- Prometheus (GPU server): `http://localhost:9090`

## 🤖 Available Models

Different configurations support different model sizes:

### M2 MacBook Air
- Mistral (recommended)
- Small variants of other models

### 16 GB PC
- Llama2
- Mistral
- Medium-sized models

### GPU Server
- All models supported
- Mixtral
- Large variants

## 📦 Volume Management

Persistent volumes are maintained for:
- Model storage
- Database data (PostgreSQL)
- Monitoring data (Prometheus/Grafana)

To preserve data between restarts, use `stop`. To clean up all data, use `cleanup`.

## 🔧 Customization

### Memory Limits

Adjust memory limits in the configuration files:

```yaml
services:
  ollama:
    mem_limit: "4g"  # Adjust based on your needs
    mem_reservation: "2g"
```

### Ports

Default ports can be modified in the configuration files:

```yaml
ports:
  - "custom:default"  # e.g., "11435:11434"
```

## 🚨 Troubleshooting

1. **Out of Memory**
   - Reduce model size
   - Adjust memory limits
   - Close other applications

2. **GPU Issues**
   - Ensure NVIDIA drivers are installed
   - Verify Docker GPU support
   - Check `nvidia-smi` output

3. **Database Connection**
   - Check PostgreSQL logs
   - Verify credentials
   - Ensure ports are not blocked

## 📄 License

MIT License - Feel free to modify and distribute this code.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## ⚠️ Requirements

- Docker Engine 20.10+
- Docker Compose V2
- NVIDIA Container Toolkit (for GPU support)
- At least 8 GB RAM
- 20 GB free disk space

## 📚 Additional Resources

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)
