# План миграции на Extensions с CI/CD

**Дата:** 29 марта 2026  
**Статус:** ✅ Черновик  
**Агент:** qwen-code-cli-specialist  
**Версия плана:** 1.0  
**Целевая версия:** v0.8.0

---

## Резюме

Данный план описывает полную миграцию Qwen Orchestrator Kit с модели копирования файлов в директорию проекта на модель **Extensions** (глобальная установка) с настройкой **CI/CD** для автоматических обновлений.

**Ключевые изменения:**
- ✅ Отказ от копирования файлов в проект
- ✅ Глобальная установка через `qwen extensions install`
- ✅ Автоматические обновления через `qwen extensions update`
- ✅ CI/CD для авто-релизов с Git тегами
- ✅ Разделение на stable/dev ветки

**Преимущества:**
- 🚀 Упрощённая установка (1 команда)
- 🔄 Автоматические обновления
- 📦 Чистая структура проекта (нет .qwen/ в проекте)
- 🎯 Разделение ответственности (расширение vs конфигурация проекта)

---

## 1. Текущее состояние

### 1.1. Архитектура проекта

**Текущая структура:**

```
qwen_orc_kit_ru/
├── .qwen/                          # Конфигурация Qwen Code
│   ├── agents/                     # 36 агентов
│   ├── skills/                     # 40 навыков
│   ├── scripts/                    # 29 директорий скриптов
│   ├── commands/                   # 0 файлов (22 git-ignored)
│   ├── docs/                       # 27 файлов документации
│   ├── templates/                  # Шаблоны
│   ├── config.sh                   # Конфигурация
│   ├── settings.json               # Настройки
│   └── mcp.*.json                  # MCP конфигурации
├── package.json                    # Версия 0.6.0
├── .version                        # Версия 0.7.0
└── ...
```

**Проблемы текущей архитектуры:**

| Проблема | Описание | Влияние |
|----------|----------|---------|
| ❌ Копирование файлов | `.qwen/` копируется в каждый проект | Дублирование, сложно обновлять |
| ❌ Нет централизованного обновления | Каждое обновление требует ручного копирования | Устаревание проектов |
| ❌ Смешанная ответственность | Конфигурация проекта + глобальные агенты | Путаница, конфликты |
| ❌ Нет Git тегов | Версии не отмечены тегами | Сложно отслеживать релизы |
| ❌ Нет CI/CD | Ручные релизы | Медленно, ошибки человека |
| ❌ Нет разделения веток | Все изменения в main | Нестабильность для пользователей |

### 1.2. Компоненты системы

**Агенты (36 файлов):**
- 8 оркестраторов (`orc_*.md`)
- 4 Speckit агента
- 24 воркера (`work_*.md`)

**Навыки (40 файлов):**
- Обработка данных
- Валидация
- Форматирование
- Анализ

**Скрипты (29 директорий):**
- Agent creation
- Bug tracking
- Git automation
- Quality gates
- Orchestration tools
- Release tools

**Документация:**
- Архитектурная (`.qwen/docs/architecture/`)
- Помощь (`.qwen/docs/help/`)
- Примеры (`.qwen/docs/examples/`)

**Конфигурация:**
- `config.sh` — универсальная конфигурация
- `settings.json` — настройки Qwen Code
- `mcp.*.json` — MCP конфигурации

### 1.3. Зависимости

**Внутренние зависимости:**

```
Агенты → Skills → Scripts → Config
   ↓         ↓         ↓
Docs ← Templates ← MCP
```

**Внешние зависимости:**

```
Qwen Code CLI (≥0.6.0)
Node.js (≥20.0.0)
npm (≥10.0.0)
Git (≥2.30)
Python (≥3.9) — для тестов
```

**MCP серверы:**
- `chrome-devtools` — браузерная автоматизация
- `searxng` — веб-поиск
- `context7` — документация API
- `filesystem` — файловая система
- `git` — Git операции
- `github` — GitHub API
- `playwright` — кросс-браузерная автоматизация

---

## 2. Целевое состояние

### 2.1. Архитектура после миграции

**Структура расширения (глобально):**

```
~/.qwen/extensions/qwen-orchestrator-kit/
├── qwen-extension.json         # Манифест расширения
├── QWEN.md                     # Контекст расширения
├── agents/                     # 36 агентов
├── skills/                     # 40 навыков
├── commands/                   # Слэш-команды
├── scripts/                    # Скрипты (опционально)
├── docs/                       # Документация
└── templates/                  # Шаблоны
```

**Структура проекта (локально):**

```
my-project/
├── .qwen/
│   ├── settings.json           # Настройки проекта
│   ├── mcp.json                # MCP конфигурация проекта
│   └── config.sh               # Конфигурация проекта (опционально)
├── src/
├── tests/
└── ...
```

### 2.2. Разделение ответственности

**В расширении (глобально):**

| Компонент | Расположение | Назначение |
|-----------|--------------|------------|
| Агенты | `~/.qwen/extensions/.../agents/` | Глобальные ИИ-агенты |
| Навыки | `~/.qwen/extensions/.../skills/` | Переиспользуемые функции |
| Команды | `~/.qwen/extensions/.../commands/` | Слэш-команды (/help, /test) |
| Шаблоны | `~/.qwen/extensions/.../templates/` | Шаблоны для создания |
| Документация | `~/.qwen/extensions/.../docs/` | Общая документация |
| Скрипты | `~/.qwen/extensions/.../scripts/` | Глобальные скрипты |

**В проекте (локально):**

| Компонент | Расположение | Назначение |
|-----------|--------------|------------|
| Настройки | `.qwen/settings.json` | Настройки конкретного проекта |
| MCP | `.qwen/mcp.json` | MCP конфигурация проекта |
| Конституция | `.qwen/specify/memory/constitution.md` | Принципы проекта |
| Спецификации | `.qwen/specify/specs/` | Спецификации проекта |
| Конфигурация | `config.sh` (опционально) | Конфигурация проекта |

### 2.3. Обратная совместимость

**Поддержка старых проектов:**

1. **Гибридный режим (переходный период):**
   - Проекты с `.qwen/` продолжают работать
   - Новые проекты используют Extensions
   - Постепенная миграция

2. **Миграционный скрипт:**
   ```bash
   .qwen/scripts/migration/migrate-to-extensions.sh
   ```
   - Удаляет дублирующиеся файлы
   - Сохраняет конфигурацию проекта
   - Проверяет работоспособность

3. **Обновление существующих проектов:**
   ```bash
   # 1. Установить расширение
   qwen extensions install https://github.com/...
   
   # 2. Запустить миграцию
   ./migrate-to-extensions.sh
   
   # 3. Проверить работу
   qwen extensions list
   ```

### 2.4. Git стратегия

**Ветки:**

```
main (stable)         ← стабильные релизы (теги v*)
  ↑
release/v*            ← подготовка релиза
  ↑
develop               ← разработка
  ↑
feature/*             ← новые функции
  ↑
bugfix/*              ← исправления
  ↑
hotfix/*              ← срочные исправления для stable
```

**Теги:**

```bash
# Семантическое версионирование
v0.7.0    ← текущая версия
v0.8.0    ← следующая версия (миграция)
v1.0.0    ← стабильный релиз
```

**Процесс релиза:**

```bash
# 1. Обновить версию в qwen-extension.json
# 2. Обновить CHANGELOG.md
# 3. Создать Git тег
git tag -a v0.8.0 -m "Release v0.8.0: Extensions + CI/CD"
git push origin v0.8.0

# 4. GitHub Actions создаёт релиз
# 5. Пользователи обновляются:
qwen extensions update qwen-orchestrator-kit
```

---

## 3. Стратегия миграции

### 3.1. Этапы миграции

**Этап 1: Подготовка расширения (1-2 дня)**

```
[ ] Создать манифест qwen-extension.json
[ ] Обновить структуру расширения
[ ] Создать QWEN.md для расширения
[ ] Протестировать установку
```

**Этап 2: Создание миграционного скрипта (1 день)**

```
[ ] Создать script/migrate-to-extensions.sh
[ ] Протестировать на тестовом проекте
[ ] Обновить документацию
```

**Этап 3: Настройка CI/CD (2-3 дня)**

```
[ ] Настроить GitHub Actions workflow
[ ] Создать workflow релиза
[ ] Протестировать авто-релиз
```

**Этап 4: Тестирование (2-3 дня)**

```
[ ] Тест на чистом проекте
[ ] Тест на существующем проекте
[ ] Тест обновления
```

**Этап 5: Публикация (1 день)**

```
[ ] Создать релиз v0.8.0
[ ] Обновить README
[ ] Опубликовать документацию
```

### 3.2. Манифест расширения

**Файл:** `.qwen/qwen-extension.json`

```json
{
  "name": "qwen-orchestrator-kit",
  "version": "0.8.0",
  "description": "Qwen Code Orchestrator Kit — интеллектуальная система оркестрации разработки с ИИ-агентами",
  "contextFileName": "QWEN.md",
  "agents": "agents",
  "skills": "skills",
  "commands": "commands",
  "templates": "templates",
  "docs": "docs",
  "scripts": "scripts",
  "excludeTools": [
    "run_shell_command(rm -rf)",
    "run_shell_command(sudo)"
  ],
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest", "--executable-path=/usr/bin/chromium", "--isolated"]
    },
    "searxng": {
      "command": "npx",
      "args": ["-y", "mcp-searxng@latest"],
      "env": {"SEARXNG_URL": "http://localhost:8080"}
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem@latest"]
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git@latest"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github@latest"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-playwright@latest"]
    }
  },
  "settings": [
    {
      "name": "outputLanguage",
      "value": "Russian",
      "description": "Язык вывода"
    },
    {
      "name": "enableAutoUpdate",
      "value": false,
      "description": "Автоматическое обновление"
    }
  ],
  "repository": {
    "type": "git",
    "url": "https://github.com/yourusername/qwen_orc_kit_ru"
  },
  "author": "Qwen Community",
  "license": "MIT",
  "engines": {
    "qwen-code": ">=0.6.0",
    "node": ">=20.0.0"
  }
}
```

### 3.3. QWEN.md для расширения

**Файл:** `.qwen/QWEN.md` (контекст расширения)

```markdown
# Qwen Orchestrator Kit Extension

**Версия:** 0.8.0  
**Дата:** 29 марта 2026

## Описание

Интеллектуальная система оркестрации разработки с ИИ-агентами.

## Компоненты

- **36 агентов** (оркестраторы + воркеры)
- **40 навыков** (обработка, валидация, анализ)
- **Слэш-команды** (/health-bugs, /health-security, /health-cleanup, /health-deps)
- **MCP интеграция** (7 серверов)
- **Quality Gates** (5 контрольных точек)
- **Speckit Workflow** (разработка по спецификациям)
- **TDD система** (6 агентов тестирования)

## Установка

```bash
qwen extensions install https://github.com/yourusername/qwen_orc_kit_ru
```

## Обновление

```bash
qwen extensions update qwen-orchestrator-kit
```

## Документация

См. `.qwen/docs/` для подробной документации.

## Лицензия

MIT
```

### 3.4. Миграционный скрипт

**Файл:** `.qwen/scripts/migration/migrate-to-extensions.sh`

```bash
#!/bin/bash

# =============================================================================
# migrate-to-extensions.sh - Миграция на Extensions модель
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
QWEN_DIR="$PROJECT_ROOT/.qwen"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка расширения
check_extension() {
  log_info "Проверка установленного расширения..."
  
  if ! command -v qwen &> /dev/null; then
    log_error "Qwen Code CLI не установлен"
    exit 1
  fi
  
  EXTENSION_INSTALLED=$(qwen extensions list 2>/dev/null | grep -c "qwen-orchestrator-kit" || true)
  
  if [ "$EXTENSION_INSTALLED" -eq 0 ]; then
    log_error "Расширение qwen-orchestrator-kit не установлено"
    log_info "Установите: qwen extensions install https://github.com/..."
    exit 1
  fi
  
  log_success "Расширение установлено"
}

# Сохранение конфигурации проекта
save_project_config() {
  log_info "Сохранение конфигурации проекта..."
  
  BACKUP_DIR="$PROJECT_ROOT/.qwen.backup.$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  
  # Сохранить настройки проекта
  if [ -f "$QWEN_DIR/settings.json" ]; then
    cp "$QWEN_DIR/settings.json" "$BACKUP_DIR/"
    log_success "settings.json сохранён"
  fi
  
  # Сохранить MCP конфигурацию
  if [ -f "$QWEN_DIR/mcp.json" ]; then
    cp "$QWEN_DIR/mcp.json" "$BACKUP_DIR/"
    log_success "mcp.json сохранён"
  fi
  
  # Сохранить спецификации
  if [ -d "$QWEN_DIR/specify" ]; then
    cp -r "$QWEN_DIR/specify" "$BACKUP_DIR/"
    log_success "specify/ сохранён"
  fi
  
  log_success "Конфигурация сохранена в $BACKUP_DIR"
}

# Удаление дублирующихся файлов
remove_duplicate_files() {
  log_info "Удаление дублирующихся файлов..."
  
  # Удалить агенты (теперь в расширении)
  if [ -d "$QWEN_DIR/agents" ]; then
    rm -rf "$QWEN_DIR/agents"
    log_success "agents/ удалён"
  fi
  
  # Удалить навыки (теперь в расширении)
  if [ -d "$QWEN_DIR/skills" ]; then
    rm -rf "$QWEN_DIR/skills"
    log_success "skills/ удалён"
  fi
  
  # Удалить команды (теперь в расширении)
  if [ -d "$QWEN_DIR/commands" ]; then
    rm -rf "$QWEN_DIR/commands"
    log_success "commands/ удалён"
  fi
  
  # Удалить шаблоны (теперь в расширении)
  if [ -d "$QWEN_DIR/templates" ]; then
    rm -rf "$QWEN_DIR/templates"
    log_success "templates/ удалён"
  fi
  
  # Удалить документацию (теперь в расширении)
  if [ -d "$QWEN_DIR/docs" ]; then
    rm -rf "$QWEN_DIR/docs"
    log_success "docs/ удалён"
  fi
  
  # Удалить скрипты (теперь в расширении)
  if [ -d "$QWEN_DIR/scripts" ]; then
    rm -rf "$QWEN_DIR/scripts"
    log_success "scripts/ удалён"
  fi
  
  log_success "Дублирующиеся файлы удалены"
}

# Проверка работоспособности
check_functionality() {
  log_info "Проверка работоспособности..."
  
  # Проверить доступность агентов
  AGENTS_COUNT=$(ls -1 "$HOME/.qwen/extensions/qwen-orchestrator-kit/agents/" 2>/dev/null | wc -l)
  
  if [ "$AGENTS_COUNT" -eq 0 ]; then
    log_error "Агенты не найдены в расширении"
    exit 1
  fi
  
  log_success "Найдено агентов: $AGENTS_COUNT"
  
  # Проверить доступность навыков
  SKILLS_COUNT=$(ls -1 "$HOME/.qwen/extensions/qwen-orchestrator-kit/skills/" 2>/dev/null | wc -l)
  
  if [ "$SKILLS_COUNT" -eq 0 ]; then
    log_error "Навыки не найдены в расширении"
    exit 1
  fi
  
  log_success "Найдено навыков: $SKILLS_COUNT"
  
  # Проверить QWEN.md
  if [ ! -f "$QWEN_DIR/QWEN.md" ]; then
    log_warning "QWEN.md не найден"
  else
    log_success "QWEN.md найден"
  fi
}

# Основная функция
main() {
  echo "========================================"
  echo "Миграция на Extensions модель"
  echo "========================================"
  echo ""
  
  # Проверка расширения
  check_extension
  
  # Сохранение конфигурации
  save_project_config
  
  # Удаление дублирующихся файлов
  remove_duplicate_files
  
  # Проверка работоспособности
  check_functionality
  
  echo ""
  echo "========================================"
  log_success "Миграция завершена успешно!"
  echo "========================================"
  echo ""
  log_info "Следующие шаги:"
  echo "  1. Проверьте работу: qwen"
  echo "  2. При проблемах восстановите из backup:"
  echo "     cp -r .qwen.backup.*/* .qwen/"
  echo ""
}

main "$@"
```

---

## 4. CI/CD процесс

### 4.1. GitHub Actions Workflow

**Файл:** `.github/workflows/release.yml`

```yaml
name: Release Extension

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      version:
        description: 'Версия для релиза (например, v0.8.0)'
        required: true
        type: string

jobs:
  release:
    name: Create Release
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Get version from tag
        id: get_version
        run: |
          if [ "${{ github.event_name }}" = "workflow_dispatch" ]; then
            VERSION="${{ inputs.version }}"
          else
            VERSION="${{ github.ref_name }}"
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Release version: $VERSION"
      
      - name: Update version in qwen-extension.json
        run: |
          VERSION="${{ steps.get_version.outputs.version }}"
          VERSION_NO_V="${VERSION#v}"
          
          # Обновить версию в манифесте
          jq --arg version "$VERSION_NO_V" '.version = $version' .qwen/qwen-extension.json > .qwen/qwen-extension.json.tmp
          mv .qwen/qwen-extension.json.tmp .qwen/qwen-extension.json
          
          # Обновить версию в package.json
          jq --arg version "$VERSION_NO_V" '.version = $version' package.json > package.json.tmp
          mv package.json.tmp package.json
          
          # Обновить версию в .version
          echo "$VERSION_NO_V" > .version
          
          # Закоммитить изменения
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add .qwen/qwen-extension.json package.json .version
          git commit -m "chore: bump version to $VERSION_NO_V" || echo "No changes to commit"
          git push
      
      - name: Generate changelog
        id: changelog
        run: |
          PREV_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
          
          if [ -z "$PREV_TAG" ]; then
            echo "First release, using all commits"
            CHANGELOG=$(git log --pretty=format:"* %s (%h)" --no-merges)
          else
            echo "Generating changelog from $PREV_TAG to ${{ steps.get_version.outputs.version }}"
            CHANGELOG=$(git log --pretty=format:"* %s (%h)" --no-merges "$PREV_TAG"..HEAD)
          fi
          
          echo "changelog<<EOF" >> $GITHUB_OUTPUT
          echo "$CHANGELOG" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT
      
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          name: Release ${{ steps.get_version.outputs.version }}
          body: |
            ## Changes
            
            ${{ steps.changelog.outputs.changelog }}
            
            ## Installation
            
            \`\`\`bash
            qwen extensions install https://github.com/${{ github.repository }} --ref ${{ steps.get_version.outputs.version }}
            \`\`\`
            
            ## Update
            
            \`\`\`bash
            qwen extensions update qwen-orchestrator-kit
            \`\`\`
          draft: false
          prerelease: false
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Notify success
        run: |
          echo "✅ Release ${{ steps.get_version.outputs.version }} created successfully!"
          echo "Repository: https://github.com/${{ github.repository }}"
          echo "Users can update with: qwen extensions update qwen-orchestrator-kit"
```

### 4.2. Workflow для стабильной ветки

**Файл:** `.github/workflows/stable-sync.yml`

```yaml
name: Sync Stable Branch

on:
  push:
    branches:
      - main

jobs:
  sync-stable:
    name: Sync to Stable
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Sync to stable branch
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          
          # Создать или обновить stable ветку
          if git show-ref --verify --quiet refs/heads/stable; then
            git checkout stable
            git merge main --no-ff -m "chore: sync stable with main"
          else
            git checkout -b stable
          fi
          
          git push -u origin stable
      
      - name: Notify success
        run: |
          echo "✅ Stable branch synced with main"
```

### 4.3. Процесс релиза

**Пошаговый процесс:**

```bash
# 1. Подготовка релиза (в ветке main)
git checkout main
git pull origin main

# 2. Обновить CHANGELOG.md
# Добавить записи о изменениях

# 3. Обновить версию в qwen-extension.json
# "version": "0.8.0"

# 4. Закоммитить изменения
git add .qwen/qwen-extension.json CHANGELOG.md
git commit -m "chore: prepare release v0.8.0"
git push origin main

# 5. Создать Git тег
git tag -a v0.8.0 -m "Release v0.8.0: Extensions + CI/CD"
git push origin v0.8.0

# 6. GitHub Actions автоматически:
#    - Обновит версию в манифесте
#    - Создаст GitHub Release
#    - Опубликует релиз

# 7. Пользователи обновляются:
qwen extensions update qwen-orchestrator-kit
```

### 4.4. Семантическое версионирование

**Правила:**

```
MAJOR.MINOR.PATCH
  ↓     ↓     ↓
  1     2     3

MAJOR (1): Несовместимые изменения API
  - Удаление функциональности
  - Изменение API агентов
  - Breaking changes

MINOR (2): Новая функциональность (обратно совместимая)
  - Новые агенты
  - Новые навыки
  - Новые команды

PATCH (3): Исправления ошибок (обратно совместимые)
  - Исправление багов
  - Улучшение документации
  - Рефакторинг
```

**Примеры:**

```
0.7.0 → 0.7.1  # Исправление ошибок (PATCH)
0.7.0 → 0.8.0  # Новая функциональность (MINOR)
0.7.0 → 1.0.0  # Стабильный релиз (MAJOR)
```

---

## 5. Пошаговый план

### Этап 1: Подготовка (1-2 дня)

**Задачи:**

- [ ] **1.1. Создать манифест qwen-extension.json**
  - Файл: `.qwen/qwen-extension.json`
  - Содержимое: см. раздел 3.2
  - Ответственный: qwen-code-cli-specialist

- [ ] **1.2. Создать QWEN.md для расширения**
  - Файл: `.qwen/QWEN.md`
  - Содержимое: см. раздел 3.3
  - Ответственный: qwen-code-cli-specialist

- [ ] **1.3. Обновить структуру расширения**
  - Проверить наличие всех директорий
  - Удалить лишние файлы
  - Ответственный: qwen-code-cli-specialist

- [ ] **1.4. Протестировать установку**
  ```bash
  # Локальная установка
  qwen extensions link ./qwen_orc_kit_ru
  
  # Проверка
  qwen extensions list
  qwen extensions detail qwen-orchestrator-kit
  ```
  - Ответственный: tester

- [ ] **1.5. Создать миграционный скрипт**
  - Файл: `.qwen/scripts/migration/migrate-to-extensions.sh`
  - Содержимое: см. раздел 3.4
  - Ответственный: qwen-code-cli-specialist

**Критерии завершения:**
- ✅ Манифест создан и валиден
- ✅ QWEN.md создан
- ✅ Структура правильная
- ✅ Установка работает
- ✅ Миграционный скрипт готов

### Этап 2: Тестирование (2-3 дня)

**Задачи:**

- [ ] **2.1. Тест на чистом проекте**
  ```bash
  # Создать тестовый проект
  mkdir test-project && cd test-project
  git init
  
  # Установить расширение
  qwen extensions install /path/to/qwen_orc_kit_ru
  
  # Проверить работу
  qwen extensions list
  qwen "Привет"
  ```
  - Ответственный: tester

- [ ] **2.2. Тест на существующем проекте**
  ```bash
  # Существующий проект с .qwen/
  cd existing-project
  
  # Запустить миграцию
  ../qwen_orc_kit_ru/.qwen/scripts/migration/migrate-to-extensions.sh
  
  # Проверить работу
  qwen extensions list
  qwen "Привет"
  ```
  - Ответственный: tester

- [ ] **2.3. Тест обновления**
  ```bash
  # Внести изменения в расширение
  cd qwen_orc_kit_ru
  git commit -m "test: update for testing"
  git push
  
  # Обновить расширение
  qwen extensions update qwen-orchestrator-kit
  
  # Проверить версию
  qwen extensions list
  ```
  - Ответственный: tester

- [ ] **2.4. Тест отката**
  ```bash
  # Восстановить из backup
  cp -r .qwen.backup.*/* .qwen/
  
  # Проверить работу
  qwen "Привет"
  ```
  - Ответственный: tester

**Критерии завершения:**
- ✅ Чистый проект работает
- ✅ Существующий проект мигрирован
- ✅ Обновление работает
- ✅ Откат работает

### Этап 3: CI/CD (1-2 дня)

**Задачи:**

- [ ] **3.1. Настроить GitHub Actions**
  - Файл: `.github/workflows/release.yml`
  - Содержимое: см. раздел 4.1
  - Ответственный: devops

- [ ] **3.2. Создать workflow для stable ветки**
  - Файл: `.github/workflows/stable-sync.yml`
  - Содержимое: см. раздел 4.2
  - Ответственный: devops

- [ ] **3.3. Протестировать авто-релиз**
  ```bash
  # Создать тестовый тег
  git tag -a v0.8.0-test -m "Test release"
  git push origin v0.8.0-test
  
  # Проверить GitHub Actions
  # Проверить GitHub Release
  
  # Удалить тестовый тег
  git tag -d v0.8.0-test
  git push origin :refs/tags/v0.8.0-test
  ```
  - Ответственный: devops

- [ ] **3.4. Настроить уведомления**
  - Discord webhook (опционально)
  - Telegram webhook (опционально)
  - Email уведомления (опционально)
  - Ответственный: devops

**Критерии завершения:**
- ✅ GitHub Actions работает
- ✅ Релиз создаётся автоматически
- ✅ Версия обновляется автоматически
- ✅ Уведомления работают

### Этап 4: Публикация (1 день)

**Задачи:**

- [ ] **4.1. Создать релиз v0.8.0**
  ```bash
  # Обновить версию
  # .qwen/qwen-extension.json: "version": "0.8.0"
  # package.json: "version": "0.8.0"
  # .version: "0.8.0"
  
  # Закоммитить
  git add .qwen/qwen-extension.json package.json .version
  git commit -m "chore: prepare release v0.8.0"
  git push origin main
  
  # Создать тег
  git tag -a v0.8.0 -m "Release v0.8.0: Extensions + CI/CD"
  git push origin v0.8.0
  ```
  - Ответственный: maintainer

- [ ] **4.2. Обновить README**
  - Добавить раздел "Установка расширения"
  - Добавить раздел "Обновление"
  - Обновить примеры
  - Ответственный: qwen-code-cli-specialist

- [ ] **4.3. Опубликовать документацию**
  - MIGRATION.md
  - EXTENSIONS.md
  - RELEASE.md
  - Ответственный: qwen-code-cli-specialist

- [ ] **4.4. Уведомить пользователей**
  - GitHub Issues
  - Discord/Telegram
  - Email рассылка (опционально)
  - Ответственный: maintainer

**Критерии завершения:**
- ✅ Релиз v0.8.0 создан
- ✅ README обновлён
- ✅ Документация опубликована
- ✅ Пользователи уведомлены

---

## 6. Риски и решения

| Риск | Вероятность | Влияние | Решение |
|------|-------------|---------|---------|
| **Потеря конфигурации проекта** | Средняя | Высокое | Backup перед миграцией, скрипт сохраняет настройки |
| **Несовместимость версий** | Низкая | Высокое | Проверка версий Qwen Code, требования в манифесте |
| **Ошибки в миграционном скрипте** | Средняя | Среднее | Тестирование на тестовых проектах, откат через backup |
| **Проблемы с CI/CD** | Низкая | Среднее | Ручной релиз как fallback, тестирование workflow |
| **Пользователи не обновятся** | Высокая | Низкое | Уведомления, документация, автоматические обновления |
| **Конфликты MCP конфигураций** | Средняя | Низкое | Разделение глобальных и проектных настроек |
| **Потеря данных в .qwen/specify/** | Низкая | Высокое | Миграционный скрипт не трогает specify/ |
| **Ошибки в манифесте** | Низкая | Высокое | Валидация манифеста перед релизом |

---

## 7. Метрики успеха

### 7.1. Технические метрики

| Метрика | Целевое значение | Измерение |
|---------|------------------|-----------|
| **Время установки** | < 1 минуты | `time qwen extensions install ...` |
| **Время обновления** | < 30 секунд | `time qwen extensions update ...` |
| **Размер расширения** | < 10 MB | `du -sh ~/.qwen/extensions/qwen-orchestrator-kit/` |
| **Количество агентов** | 36+ | `ls -1 agents/ | wc -l` |
| **Количество навыков** | 40+ | `ls -1 skills/ | wc -l` |
| **Покрытие тестами** | ≥ 80% | Quality Gate 5 |

### 7.2. Пользовательские метрики

| Метрика | Целевое значение | Измерение |
|---------|------------------|-----------|
| **Успешность установки** | ≥ 95% | GitHub Issues / установок |
| **Успешность обновления** | ≥ 90% | GitHub Issues / обновлений |
| **Удовлетворённость** | ≥ 4.5/5 | Опросы пользователей |
| **Время миграции** | < 5 минут | Замеры на тестовых проектах |
| **Количество проблем** | < 5 на релиз | GitHub Issues |

### 7.3. Процессные метрики

| Метрика | Целевое значение | Измерение |
|---------|------------------|-----------|
| **Время релиза** | < 10 минут | GitHub Actions duration |
| **Автоматизация** | ≥ 90% | Ручные шаги / всего шагов |
| **Частота релизов** | 1-2 в месяц | GitHub Releases |
| **Время отклика на баги** | < 24 часа | GitHub Issues response time |

---

## 8. Приложения

### A. Чек-лист для релиза

```markdown
## Pre-Release Checklist

- [ ] Обновить версию в qwen-extension.json
- [ ] Обновить версию в package.json
- [ ] Обновить версию в .version
- [ ] Обновить CHANGELOG.md
- [ ] Проверить манифест (валидация)
- [ ] Протестировать установку
- [ ] Протестировать обновление
- [ ] Протестировать миграцию
- [ ] Проверить документацию
- [ ] Создать Git тег
- [ ] Push тега
- [ ] Проверить GitHub Actions
- [ ] Проверить GitHub Release
- [ ] Уведомить пользователей

## Post-Release Checklist

- [ ] Проверить метрики установки
- [ ] Мониторить GitHub Issues
- [ ] Ответить на вопросы пользователей
- [ ] Обновить документацию (при необходимости)
- [ ] Собрать обратную связь
```

### B. Команды для управления расширением

```bash
# Установка
qwen extensions install https://github.com/yourusername/qwen_orc_kit_ru
qwen extensions install ./qwen_orc_kit_ru  # локально

# Обновление
qwen extensions update qwen-orchestrator-kit
qwen extensions update --all

# Проверка
qwen extensions list
qwen extensions detail qwen-orchestrator-kit

# Управление
qwen extensions enable qwen-orchestrator-kit
qwen extensions disable qwen-orchestrator-kit
qwen extensions uninstall qwen-orchestrator-kit

# Разработка
qwen extensions link ./qwen_orc_kit_ru
qwen extensions unlink qwen-orchestrator-kit
```

### C. Ссылки на документацию

- [Extension Management](https://qwenlm.github.io/qwen-code-docs/en/developers/extensions/extension)
- [Getting Started Extensions](https://qwenlm.github.io/qwen-code-docs/en/developers/extensions/getting-started-extensions)
- [Extension Releasing](https://github.com/qwenlm/qwen-code/blob/main/docs/extensions/extension-releasing.md)
- [Introduction to Extensions](https://qwenlm.github.io/qwen-code-docs/en/users/extension/introduction)

---

## 9. Заключение

### 9.1. Итоговый статус

| Компонент | Статус | Примечание |
|-----------|--------|------------|
| Манифест qwen-extension.json | ⚠️ Требуется | Создать в Фазе 1 |
| QWEN.md расширения | ⚠️ Требуется | Создать в Фазе 1 |
| Структура расширения | ✅ Готово | Соответствует требованиям |
| Миграционный скрипт | ⚠️ Требуется | Создать в Фазе 1 |
| CI/CD workflow | ⚠️ Требуется | Создать в Фазе 3 |
| Git теги | ⚠️ Требуется | Создать для v0.8.0 |
| Документация | ⚠️ Частично | Создать MIGRATION.md, EXTENSIONS.md, RELEASE.md |

### 9.2. Критические действия

**Обязательно:**
1. Создать манифест qwen-extension.json
2. Создать QWEN.md для расширения
3. Создать миграционный скрипт
4. Настроить CI/CD
5. Создать Git тег v0.8.0

**Опционально:**
1. Настроить stable/dev ветки
2. Настроить автоматические уведомления
3. Создать видео-туториал

### 9.3. Финальные рекомендации

**Миграция на Extensions — это:**
- ✅ Упрощение установки (1 команда)
- ✅ Автоматические обновления
- ✅ Чистая структура проекта
- ✅ Лучшее разделение ответственности

**Риски минимизируются:**
- Backup перед миграцией
- Тестирование на тестовых проектах
- Пошаговая документация
- Поддержка пользователей

**Рекомендуемый порядок:**
1. Подготовка (Фазы 1-2)
2. Тестирование (Фаза 3)
3. CI/CD (Фаза 4)
4. Публикация (Фаза 5)

---

**План сгенерирован:** 29 марта 2026  
**Агент:** qwen-code-cli-specialist  
**Версия:** 1.0  
**Следующий шаг:** Реализация Фазы 1 (Подготовка)
