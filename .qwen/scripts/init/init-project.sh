#!/bin/bash
# Скрипт: .qwen/scripts/init/init-project.sh
# Назначение: Инициализация нового проекта на основе Qwen Orchestrator Kit Template
# Использование: .qwen/scripts/init/init-project.sh

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода сообщений
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

# Заголовок
echo "========================================"
echo "  Qwen Orchestrator Kit: Инициализация"
echo "========================================"
echo ""

# Проверка, что мы в корне проекта
if [ ! -f "QWEN.md" ]; then
    log_error "QWEN.md не найден в текущей директории"
    log_error "Запустите скрипт из корня проекта"
    exit 1
fi

if [ ! -d ".qwen" ]; then
    log_error "Директория .qwen не найдена"
    log_error "Запустите скрипт из корня проекта"
    exit 1
fi

log_info "Начало инициализации проекта..."
echo ""

# Список файлов для удаления
FILES_TO_REMOVE=(
    "CHANGELOG.md"
    "README.md"
    "INSTALLATION.md"
    "USAGE_INSTRUCTIONS.md"
    "CONTRIBUTING.md"
    "QUICKSTART.md"
    ".markdownlint.yml"
    ".version"
    "package.json"
)

# Удаление файлов шаблона
log_info "Удаление файлов шаблона..."
for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        log_info "  Удалено: $file"
    fi
done

# Удаление директорий разработки (не нужны в проекте пользователя)
DIRS_TO_REMOVE=("reports" "specs" "tests")
log_info "Удаление директорий разработки..."
for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        log_info "  Удалена директория: $dir"
    fi
done

# Удаление конституции шаблона (пользователь создаст свою)
if [ -f ".qwen/specify/memory/constitution.md" ]; then
    log_info "Удаление конституции шаблона..."
    rm -f ".qwen/specify/memory/constitution.md"
    log_success "  Конституция шаблона удалена"
    log_info "  Пользователь создаст свою через: speckit.constitution"
fi

# Удаление старой директории .git (если существует)
if [ -d ".git" ]; then
    log_info "Удаление старой Git истории..."
    rm -rf ".git"
    log_success "  Старая .git удалена"
fi

echo ""

# Инициализация нового Git репозитория
log_info "Инициализация нового Git репозитория..."
git init
log_success "  Git репозиторий инициализирован"

# Удаление старого .gitignore (из шаблона разработки)
if [ -f ".gitignore" ]; then
    log_info "Удаление старого .gitignore (шаблон разработки)..."
    rm -f ".gitignore"
    log_success "  Старый .gitignore удалён"
fi

# Создание чистого .gitignore для проекта пользователя
log_info "Создание .gitignore для проекта..."
cat > .gitignore << 'EOF'
# Node modules
node_modules/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment
.env
.env.local
.env.*.local

# Build
dist/
build/
*.min.js
*.min.css
EOF
log_success "  .gitignore создан (НЕ игнорирует .qwen/!)"

# Создание начальной структуры README.md
log_info "Создание README.md..."
cat > README.md << 'EOF'
# Мой Проект

Описание проекта.

## Начало работы

```bash
# Инициализация проекта
.qwen/scripts/init/init-project.sh

# Запуск Qwen Code
qwen
```

## Документация

См. [QWEN.md](QWEN.md) для информации об оркестрации задач.
EOF
log_success "  README.md создан"

# Создание начального CHANGELOG.md
log_info "Создание CHANGELOG.md..."
cat > CHANGELOG.md << 'EOF'
# Changelog

Все заметные изменения в этом проекте будут задокументированы в этом файле.

## [0.1.0] - YYYY-MM-DD

### Добавлено
- Начальная версия проекта
EOF
log_success "  CHANGELOG.md создан"

# Создание package.json (если не существует)
if [ ! -f "package.json" ]; then
    log_info "Создание package.json..."
    cat > package.json << 'EOF'
{
  "name": "my-qwen-project",
  "version": "0.1.0",
  "description": "Проект на базе Qwen Orchestrator Kit",
  "private": true
}
EOF
    log_success "  package.json создан"
else
    log_info "  package.json уже существует"
fi

echo ""
log_success "========================================"
log_success "  Инициализация завершена!"
log_success "========================================"
echo ""
log_info "Следующие шаги:"
echo "  1. Запустите: qwen"
echo "  2. Введите ваше техническое задание"
echo ""
