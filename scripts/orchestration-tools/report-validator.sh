#!/bin/bash
# Скрипт валидации отчетов
# Назначение: Проверяет формат и полноту отчетов агентов
# Блокирующая: false (только предупреждение)

set -e

echo "=== Валидация отчетов агентов ==="

# Проверка аргументов
if [ $# -lt 1 ]; then
    echo "Использование: $0 <путь_к_файлу_отчета>"
    echo "Пример: $0 .tmp/current/reports/bug-fix-report.md"
    exit 1
fi

REPORT_FILE=$1

# Проверка существования файла
if [ ! -f "$REPORT_FILE" ]; then
    echo "❌ ОШИБКА: Файл отчета не найден: $REPORT_FILE"
    exit 1
fi

echo "✅ Файл отчета найден: $REPORT_FILE"

# Проверка обязательных разделов
REQUIRED_SECTIONS=(
    "Executive Summary"
    "Work Performed"
    "Changes Made"
    "Validation Results"
    "Metrics"
    "Errors Encountered"
    "Next Steps"
    "Artifacts"
)

MISSING_SECTIONS=()
for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "^## $section" "$REPORT_FILE"; then
        MISSING_SECTIONS+=("$section")
    fi
done

if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
    echo "❌ ОШИБКА: В отчете отсутствуют следующие обязательные разделы:"
    for section in "${MISSING_SECTIONS[@]}"; do
        echo "  - $section"
    done
    exit 1
else
    echo "✅ Все обязательные разделы присутствуют"
fi

# Проверка наличия заголовка с метаданными
METADATA_CHECKS=(
    "Status"
    "Duration"
    "Agent"
    "Phase"
)

MISSING_METADATA=()
for metadata in "${METADATA_CHECKS[@]}"; do
    if ! grep -q "$metadata" "$REPORT_FILE"; then
        MISSING_METADATA+=("$metadata")
    fi
done

if [ ${#MISSING_METADATA[@]} -gt 0 ]; then
    echo "⚠️  В отчете отсутствуют следующие метаданные:"
    for metadata in "${MISSING_METADATA[@]}"; do
        echo "  - $metadata"
    done
else
    echo "✅ Все метаданные присутствуют"
fi

# Проверка формата статуса
if grep -q "Status.*✅\|Status.*⚠️\|Status.*❌" "$REPORT_FILE"; then
    echo "✅ Формат статуса корректен"
else
    echo "⚠️  Формат статуса может быть некорректным (ожидается ✅, ⚠️ или ❌)"
fi

# Подсчет общего количества проверок
TOTAL_CHECKS=$((${#REQUIRED_SECTIONS[@]} + ${#METADATA_CHECKS[@]}))
PASSED_CHECKS=$((${#REQUIRED_SECTIONS[@]} - ${#MISSING_SECTIONS[@]} + ${#METADATA_CHECKS[@]} - ${#MISSING_METADATA[@]}))

echo "📊 Результаты проверки: $PASSED_CHECKS/$TOTAL_CHECKS проверок пройдено"

if [ ${#MISSING_SECTIONS[@]} -eq 0 ]; then
    echo "🎉 Отчет соответствует стандартизированному формату!"
    exit 0
else
    echo "❌ Отчет не соответствует стандартизированному формату"
    exit 1
fi