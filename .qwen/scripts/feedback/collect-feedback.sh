#!/bin/bash

# ============================================
# QWEN ORCHESTRATOR KIT - Feedback Collector
# Версия: 1.0.0
# Дата: 2026-03-21
# ============================================
# Назначение: Сбор обратной связи от разработчиков
# для отправки в репозиторий шаблона
# ============================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

log_section() {
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
}

# Проверка аргументов
if [ -z "$1" ]; then
    log_section "СБОР ОБРАТНОЙ СВЯЗИ"
    echo ""
    log_error "Использование: $0 <output_dir>"
    log_error "Пример: $0 ./feedback-export"
    echo ""
    echo "Скрипт собирает обратную связь из текущего проекта:"
    echo "  - Логи работы агентов (.qwen/logs/agent-calls.log)"
    echo "  - Отчеты Feedback System (.qwen/feedback/)"
    echo "  - Статистику использования команд"
    echo "  - Ошибки и проблемы (.qwen/logs/errors.log)"
    echo "  - Метрики производительности"
    echo ""
    exit 1
fi

OUTPUT_DIR=$1
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FEEDBACK_ARCHIVE="feedback-${TIMESTAMP}.tar.gz"

log_section "СБОР ОБРАТНОЙ СВЯЗИ ИЗ ПРОЕКТА"

# Шаг 1: Создание директории для сбора
log_info "Шаг 1: Создание директории для сбора..."

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/logs"
mkdir -p "${OUTPUT_DIR}/feedback"
mkdir -p "${OUTPUT_DIR}/metrics"
mkdir -p "${OUTPUT_DIR}/errors"
mkdir -p "${OUTPUT_DIR}/info"

log_success "Директория ${OUTPUT_DIR} создана"

# Шаг 2: Сбор логов агентов
log_info "Шаг 2: Сбор логов работы агентов..."

if [ -f ".qwen/logs/agent-calls.log" ]; then
    cp .qwen/logs/agent-calls.log "${OUTPUT_DIR}/logs/"
    log_success "  ✅ agent-calls.log скопирован"
else
    log_warning "  ⚠️ agent-calls.log не найден"
fi

if [ -d ".qwen/reports/agent-calls" ]; then
    cp -r .qwen/reports/agent-calls "${OUTPUT_DIR}/logs/"
    log_success "  ✅ agent-calls reports скопированы"
else
    log_warning "  ⚠️ agent-calls reports не найдены"
fi

# Шаг 3: Сбор отчетов Feedback System
log_info "Шаг 3: Сбор отчетов Feedback System..."

if [ -d ".qwen/feedback" ]; then
    # Копируем только отчеты, не скрипты
    if [ -d ".qwen/feedback/reports" ]; then
        cp -r .qwen/feedback/reports "${OUTPUT_DIR}/feedback/"
        log_success "  ✅ feedback/reports скопированы"
    fi
    
    # Копируем чеклисты
    if [ -d ".qwen/feedback/checklists" ]; then
        cp -r .qwen/feedback/checklists "${OUTPUT_DIR}/feedback/"
        log_success "  ✅ feedback/checklists скопированы"
    fi
else
    log_warning "  ⚠️ .qwen/feedback не найдена"
fi

# Шаг 4: Сбор метрик и статистики
log_info "Шаг 4: Сбор метрик и статистики..."

# Генерация статистики проекта
cat > "${OUTPUT_DIR}/info/project-info.txt" << EOF
Project Information
===================
Date: $(date)
Qwen Orchestrator Kit Version: $(cat .version 2>/dev/null || echo "unknown")
Git Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "unknown")
Total Commits: $(git rev-list --count HEAD 2>/dev/null || echo "unknown")

Directory Structure:
===================
.qwen/agents: $(find .qwen/agents -type f 2>/dev/null | wc -l) files
.qwen/skills: $(find .qwen/skills -type f 2>/dev/null | wc -l) files
.qwen/commands: $(find .qwen/commands -type f 2>/dev/null | wc -l) files
.qwen/scripts: $(find .qwen/scripts -type f 2>/dev/null | wc -l) files
.qwen/docs: $(find .qwen/docs -type f 2>/dev/null | wc -l) files

Disk Usage:
===================
$(du -sh .qwen 2>/dev/null || echo "unknown")
$(du -sh . 2>/dev/null || echo "unknown")
EOF

log_success "  ✅ project-info.txt создан"

# Шаг 5: Сбор ошибок
log_info "Шаг 5: Сбор ошибок и проблем..."

if [ -f ".qwen/logs/errors.log" ]; then
    cp .qwen/logs/errors.log "${OUTPUT_DIR}/errors/"
    log_success "  ✅ errors.log скопирован"
else
    log_warning "  ⚠️ errors.log не найден"
fi

# Копируем логи сборок если есть
if [ -f "npm-debug.log" ]; then
    cp npm-debug.log "${OUTPUT_DIR}/errors/"
    log_success "  ✅ npm-debug.log скопирован"
fi

if [ -f ".qwen/logs/build-errors.log" ]; then
    cp .qwen/logs/build-errors.log "${OUTPUT_DIR}/errors/"
    log_success "  ✅ build-errors.log скопирован"
fi

# Шаг 6: Генерация отчета об использовании
log_info "Шаг 6: Генерация отчета об использовании..."

cat > "${OUTPUT_DIR}/info/usage-report.txt" << EOF
Usage Report
============
Generated: $(date)

Agent Call Statistics:
---------------------
EOF

if [ -f ".qwen/logs/agent-calls.log" ]; then
    echo "Total agent calls: $(wc -l < .qwen/logs/agent-calls.log)" >> "${OUTPUT_DIR}/info/usage-report.txt"
    echo "" >> "${OUTPUT_DIR}/info/usage-report.txt"
    echo "Calls by agent:" >> "${OUTPUT_DIR}/info/usage-report.txt"
    awk -F'|' '{print $2}' .qwen/logs/agent-calls.log | sort | uniq -c | sort -rn >> "${OUTPUT_DIR}/info/usage-report.txt" 2>/dev/null || echo "  (no data)" >> "${OUTPUT_DIR}/info/usage-report.txt"
else
    echo "  (no agent calls log found)" >> "${OUTPUT_DIR}/info/usage-report.txt"
fi

log_success "  ✅ usage-report.txt создан"

# Шаг 7: Создание README для экспорта
log_info "Шаг 7: Создание README для экспорта..."

cat > "${OUTPUT_DIR}/README.md" << EOF
# Feedback Export

**Дата сбора:** $(date)  
**Проект:** $(basename "$(pwd)")  
**Версия шаблона:** $(cat .version 2>/dev/null || echo "unknown")

## Структура

\`\`\`
${OUTPUT_DIR}/
├── logs/           # Логи работы агентов
│   ├── agent-calls.log
│   └── agent-calls/
├── feedback/       # Отчеты Feedback System
│   ├── reports/
│   └── checklists/
├── metrics/        # Метрики производительности
├── errors/         # Ошибки и проблемы
│   └── errors.log
└── info/           # Информация о проекте
    ├── project-info.txt
    └── usage-report.txt
\`\`\`

## Как отправить

### Вариант 1: GitHub Issue

1. Создайте issue в репозитории Qwen Orchestrator Kit
2. Прикрепите этот архив
3. Опишите проблему или предложение

### Вариант 2: Email

1. Создайте архив:
   \`\`\`bash
   tar -czf feedback-export.tar.gz ${OUTPUT_DIR}
   \`\`\`

2. Отправьте на email разработчиков

### Вариант 3: Google Form

Заполните форму обратной связи:
[URL формы]

## Конфиденциальность

Перед отправкой проверьте, что архив не содержит:
- [ ] API ключей
- [ ] Паролей
- [ ] Персональных данных
- [ ] Коммерческой тайны

EOF

log_success "  ✅ README.md создан"

# Шаг 8: Создание архива
log_info "Шаг 8: Создание архива..."

cd "$(dirname "${OUTPUT_DIR}")"
tar -czf "${FEEDBACK_ARCHIVE}" "$(basename "${OUTPUT_DIR}")"
cd - > /dev/null

log_success "Архив создан: ${FEEDBACK_ARCHIVE}"

# Шаг 9: Вывод инструкций
log_section "СБОР ЗАВЕРШЕН"

echo ""
echo "📁 Директория с данными: ${OUTPUT_DIR}"
echo "📦 Архив: ${FEEDBACK_ARCHIVE}"
echo ""
echo "📊 Статистика:"
echo "   Файлов собрано: $(find "${OUTPUT_DIR}" -type f | wc -l)"
echo "   Размер архива: $(du -h "${FEEDBACK_ARCHIVE}" | cut -f1)"
echo ""
echo "📤 Как отправить обратную связь:"
echo ""
echo "   1. GitHub Issue:"
echo "      - Откройте https://github.com/YOUR_REPO/issues"
echo "      - Создайте новый issue с описанием"
echo "      - Прикрепите архив ${FEEDBACK_ARCHIVE}"
echo ""
echo "   2. Email:"
echo "      - Прикрепите ${FEEDBACK_ARCHIVE}"
echo "      - Отправьте на feedback@qwen-orchestrator.dev"
echo ""
echo "   3. Telegram:"
echo "      - @qwen_orchestrator_feedback"
echo ""
echo "⚠️  Перед отправкой проверьте архив на наличие"
echo "   конфиденциальной информации!"
echo ""

# Очистка (опционально)
read -p "Удалить исходную директорию после создания архива? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "${OUTPUT_DIR}"
    log_success "Директория ${OUTPUT_DIR} удалена"
    log_info "Остался только архив: ${FEEDBACK_ARCHIVE}"
fi

exit 0
