#!/bin/bash
# Скрипт: .qwen/scripts/orchestration-tools/initialize-project.sh
# Назначение: Инициализация нового проекта на основе шаблона Qwen Code Orchestrator Kit
# Использование: .qwen/scripts/orchestration-tools/initialize-project.sh [имя-проекта]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${CYAN}📍 $1${NC}"
}

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Инициализация проекта Qwen Code Orchestrator Kit        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# ШАГ 1: Проверка окружения
# ============================================================================
log_step "Шаг 1: Проверка окружения..."

if ! command -v git &> /dev/null; then
    log_error "Git не установлен"
    exit 1
fi
log_success "Git установлен: $(git --version)"

if ! command -v node &> /dev/null; then
    log_warning "Node.js не установлен (рекомендуется для некоторых функций)"
else
    log_success "Node.js установлен: $(node --version)"
fi

echo ""

# ============================================================================
# ШАГ 2: Инициализация Git репозитория
# ============================================================================
log_step "Шаг 2: Инициализация Git репозитория..."

if [ -d ".git" ]; then
    log_warning "Git репозиторий уже инициализирован"
else
    git init
    log_success "Git репозиторий инициализирован"
fi

echo ""

# ============================================================================
# ШАГ 3: Создание ветки develop
# ============================================================================
log_step "Шаг 3: Создание ветки develop..."

if ! git branch | grep -q "develop"; then
    git branch develop
    log_success "Ветка develop создана"
else
    log_warning "Ветка develop уже существует"
fi

# Проверка текущей ветки
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ]; then
    log_info "Переключение с main на develop..."
    git checkout develop
    log_success "Переключено на ветку develop"
fi

echo ""

# ============================================================================
# ШАГ 4: Создание .gitignore
# ============================================================================
log_step "Шаг 4: Создание .gitignore..."

if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# State directory (development artifacts)
state/

# Development reports
ORCHESTRATION_DEVELOPMENT_REPORT.md
release_preparation_report.md

# Release files
RELEASE_*.md
release_*.md

# TEMPLATE.md
TEMPLATE.md

# Temporary files
.tmp/
*.tmp

# Logs
logs/
*.log

# Backup files
*.backup
backups/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Node modules (если используется)
node_modules/

# Python (если используется)
__pycache__/
*.pyc
.venv/
venv/

# Rust (если используется)
target/
**/target/

# Build artifacts
dist/
build/
EOF
    log_success ".gitignore создан"
else
    log_warning ".gitignore уже существует"
    
    # Проверка наличия state/ в .gitignore
    if ! grep -q "^state/" .gitignore 2>/dev/null; then
        log_info "Добавление state/ в .gitignore..."
        echo "" >> .gitignore
        echo "# State directory" >> .gitignore
        echo "state/" >> .gitignore
        log_success "state/ добавлен в .gitignore"
    fi
fi

echo ""

# ============================================================================
# ШАГ 5: Создание pre-commit хука
# ============================================================================
log_step "Шаг 5: Настройка pre-commit хука..."

if [ ! -f ".git/hooks/pre-commit" ]; then
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit хук для Qwen Code Orchestrator Kit

echo "=== Pre-commit проверки ==="

# Проверка синтаксиса bash скриптов
for file in $(git diff --cached --name-only | grep '\.sh$'); do
    if [ -f "$file" ]; then
        bash -n "$file" || {
            echo "❌ Ошибка синтаксиса в $file"
            exit 1
        }
    fi
done

# Проверка markdown (если есть markdownlint)
if command -v markdownlint &> /dev/null; then
    markdownlint $(git diff --cached --name-only | grep '\.md$') || {
        echo "❌ Ошибки markdown"
        exit 1
    }
fi

echo "✅ Pre-commit проверки пройдены"
exit 0
EOF
    chmod +x .git/hooks/pre-commit
    log_success "Pre-commit хук настроен"
else
    log_warning "Pre-commit хук уже существует"
fi

echo ""

# ============================================================================
# ШАГ 6: Проверка конституции проекта
# ============================================================================
log_step "Шаг 6: Проверка конституции проекта..."

CONSTITUTION_FILE=".qwen/specify/memory/constitution.md"

if [ ! -f "$CONSTITUTION_FILE" ]; then
    log_warning "Конституция проекта отсутствует"
    log_info "Создайте через: speckit.constitution"
else
    log_success "Конституция проекта существует"
fi

echo ""

# ============================================================================
# ШАГ 7: Проверка структуры проекта
# ============================================================================
log_step "Шаг 7: Проверка структуры проекта..."

REQUIRED_DIRS=(
    ".qwen/agents"
    ".qwen/commands"
    ".qwen/skills"
    ".qwen/scripts"
    ".qwen/docs"
    ".qwen/templates"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        log_error "Отсутствует директория: $dir"
    fi
done

log_success "Структура проекта проверена"

echo ""

# ============================================================================
# ШАГ 8: Запуск Pre-Flight проверок
# ============================================================================
log_step "Шаг 8: Запуск Pre-Flight проверок..."

if [ -f ".qwen/scripts/orchestration-tools/pre-flight-check.sh" ]; then
    .qwen/scripts/orchestration-tools/pre-flight-check.sh "Инициализация"
    if [ $? -ne 0 ]; then
        log_error "Pre-Flight проверки не пройдены"
        exit 1
    fi
else
    log_warning "pre-flight-check.sh отсутствует"
fi

echo ""

# ============================================================================
# ШАГ 9: Создание CHANGELOG.md
# ============================================================================
log_step "Шаг 9: Проверка CHANGELOG.md..."

if [ ! -f "CHANGELOG.md" ]; then
    cat > CHANGELOG.md << 'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - YYYY-MM-DD

### Added
- Initial project setup
- Qwen Code Orchestrator Kit template

EOF
    log_success "CHANGELOG.md создан"
else
    log_warning "CHANGELOG.md уже существует"
fi

echo ""

# ============================================================================
# ШАГ 10: Создание README.md (если отсутствует)
# ============================================================================
log_step "Шаг 10: Проверка README.md..."

if [ ! -f "README.md" ]; then
    cat > README.md << 'EOF'
# Проект

Описание проекта.

## Начало работы

### Требования

- Git
- Node.js (рекомендуется)

### Установка

```bash
git clone <repository-url>
cd <project-directory>
```

### Использование

```bash
# Запуск Pre-Flight проверок
.qwen/scripts/orchestration-tools/pre-flight-check.sh

# Инициализация (если нужно)
.qwen/scripts/orchestration-tools/initialize-project.sh
```

## Документация

- [QWEN.md](QWEN.md) - Поведенческая парадигма
- [QUICKSTART.md](QUICKSTART.md) - Быстрый старт
- [INSTALLATION.md](INSTALLATION.md) - Установка

## Разработка

### Git Workflow

- `main` — production релизы
- `develop` — основная ветка разработки
- `feature/*` — новые функции
- `bugfix/*` — исправления ошибок
- `hotfix/*` — срочные исправления

### Коммиты

Используем Conventional Commits:
- `feat:` — новая функция
- `fix:` — исправление
- `docs:` — документация
- `style:` — форматирование
- `refactor:` — рефакторинг
- `test:` — тесты
- `chore:` — служебные

## License

EOF
    log_success "README.md создан"
else
    log_warning "README.md уже существует"
fi

echo ""

# ============================================================================
# ФИНАЛ
# ============================================================================
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ✅ Инициализация проекта завершена!                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
log_success "Проект готов к разработке!"
echo ""
echo "Следующие шаги:"
echo "  1. Изучите документацию: QWEN.md, QUICKSTART.md"
echo "  2. Создайте конституцию: speckit.constitution"
echo "  3. Создайте первую спецификацию: speckit.specify"
echo "  4. Запустите Фазу 0: speckit.plan"
echo ""
log_info "Текущая ветка: $(git branch --show-current)"
log_info "Git статус: $(git status --short | wc -l | xargs) изменений"
echo ""
