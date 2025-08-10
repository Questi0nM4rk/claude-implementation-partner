# Claude Implementation Partner

🧠 **A powerful Claude Code enhancement system with argumentative intelligence and persistent memory for .NET development.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![.NET](https://img.shields.io/badge/.NET-8%2F9-purple.svg)](https://dotnet.microsoft.com/)

## 🌟 Features

- **🎯 Argumentative Intelligence** - Claude challenges assumptions, demands evidence, and thinks critically
- **💾 Persistent Memory** - Learns from your corrections and remembers project context via Mem0
- **🔧 .NET Optimized** - Built specifically for .NET 8/9, MediatR, EF Core development
- **🚀 Auto-Configuration** - Everything installs and configures automatically
- **🐳 Docker-Based** - Clean, isolated services with automatic health monitoring
- **🔬 Research Integration** - Uses Perplexity for fact-checking and best practices

## 📋 Prerequisites

- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- 8GB+ RAM recommended
- Linux/macOS/WSL2

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/Questi0nM4rk/claude-implementation-partner.git
cd claude-implementation-partner

# 2. Configure environment (optional)
cp .env.example .env
# Edit .env with your API keys for enhanced features

# 3. Install and start everything
./install.sh          # One-time installation
./install.sh start    # Start services (auto-downloads embedding model)
```

That's it! The system handles everything automatically.

## 📦 What Gets Installed

- **Qdrant** - Vector database for semantic memory (port 6333)
- **Ollama** - Local LLM for embeddings (port 11434)
- **Mem0** - Memory management system (port 8765)
- **Embedding Model** - `mxbai-embed-large` (downloads automatically)

## 🎮 Commands

All functionality through one simple script:

| Command | Description |
|---------|-------------|
| `./install.sh` | Initial installation (run once) |
| `./install.sh start` | Start all services |
| `./install.sh stop` | Stop all services |
| `./install.sh status` | Check service health |
| `./install.sh clean` | Remove containers and data |
| `./install.sh help` | Show all commands |

## 🌐 Service Dashboard

Once running, access your services at:

- **Qdrant Dashboard**: http://localhost:6333/dashboard
- **Ollama API**: http://localhost:11434
- **Mem0 API**: http://localhost:8765

## 🧠 How It Works

### Argumentative Intelligence
Claude doesn't just follow orders - it thinks critically:
- **Challenges assumptions** - Questions suboptimal decisions
- **Demands evidence** - Requires data to support claims
- **Research-backed** - Uses Perplexity to verify best practices
- **Context-aware** - Understands your project's patterns

### Memory System
Every interaction improves future responses:
- **Project namespaces** - Separate memory per Git repository
- **Pattern learning** - Remembers your coding conventions
- **Error corrections** - Learns from your feedback
- **Cross-session persistence** - Knowledge carries between sessions

## 🔧 Configuration

### API Keys (Optional but Recommended)

Edit `.env` to add:
```bash
PERPLEXITY_API_KEY=pplx-...  # For research and fact-checking
GITHUB_TOKEN=ghp-...         # For repository operations
```

See `.env.example` for all available options.

## 🛠️ Troubleshooting

### Services won't start?
```bash
./install.sh clean    # Clean everything
./install.sh          # Reinstall
./install.sh start    # Start fresh
```

### Check logs
```bash
docker logs claude-mem0
docker logs claude-qdrant
docker logs claude-ollama
```

### Verify installation
```bash
./install.sh status   # Shows detailed health information
```

## 📁 Project Structure

```
claude-implementation-partner/
├── install.sh        # Main installer - handles everything
├── README.md         # This file
├── .env.example      # Environment template
├── config/           # Claude configuration
│   └── claude/       # Settings and MCP configs
├── scripts/          # Internal scripts (don't run directly)
├── mcp/              # MCP service definitions
└── docs/             # Additional documentation
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- Built with [Mem0](https://mem0.ai/) for memory management
- Uses [Qdrant](https://qdrant.tech/) for vector storage
- Powered by [Ollama](https://ollama.ai/) for local embeddings
- Integrates [Perplexity](https://www.perplexity.ai/) for research

---

**Made with 🧠 by the community** | **Simple. Powerful. Automatic.**