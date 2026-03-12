#!/bin/bash
# Скрипт: scripts/orchestration-tools/analyze-project-state.sh
# Назначение: Определение состояния проекта и классификация для адаптации оркестратора

# Функция для подсчета файлов определенного типа
count_files() {
    local extension=$1
    local count=$(find . -name "*.$extension" -type f 2>/dev/null | wc -l)
    echo $count
}

# Функция для проверки наличия директорий
check_directories() {
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
    if [ -f ".specify/memory/constitution.md" ]; then
        echo "found"
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
    count=$(find . -name "*.$ext" -type f 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        detected_languages+=("$ext:$count")
        total_code_files=$((total_code_files + count))
    fi
done

# Проверка директорий
found_dirs=($(check_directories))

# Проверка файлов конфигурации
found_configs=($(check_config_files))

# Проверка спецификаций
specs_status=$(check_specifications)

# Проверка конституции
constitution_status=$(check_constitution)

# Определение состояния проекта
project_state="unknown"

if [ $total_code_files -eq 0 ] && [ ${#found_dirs[@]} -eq 0 ] && [ ${#found_configs[@]} -eq 0 ]; then
    # Только системные файлы (git, readme, gitignore)
    project_state="empty"
elif [ "$specs_status" == "found" ] && [ "$constitution_status" == "found" ]; then
    project_state="full_specification"
elif [ "$specs_status" == "found" ]; then
    project_state="partial_specification"
else
    project_state="existing_code_no_specs"
fi

# Вывод результатов анализа
echo "Состояние проекта: $project_state"
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
        exit 10  # Код для пустого проекта
        ;;
    "existing_code_no_specs")
        echo "Проект с кодом, но без спецификаций обнаружен. Рекомендуется:"
        echo "1. Провести анализ существующего кода"
        echo "2. Создать реверс-инжиниринг спецификаций"
        echo "3. Постепенно интегрировать процесс Speckit"
        exit 20  # Код для проекта с кодом, но без спецификаций
        ;;
    "partial_specification")
        echo "Проект с частичными спецификациями обнаружен. Рекомендуется:"
        echo "1. Доработать существующие спецификации"
        echo "2. Заполнить пробелы в спецификациях"
        echo "3. Проверить соответствие реализации спецификациям"
        exit 30  # Код для проекта с частичными спецификациями
        ;;
    "full_specification")
        echo "Проект с полными спецификациями обнаружен. Рекомендуется:"
        echo "1. Следовать стандартному процессу Speckit"
        echo "2. Проверять соответствие реализации спецификациям"
        echo "3. Использовать контрольные точки качества"
        exit 40  # Код для проекта с полными спецификациями
        ;;
    *)
        echo "Неопределенное состояние проекта: $project_state"
        echo "Требуется ручной анализ и определение подходящего процесса"
        exit 0   # Неопределенное состояние
        ;;
esac
