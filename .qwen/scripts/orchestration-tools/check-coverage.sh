#!/bin/bash

# Скрипт проверки покрытия тестами
# Проверяет процент покрытия кода тестами

set -e  # Прервать при ошибке

OUTPUT_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$OUTPUT_DIR/coverage_report_$TIMESTAMP.md"

# Создать директорию для отчетов, если не существует
mkdir -p "$OUTPUT_DIR"

echo "=== Проверка покрытия тестами ==="
echo "Время: $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Определить тип проекта и соответствующие инструменты проверки покрытия
PROJECT_TYPE="unknown"
COVERAGE_THRESHOLD=80  # Минимальный порог покрытия в процентах

if [ -f "package.json" ] && grep -q "jest" package.json; then
    PROJECT_TYPE="nodejs-jest"
elif [ -f "requirements.txt" ] && grep -q "pytest-cov\|coverage" requirements.txt; then
    PROJECT_TYPE="python-pytest"
elif [ -f "pyproject.toml" ] && grep -q "pytest-cov\|coverage" pyproject.toml; then
    PROJECT_TYPE="python-pytest"
elif [ -f "go.mod" ]; then
    PROJECT_TYPE="go"
elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="rust"
fi

echo "Тип проекта: $PROJECT_TYPE" >> "$REPORT_FILE"
echo "Порог покрытия: ${COVERAGE_THRESHOLD}%" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

COVERAGE_PERCENTAGE=0
PASS_STATUS="Неизвестно"

case $PROJECT_TYPE in
    "nodejs-jest")
        if command -v npx >/dev/null 2>&1; then
            echo "=== Проверка покрытия тестами (Jest) ===" >> "$REPORT_FILE"
            # Запустить тесты с покрытием и получить результат
            if npx jest --coverage --coverageReporters=text 2>/dev/null | grep -E "Lines.*|Functions.*|Branch.*|Statements.*" > /tmp/coverage_result.txt; then
                COVERAGE_PERCENTAGE=$(grep "Lines" /tmp/coverage_result.txt | grep -oE "[0-9]+([.][0-9]+)?" | head -1)
                echo "Процент покрытия: ${COVERAGE_PERCENTAGE}%" >> "$REPORT_FILE"
                
                if (( $(echo "$COVERAGE_PERCENTAGE >= $COVERAGE_THRESHOLD" | bc -l) )); then
                    PASS_STATUS="ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                else
                    PASS_STATUS="НЕ ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                    echo "Покрытие ниже порога в ${COVERAGE_THRESHOLD}%" >> "$REPORT_FILE"
                fi
            else
                echo "Ошибка: не удалось получить результаты покрытия" >> "$REPORT_FILE"
                PASS_STATUS="ОШИБКА"
            fi
        else
            echo "npx не установлен, невозможно проверить покрытие" >> "$REPORT_FILE"
            PASS_STATUS="НЕ ПРОЙДЕНО"
        fi
        ;;
    "python-pytest")
        if command -v python >/dev/null 2>&1; then
            echo "=== Проверка покрытия тестами (Pytest) ===" >> "$REPORT_FILE"
            # Запустить тесты с покрытием и получить результат
            if python -m pytest --cov --cov-report=term 2>/dev/null | grep -E "TOTAL.*" > /tmp/coverage_result.txt; then
                COVERAGE_PERCENTAGE=$(grep "TOTAL" /tmp/coverage_result.txt | awk '{print $NF}' | sed 's/%//')
                echo "Процент покрытия: ${COVERAGE_PERCENTAGE}%" >> "$REPORT_FILE"
                
                if (( $(echo "$COVERAGE_PERCENTAGE >= $COVERAGE_THRESHOLD" | bc -l) )); then
                    PASS_STATUS="ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                else
                    PASS_STATUS="НЕ ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                    echo "Покрытие ниже порога в ${COVERAGE_THRESHOLD}%" >> "$REPORT_FILE"
                fi
            else
                echo "Ошибка: не удалось получить результаты покрытия" >> "$REPORT_FILE"
                PASS_STATUS="ОШИБКА"
            fi
        else
            echo "python не установлен, невозможно проверить покрытие" >> "$REPORT_FILE"
            PASS_STATUS="НЕ ПРОЙДЕНО"
        fi
        ;;
    "go")
        if command -v go >/dev/null 2>&1; then
            echo "=== Проверка покрытия тестами (Go) ===" >> "$REPORT_FILE"
            # Запустить тесты с покрытием и получить результат
            if go test -coverprofile=coverage.out ./... 2>/dev/null; then
                COVERAGE_PERCENTAGE=$(go tool cover -func=coverage.out 2>/dev/null | grep -E "^total:" | awk '{print $3}' | sed 's/%//')
                echo "Процент покрытия: ${COVERAGE_PERCENTAGE}%" >> "$REPORT_FILE"
                
                if (( $(echo "$COVERAGE_PERCENTAGE >= $COVERAGE_THRESHOLD" | bc -l) )); then
                    PASS_STATUS="ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                else
                    PASS_STATUS="НЕ ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                    echo "Покрытие ниже порога в ${COVERAGE_THRESHOLD}%" >> "$REPORT_FILE"
                fi
                rm -f coverage.out
            else
                echo "Ошибка: не удалось получить результаты покрытия" >> "$REPORT_FILE"
                PASS_STATUS="ОШИБКА"
            fi
        else
            echo "go не установлен, невозможно проверить покрытие" >> "$REPORT_FILE"
            PASS_STATUS="НЕ ПРОЙДЕНО"
        fi
        ;;
    "rust")
        if command -v cargo >/dev/null 2>&1; then
            echo "=== Проверка покрытия тестами (Rust) ===" >> "$REPORT_FILE"
            # Проверить наличие инструмента tarpaulin для покрытия в Rust
            if cargo tarpaulin --help >/dev/null 2>&1; then
                if cargo tarpaulin --out Xml 2>/dev/null; then
                    COVERAGE_PERCENTAGE=$(grep -oE '[0-9]+([.][0-9]+)?' cobertura.xml | head -1)
                    echo "Процент покрытия: ${COVERAGE_PERCENTAGE}%" >> "$REPORT_FILE"
                    
                    if (( $(echo "$COVERAGE_PERCENTAGE >= $COVERAGE_THRESHOLD" | bc -l) )); then
                        PASS_STATUS="ПРОЙДЕНО"
                        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                    else
                        PASS_STATUS="НЕ ПРОЙДЕНО"
                        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                        echo "Покрытие ниже порога в ${COVERAGE_THRESHOLD}%" >> "$REPORT_FILE"
                    fi
                    rm -f cobertura.xml
                else
                    echo "Ошибка: не удалось получить результаты покрытия" >> "$REPORT_FILE"
                    PASS_STATUS="ОШИБКА"
                fi
            else
                echo "cargo-tarpaulin не установлен, невозможно проверить покрытие" >> "$REPORT_FILE"
                PASS_STATUS="НЕ ПРОЙДЕНО"
            fi
        else
            echo "cargo не установлен, невозможно проверить покрытие" >> "$REPORT_FILE"
            PASS_STATUS="НЕ ПРОЙДЕНО"
        fi
        ;;
    *)
        echo "Тип проекта не поддерживается для проверки покрытия тестами" >> "$REPORT_FILE"
        echo "Попробуйте вручную запустить инструмент покрытия для вашего типа проекта" >> "$REPORT_FILE"
        PASS_STATUS="НЕ ПРОЙДЕНО"
        ;;
esac

echo "" >> "$REPORT_FILE"

# Добавить рекомендации
echo "=== Рекомендации по улучшению покрытия тестами ===" >> "$REPORT_FILE"
echo "1. Пишите модульные тесты для новых функций" >> "$REPORT_FILE"
echo "2. Покрывайте граничные условия и ошибочные сценарии" >> "$REPORT_FILE"
echo "3. Используйте инструменты для анализа покрытия кода" >> "$REPORT_FILE"
echo "4. Устанавливайте минимальный порог покрытия для команды" >> "$REPORT_FILE"
echo "5. Регулярно анализируйте непокрытые участки кода" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Отчет о покрытии тестами сохранен в: $REPORT_FILE"
echo ""
echo "=== Проверка покрытия тестами завершена ==="

# Возвращаем соответствующий код возврата
if [ "$PASS_STATUS" = "ПРОЙДЕНО" ]; then
    exit 0
else
    exit 1
fi