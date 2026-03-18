#!/bin/bash
# Скрипт проверки покрытия тестами
# Назначение: Проверяет уровень покрытия кода тестами
# Блокирующая: false (только предупреждение)

set -e

echo "=== Проверка покрытия тестами ==="

# Проверка наличия системы тестирования
if [ ! -f "package.json" ] || ! grep -q "test" package.json; then
    echo "⚠️  Система тестирования не обнаружена, пропускаем проверку покрытия"
    exit 0
fi

# Запуск тестов с измерением покрытия
echo "Запуск тестов с измерением покрытия..."
if npm run test:coverage; then
    COVERAGE_REPORT_PATH="coverage/coverage-summary.json"
    
    if [ -f "$COVERAGE_REPORT_PATH" ]; then
        # Извлечение данных о покрытии (пример для Istanbul)
        TOTAL_COVERAGE=$(grep -o '"lines":{"total":[0-9]*' "$COVERAGE_REPORT_PATH" | grep -o '[0-9]*' | tail -n 1)
        COVERED_LINES=$(grep -o '"lines":{"total":[0-9]*,"covered":[0-9]*' "$COVERAGE_REPORT_PATH" | grep -o 'covered":[0-9]*' | cut -d':' -f2)
        
        if [ -n "$TOTAL_COVERAGE" ] && [ -n "$COVERED_LINES" ] && [ "$TOTAL_COVERAGE" -ne 0 ]; then
            COVERAGE_PERCENTAGE=$((COVERED_LINES * 100 / TOTAL_COVERAGE))
            
            echo "📊 Покрытие кода: $COVERAGE_PERCENTAGE% ($COVERED_LINES из $TOTAL_COVERAGE строк)"
            
            # Проверка минимального порога покрытия (80%)
            MIN_COVERAGE=80
            
            if [ "$COVERAGE_PERCENTAGE" -ge "$MIN_COVERAGE" ]; then
                echo "✅ Покрытие тестами выше минимального порога ($MIN_COVERAGE%)"
            else
                echo "⚠️  Покрытие тестами ниже минимального порога ($MIN_COVERAGE%)"
                echo "   Текущее покрытие: $COVERAGE_PERCENTAGE%"
            fi
        else
            echo "⚠️  Не удалось извлечь данные о покрытии из отчета"
        fi
    else
        echo "⚠️  Отчет о покрытии не найден по пути: $COVERAGE_REPORT_PATH"
    fi
else
    echo "⚠️  Ошибка при запуске тестов с измерением покрытия"
fi

echo "Проверка покрытия тестами завершена"