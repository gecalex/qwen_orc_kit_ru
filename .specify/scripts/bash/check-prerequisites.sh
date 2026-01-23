#!/usr/bin/env bash

# Скрипт проверки зависимостей
#
# Этот скрипт предоставляет унифицированную проверку зависимостей для рабочего процесса разработки по спецификациям.
# Он заменяет функциональность, ранее распределенную по нескольким скриптам.
#
# Использование: ./check-prerequisites.sh [ОПЦИИ]
#
# ОПЦИИ:
#   --json              Вывод в формате JSON
#   --require-tasks     Требовать существования tasks.md (для фазы реализации)
#   --include-tasks     Включить tasks.md в список AVAILABLE_DOCS
#   --paths-only        Выводить только переменные пути (без проверки зависимостей)
#   --help, -h          Показать справочное сообщение
#
# ВЫВОД:
#   Режим JSON: {"FEATURE_DIR":"...", "AVAILABLE_DOCS":["..."]}
#   Текстовый режим: FEATURE_DIR:... \n AVAILABLE_DOCS: \n ✓/✗ file.md
#   Только пути: REPO_ROOT: ... \n BRANCH: ... \n FEATURE_DIR: ... и т.д.

set -e

# Разбор аргументов командной строки
JSON_MODE=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false
PATHS_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --require-tasks)
            REQUIRE_TASKS=true
            ;;
        --include-tasks)
            INCLUDE_TASKS=true
            ;;
        --paths-only)
            PATHS_ONLY=true
            ;;
        --help|-h)
            cat << 'EOF'
Использование: check-prerequisites.sh [ОПЦИИ]

Унифицированная проверка зависимостей для рабочего процесса разработки по спецификациям.

ОПЦИИ:
  --json              Вывод в формате JSON
  --require-tasks     Требовать существования tasks.md (для фазы реализации)
  --include-tasks     Включить tasks.md в список AVAILABLE_DOCS
  --paths-only        Выводить только переменные пути (без проверки зависимостей)
  --help, -h          Показать это справочное сообщение

ПРИМЕРЫ:
  # Проверить зависимости задач (требуется plan.md)
  ./check-prerequisites.sh --json

  # Проверить зависимости реализации (требуется plan.md + tasks.md)
  ./check-prerequisites.sh --json --require-tasks --include-tasks

  # Получить только пути функций (без проверки)
  ./check-prerequisites.sh --paths-only

EOF
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option '$arg'. Use --help for usage information." >&2
            exit 1
            ;;
    esac
done

# Подключение общих функций
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Получить пути функций и проверить ветку
eval $(get_feature_paths)
check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

# Если режим только пути, вывести пути и выйти (поддержка JSON + только пути объединенные)
if $PATHS_ONLY; then
    if $JSON_MODE; then
        # Минимальный JSON пакет путей (проверка не выполняется)
        printf '{"REPO_ROOT":"%s","BRANCH":"%s","FEATURE_DIR":"%s","FEATURE_SPEC":"%s","IMPL_PLAN":"%s","TASKS":"%s"}\n' \
            "$REPO_ROOT" "$CURRENT_BRANCH" "$FEATURE_DIR" "$FEATURE_SPEC" "$IMPL_PLAN" "$TASKS"
    else
        echo "REPO_ROOT: $REPO_ROOT"
        echo "BRANCH: $CURRENT_BRANCH"
        echo "FEATURE_DIR: $FEATURE_DIR"
        echo "FEATURE_SPEC: $FEATURE_SPEC"
        echo "IMPL_PLAN: $IMPL_PLAN"
        echo "TASKS: $TASKS"
    fi
    exit 0
fi

# Validate required directories and files
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "ERROR: Feature directory not found: $FEATURE_DIR" >&2
    echo "Run /speckit.specify first to create the feature structure." >&2
    exit 1
fi

if [[ ! -f "$IMPL_PLAN" ]]; then
    echo "ERROR: plan.md not found in $FEATURE_DIR" >&2
    echo "Run /speckit.plan first to create the implementation plan." >&2
    exit 1
fi

# Check for tasks.md if required
if $REQUIRE_TASKS && [[ ! -f "$TASKS" ]]; then
    echo "ERROR: tasks.md not found in $FEATURE_DIR" >&2
    echo "Run /speckit.tasks first to create the task list." >&2
    exit 1
fi

# Создать список доступных документов
docs=()

# Всегда проверять эти дополнительные документы
[[ -f "$RESEARCH" ]] && docs+=("research.md")
[[ -f "$DATA_MODEL" ]] && docs+=("data-model.md")

# Проверить каталог контрактов (только если он существует и содержит файлы)
if [[ -d "$CONTRACTS_DIR" ]] && [[ -n "$(ls -A "$CONTRACTS_DIR" 2>/dev/null)" ]]; then
    docs+=("contracts/")
fi

[[ -f "$QUICKSTART" ]] && docs+=("quickstart.md")

# Включить tasks.md если запрошено и файл существует
if $INCLUDE_TASKS && [[ -f "$TASKS" ]]; then
    docs+=("tasks.md")
fi

# Вывести результаты
if $JSON_MODE; then
    # Создать JSON массив документов
    if [[ ${#docs[@]} -eq 0 ]]; then
        json_docs="[]"
    else
        json_docs=$(printf '"%s",' "${docs[@]}")
        json_docs="[${json_docs%,}]"
    fi

    printf '{"FEATURE_DIR":"%s","AVAILABLE_DOCS":%s}\n' "$FEATURE_DIR" "$json_docs"
else
    # Текстовый вывод
    echo "FEATURE_DIR:$FEATURE_DIR"
    echo "AVAILABLE_DOCS:"

    # Показать статус каждого возможного документа
    check_file "$RESEARCH" "research.md"
    check_file "$DATA_MODEL" "data-model.md"
    check_dir "$CONTRACTS_DIR" "contracts/"
    check_file "$QUICKSTART" "quickstart.md"

    if $INCLUDE_TASKS; then
        check_file "$TASKS" "tasks.md"
    fi
fi
