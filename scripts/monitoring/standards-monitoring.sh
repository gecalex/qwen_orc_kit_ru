#!/bin/bash

# Скрипт регулярного мониторинга соответствия стандартам Qwen Code CLI
# Вызывается агентом-специалистом по Qwen Code CLI

PROJECT_ROOT="/home/alex/MyProjects/qwen_orc_kit_ru"
CONFIG_FILE="$PROJECT_ROOT/.qwen/config/monitoring-config.json"
LOG_DIR="$PROJECT_ROOT/logs"
REPORT_DIR="$PROJECT_ROOT/reports"

# Создаем директории
mkdir -p "$LOG_DIR"
mkdir -p "$REPORT_DIR"

# Функция для логирования
log_monitoring() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_DIR/monitoring-$(date +%Y%m).log"
}

log_monitoring "=== Запуск мониторинга соответствия стандартам ==="

# Проверяем, есть ли конфигурационный файл, если нет - создаем с настройками по умолчанию
if [ ! -f "$CONFIG_FILE" ]; then
    log_monitoring "Конфигурационный файл не найден, создаем с настройками по умолчанию"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
{
  "monitoring": {
    "enabled": true,
    "frequency": "daily",
    "checks": {
      "yaml_headers": true,
      "agent_structure": true,
      "skill_structure": true,
      "naming_convention": true
    },
    "notifications": {
      "enabled": true,
      "threshold_error_count": 5
    }
  }
}
EOF
fi

# Загружаем конфигурацию
ENABLED=$(jq -r '.monitoring.enabled // true' "$CONFIG_FILE")
FREQUENCY=$(jq -r '.monitoring.frequency // "daily"' "$CONFIG_FILE")
YAML_CHECK=$(jq -r '.monitoring.checks.yaml_headers // true' "$CONFIG_FILE")
AGENT_CHECK=$(jq -r '.monitoring.checks.agent_structure // true' "$CONFIG_FILE")
SKILL_CHECK=$(jq -r '.monitoring.checks.skill_structure // true' "$CONFIG_FILE")
NAMING_CHECK=$(jq -r '.monitoring.checks.naming_convention // true' "$CONFIG_FILE")
NOTIF_ENABLED=$(jq -r '.monitoring.notifications.enabled // true' "$CONFIG_FILE")
THRESHOLD=$(jq -r '.monitoring.notifications.threshold_error_count // 5' "$CONFIG_FILE")

# Выполняем проверки в зависимости от конфигурации
REPORT_FILE="$REPORT_DIR/monitoring-report-$(date +%Y%m%d_%H%M%S).md"

echo "# Отчет мониторинга соответствия стандартам" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Дата: $(date)" >> "$REPORT_FILE"
echo "Проект: Qwen Code CLI" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ "$YAML_CHECK" = true ]; then
    echo "## Проверка YAML заголовков" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Проверяем формат YAML заголовков
    for file in "$PROJECT_ROOT"/.qwen/agents/*.md; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if grep -A 50 "^---$" "$file" 2>/dev/null | grep -q "tools: \["; then
                echo "- ❌ $filename - неправильный формат tools" >> "$REPORT_FILE"
            else
                echo "- ✅ $filename - формат корректный" >> "$REPORT_FILE"
            fi
        fi
    done
    echo "" >> "$REPORT_FILE"
fi

if [ "$AGENT_CHECK" = true ]; then
    echo "## Проверка структуры агентов" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Проверяем наличие обязательных разделов в агентах
    for file in "$PROJECT_ROOT"/.qwen/agents/*.md; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            missing_sections=""
            
            if ! grep -q "^## Назначение" "$file"; then
                missing_sections="$missing_sections Назначение"
            fi
            
            # Для оркестраторов проверяем дополнительные разделы
            if [[ "$filename" == orc_* ]]; then
                if ! grep -q "^## Интеграция навыков" "$file"; then
                    missing_sections="$missing_sections Интеграция_навыков"
                fi
            fi
            
            if [ -z "$missing_sections" ]; then
                echo "- ✅ $filename - структура корректная" >> "$REPORT_FILE"
            else
                echo "- ❌ $filename - отсутствуют разделы: $missing_sections" >> "$REPORT_FILE"
            fi
        fi
    done
    echo "" >> "$REPORT_FILE"
fi

if [ "$SKILL_CHECK" = true ]; then
    echo "## Проверка структуры навыков" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Проверяем наличие обязательных разделов в навыках
    for skill_dir in "$PROJECT_ROOT"/.qwen/skills/*/; do
        if [ -d "$skill_dir" ]; then
            skill_file="$skill_dir/SKILL.md"
            skill_name=$(basename "$skill_dir")
            
            if [ -f "$skill_file" ]; then
                missing_sections=""
                
                if ! grep -q "^## Когда использовать" "$skill_file"; then
                    missing_sections="$missing_sections Когда_использовать"
                fi
                
                if ! grep -q "^## Инструкции" "$skill_file"; then
                    missing_sections="$missing_sections Инструкции"
                fi
                
                if [ -z "$missing_sections" ]; then
                    echo "- ✅ $skill_name - структура корректная" >> "$REPORT_FILE"
                else
                    echo "- ❌ $skill_name - отсутствуют разделы: $missing_sections" >> "$REPORT_FILE"
                fi
            fi
        fi
    done
    echo "" >> "$REPORT_FILE"
fi

if [ "$NAMING_CHECK" = true ]; then
    echo "## Проверка соглашений об именовании" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Проверяем именование агентов
    for file in "$PROJECT_ROOT"/.qwen/agents/*.md; do
        if [ -f "$file" ]; then
            filename=$(basename "$file" .md)
            
            # Проверяем, соответствует ли имя формату
            if [[ "$filename" =~ ^orc_ ]] || [[ "$filename" =~ ^work_ ]]; then
                # Проверяем формат kebab-case
                if [[ "$filename" =~ [A-Z] ]]; then
                    echo "- ❌ $filename - содержит заглавные буквы (должен быть kebab-case)" >> "$REPORT_FILE"
                else
                    echo "- ✅ $filename - именование корректное" >> "$REPORT_FILE"
                fi
            else
                echo "- ❌ $filename - не соответствует формату (должен начинаться с orc_ или work_)" >> "$REPORT_FILE"
            fi
        fi
    done
    echo "" >> "$REPORT_FILE"
fi

# Подсчитываем ошибки
ERROR_COUNT=$(grep -c "^- ❌" "$REPORT_FILE")
SUCCESS_COUNT=$(grep -c "^- ✅" "$REPORT_FILE")

echo "## Статистика" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- Всего проверено: $((ERROR_COUNT + SUCCESS_COUNT)) компонентов" >> "$REPORT_FILE"
echo "- Найдено ошибок: $ERROR_COUNT" >> "$REPORT_FILE"
echo "- Успешно пройдено: $SUCCESS_COUNT" >> "$REPORT_FILE"

log_monitoring "Мониторинг завершен. Найдено ошибок: $ERROR_COUNT, успешно: $SUCCESS_COUNT."

# Отправляем уведомление, если количество ошибок превышает порог
if [ "$NOTIF_ENABLED" = true ] && [ "$ERROR_COUNT" -ge "$THRESHOLD" ]; then
    log_monitoring "Количество ошибок ($ERROR_COUNT) превышает порог ($THRESHOLD). Требуется вмешательство."
    echo "" >> "$REPORT_FILE"
    echo "**ВНИМАНИЕ**: Количество ошибок превышает порог. Требуется вмешательство." >> "$REPORT_FILE"
    
    # Здесь можно добавить вызов навыка для уведомления
    # skill: "webhook-sender" с параметрами уведомления
fi

log_monitoring "Отчет сохранен в: $REPORT_FILE"
log_monitoring "=== Мониторинг завершен ==="

echo ""
echo "Мониторинг соответствия стандартам завершен."
echo "Отчет доступен в: $REPORT_FILE"
echo "Найдено ошибок: $ERROR_COUNT"