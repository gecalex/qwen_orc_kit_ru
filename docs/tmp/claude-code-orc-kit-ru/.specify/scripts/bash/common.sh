#!/usr/bin/env bash
# Общие функции и переменные для всех скриптов

# Получить корень репозитория, с резервным вариантом для негит-репозиториев
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        # Возврат к местоположению скрипта для негит-репозиториев
        local script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}

# Получить текущую ветку, с резервным вариантом для негит-репозиториев
get_current_branch() {
    # Сначала проверить, установлена ли переменная окружения SPECIFY_FEATURE
    if [[ -n "${SPECIFY_FEATURE:-}" ]]; then
        echo "$SPECIFY_FEATURE"
        return
    fi

    # Затем проверить git, если доступен
    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi

    # Для негит-репозиториев, попытаться найти последнюю директорию фичи
    local repo_root=$(get_repo_root)
    local specs_dir="$repo_root/specs"

    if [[ -d "$specs_dir" ]]; then
        local latest_feature=""
        local highest=0

        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname=$(basename "$dir")
                if [[ "$dirname" =~ ^([0-9]{3})- ]]; then
                    local number=${BASH_REMATCH[1]}
                    number=$((10#$number))
                    if [[ "$number" -gt "$highest" ]]; then
                        highest=$number
                        latest_feature=$dirname
                    fi
                fi
            fi
        done

        if [[ -n "$latest_feature" ]]; then
            echo "$latest_feature"
            return
        fi
    fi

    echo "main"  # Финальный резервный вариант
}

# Проверить, есть ли git доступен
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

check_feature_branch() {
    local branch="$1"
    local has_git_repo="$2"

    # Для негит-репозиториев, мы не можем обеспечить именование веток, но всё равно предоставляем вывод
    if [[ "$has_git_repo" != "true" ]]; then
        echo "[specify] Предупреждение: Git-репозиторий не обнаружен; пропущена проверка ветки" >&2
        return 0
    fi

    if [[ ! "$branch" =~ ^[0-9]{3}- ]]; then
        echo "ОШИБКА: Не на ветке фичи. Текущая ветка: $branch" >&2
        echo "Ветки фич должны называться как: 001-feature-name" >&2
        return 1
    fi

    return 0
}

get_feature_dir() { echo "$1/specs/$2"; }

# Найти директорию фичи по числовому префиксу вместо точного соответствия ветки
# Это позволяет нескольким веткам работать над одним спецификацией (например, 004-fix-bug, 004-add-feature)
find_feature_dir_by_prefix() {
    local repo_root="$1"
    local branch_name="$2"
    local specs_dir="$repo_root/specs"

    # Извлечь числовой префикс из ветки (например, "004" из "004-whatever")
    if [[ ! "$branch_name" =~ ^([0-9]{3})- ]]; then
        # Если ветка не имеет числового префикса, вернуться к точному соответствию
        echo "$specs_dir/$branch_name"
        return
    fi

    local prefix="${BASH_REMATCH[1]}"

    # Поиск директорий в specs/, которые начинаются с этого префикса
    local matches=()
    if [[ -d "$specs_dir" ]]; then
        for dir in "$specs_dir"/"$prefix"-*; do
            if [[ -d "$dir" ]]; then
                matches+=("$(basename "$dir")")
            fi
        done
    fi

    # Обработка результатов
    if [[ ${#matches[@]} -eq 0 ]]; then
        # Совпадений не найдено - вернуть путь к имени ветки (упадёт позже с понятной ошибкой)
        echo "$specs_dir/$branch_name"
    elif [[ ${#matches[@]} -eq 1 ]]; then
        # Ровно одно совпадение - отлично!
        echo "$specs_dir/${matches[0]}"
    else
        # Несколько совпадений - этого не должно происходить с правильным соглашением об именовании
        echo "ОШИБКА: Найдено несколько директорий спецификаций с префиксом '$prefix': ${matches[*]}" >&2
        echo "Пожалуйста, убедитесь, что существует только одна директория спецификаций на числовой префикс." >&2
        echo "$specs_dir/$branch_name"  # Вернуть что-то, чтобы не сломать скрипт
    fi
}

get_feature_paths() {
    local repo_root=$(get_repo_root)
    local current_branch=$(get_current_branch)
    local has_git_repo="false"

    if has_git; then
        has_git_repo="true"
    fi

    # Использовать поиск на основе префикса для поддержки нескольких веток на спецификацию
    local feature_dir=$(find_feature_dir_by_prefix "$repo_root" "$current_branch")

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
HAS_GIT='$has_git_repo'
FEATURE_DIR='$feature_dir'
FEATURE_SPEC='$feature_dir/spec.md'
IMPL_PLAN='$feature_dir/plan.md'
TASKS='$feature_dir/tasks.md'
RESEARCH='$feature_dir/research.md'
DATA_MODEL='$feature_dir/data-model.md'
QUICKSTART='$feature_dir/quickstart.md'
CONTRACTS_DIR='$feature_dir/contracts'
EOF
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }

