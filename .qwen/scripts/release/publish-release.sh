#!/bin/bash

# ============================================
# QWEN ORCHESTRATOR KIT - Publish Release Script
# Версия: 2.0.0
# Дата: 2026-03-21
# ============================================
# Назначение: Создание чистой релизной ветки
# БЕЗ ИСТОРИИ разработки шаблона
# ============================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Проверка аргументов
if [ -z "$1" ]; then
    log_error "Использование: $0 <version>"
    log_error "Пример: $0 v0.6.0"
    exit 1
fi

VERSION=$1
RELEASE_BRANCH="release/${VERSION}"

log_info "═══════════════════════════════════════════════════"
log_info "  ПУБЛИКАЦИЯ РЕЛИЗА ${VERSION}"
log_info "═══════════════════════════════════════════════════"

# Шаг 1: Проверка текущего состояния
log_info "Шаг 1: Проверка текущего состояния..."

if [ -n "$(git status --porcelain)" ]; then
    log_warning "Есть незакоммиченные изменения. Закоммитьте их перед публикацией."
    git status --short
    exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
log_info "Текущая ветка: ${CURRENT_BRANCH}"

# Шаг 2: Создание orphan ветки (без истории)
log_info "Шаг 2: Создание ветки ${RELEASE_BRANCH} БЕЗ ИСТОРИИ..."

# Сохраняем список всех файлов перед переключением
FILES_LIST=$(find . -maxdepth 1 -type f -name ".*" -o -maxdepth 1 -type f -name "*" | grep -v "^./\.git$" | sort)

# Создаем orphan ветку
git checkout --orphan "${RELEASE_BRANCH}"

# Сбрасываем индекс, но оставляем файлы в рабочей директории
git reset

log_success "Ветка ${RELEASE_BRANCH} создана без истории"

# Шаг 3: Удаление временных файлов разработки
log_info "Шаг 3: Очистка временных файлов разработки..."

# Директории для удаления
TEMP_DIRS=(
    ".qwen/docs/claude_report"
    ".qwen/docs/next_step"
    ".qwen/docs/tmp"
    ".qwen/docs/temp"
    "logs"
    "state"
    "reports/audits"
    "reports/health-checks"
    "reports/phase-reports"
    "reports/quality-gates"
)

for dir in "${TEMP_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        log_info "  Удаление: $dir"
        rm -rf "$dir"
    fi
done

log_success "Очистка завершена"

# Шаг 4: Добавление всех файлов кроме исключенных
log_info "Шаг 4: Добавление файлов в релиз..."

# Добавляем все файлы
git add -A

log_success "Файлы добавлены"

# Шаг 5: Создание чистого коммита
log_info "Шаг 5: Создание чистого релизного коммита..."

COMMIT_MESSAGE="release: Публикация версии ${VERSION}

Чистая версия шаблона Qwen Orchestrator Kit ${VERSION}

Включает:
- Все агенты, навыки, команды
- Feedback System
- Gastown Multi-Agent
- SpecKit
- Plugin Architecture
- Agent Analytics
- Error Knowledge Base
- Specification Analyzer
- Unified MCP Configuration

Исключает:
- Временные файлы разработки (.qwen/docs/claude_report, next_step, tmp, temp)
- Логи отладки (logs/)
- Состояние системы (state/)
- Внутренние отчеты (reports/audits, health-checks, phase-reports, quality-gates)

Собрано из ветки: ${CURRENT_BRANCH}
Без истории разработки (orphan branch)"

git commit -m "$COMMIT_MESSAGE"

log_success "Релизный коммит создан"

# Шаг 6: Создание тега
log_info "Шаг 6: Создание тега ${VERSION}..."

git tag -a "${VERSION}" -m "Release ${VERSION}"

log_success "Тег ${VERSION} создан"

# Шаг 7: Вывод статистики
log_info "Шаг 7: Статистика релиза..."

echo ""
echo "═══════════════════════════════════════════════════"
echo "  СТАТИСТИКА РЕЛИЗА ${VERSION}"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Ветка: ${RELEASE_BRANCH}"
echo "Тег: ${VERSION}"
echo "Коммитов в истории: 1 (только релизный)"
echo ""
echo "Структура релиза:"
find .qwen -type d 2>/dev/null | wc -l | xargs -I {} echo "  Директорий .qwen: {}"
find .qwen -type f 2>/dev/null | wc -l | xargs -I {} echo "  Файлов .qwen: {}"
echo ""
echo "Исключенные директории:"
echo "  ✅ .qwen/docs/claude_report/"
echo "  ✅ .qwen/docs/next_step/"
echo "  ✅ .qwen/docs/tmp/"
echo "  ✅ .qwen/docs/temp/"
echo "  ✅ logs/"
echo "  ✅ state/"
echo "  ✅ reports/audits/"
echo "  ✅ reports/health-checks/"
echo "  ✅ reports/phase-reports/"
echo "  ✅ reports/quality-gates/"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  РЕЛИЗ ГОТОВ К ПРОВЕРКЕ"
echo "═══════════════════════════════════════════════════"
echo ""
log_info "Следующие шаги:"
log_info "1. Переключиться на релизную ветку: git checkout ${RELEASE_BRANCH}"
log_info "2. Проверить историю: git log --oneline"
log_info "3. Проверить файлы: ls -la"
log_info "4. Для публикации: git push origin ${RELEASE_BRANCH} --tags"
echo ""

exit 0
