#!/bin/bash

# Скрипт генерации отчета безопасности
# Генерирует отчет о найденных уязвимостях в проекте

set -e  # Прервать при ошибке

OUTPUT_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$OUTPUT_DIR/security_report_$TIMESTAMP.md"

# Создать директорию для отчетов, если не существует
mkdir -p "$OUTPUT_DIR"

echo "=== Генерация отчета безопасности ==="
echo "Время: $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Проверить наличие уязвимостей в проекте
VULNERABILITY_COUNT=0
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0

# Пример поиска потенциальных уязвимостей (в реальном сценарии это будет сложнее)
if command -v grep >/dev/null 2>&1; then
    # Поиск потенциальных жестко закодированных паролей
    PASSWORD_PATTERN_COUNT=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" -o -name "*.sh" -o -name "*.md" 2>/dev/null | xargs grep -i "password\|pwd\|pass" 2>/dev/null | grep -v "^[[:space:]]*#" | grep -v "^.*//.*password" | wc -l)
    
    # Поиск потенциальных SQL-инъекций
    SQL_INJECTION_PATTERN_COUNT=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" 2>/dev/null | xargs grep -i "select\|insert\|update\|delete" 2>/dev/null | grep -v "^[[:space:]]*" | grep "=" | wc -l)
    
    VULNERABILITY_COUNT=$((PASSWORD_PATTERN_COUNT + SQL_INJECTION_PATTERN_COUNT))
    CRITICAL_COUNT=$PASSWORD_PATTERN_COUNT
    HIGH_COUNT=$SQL_INJECTION_PATTERN_COUNT
    
    echo "Найдено потенциальных уязвимостей: $VULNERABILITY_COUNT" >> "$REPORT_FILE"
    echo "- Критические (жестко закодированные пароли): $CRITICAL_COUNT" >> "$REPORT_FILE"
    echo "- Высокие (потенциальные SQL-инъекции): $HIGH_COUNT" >> "$REPORT_FILE"
    echo "- Средние: $MEDIUM_COUNT" >> "$REPORT_FILE"
    echo "- Низкие: $LOW_COUNT" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Добавить информацию о файлах с потенциальными уязвимостями
echo "=== Файлы с потенциальными уязвимостями ===" >> "$REPORT_FILE"
if command -v grep >/dev/null 2>&1; then
    echo "Файлы с потенциальными жестко закодированными паролями:" >> "$REPORT_FILE"
    find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" -o -name "*.sh" 2>/dev/null | xargs grep -l -i "password\|pwd\|pass" 2>/dev/null | head -10 >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "Файлы с потенциальными SQL-инъекциями:" >> "$REPORT_FILE"
    find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" 2>/dev/null | xargs grep -l -i "select\|insert\|update\|delete" 2>/dev/null | head -10 >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Добавить рекомендации
echo "=== Рекомендации по улучшению безопасности ===" >> "$REPORT_FILE"
echo "1. Не храните учетные данные в открытом виде в коде" >> "$REPORT_FILE"
echo "2. Используйте подготовленные выражения для SQL-запросов" >> "$REPORT_FILE"
echo "3. Проверяйте и фильтруйте все входные данные" >> "$REPORT_FILE"
echo "4. Используйте безопасные методы аутентификации и авторизации" >> "$REPORT_FILE"
echo "5. Регулярно обновляйте зависимости проекта" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Отчет о безопасности сохранен в: $REPORT_FILE"
echo ""
echo "=== Генерация отчета завершена ==="