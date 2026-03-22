#!/bin/bash
# Скрипт автоматического создания агентов
# Назначение: Создание новых агентов (оркестраторов и воркеров) на основе заданных параметров

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка аргументов
if [ $# -lt 3 ]; then
    echo "Использование: $0 <agent_type> <domain> <name> [description]"
    echo "  agent_type: orc (оркестратор) или work (воркер)"
    echo "  domain: dev, frontend, backend, testing, research, security"
    echo "  name: имя агента в формате kebab-case"
    echo "  description: (опционально) описание агента"
    exit 1
fi

AGENT_TYPE=$1
DOMAIN=$2
NAME=$3
DESCRIPTION=${4:-"Автоматически созданный агент для домена $DOMAIN"}

# Проверка типа агента
if [[ "$AGENT_TYPE" != "orc" && "$AGENT_TYPE" != "work" ]]; then
    log_error "Неверный тип агента: $AGENT_TYPE. Допустимые значения: orc, work"
    exit 1
fi

# Проверка домена
VALID_DOMAINS=("dev" "frontend" "backend" "testing" "research" "security")
if [[ ! " ${VALID_DOMAINS[@]} " =~ " ${DOMAIN} " ]]; then
    log_error "Неверный домен: $DOMAIN. Допустимые значения: ${VALID_DOMAINS[*]}"
    exit 1
fi

# Проверка формата имени (kebab-case)
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]; then
    log_error "Неверный формат имени: $NAME. Имя должно быть в формате kebab-case (например: my-agent-name)"
    exit 1
fi

# Формирование полного имени агента
FULL_NAME="${AGENT_TYPE}_${DOMAIN}_${NAME}"

# Проверка, существует ли уже агент с таким именем
AGENT_FILE=".qwen/agents/${FULL_NAME}.md"
if [ -f "$AGENT_FILE" ]; then
    log_warning "Агент с именем $FULL_NAME уже существует: $AGENT_FILE"
    read -p "Перезаписать файл? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Создание агента отменено."
        exit 0
    fi
fi

# Создание директории, если не существует
mkdir -p .qwen/agents

# Определение типа агента для описания
if [ "$AGENT_TYPE" = "orc" ]; then
    AGENT_DESCRIPTION="Используйте для координации задач разработки в области $DOMAIN. Реализует итерационную логику и шаблон возврата управления. Следует стандартизированному формату отчетности."
    COLOR="purple"
else
    AGENT_DESCRIPTION="Активно используйте для выполнения задач из файлов плана в области $DOMAIN. Следует стандартизированному формату отчетности и реализует шаблон возврата управления."
    COLOR="blue"
fi

# Создание файла агента
cat > "$AGENT_FILE" << EOF
---
name: $FULL_NAME
description: $AGENT_DESCRIPTION
color: $COLOR
---

# Агент: $FULL_NAME

## Назначение
Краткое описание функций агента $FULL_NAME. Агент должен выполнять задачи в домене $DOMAIN и следовать архитектурным принципам проекта.

## Git Workflow (ОБЯЗАТЕЛЬНО)
EOF

# Добавление Git Workflow в зависимости от типа агента
if [ "$AGENT_TYPE" = "orc" ]; then
    cat >> "$AGENT_FILE" << 'EOF'

**ПЕРЕД НАЧАЛОМ КАЖДОЙ ЗАДАЧИ:**
1. Создать feature-ветку:
   ```bash
   .qwen/scripts/git/create-feature-branch.sh "<domain>-<task-name>"
   ```
2. Задокументировать имя ветки в отчёте

**ПОСЛЕ ВЫПОЛНЕНИЯ КАЖДОЙ ЗАДАЧИ:**
1. Pre-commit ревью:
   ```bash
   .qwen/scripts/git/pre-commit-review.sh "feat: <domain> <description>"
   ```
2. Quality Gate:
   ```bash
   .qwen/scripts/quality-gates/check-commit.sh
   ```
3. Push ветки:
   ```bash
   git push -u origin feature/<domain>-<name>
   ```

**ПОСЛЕ ЗАВЕРШЕНИЯ ФАЗЫ:**
1. Слияние в develop:
   ```bash
   git checkout develop
   git merge --no-ff feature/<domain>-<name>
   git branch -d feature/<domain>-<name>
   ```
EOF
else
    cat >> "$AGENT_FILE" << 'EOF'

**ВОЛНОВЫЕ АГЕНТЫ выполняют Git Workflow после КАЖДОЙ задачи:**

**ПОСЛЕ ВЫПОЛНЕНИЯ ЗАДАЧИ:**
1. Pre-commit ревью:
   ```bash
   .qwen/scripts/git/pre-commit-review.sh "<type>: <description>"
   ```
   Где `<type>`: feat, fix, docs, style, refactor, test, chore

2. Quality Gate:
   ```bash
   .qwen/scripts/quality-gates/check-commit.sh
   ```

3. Коммит (только после успешного Quality Gate):
   ```bash
   git add -A
   git commit -m "<type>: <description>"
   ```

**ВАЖНО:**
- Воркеры НЕ создают feature-ветки (это делает оркестратор)
- Воркеры ДЕЛАЮТ коммиты после каждой завершённой задачи
- Воркеры ПРОВЕРЯЮТ Quality Gate перед коммитом
EOF
fi

# Добавление остальной части шаблона
cat >> "$AGENT_FILE" << EOF

## Использование сервера MCP
- Используйте \`mcp__context7__*\` для поиска актуальных паттернов и API при реализации функций
- Триггер: При реализации функций с использованием внешних библиотек или фреймворков

## Инструкции

### Фаза 1: Анализ задачи
1.1. Прочитать параметры задачи из файла плана
1.2. Определить тип и сложность задачи
1.3. Проверить доступность необходимых ресурсов

### Фаза 2: Подготовка
2.1. Подготовить необходимые данные и контекст
2.2. Инициализировать требуемые инструменты
2.3. Проверить зависимости

### Фаза 3: Выполнение
3.1. Выполнить основную логику агента
3.2. Обработать результаты
3.3. Обеспечить корректную обработку ошибок

### Фаза 4: Проверка качества
4.1. Проверить корректность выполнения задачи
4.2. Убедиться, что результат соответствует требованиям
4.3. Проверить соблюдение стандартов качества

### Фаза 5: Git Workflow и Отчетность
5.1. **Pre-commit ревью** (Git Workflow)
5.2. **Quality Gate** (Git Workflow)
5.3. **Коммит** (Git Workflow)
5.4. Сформировать отчет о выполнении задачи
5.5. Зафиксировать метрики выполнения
5.6. Подготовить данные для следующего этапа (если применимо)

## Формат файла плана
\`\`\`json
{
  "phase": 3,
  "config": {
    "priority": "high|medium|low",
    "scope": ["src/", "lib/", "tests/"],
    "timeout": 300
  },
  "validation": {
    "required": ["type-check", "build"],
    "optional": ["tests"]
  },
  "nextAgent": "work_dev_code_analyzer",
  "mcpGuidance": {
    "recommended": ["mcp__context7__*"],
    "library": "qwen-orchestrator-kit",
    "reason": "Check current patterns before implementing changes"
  }
}
\`\`\`

## Шаблон возврата управления
После выполнения задачи агент возвращает управление с указанием результата выполнения и метаданными. При ошибке возвращает информацию об ошибке и рекомендации по исправлению.

## Стандартизированная отчетность
- Заголовок: "Выполнение задачи: {описание_задачи}"
- Исполнительное резюме: Краткое описание выполненной работы
- Выполненная работа: Перечень выполненных действий
- **Git Workflow:**
  - Pre-commit review: ✅/❌
  - Quality Gate: ✅/❌
  - Коммит: <hash>
- Внесенные изменения: Список измененных файлов
- Результаты валидации: Статус проверок качества
- Метрики: Время выполнения, количество обработанных элементов
- Обнаруженные ошибки: Ошибки при выполнении (если были)
- Следующие шаги: Рекомендации по дальнейшим действиям
- Артефакты: Список созданных файлов

## Интеграция навыков
- \`generate-report-header\` - для формирования заголовков отчетов
- \`run-quality-gate\` - для проверки качества создаваемого кода
- \`format-markdown-table\` - для форматирования таблиц в документации
- \`parse-error-logs\` - для обработки ошибок
- \`validate-plan-file\` - для проверки корректности плана
- \`validate-report-file\` - для проверки формата отчетов
EOF

# Обновление индекса агентов (если файл существует)
if [ -f "docs/agents-index.md" ]; then
    log_info "Обновление индекса агентов..."
    if grep -q "$FULL_NAME" "docs/agents-index.md"; then
        log_warning "Агент $FULL_NAME уже присутствует в индексе"
    else
        echo "- [$FULL_NAME](../$AGENT_FILE) - $DESCRIPTION" >> "docs/agents-index.md"
        log_success "Агент добавлен в индекс: docs/agents-index.md"
    fi
else
    log_warning "Файл индекса агентов docs/agents-index.md не найден"
fi

# Обновление общего README.md (если файл существует и содержит секцию агентов)
if [ -f "README.md" ]; then
    log_info "Проверка README.md на наличие упоминания нового агента..."
    if ! grep -q "$FULL_NAME" "README.md"; then
        log_info "Агент $FULL_NAME добавлен в проект, но не упомянут в README.md"
    fi
fi

log_info "Создание агента завершено!"