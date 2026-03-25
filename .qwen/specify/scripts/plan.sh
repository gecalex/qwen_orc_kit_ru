#!/bin/bash
# SpecKit: Plan Script
# Назначение: Планирование реализации ВСЕГО проекта
# Версия: 2.0.0 (Исправление: ОБЩИЙ план для всех модулей)

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECIFY_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SPECIFY_DIR")")"
TEMPLATES_DIR="$SPECIFY_DIR/templates"
LOGS_DIR="$PROJECT_ROOT/logs"

# plan.sh создаёт ОБЩИЙ план для ВСЕГО проекта!
# Файлы создаются в .qwen/specify/, а не в specs/{ID}/
PLAN_FILE="$PROJECT_ROOT/.qwen/specify/plan.md"
DATA_MODEL_FILE="$PROJECT_ROOT/.qwen/specify/data-model.md"
RESEARCH_FILE="$PROJECT_ROOT/.qwen/specify/research.md"
QUICKSTART_FILE="$PROJECT_ROOT/.qwen/specify/quickstart.md"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Логирование
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."

    # Проверка конституции
    if [ ! -f "$PROJECT_ROOT/.qwen/specify/memory/constitution.md" ]; then
        log_error "constitution.md не найден. Запустите сначала speckit.constitution"
        exit 1
    fi

    # Проверка наличия спецификаций
    local specs_count=$(ls -d "$PROJECT_ROOT/.qwen/specify/specs/"*/ 2>/dev/null | wc -l)
    if [ "$specs_count" -eq 0 ]; then
        log_error "Спецификации не найдены. Запустите сначала speckit.specify"
        exit 1
    fi

    log_success "Зависимости проверены (конституция + $specs_count спецификаций)"
}

# Создание plan.md (ОБЩИЙ ПЛАН)
create_plan() {
    log_info "Создание ОБЩЕГО plan.md..."

    # Найти все спецификации
    local specs_dir="$PROJECT_ROOT/.qwen/specify/specs"
    local modules=()
    for spec_dir in "$specs_dir"/*/; do
        if [ -d "$spec_dir" ]; then
            module_name=$(basename "$spec_dir")
            modules+=("$module_name")
        fi
    done

    cat > "$PLAN_FILE" << EOF
# Project Implementation Plan: $PROJECT_NAME

**Версия:** 2.0.0
**Дата:** $(date +%Y-%m-%d)
**Статус:** Draft
**Модулей:** ${#modules[@]}

---

## 1. Архитектура проекта

### 1.1 Общая схема
\`\`\`
┌─────────────────┐
│    Frontend     │
│   (React 19)    │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│    Backend      │
│  (FastAPI +     │
│   PostgreSQL)   │
└─────────────────┘
\`\`\`

### 1.2 Компоненты
- **Frontend:** React 19 + TypeScript + Bootstrap
- **Backend:** Python 3.11+ + FastAPI
- **БД:** PostgreSQL (Supabase)

### 1.3 Модули проекта
EOF

    for module in "${modules[@]}"; do
        echo "- **$module**" >> "$PLAN_FILE"
    done

    cat >> "$PLAN_FILE" << 'EOF'

---

## 2. Модель данных

### 2.1 Основные сущности
- User
- Note
- Tag
- SearchIndex
- ExportProfile

### 2.2 Связи
- User → Notes (1:N)
- Note → Tags (M:N)
- Note → SearchIndex (1:1)

---

## 3. План реализации

### Фаза 1: Инфраструктура
- Настройка проекта
- CI/CD pipeline
- БД

### Фаза 2: Backend
- API модуль
- Notes API
- Search API
- Export/Import API

### Фаза 3: Frontend
- React приложение
- Notes UI
- Search UI
- Export/Import UI

### Фаза 4: Интеграция
- Тестирование
- Документация
- Релиз

---

## 4. Исследования

### 4.1 Технические риски
- Производительность при большой БД
- Синхронизация данных

### 4.2 Альтернативы
- БД: SQLite (локально) vs PostgreSQL (облако)

---

## 5. Быстрый старт

### 5.1 Настройка окружения
\`\`\`bash
git clone <repo>
cd <repo>
npm install
pip install -r requirements.txt
\`\`\`

### 5.2 Установка зависимостей
- Node.js 20+
- Python 3.11+
- PostgreSQL 15+

### 5.3 Первый запуск
\`\`\`bash
npm run dev
python -m uvicorn main:app --reload
\`\`\`
EOF

    log_success "plan.md создан: $PLAN_FILE"
}

# Создание data-model.md
create_data_model() {
    log_info "Создание data-model.md..."
    
    cat > "$DATA_MODEL_FILE" << 'EOF'
# Data Model

## Схема базы данных

```sql
-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Notes
CREATE TABLE notes (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Tags
CREATE TABLE tags (
    id UUID PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

-- Note-Tags (M:N)
CREATE TABLE note_tags (
    note_id UUID REFERENCES notes(id),
    tag_id UUID REFERENCES tags(id),
    PRIMARY KEY (note_id, tag_id)
);
```

## Сущности

### User
- id: UUID
- email: String
- notes: Note[]

### Note
- id: UUID
- title: String
- content: Text
- tags: Tag[]

### Tag
- id: UUID
- name: String
EOF

    log_success "data-model.md создан: $DATA_MODEL_FILE"
}

# Создание research.md
create_research() {
    log_info "Создание research.md..."
    
    cat > "$RESEARCH_FILE" << 'EOF'
# Research

## Технические риски

### 1. Производительность
**Проблема:** Деградация при 100,000+ заметок

**Решение:**
- Индексация БД
- Пагинация
- Кэширование

### 2. Синхронизация
**Проблема:** Конфликты при одновременном редактировании

**Решение:**
- Optimistic locking
- Версионность
- Conflict resolution

## Альтернативы

### БД
| Вариант | Плюсы | Минусы |
|---------|-------|--------|
| SQLite | Локально, быстро | Нет синхронизации |
| PostgreSQL | Мощно, надёжно | Требует сервер |

### Фронтенд
| Вариант | Плюсы | Минусы |
|---------|-------|--------|
| React | Популярно, экосистема | Сложно |
| Vue | Проще | Меньше экосистема |
EOF

    log_success "research.md создан: $RESEARCH_FILE"
}

# Создание quickstart.md
create_quickstart() {
    log_info "Создание quickstart.md..."
    
    cat > "$QUICKSTART_FILE" << 'EOF'
# Quick Start

## Требования

- Node.js 20+
- Python 3.11+
- PostgreSQL 15+

## Установка

```bash
# Клонировать репозиторий
git clone <repo>
cd <repo>

# Frontend
cd frontend
npm install

# Backend
cd ../backend
pip install -r requirements.txt

# БД
psql -U postgres -c "CREATE DATABASE pkb;"
```

## Запуск

```bash
# Frontend (терминал 1)
cd frontend
npm run dev

# Backend (терминал 2)
cd backend
python -m uvicorn main:app --reload
```

## Проверка

- Frontend: http://localhost:3000
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs
EOF

    log_success "quickstart.md создан: $QUICKSTART_FILE"
}

# Основная функция
main() {
    echo "========================================"
    echo "  SpecKit: Plan (Общий план проекта)"
    echo "  Версия: 2.0.0"
    echo "  Project: $PROJECT_NAME"
    echo "========================================"
    echo ""

    check_dependencies
    echo ""

    create_plan
    echo ""

    create_data_model
    echo ""

    create_research
    echo ""

    create_quickstart
    echo ""

    log_success "========================================"
    log_success "  Общий план создан!"
    log_success "  Файлы:"
    log_success "  - plan.md"
    log_success "  - data-model.md"
    log_success "  - research.md"
    log_success "  - quickstart.md"
    log_success "  Следующий шаг: speckit.tasks"
    log_success "========================================"
}

# Запуск
main
