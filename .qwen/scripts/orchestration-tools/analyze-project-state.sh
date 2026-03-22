#!/bin/bash
# Скрипт: .qwen/scripts/orchestration-tools/analyze-project-state.sh
# Назначение: Определение состояния проекта и классификация для адаптации оркестратора

# Функция для подсчета файлов определенного типа
count_files_by_extension() {
    local extension=$1
    # Исключаем директорию .qwen/ из подсчёта (системная директория Qwen Code)
    local count=$(find . -path "./.qwen" -prune -o -name "*.$extension" -type f -print 2>/dev/null | wc -l)
    echo $count
}

# Функция для проверки наличия директорий
check_directories() {
    # Исключаем системные директории (.qwen, .git, .specify)
    local dirs=("src" "lib" "app" "backend" "frontend" "api" "services" "models" "components" "core")
    local found_dirs=()

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ] && [ -n "$(ls -A $dir 2>/dev/null)" ]; then
            found_dirs+=("$dir")
        fi
    done

    echo "${found_dirs[@]}"
}

# Функция для проверки наличия файлов конфигурации
check_config_files() {
    local configs=("package.json" "pyproject.toml" "requirements.txt" "Gemfile" "Cargo.toml" "go.mod" "pom.xml" "build.gradle" "composer.json")
    local found_configs=()

    for config in "${configs[@]}"; do
        if [ -f "$config" ]; then
            found_configs+=("$config")
        fi
    done

    echo "${found_configs[@]}"
}

# Функция для проверки наличия спецификаций
check_specifications() {
    if [ -d "specs" ] && [ -n "$(find specs -name "spec.md" -type f 2>/dev/null)" ]; then
        echo "found"
    else
        echo "not_found"
    fi
}

# Функция для проверки наличия конституции
check_constitution() {
    # Проверяем конституцию в корне проекта (новый формат)
    if [ -f "constitution.md" ]; then
        echo "found"
    # Проверяем конституцию в старом месте (для совместимости)
    elif [ -f ".specify/memory/constitution.md" ]; then
        echo "found_legacy"
    else
        echo "not_found"
    fi
}

# Основная логика скрипта
echo "=== Анализ состояния проекта ==="

# Подсчет файлов кода
code_extensions=("py" "js" "ts" "jsx" "tsx" "java" "cpp" "c" "cs" "rb" "go" "rs" "php" "swift" "kt" "scala" "dart" "html" "css" "vue" "svelte")
total_code_files=0
detected_languages=()

for ext in "${code_extensions[@]}"; do
    count=$(count_files_by_extension "$ext")
    if [ "$count" -gt 0 ]; then
        detected_languages+=("$ext:$count")
        total_code_files=$((total_code_files + count))
    fi
done

# Проверка директорий
found_dirs_str=$(check_directories)
found_dirs=($found_dirs_str)

# Проверка файлов конфигурации
found_configs_str=$(check_config_files)
found_configs=($found_configs_str)

# Проверка спецификаций
specs_status=$(check_specifications)

# Проверка конституции
constitution_status=$(check_constitution)

# Определение состояния проекта
# Коды состояния:
# 10 - Пустой проект (нет кода, нет спецификаций)
# 20 - Существующий код, но без спецификаций
# 30 - Частичные спецификации
# 40 - Полные спецификации

project_state="unknown"
exit_code=0

# Проверка на пустой проект
if [ $total_code_files -eq 0 ] && [ ${#found_dirs[@]} -eq 0 ] && [ ${#found_configs[@]} -eq 0 ]; then
    # Только системные файлы (git, readme, gitignore)
    project_state="empty"
    exit_code=10
# Проверка на проект с полными спецификациями
elif [ "$specs_status" == "found" ] && { [ "$constitution_status" == "found" ] || [ "$constitution_status" == "found_legacy" ]; }; then
    project_state="full_specification"
    exit_code=40
# Проверка на проект с частичными спецификациями
elif [ "$specs_status" == "found" ] && [ "$constitution_status" == "not_found" ]; then
    project_state="partial_specification"
    exit_code=30
# Проект с кодом, но без спецификаций
else
    project_state="existing_code_no_specs"
    exit_code=20
fi

# Вывод результатов анализа
echo "Состояние проекта: $project_state"
echo "Код состояния: $exit_code"
echo ""
echo "Детали анализа:"
echo "- Обнаружено файлов кода: $total_code_files"
if [ ${#detected_languages[@]} -gt 0 ]; then
    echo "- Обнаруженные языки: ${detected_languages[*]}"
fi
if [ ${#found_dirs[@]} -gt 0 ]; then
    echo "- Обнаруженные директории: ${found_dirs[*]}"
fi
if [ ${#found_configs[@]} -gt 0 ]; then
    echo "- Файлы конфигурации: ${found_configs[*]}"
fi
echo "- Спецификации: $specs_status"
echo "- Конституция: $constitution_status"

# Вывод рекомендаций
echo ""
echo "=== Рекомендации оркестратора ==="
case $project_state in
    "empty")
        echo "Пустой проект обнаружен. Рекомендуется:"
        echo "1. Создать конституцию проекта с помощью speckit.constitution"
        echo "2. Определить основные принципы и стандарты"
        echo "3. Создать первую спецификацию с помощью speckit.specify"
        exit $exit_code  # Код 10 для пустого проекта
        ;;
    "existing_code_no_specs")
        echo "Проект с кодом, но без спецификаций обнаружен. Рекомендуется:"
        echo "1. Провести анализ существующего кода"
        echo "2. Создать реверс-инжиниринг спецификаций"
        echo "3. Постепенно интегрировать процесс Speckit"
        exit $exit_code  # Код 20 для проекта с кодом, но без спецификаций
        ;;
    "partial_specification")
        echo "Проект с частичными спецификациями обнаружен. Рекомендуется:"
        echo "1. Доработать существующие спецификации"
        echo "2. Заполнить пробелы в спецификациях"
        echo "3. Проверить соответствие реализации спецификациям"
        exit $exit_code  # Код 30 для проекта с частичными спецификациями
        ;;
    "full_specification")
        echo "Проект с полными спецификациями обнаружен. Рекомендуется:"
        echo "1. Следовать стандартному процессу Speckit"
        echo "2. Проверять соответствие реализации спецификациям"
        echo "3. Использовать контрольные точки качества"
        exit $exit_code  # Код 40 для проекта с полными спецификациями
        ;;
    *)
        echo "Неопределенное состояние проекта: $project_state"
        echo "Требуется ручной анализ и определение подходящего процесса"
        exit $exit_code  # Код 0 для неопределенного состояния
        ;;
esac
