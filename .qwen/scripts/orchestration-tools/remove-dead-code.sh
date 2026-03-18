#!/bin/bash

# Скрипт удаления мертвого кода
# Ищет и отмечает потенциальный мертвый код в проекте

set -e  # Прервать при ошибке

OUTPUT_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$OUTPUT_DIR/dead_code_report_$TIMESTAMP.md"

# Создать директорию для отчетов, если не существует
mkdir -p "$OUTPUT_DIR"

echo "=== Анализ мертвого кода ==="
echo "Время: $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Подсчет потенциального мертвого кода
UNUSED_FUNCTIONS=0
UNUSED_VARIABLES=0
COMMENTED_CODE_BLOCKS=0
UNUSED_IMPORTS=0

echo "=== Обнаруженный мертвый код ===" >> "$REPORT_FILE"

# Поиск потенциальных неиспользуемых функций (ограниченная проверка)
if command -v grep >/dev/null 2>&1; then
    # Поиск функций, которые не используются в проекте (ограниченная проверка)
    UNUSED_FUNCTIONS=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" 2>/dev/null | xargs grep -h -E "def |function |func |var |const |let " 2>/dev/null | grep -v "__init__\|__main__\|main\|export\|import" | cut -d'(' -f1 | cut -d' ' -f2- | while read func; do
        if [ -n "$func" ]; then
            count=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" 2>/dev/null | xargs grep -F "$func" 2>/dev/null | grep -v "$func *(" | wc -l)
            if [ "$count" -eq 0 ]; then
                echo "$func"
            fi
        fi
    done | wc -l)
    
    echo "Потенциальные неиспользуемые функции: $UNUSED_FUNCTIONS" >> "$REPORT_FILE"
fi

# Поиск закомментированного кода
if command -v grep >/dev/null 2>&1; then
    COMMENTED_CODE_BLOCKS=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" -o -name "*.sh" -o -name "*.md" 2>/dev/null | xargs grep -E "^[[:space:]]*//|^[[:space:]]*#" 2>/dev/null | grep -E "\w+" | wc -l)
    
    echo "Блоки закомментированного кода: $COMMENTED_CODE_BLOCKS" >> "$REPORT_FILE"
fi

# Поиск потенциальных неиспользуемых импортов
if command -v grep >/dev/null 2>&1; then
    UNUSED_IMPORTS=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" 2>/dev/null | xargs grep -h -E "import \|from \|require\|include\|using\|use " 2>/dev/null | while read import_line; do
        # Извлекаем имя импорта
        import_name=$(echo "$import_line" | grep -oE "[a-zA-Z_][a-zA-Z0-9_.]*" | head -n 1 | grep -v "import\|from\|require\|include\|using\|use" | head -c 50)
        if [ -n "$import_name" ]; then
            # Проверяем, используется ли импорт в коде
            usage_count=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" 2>/dev/null | xargs grep -F "$import_name" 2>/dev/null | grep -v "import \|from \|require\|include\|using\|use " | wc -l)
            if [ "$usage_count" -eq 0 ]; then
                echo "$import_name"
            fi
        fi
    done | wc -l)
    
    echo "Потенциальные неиспользуемые импорты: $UNUSED_IMPORTS" >> "$REPORT_FILE"
fi

TOTAL_DEAD_CODE=$((UNUSED_FUNCTIONS + COMMENTED_CODE_BLOCKS + UNUSED_IMPORTS))
echo "" >> "$REPORT_FILE"
echo "Всего потенциального мертвого кода: $TOTAL_DEAD_CODE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Добавить информацию о файлах с потенциальным мертвым кодом
echo "=== Файлы с потенциальным мертвым кодом ===" >> "$REPORT_FILE"
if command -v grep >/dev/null 2>&1; then
    echo "Файлы с закомментированным кодом:" >> "$REPORT_FILE"
    find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" -o -name "*.sh" 2>/dev/null | xargs grep -l -E "^[[:space:]]*//|^[[:space:]]*#" 2>/dev/null | head -10 >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Добавить рекомендации
echo "=== Рекомендации по очистке кода ===" >> "$REPORT_FILE"
echo "1. Удаляйте неиспользуемые функции и переменные" >> "$REPORT_FILE"
echo "2. Удаляйте закомментированный код, если он не нужен" >> "$REPORT_FILE"
echo "3. Удаляйте неиспользуемые импорты" >> "$REPORT_FILE"
echo "4. Проверяйте код на недостижимые участки" >> "$REPORT_FILE"
echo "5. Используйте инструменты статического анализа для обнаружения мертвого кода" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Отчет о мертвом коде сохранен в: $REPORT_FILE"
echo ""
echo "=== Анализ мертвого кода завершен ==="