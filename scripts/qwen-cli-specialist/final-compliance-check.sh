#!/bin/bash

# Скрипт проверки соответствия всех компонентов Qwen Orchestrator Kit стандартам

PROJECT_ROOT="/home/alex/MyProjects/qwen_orc_kit_ru"
REPORT_FILE="$PROJECT_ROOT/reports/final-compliance-report-$(date +%Y%m%d_%H%M%S).md"
LOG_FILE="$PROJECT_ROOT/logs/final-compliance-check-$(date +%Y%m%d_%H%M%S).log"

# Создаем директории
mkdir -p "$PROJECT_ROOT/reports"
mkdir -p "$PROJECT_ROOT/logs"

# Функция для логирования
log_check() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Начинаем отчет
echo "# Финальный отчет о соответствии стандартам Qwen Orchestrator Kit" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Дата: $(date)" >> "$REPORT_FILE"
echo "Проект: Qwen Orchestrator Kit" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

log_check "=== Запуск финальной проверки соответствия стандартам ==="

# Проверяем оркестраторы
log_check "Проверка оркестраторов..."
ORC_COUNT=0
ORC_ERRORS=0
for file in "$PROJECT_ROOT/.qwen/agents/orc_"*.md; do
    if [ -f "$file" ]; then
        ((ORC_COUNT++))
        filename=$(basename "$file")
        log_check "  Проверка оркестратора: $filename"
        
        # Проверяем наличие поля task
        if ! grep -A 50 "^---$" "$file" | grep -q " - task"; then
            log_check "    ❌ НЕТ: Поле task отсутствует (должно быть у оркестраторов)"
            echo "- ❌ $filename: Поле task отсутствует" >> "$REPORT_FILE"
            ((ORC_ERRORS++))
        else
            log_check "    ✅ OK: Поле task присутствует"
        fi
        
        # Проверяем наличие раздела ## Назначение
        if ! grep -q "^## Назначение" "$file"; then
            log_check "    ❌ НЕТ: Раздел ## Назначение отсутствует"
            echo "- ❌ $filename: Раздел ## Назначение отсутствует" >> "$REPORT_FILE"
            ((ORC_ERRORS++))
        else
            log_check "    ✅ OK: Раздел ## Назначение присутствует"
        fi
    fi
done

# Проверяем воркеры
log_check "Проверка воркеров..."
WORK_COUNT=0
WORK_ERRORS=0
for file in "$PROJECT_ROOT/.qwen/agents/work_"*.md; do
    if [ -f "$file" ]; then
        ((WORK_COUNT++))
        filename=$(basename "$file")
        log_check "  Проверка воркера: $filename"
        
        # Проверяем отсутствие поля task
        if grep -A 50 "^---$" "$file" | grep -q " - task"; then
            log_check "    ❌ НЕТ: Поле task присутствует (не должно быть у воркеров)"
            echo "- ❌ $filename: Поле task присутствует (не должно быть у воркеров)" >> "$REPORT_FILE"
            ((WORK_ERRORS++))
        else
            log_check "    ✅ OK: Поле task отсутствует (как и должно быть у воркеров)"
        fi
        
        # Проверяем наличие раздела ## Назначение
        if ! grep -q "^## Назначение" "$file"; then
            log_check "    ❌ НЕТ: Раздел ## Назначение отсутствует"
            echo "- ❌ $filename: Раздел ## Назначение отсутствует" >> "$REPORT_FILE"
            ((WORK_ERRORS++))
        else
            log_check "    ✅ OK: Раздел ## Назначение присутствует"
        fi
    fi
done

# Проверяем навыки
log_check "Проверка навыков..."
SKILL_COUNT=0
SKILL_ERRORS=0
for skill_dir in "$PROJECT_ROOT/.qwen/skills/"*/; do
    if [ -d "$skill_dir" ]; then
        skill_file="$skill_dir/SKILL.md"
        if [ -f "$skill_file" ]; then
            ((SKILL_COUNT++))
            skill_name=$(basename "$skill_dir")
            log_check "  Проверка навыка: $skill_name"
            
            # Проверяем наличие обязательных разделов
            missing_sections=""
            
            if ! grep -q "^## Когда использовать" "$skill_file"; then
                missing_sections="$missing_sections ## Когда использовать"
            fi
            
            if ! grep -q "^## Инструкции" "$skill_file"; then
                missing_sections="$missing_sections ## Инструкции"
            fi
            
            if ! grep -q "^## Формат ввода" "$skill_file"; then
                missing_sections="$missing_sections ## Формат ввода"
            fi
            
            if ! grep -q "^## Формат вывода" "$skill_file"; then
                missing_sections="$missing_sections ## Формат вывода"
            fi
            
            if ! grep -q "^## Примеры" "$skill_file"; then
                missing_sections="$missing_sections ## Примеры"
            fi
            
            if [ -n "$missing_sections" ]; then
                log_check "    ❌ НЕТ: Отсутствуют разделы: $missing_sections"
                echo "- ❌ $skill_name: Отсутствуют разделы: $missing_sections" >> "$REPORT_FILE"
                ((SKILL_ERRORS++))
            else
                log_check "    ✅ OK: Все обязательные разделы присутствуют"
            fi
        fi
    fi
done

# Подводим итоги
TOTAL_ERRORS=$((ORC_ERRORS + WORK_ERRORS + SKILL_ERRORS))
TOTAL_COMPONENTS=$((ORC_COUNT + WORK_COUNT + SKILL_COUNT))

echo "" >> "$REPORT_FILE"
echo "## Сводка" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| Тип компонента | Всего | Ошибок | Соответствие |" >> "$REPORT_FILE"
echo "|----------------|-------|--------|--------------|" >> "$REPORT_FILE"
echo "| Оркестраторы | $ORC_COUNT | $ORC_ERRORS | $((100 - ORC_ERRORS * 100 / (ORC_COUNT ? ORC_COUNT : 1)))% |" >> "$REPORT_FILE"
echo "| Воркеры | $WORK_COUNT | $WORK_ERRORS | $((100 - WORK_ERRORS * 100 / (WORK_COUNT ? WORK_COUNT : 1)))% |" >> "$REPORT_FILE"
echo "| Навыки | $SKILL_COUNT | $SKILL_ERRORS | $((100 - SKILL_ERRORS * 100 / (SKILL_COUNT ? SKILL_COUNT : 1)))% |" >> "$REPORT_FILE"
echo "| Всего | $TOTAL_COMPONENTS | $TOTAL_ERRORS | $((100 - TOTAL_ERRORS * 100 / (TOTAL_COMPONENTS ? TOTAL_COMPONENTS : 1)))% |" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

log_check ""
log_check "=== Результаты проверки ==="
log_check "Оркестраторы: $ORC_COUNT (ошибок: $ORC_ERRORS)"
log_check "Воркеры: $WORK_COUNT (ошибок: $WORK_ERRORS)"
log_check "Навыки: $SKILL_COUNT (ошибок: $SKILL_ERRORS)"
log_check "Всего компонентов: $TOTAL_COMPONENTS"
log_check "Всего ошибок: $TOTAL_ERRORS"

if [ $TOTAL_ERRORS -eq 0 ]; then
    log_check ""
    log_check "🎉 Все компоненты соответствуют стандартам!"
    echo "" >> "$REPORT_FILE"
    echo "## Заключение" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "🎉 Все компоненты соответствуют стандартам Qwen Orchestrator Kit!" >> "$REPORT_FILE"
else
    log_check ""
    log_check "⚠️  Обнаружены ошибки в $TOTAL_ERRORS компонентах из $TOTAL_COMPONENTS"
    echo "" >> "$REPORT_FILE"
    echo "## Заключение" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "⚠️  Обнаружены ошибки в $TOTAL_ERRORS компонентах из $TOTAL_COMPONENTS" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Рекомендуется исправить указанные проблемы для обеспечения полного соответствия стандартам." >> "$REPORT_FILE"
fi

log_check ""
log_check "Отчет сохранен в: $REPORT_FILE"
log_check "Подробные логи доступны в: $LOG_FILE"

echo "" >> "$REPORT_FILE"
echo "Отчет сгенерирован агентом-специалистом по Qwen Orchestrator Kit" >> "$REPORT_FILE"

log_check "=== Проверка завершена ==="