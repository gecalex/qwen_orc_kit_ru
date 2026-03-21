# MCP Configuration Guide

## Обзор

Model Context Protocol (MCP) позволяет подключать внешние серверы к Qwen Code для расширения функциональности. Этот документ описывает систему управления конфигурациями MCP серверов в проекте.

## Структура конфигураций

```
.qwen/
├── mcp.json              # Активная конфигурация (используется Qwen Code)
├── mcp.base.json         # Базовая конфигурация
├── mcp.database.json     # Конфигурация для работы с базами данных
├── mcp.testing.json      # Конфигурация для тестирования
├── mcp.infrastructure.json # Конфигурация для инфраструктуры
└── mcp.full.json         # Полная конфигурация всех серверов
```

## Базовая конфигурация

**Файл:** `.qwen/mcp.base.json`

Базовая конфигурация включает серверы для повседневной разработки:

| Сервер | Описание | Категория |
|--------|----------|-----------|
| `context7` | Документация библиотек и фреймворков | development |
| `searxng` | Поиск в интернете через SearXNG | research |
| `chrome-devtools` | Автоматизация браузера Chrome/Chromium | testing |

**Использование:**
```bash
.qwen/scripts/mcp/switch-config.sh base
```

## Доменные конфигурации

### Database Configuration

**Файл:** `.qwen/mcp.database.json`

Серверы для работы с базами данных:

| Сервер | Описание | Переменные окружения |
|--------|----------|---------------------|
| `supabase` | Работа с Supabase (PostgreSQL, Auth, Storage) | `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_ID` |
| `postgresql` | Подключение к PostgreSQL | `DATABASE_URL` |
| `sqlite` | Работа с SQLite | - |

**Использование:**
```bash
.qwen/scripts/mcp/switch-config.sh database
```

**Требуемые переменные окружения:**
```bash
export SUPABASE_ACCESS_TOKEN="your-token"
export SUPABASE_PROJECT_ID="your-project-id"
export DATABASE_URL="postgresql://user:pass@host:5432/dbname"
```

### Testing Configuration

**Файл:** `.qwen/mcp.testing.json`

Серверы для тестирования:

| Сервер | Описание | Категория |
|--------|----------|-----------|
| `playwright` | E2E тестирование с Playwright | testing |
| `puppeteer` | Автоматизация браузера для тестирования | testing |

**Использование:**
```bash
.qwen/scripts/mcp/switch-config.sh testing
```

### Infrastructure Configuration

**Файл:** `.qwen/mcp.infrastructure.json`

Серверы для работы с инфраструктурой:

| Сервер | Описание | Переменные окружения |
|--------|----------|---------------------|
| `github` | Работа с GitHub API | `GITHUB_TOKEN` |
| `gitlab` | Работа с GitLab API | `GITLAB_TOKEN` |
| `docker` | Управление Docker контейнерами | - |
| `kubernetes` | Управление Kubernetes кластерами | - |

**Использование:**
```bash
.qwen/scripts/mcp/switch-config.sh infrastructure
```

**Требуемые переменные окружения:**
```bash
export GITHUB_TOKEN="your-github-token"
export GITLAB_TOKEN="your-gitlab-token"
```

### Full Configuration

**Файл:** `.qwen/mcp.full.json`

Объединяет все серверы из всех конфигураций. Используйте с осторожностью - большое количество серверов может замедлить запуск.

**Использование:**
```bash
.qwen/scripts/mcp/switch-config.sh full
```

## Скрипты управления MCP

### switch-config.sh

Переключает конфигурацию MCP серверов.

**Использование:**
```bash
.qwen/scripts/mcp/switch-config.sh <config-name>
```

**Примеры:**
```bash
# Переключиться на базовую конфигурацию
.qwen/scripts/mcp/switch-config.sh base

# Переключиться на конфигурацию для БД
.qwen/scripts/mcp/switch-config.sh database

# Переключиться на полную конфигурацию
.qwen/scripts/mcp/switch-config.sh full
```

**Функционал:**
- Проверка существования файла конфигурации
- Валидация JSON
- Создание резервной копии текущей конфигурации
- Копирование выбранной конфигурации в `mcp.json`
- Уведомление о необходимости перезапуска Qwen Code

### health-check.sh

Проверяет состояние всех активных MCP серверов.

**Использование:**
```bash
.qwen/scripts/mcp/health-check.sh
```

**Выходные данные:**
- Список всех серверов из активной конфигурации
- Статус доступности команд для каждого сервера
- Проверка переменных окружения
- Итоговая статистика (исправны/проблемы)

**Пример вывода:**
```
========================================
MCP Health Check
========================================

[INFO] Конфигурация: /path/to/.qwen/mcp.json

========================================
Проверка серверов
========================================

Сервер: context7
[OK] context7: Команда 'npx' доступна

Сервер: github
[OK] github: Команда 'npx' доступна
[WARNING] github: Переменная окружения 'GITHUB_TOKEN' не установлена

========================================
Итоги
========================================

Всего серверов:    5
Исправны:          4
Проблемы:          1

[WARNING] Некоторые серверы имеют проблемы
```

### list-configs.sh

Выводит список доступных конфигураций с подробной информацией.

**Использование:**
```bash
.qwen/scripts/mcp/list-configs.sh
```

**Выходные данные:**
- Таблица всех доступных конфигураций
- Детальная информация о каждой конфигурации
- Инструкция по переключению

**Пример вывода:**
```
========================================
MCP Configurations
========================================

Текущая активная конфигурация: base

========================================
Доступные конфигурации
========================================

НАЗВАНИЕ             СЕРВЕРЫ    КАТЕГОРИИ    ОПИСАНИЕ
--------             -------    ---------    --------
base                 3          develop...   Базовая конфигурация...
database             3          database   Конфигурация для работы...
testing              2          testing    Конфигурация для тестир...
infrastructure       4          infrastr... Конфигурация для инфра...
full                 14         develop... Полная конфигурация все...

* - активная конфигурация
```

## Переключение конфигураций

### Автоматическое переключение

Используйте скрипт `switch-config.sh`:

```bash
# Переключиться на конфигурацию для работы с БД
.qwen/scripts/mcp/switch-config.sh database

# После переключения перезапустите Qwen Code
```

### Ручное переключение

1. Скопируйте нужную конфигурацию в `mcp.json`:
```bash
cp .qwen/mcp.database.json .qwen/mcp.json
```

2. Перезапустите Qwen Code

### Проверка активной конфигурации

```bash
.qwen/scripts/mcp/list-configs.sh
```

Активная конфигурация будет помечена звездочкой (*).

## Best Practices

### 1. Используйте минимальную конфигурацию

Для повседневной разработки используйте `base` конфигурацию. Переключайтесь на специализированные конфигурации только при необходимости.

### 2. Управляйте переменными окружения

- Используйте `.env` файлы для хранения токенов
- Не коммитьте токены в репозиторий
- Используйте `${VAR}` синтаксис для ссылок на переменные

### 3. Регулярная проверка состояния

Запускайте `health-check.sh` перед началом работы:

```bash
# Добавьте в alias
alias mcp-check='.qwen/scripts/mcp/health-check.sh'
```

### 4. Создание собственных конфигураций

Для создания новой конфигурации:

1. Скопируйте существующую:
```bash
cp .qwen/mcp.base.json .qwen/mcp.custom.json
```

2. Отредактируйте файл, добавив нужные серверы

3. Используйте скрипт переключения:
```bash
.qwen/scripts/mcp/switch-config.sh custom
```

### 5. Версионирование конфигураций

Добавляйте `_metadata` секцию для отслеживания версий:

```json
{
  "mcpServers": { ... },
  "_metadata": {
    "name": "custom",
    "description": "Описание конфигурации",
    "version": "1.0.0",
    "servers_count": 5
  }
}
```

## Troubleshooting

### Сервер не запускается

**Проблема:** MCP сервер не запускается при старте Qwen Code

**Решение:**
1. Проверьте наличие команды:
```bash
which npx
which uvx
```

2. Проверьте переменные окружения:
```bash
echo $GITHUB_TOKEN
echo $DATABASE_URL
```

3. Запустите health check:
```bash
.qwen/scripts/mcp/health-check.sh
```

### Ошибки JSON

**Проблема:** Ошибка валидации JSON при переключении

**Решение:**
1. Проверьте синтаксис JSON:
```bash
jq . .qwen/mcp.custom.json
```

2. Убедитесь в отсутствии trailing commas

3. Проверьте экранирование специальных символов

### Конфликты серверов

**Проблема:** Несколько серверов конфликтуют

**Решение:**
1. Проверьте, не дублируются ли серверы в конфигурации
2. Убедитесь, что серверы используют разные порты
3. Проверьте логи Qwen Code

### Переменные окружения не подставляются

**Проблема:** `${VAR}` не заменяется на значение

**Решение:**
1. Убедитесь, что переменная установлена в среде:
```bash
export VAR=value
```

2. Проверьте, что переменная доступна в процессе Qwen Code

3. Перезапустите Qwen Code после установки переменной

## Примеры использования

### Сценарий 1: Веб-разработка

```bash
# Базовая конфигурация для повседневной работы
.qwen/scripts/mcp/switch-config.sh base

# Для E2E тестирования
.qwen/scripts/mcp/switch-config.sh testing

# Для работы с GitHub
export GITHUB_TOKEN="token"
.qwen/scripts/mcp/switch-config.sh infrastructure
```

### Сценарий 2: Работа с базой данных

```bash
# Установка переменных окружения
export SUPABASE_ACCESS_TOKEN="token"
export SUPABASE_PROJECT_ID="project-id"

# Переключение на конфигурацию БД
.qwen/scripts/mcp/switch-config.sh database

# Проверка состояния
.qwen/scripts/mcp/health-check.sh
```

### Сценарий 3: Полный стек

```bash
# Для работы со всем стеком технологий
.qwen/scripts/mcp/switch-config.sh full

# Проверка всех серверов
.qwen/scripts/mcp/health-check.sh
```

## Ссылки

- [MCP Specification](https://modelcontextprotocol.io/)
- [MCP Servers Registry](https://github.com/modelcontextprotocol/servers)
- [Command → Agent → Skill Pattern](./command-agent-skill-pattern.md)
