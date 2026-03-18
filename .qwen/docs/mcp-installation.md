# Установка MCP серверов

**Версия:** 1.0.0  
**Дата:** 2026-03-09

---

## 📋 Обзор

Этот документ описывает процесс установки и настройки MCP серверов для проекта.

## 🔧 Предварительные требования

- Node.js 18+
- npm или yarn
- Docker (для SearXNG)
- Chromium (для Chrome DevTools)

---

## 1. Установка Chromium

```bash
# Arch Linux / Manjaro
sudo pacman -S chromium

# Debian / Ubuntu
sudo apt install chromium-browser

# Fedora
sudo dnf install chromium
```

**Проверка:**
```bash
chromium --version
```

---

## 2. Установка SearXNG (Docker)

```bash
# Создание директории
mkdir -p ~/.searxng
cd ~/.searxng

# Генерация секретного ключа
openssl rand -hex 32

# Создание settings.yml
cat > settings.yml << EOF
use_default_settings: true
search:
  formats:
    - html
    - json
server:
  secret_key: "YOUR_SECRET_KEY"
  limiter: false
  bind_address: "0.0.0.0"
  port: 8080
outgoing:
  request_timeout: 10.0
EOF

# Запуск Docker
docker run -d \
  --name searxng \
  -p 8080:8080 \
  -v ~/.searxng:/etc/searxng \
  -e SEARXNG_SECRET_KEY="YOUR_SECRET_KEY" \
  --restart unless-stopped \
  searxng/searxng:latest
```

**Проверка:**
```bash
curl "http://localhost:8080/search?q=test&format=json"
```

---

## 3. Установка MCP серверов

### 3.1 Chrome DevTools MCP

```bash
npx -y chrome-devtools-mcp@latest --help
```

### 3.2 SearXNG MCP

```bash
npx -y mcp-searxng --help
```

### 3.3 Context7 MCP

```bash
npx -y @upstash/context7-mcp@latest --help
```

### 3.4 FileSystem MCP

```bash
npx -y @modelcontextprotocol/server-filesystem --help
```

### 3.5 Git MCP

```bash
# Установка uvx
curl -LsSf https://astral.sh/uv/install.sh | sh

# Проверка
uvx mcp-server-git --help
```

### 3.6 GitHub MCP

```bash
npx -y @modelcontextprotocol/server-github --help
```

**Требуется:**
- GitHub Personal Access Token
- Экспортировать: `export GITHUB_TOKEN="your_token"`

### 3.7 Playwright MCP

```bash
npx -y @modelcontextprotocol/server-playwright --help
```

---

## 4. Конфигурация проекта

### 4.1 settings.json

Файл: `.qwen/settings.json`

Содержит полную конфигурацию MCP серверов.

### 4.2 mcp.json

Файл: `.qwen/mcp.json`

Дублирует конфигурацию MCP серверов для совместимости.

### 4.3 QWEN.md

Файл: `.qwen/QWEN.md`

Правила использования MCP серверов.

---

## 5. Переключение конфигураций

**Скрипт:** `scripts/orchestration-tools/switch-mcp.sh`

```bash
./scripts/orchestration-tools/switch-mcp.sh
```

**Доступные конфигурации:**
- **BASE** — минимальная (~600 токенов)
- **DATABASE** — для работы с БД (~2500 токенов)
- **FRONTEND** — для UI/UX (~2000 токенов)
- **FULL** — полная конфигурация (~5000 токенов)

---

## 6. Проверка установки

### 6.1 Анализ проекта

```bash
./scripts/orchestration-tools/analyze-project-state.sh
```

### 6.2 Тест MCP серверов

```bash
# Chrome DevTools
npx -y chrome-devtools-mcp@latest --version

# SearXNG
curl "http://localhost:8080/search?q=test&format=json" | python3 -m json.tool

# Context7
npx -y @upstash/context7-mcp@latest --version
```

---

## 7. Устранение проблем

### Проблема: SearXNG не запускается

**Решение:**
```bash
# Проверка Docker
docker ps | grep searxng

# Перезапуск
docker restart searxng

# Проверка логов
docker logs searxng
```

### Проблема: Chrome DevTools не подключается

**Решение:**
```bash
# Проверка Chromium
which chromium
chromium --version

# Проверка пути в конфигурации
# Убедитесь, что --executable-path указан правильно
```

### Проблема: GitHub MCP требует токен

**Решение:**
```bash
# Создание токена
# GitHub → Settings → Developer settings → Personal access tokens

# Экспорт токена
export GITHUB_TOKEN="ghp_..."

# Добавление в ~/.bashrc или ~/.zshrc
echo 'export GITHUB_TOKEN="ghp_..."' >> ~/.bashrc
```

---

## 8. Обновление MCP серверов

```bash
# Обновление всех пакетов
npm update -g

# Обновление конкретных серверов
npx -y chrome-devtools-mcp@latest
npx -y @upstash/context7-mcp@latest
npx -y @modelcontextprotocol/server-filesystem@latest
```

---

## 9. Дополнительные ресурсы

- **Официальная документация MCP:** https://modelcontextprotocol.io/
- **MCP серверы:** https://github.com/modelcontextprotocol/servers
- **SearXNG документация:** https://docs.searxng.org/
- **Chrome DevTools MCP:** https://github.com/ChromeDevTools/chrome-devtools-mcp

---

**Документ обновлён:** 2026-03-09  
**Совместимость:** Qwen Code CLI 0.1.2+
