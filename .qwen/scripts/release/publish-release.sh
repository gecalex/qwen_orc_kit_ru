#!/bin/bash

# ============================================
# QWEN ORCHESTRATOR KIT - Publish Release Script
# Версия: 1.0.0
# Дата: 2026-03-21
# ============================================
# Назначение: Создание чистой релизной ветки
# без истории разработки шаблона
# ============================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция вывода
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

# Шаг 2: Создание новой ветки для релиза
log_info "Шаг 2: Создание ветки ${RELEASE_BRANCH}..."

git checkout -b "${RELEASE_BRANCH}"

log_success "Ветка ${RELEASE_BRANCH} создана"

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

# Файлы логов
if [ -f "*.log" ]; then
    log_info "  Удаление: *.log"
    rm -f *.log
fi

log_success "Очистка завершена"

# Шаг 4: Удаление файлов из Git индекса (но не из рабочей директории)
log_info "Шаг 4: Обновление Git индекса..."

# Файлы, которые нужно удалить из индекса
git rm -r --cached .qwen/docs/claude_report 2>/dev/null || true
git rm -r --cached .qwen/docs/next_step 2>/dev/null || true
git rm -r --cached .qwen/docs/tmp 2>/dev/null || true
git rm -r --cached .qwen/docs/temp 2>/dev/null || true
git rm -r --cached logs 2>/dev/null || true
git rm -r --cached state 2>/dev/null || true
git rm -r --cached reports/audits 2>/dev/null || true
git rm -r --cached reports/health-checks 2>/dev/null || true
git rm -r --cached reports/phase-reports 2>/dev/null || true
git rm -r --cached reports/quality-gates 2>/dev/null || true

log_success "Git индекс обновлен"

# Шаг 5: Создание чистого коммита
log_info "Шаг 5: Создание чистого релизного коммита..."

git add -A

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
- Временные файлы разработки
- Логи отладки
- Внутренние отчеты

Собрано из ветки: ${CURRENT_BRANCH}"

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
echo ""
echo "Структура релиза:"
find .qwen -type d | wc -l | xargs -I {} echo "  Директорий .qwen: {}"
find .qwen -type f | wc -l | xargs -I {} echo "  Файлов .qwen: {}"
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
log_info "1. Проверьте содержимое ветки: git status"
log_info "2. Просмотрите файлы: ls -la"
log_info "3. При необходимости: git checkout ${CURRENT_BRANCH}"
log_info "4. Для публикации: git push origin ${RELEASE_BRANCH} --tags"
echo ""

exit 0
