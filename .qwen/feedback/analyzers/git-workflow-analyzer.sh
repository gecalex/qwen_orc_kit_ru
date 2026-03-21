#!/bin/bash
#
# Git Workflow Analyzer
# Назначение: Анализ нарушений git workflow
# Версия: 1.0.0
#

# Убрано set -euo pipefail - скрипт должен работать всегда
set -u

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/../reports}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Переменные для сбора нарушений
declare -a VIOLATIONS=()
declare -a WARNINGS=()
declare -a RECOMMENDATIONS=()

# Счетчики
TOTAL_COMMITS=0
FEATURE_BRANCHES=0
DIRECT_MAIN_COMMITS=0
COMMITS_WITHOUT_REVIEW=0
MISSING_TAGS=0
UNCOMMITTED_CHANGES=0
SCORE=100

# Функция для логирования
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Функция для проверки наличия git
check_git() {
    if ! command -v git &> /dev/null; then
        log_error "Git не установлен"
        exit 1
    fi
}

# Переход в директорию проекта
cd "$PROJECT_ROOT" || exit 1

# Проверка наличия .git
if [ ! -d ".git" ]; then
    log_error "Директория .git не найдена. Это не git репозиторий."
    # Создаем пустой JSON отчет
    cat > "$OUTPUT_DIR/git-workflow-analysis-$TIMESTAMP.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "status": "error",
  "message": "Not a git repository",
  "violations": [],
  "warnings": [],
  "recommendations": [],
  "metrics": {
    "total_commits": 0,
    "feature_branches": 0,
    "direct_main_commits": 0,
    "commits_without_review": 0,
    "missing_tags": 0,
    "uncommitted_changes": 0
  },
  "score": 0
}
EOF
    exit 0
fi

log_info "Анализ git workflow в $PROJECT_ROOT"

# 1. Проверка работы в main/dev напрямую
check_direct_branch_commits() {
    log_info "Проверка коммитов напрямую в main/dev..."

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    # Проверка текущей ветки
    if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]] || [[ "$current_branch" == "dev" ]] || [[ "$current_branch" == "develop" ]]; then
        WARNINGS+=("Работа в защищенной ветке: $current_branch")
        ((DIRECT_MAIN_COMMITS++)) || true
    fi

    # Проверка существования main/master веток
    local main_branch=""
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
        main_branch="main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
        main_branch="master"
    fi

    if [ -z "$main_branch" ]; then
        WARNINGS+=("Ветки main/master не найдены. Проект на ранней стадии разработки")
        RECOMMENDATIONS+=("Создайте ветку main для релизов и develop для разработки")
        # Подсчет коммитов в текущей ветке
        TOTAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        return 0
    fi

    # Проверка коммитов в main без PR
    local recent_commits
    recent_commits=$(git log "$main_branch" --oneline -10 2>/dev/null | wc -l | tr -d '[:space:]')
    TOTAL_COMMITS=${recent_commits:-0}

    if [ "$TOTAL_COMMITS" -gt 0 ]; then
        # Проверяем наличие merge коммитов (признак PR)
        local merge_commits
        merge_commits=$(git log "$main_branch" --oneline -10 --merges 2>/dev/null | wc -l | tr -d '[:space:]')
        merge_commits=${merge_commits:-0}

        if [ "$merge_commits" -eq 0 ] && [ "$TOTAL_COMMITS" -gt 0 ]; then
            WARNINGS+=("Возможные коммиты напрямую в $main_branch без Pull Request")
            ((COMMITS_WITHOUT_REVIEW++)) || true
        fi
    fi
}

# 2. Проверка отсутствия feature-веток
check_feature_branches() {
    log_info "Проверка feature-веток..."

    local branches
    branches=$(git branch --list 2>/dev/null || echo "")

    # Подсчет feature веток
    FEATURE_BRANCHES=$(echo "$branches" | grep -cE "^(feature|feat)/" 2>/dev/null || echo "0")
    FEATURE_BRANCHES=$(echo "$FEATURE_BRANCHES" | tr -d '[:space:]')
    FEATURE_BRANCHES=${FEATURE_BRANCHES:-0}

    if [ "$FEATURE_BRANCHES" -eq 0 ] 2>/dev/null; then
        WARNINGS+=("Отсутствуют feature-ветки. Рекомендуется использовать feature-branch workflow")
        RECOMMENDATIONS+=("Создавайте feature-ветки для каждой новой функциональности: git checkout -b feature/feature-name")
    else
        log_success "Найдено feature-веток: $FEATURE_BRANCHES"
    fi

    # Проверка stale веток (старше 7 дней без изменений)
    local stale_branches=0
    while IFS= read -r branch; do
        if [ -n "$branch" ]; then
            local last_commit_date
            last_commit_date=$(git log -1 --format="%ai" "$branch" 2>/dev/null | cut -d' ' -f1 || echo "")
            if [ -n "$last_commit_date" ]; then
                local last_commit_ts
                last_commit_ts=$(date -d "$last_commit_date" +%s 2>/dev/null || echo "0")
                local now_ts
                now_ts=$(date +%s)
                local diff_days=$(( (now_ts - last_commit_ts) / 86400 ))

                if [ "$diff_days" -gt 7 ]; then
                    ((stale_branches++)) || true
                    WARNINGS+=("Stale ветка: $branch (последний коммит $diff_days дней назад)")
                fi
            fi
        fi
    done < <(git branch --list "feature/*" "feat/*" 2>/dev/null | sed 's/^[* ]*//')

    if [ "$stale_branches" -gt 0 ]; then
        RECOMMENDATIONS+=("Удалите $stale_branches устаревших feature-веток или завершите работу над ними")
    fi
}

# 3. Проверка коммитов без pre-commit review
check_commits_review() {
    log_info "Проверка качества коммитов..."
    
    # Проверка сообщений коммитов
    local bad_messages=0
    while IFS= read -r msg; do
        if [ -n "$msg" ]; then
            # Проверка на соответствие conventional commits
            if ! echo "$msg" | grep -qE "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: .+"; then
                ((bad_messages++)) || true
            fi
        fi
    done < <(git log --oneline -20 --format="%s" 2>/dev/null)
    
    if [ "$bad_messages" -gt 0 ]; then
        WARNINGS+=("$bad_messages коммитов не соответствуют Conventional Commits")
        RECOMMENDATIONS+=("Используйте Conventional Commits: feat:, fix:, docs:, etc.")
        ((COMMITS_WITHOUT_REVIEW += bad_messages / 5)) || true
    fi
    
    # Проверка наличия pre-commit хуков
    if [ ! -f ".git/hooks/pre-commit" ] && [ ! -f ".git/hooks/pre-commit.sample" ]; then
        WARNINGS+=("Отсутствуют pre-commit хуки")
        RECOMMENDATIONS+=("Настройте pre-commit хуки для автоматических проверок")
    fi
    
    # Проверка размера коммитов
    local large_commits=0
    while IFS= read -r commit; do
        if [ -n "$commit" ]; then
            local changed_files
            changed_files=$(git show --stat "$commit" 2>/dev/null | tail -1 | grep -oE "[0-9]+ file" | grep -oE "[0-9]+" || echo "0")
            if [ "${changed_files:-0}" -gt 10 ]; then
                ((large_commits++)) || true
                WARNINGS+=("Большой коммит $commit: изменено $changed_files файлов")
            fi
        fi
    done < <(git log --oneline -20 --format="%H" 2>/dev/null)
    
    if [ "$large_commits" -gt 0 ]; then
        RECOMMENDATIONS+=("Разбейте $large_commits больших коммитов на меньшие логические единицы")
    fi
}

# 4. Проверка отсутствия тегов
check_tags() {
    log_info "Проверка тегов..."

    local tags_count
    tags_count=$(git tag -l 2>/dev/null | wc -l | tr -d '[:space:]')
    tags_count=${tags_count:-0}

    if [ "$tags_count" -eq 0 ]; then
        WARNINGS+=("Отсутствуют теги версий")
        MISSING_TAGS=1
        RECOMMENDATIONS+=("Создайте теги для версий: git tag -a v0.1.0 -m 'Version 0.1.0'")
    else
        log_success "Найдено тегов: $tags_count"

        # Проверка наличия последнего тега
        local last_tag
        last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

        if [ -z "$last_tag" ]; then
            WARNINGS+=("Не удалось определить последний тег")
        else
            # Проверка коммитов после последнего тега
            local commits_after_tag
            commits_after_tag=$(git rev-list "$last_tag"..HEAD --count 2>/dev/null || echo "0")
            commits_after_tag=${commits_after_tag:-0}

            if [ "$commits_after_tag" -gt 20 ]; then
                WARNINGS+=("$commits_after_tag коммитов после последнего тега $last_tag")
                RECOMMENDATIONS+=("Создайте новый тег версии")
            fi
        fi
    fi
}

# 5. Проверка незакоммиченных изменений
check_uncommitted_changes() {
    log_info "Проверка незакоммиченных изменений..."
    
    local status_output
    status_output=$(git status --porcelain 2>/dev/null || echo "")
    
    if [ -n "$status_output" ]; then
        local modified added deleted untracked
        modified=$(echo "$status_output" | grep -c "^ M" || true)
        modified=${modified:-0}
        added=$(echo "$status_output" | grep -c "^A " || true)
        added=${added:-0}
        deleted=$(echo "$status_output" | grep -c "^ D" || true)
        deleted=${deleted:-0}
        untracked=$(echo "$status_output" | grep -c "^??" || true)
        untracked=${untracked:-0}

        UNCOMMITTED_CHANGES=$((modified + added + deleted + untracked))
        
        if [ "$UNCOMMITTED_CHANGES" -gt 0 ]; then
            WARNINGS+=("Найдено незакоммиченных изменений: $UNCOMMITTED_CHANGES")
            log_warning "  Изменено: $modified, Добавлено: $added, Удалено: $deleted, Неотслеживаемых: $untracked"
        fi
    else
        log_success "Нет незакоммиченных изменений"
    fi
}

# Расчет общего score
calculate_score() {
    local score=100
    
    # Штрафы за нарушения
    score=$((score - DIRECT_MAIN_COMMITS * 10))
    score=$((score - COMMITS_WITHOUT_REVIEW * 5))
    score=$((score - MISSING_TAGS * 15))
    score=$((score - (UNCOMMITTED_CHANGES > 0 ? 10 : 0)))
    score=$((score - (FEATURE_BRANCHES == 0 ? 5 : 0)))
    
    # Ограничиваем от 0 до 100
    if [ "$score" -lt 0 ]; then
        score=0
    elif [ "$score" -gt 100 ]; then
        score=100
    fi
    
    echo "$score"
}

# Генерация JSON отчета
generate_json_report() {
    local score
    score=$(calculate_score)
    
    # Формирование массивов JSON
    local violations_json="[]"
    local warnings_json="[]"
    local recommendations_json="[]"
    
    if [ ${#VIOLATIONS[@]} -gt 0 ]; then
        violations_json=$(printf '%s\n' "${VIOLATIONS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        warnings_json=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        recommendations_json=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
    fi
    
    # Создание JSON файла
    cat > "$OUTPUT_DIR/git-workflow-analysis-$TIMESTAMP.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "status": "completed",
  "analyzer": "git-workflow-analyzer",
  "version": "1.0.0",
  "project_root": "$PROJECT_ROOT",
  "violations": $violations_json,
  "warnings": $warnings_json,
  "recommendations": $recommendations_json,
  "metrics": {
    "total_commits": $TOTAL_COMMITS,
    "feature_branches": $FEATURE_BRANCHES,
    "direct_main_commits": $DIRECT_MAIN_COMMITS,
    "commits_without_review": $COMMITS_WITHOUT_REVIEW,
    "missing_tags": $MISSING_TAGS,
    "uncommitted_changes": $UNCOMMITTED_CHANGES
  },
  "score": $score,
  "grade": "$(if [ $score -ge 90 ]; then echo "A"; elif [ $score -ge 80 ]; then echo "B"; elif [ $score -ge 70 ]; then echo "C"; elif [ $score -ge 60 ]; then echo "D"; else echo "F"; fi)"
}
EOF
    
    log_success "Отчет сохранен: $OUTPUT_DIR/git-workflow-analysis-$TIMESTAMP.json"
}

# Показать помощь
show_help() {
    cat << EOF
Git Workflow Analyzer v1.0.0

Назначение: Анализ нарушений git workflow

Использование:
  $(basename "$0") [OPTIONS]

Опции:
  -h, --help      Показать эту справку
  -v, --verbose   Подробный вывод
  -q, --quiet     Тихий режим (только JSON)
  -o, --output    Директория для вывода (по умолчанию: ../reports)

Примеры:
  $(basename "$0")                    # Запуск с настройками по умолчанию
  $(basename "$0") -o /tmp/reports    # Вывод в другую директорию
  $(basename "$0") -q                 # Тихий режим

Проверки:
  1. Работа в main/dev напрямую
  2. Отсутствие feature-веток
  3. Коммиты без pre-commit review
  4. Отсутствие тегов
  5. Незакоммиченные изменения

Выход:
  JSON файл с нарушениями и рекомендациями
EOF
}

# Парсинг аргументов
VERBOSE=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            log_error "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
    esac
done

# Создание директории вывода
mkdir -p "$OUTPUT_DIR"

# Основной запуск
main() {
    check_git
    
    if [ "$QUIET" = false ]; then
        echo "========================================"
        echo "  Git Workflow Analyzer v1.0.0"
        echo "========================================"
        echo ""
    fi
    
    check_direct_branch_commits
    check_feature_branches
    check_commits_review
    check_tags
    check_uncommitted_changes
    
    generate_json_report
    
    if [ "$QUIET" = false ]; then
        echo ""
        echo "========================================"
        echo "  Анализ завершен"
        echo "========================================"
        
        local score
        score=$(calculate_score)
        
        if [ "$score" -ge 90 ]; then
            log_success "Оценка: $score/100 (Отлично)"
        elif [ "$score" -ge 70 ]; then
            log_warning "Оценка: $score/100 (Требуется улучшение)"
        else
            log_error "Оценка: $score/100 (Критические проблемы)"
        fi
        
        echo ""
        echo "Нарушения: ${#VIOLATIONS[@]}"
        echo "Предупреждения: ${#WARNINGS[@]}"
        echo "Рекомендации: ${#RECOMMENDATIONS[@]}"
    fi
}

main
