#!/bin/bash

# Скрипт проверки соответствия агентов и навыков стандартам Qwen Code CLI

PROJECT_ROOT="/home/alex/MyProjects/qwen_orc_kit_ru"
AGENTS_DIR="$PROJECT_ROOT/.qwen/agents"
SKILLS_DIR="$PROJECT_ROOT/.qwen/skills"
REPORT_FILE="$PROJECT_ROOT/reports/standards-compliance-report-$(date +%Y%m%d_%H%M%S).md"

# Создаем директорию для отчетов
mkdir -p "$PROJECT_ROOT/reports"

# Функция для логирования
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$REPORT_FILE"
}

# Начинаем отчет
log_message "=== Отчет о проверке соответствия стандартам Qwen Code CLI ==="
log_message ""

# Проверяем агенты
log_message "Проверка агентов на соответствие стандартам..."
log_message ""

ORCHESTRATORS=($(find "$AGENTS_DIR" -name "orc_*.md" 2>/dev/null))
WORKERS=($(find "$AGENTS_DIR" -name "work_*.md" 2>/dev/null))

log_message "Найдено оркестраторов: ${#ORCHESTRATORS[@]}"
log_message "Найдено воркеров: ${#WORKERS[@]}"
log_message ""

# Проверяем каждый оркестратор
for orc_file in "${ORCHESTRATORS[@]}"; do
    log_message "Проверка оркестратора: $(basename "$orc_file")"
    
    # Проверяем YAML заголовок
    if ! grep -q "^---$" "$orc_file" 2>/dev/null; then
        log_message "  ❌ НЕТ: YAML заголовок не найден"
    else
        # Проверяем обязательные поля
        if ! grep -A 20 "^---$" "$orc_file" | grep -q "^name:"; then
            log_message "  ❌ НЕТ: Поле name отсутствует в YAML заголовке"
        fi
        
        if ! grep -A 20 "^---$" "$orc_file" | grep -q "^description:"; then
            log_message "  ❌ НЕТ: Поле description отсутствует в YAML заголовке"
        fi
        
        if ! grep -A 50 "^---$" "$orc_file" | grep -q "^tools:"; then
            log_message "  ❌ НЕТ: Поле tools отсутствует в YAML заголовке"
        elif grep -A 50 "^---$" "$orc_file" | grep -q "tools: \["; then
            log_message "  ❌ НЕТ: Неправильный формат поля tools (используются квадратные скобки)"
        fi
        
        if ! grep -A 20 "^---$" "$orc_file" | grep -q "^color:"; then
            log_message "  ❌ НЕТ: Поле color отсутствует в YAML заголовке"
        fi
        
        # Проверяем наличие поля task у оркестраторов
        if ! grep -A 50 "^---$" "$orc_file" | grep -q " - task"; then
            log_message "  ❌ НЕТ: Поле task отсутствует (должно быть у оркестраторов)"
        fi
    fi
    
    # Проверяем обязательные разделы
    if ! grep -q "^## Назначение" "$orc_file"; then
        log_message "  ❌ НЕТ: Раздел ## Назначение отсутствует"
    fi
    
    if ! grep -q "^## Интеграция навыков" "$orc_file"; then
        log_message "  ❌ НЕТ: Раздел ## Интеграция навыков отсутствует"
    fi
    
    log_message "  ✅ OK: $(basename "$orc_file") проверен"
    log_message ""
done

# Проверяем каждый воркер
for work_file in "${WORKERS[@]}"; do
    log_message "Проверка воркера: $(basename "$work_file")"
    
    # Проверяем YAML заголовок
    if ! grep -q "^---$" "$work_file" 2>/dev/null; then
        log_message "  ❌ НЕТ: YAML заголовок не найден"
    else
        # Проверяем обязательные поля
        if ! grep -A 20 "^---$" "$work_file" | grep -q "^name:"; then
            log_message "  ❌ НЕТ: Поле name отсутствует в YAML заголовке"
        fi
        
        if ! grep -A 20 "^---$" "$work_file" | grep -q "^description:"; then
            log_message "  ❌ НЕТ: Поле description отсутствует в YAML заголовке"
        fi
        
        if ! grep -A 50 "^---$" "$work_file" | grep -q "^tools:"; then
            log_message "  ❌ НЕТ: Поле tools отсутствует в YAML заголовке"
        elif grep -A 50 "^---$" "$work_file" | grep -q "tools: \["; then
            log_message "  ❌ НЕТ: Неправильный формат поля tools (используются квадратные скобки)"
        fi
        
        if ! grep -A 20 "^---$" "$work_file" | grep -q "^color:"; then
            log_message "  ❌ НЕТ: Поле color отсутствует в YAML заголовке"
        fi
        
        # Проверяем отсутствие поля task у воркеров (так как они не должны его иметь)
        if grep -A 50 "^---$" "$work_file" | grep -q " - task"; then
            log_message "  ❌ НЕТ: Поле task присутствует (не должно быть у воркеров)"
        fi
    fi
    
    # Проверяем обязательные разделы
    if ! grep -q "^## Назначение" "$work_file"; then
        log_message "  ❌ НЕТ: Раздел ## Назначение отсутствует"
    fi
    
    log_message "  ✅ OK: $(basename "$work_file") проверен"
    log_message ""
done

# Проверяем навыки
log_message "Проверка навыков на соответствие стандартам..."
log_message ""

SKILLS=($(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null))
log_message "Найдено навыков: ${#SKILLS[@]}"
log_message ""

for skill_file in "${SKILLS[@]}"; do
    skill_dir=$(dirname "$skill_file")
    skill_name=$(basename "$skill_dir")
    log_message "Проверка навыка: $skill_name"
    
    # Проверяем YAML заголовок
    if ! grep -q "^---$" "$skill_file" 2>/dev/null; then
        log_message "  ❌ НЕТ: YAML заголовок не найден"
    else
        # Проверяем обязательные поля
        if ! grep -A 20 "^---$" "$skill_file" | grep -q "^name:"; then
            log_message "  ❌ НЕТ: Поле name отсутствует в YAML заголовке"
        fi
        
        if ! grep -A 20 "^---$" "$skill_file" | grep -q "^description:"; then
            log_message "  ❌ НЕТ: Поле description отсутствует в YAML заголовке"
        fi
    fi
    
    # Проверяем обязательные разделы
    if ! grep -q "^## Когда использовать" "$skill_file"; then
        log_message "  ❌ НЕТ: Раздел ## Когда использовать отсутствует"
    fi
    
    if ! grep -q "^## Инструкции" "$skill_file"; then
        log_message "  ❌ НЕТ: Раздел ## Инструкции отсутствует"
    fi
    
    log_message "  ✅ OK: Навык $skill_name проверен"
    log_message ""
done

log_message "=== Проверка завершена ==="
log_message "Отчет сохранен в: $REPORT_FILE"

# Подсчитываем количество ошибок
ERROR_COUNT=$(grep -c "❌ НЕТ" "$REPORT_FILE")
SUCCESS_COUNT=$(grep -c "✅ OK" "$REPORT_FILE")

log_message ""
log_message "Статистика:"
log_message "- Найдено ошибок: $ERROR_COUNT"
log_message "- Успешно проверено компонентов: $SUCCESS_COUNT"

if [ $ERROR_COUNT -gt 0 ]; then
    log_message ""
    log_message "⚠️  Обнаружены нарушения стандартов. Рекомендуется исправить указанные проблемы."
    exit 1
else
    log_message ""
    log_message "🎉 Все компоненты соответствуют стандартам!"
    exit 0
fi