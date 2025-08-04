# 🧠 Claude Implementation Partner

**SuperClaude-Style Implementation Advisor for .NET Developers**

> Smart brainstorming partner that helps implement tasks in existing codebases without reinventing the wheel.

## 🚀 Quick Start

```bash
# Install everything (Docker required)
./install.sh

# Start using
claude
/impl:brainstorm "your implementation question"
```

## ✨ Features

- **🧠 Smart Brainstorming** - Analyzes your codebase first, then suggests approaches
- **🤖 Auto-Activating Agents** - Context-aware agents that activate when needed
- **💾 Memory System** - Remembers past decisions and patterns
- **🔌 Essential Integrations** - Jira, Confluence, GitLab, Perplexity research

## 🎯 Core Commands

```bash
# Implementation workflow
/impl:brainstorm "complex EF query with filters"
/impl:analyze --pattern database-queries
/impl:research "EF Core performance" --validate
/impl:decide --save-pattern --link-jira ABC-123

# Codebase analysis  
/code:scan --type queries --related-to Product
/code:patterns --find similar-to UserService
/code:quality --check-performance

# Memory & integration
/memory:recall --similar-to "filtering queries"
/docs:create-confluence "Implementation Pattern"
/task:update-jira ABC-123 --with-notes
```

## 🤖 Auto-Activating Agents

- **@codebase-analyzer** - Scans .NET code for existing patterns
- **@efcore-expert** - Database/EF Core implementation advice
- **@performance-advisor** - Performance optimization guidance  
- **@pattern-keeper** - Ensures consistency with existing patterns

## 🛠️ Tech Stack

- **.NET Focus** - EF Core, MediatR/Wolverine, microservices
- **Memory** - Mem0 + Qdrant + Ollama (local embeddings)
- **Research** - Perplexity integration for best practices
- **Integrations** - Atlassian (Jira/Confluence), GitLab
- **Docker** - Containerized memory and MCP services

## 📋 Installation Requirements

- Docker & Docker Compose
- Git
- Basic shell access
- API keys for integrations (optional)

## 🔧 Architecture

```
Memory Stack (Docker):
├── Mem0 MCP Server (port 8765)
├── Qdrant Vector DB (port 6333)  
└── Ollama Embeddings (port 11434)

Claude Integration:
├── hooks/ - Auto-activation & context injection
├── commands/ - SuperClaude-style commands
├── agents/ - Specialized AI agents
└── integrations/ - MCP servers for external tools
```

## 📚 Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Command Reference](docs/COMMANDS.md)  
- [Agent System](docs/AGENTS.md)
- [Integration Setup](docs/INTEGRATIONS.md)

---

**Built for hands-on .NET developers who need a thinking partner for implementation decisions.** 🎯
