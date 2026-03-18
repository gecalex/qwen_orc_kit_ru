#!/bin/bash

# Скрипт проверки безопасности
# Проверяет проект на наличие уязвимостей безопасности

set -e  # Прервать при ошибке

OUTPUT_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$OUTPUT_DIR/security_check_report_$TIMESTAMP.md"

# Создать директорию для отчетов, если не существует
mkdir -p "$OUTPUT_DIR"

echo "=== Проверка безопасности ==="
echo "Время: $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Определить тип проекта и соответствующие инструменты проверки безопасности
PROJECT_TYPE="unknown"
CRITICAL_THRESHOLD=0  # Количество критических уязвимостей, при котором проверка не проходит

if [ -f "package.json" ]; then
    PROJECT_TYPE="nodejs"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    PROJECT_TYPE="python"
elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="rust"
elif [ -f "Gemfile" ]; then
    PROJECT_TYPE="ruby"
elif [ -f "composer.json" ]; then
    PROJECT_TYPE="php"
elif [ -f "go.mod" ]; then
    PROJECT_TYPE="go"
fi

echo "Тип проекта: $PROJECT_TYPE" >> "$REPORT_FILE"
echo "Порог критических уязвимостей: $CRITICAL_THRESHOLD" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

VULNERABILITY_COUNT=0
CRITICAL_COUNT=0
HIGH_COUNT=0
PASS_STATUS="Неизвестно"

case $PROJECT_TYPE in
    "nodejs")
        if command -v npm >/dev/null 2>&1; then
            echo "=== Проверка безопасности зависимостей (npm audit) ===" >> "$REPORT_FILE"
            # Выполнить проверку безопасности
            AUDIT_OUTPUT=$(npm audit --audit-level=critical --json 2>/dev/null)
            CRITICAL_COUNT=$(echo "$AUDIT_OUTPUT" | grep -o '"critical":[0-9]*' | grep -o '[0-9]*')
            HIGH_COUNT=$(echo "$AUDIT_OUTPUT" | grep -o '"high":[0-9]*' | grep -o '[0-9]*')
            MODERATE_COUNT=$(echo "$AUDIT_OUTPUT" | grep -o '"moderate":[0-9]*' | grep -o '[0-9]*')
            LOW_COUNT=$(echo "$AUDIT_OUTPUT" | grep -o '"low":[0-9]*' | grep -o '[0-9]*')
            
            TOTAL_VULNERABILITIES=$((CRITICAL_COUNT + HIGH_COUNT + MODERATE_COUNT + LOW_COUNT))
            
            echo "Найдено уязвимостей: $TOTAL_VULNERABILITIES" >> "$REPORT_FILE"
            echo "- Критические: $CRITICAL_COUNT" >> "$REPORT_FILE"
            echo "- Высокие: $HIGH_COUNT" >> "$REPORT_FILE"
            echo "- Средние: $MODERATE_COUNT" >> "$REPORT_FILE"
            echo "- Низкие: $LOW_COUNT" >> "$REPORT_FILE"
            
            if [ "$CRITICAL_COUNT" -le "$CRITICAL_THRESHOLD" ]; then
                PASS_STATUS="ПРОЙДЕНО"
                echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
            else
                PASS_STATUS="НЕ ПРОЙДЕНО"
                echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                echo "Найдено критических уязвимостей больше порога ($CRITICAL_THRESHOLD)" >> "$REPORT_FILE"
            fi
            
            # Сохранить полный отчет
            echo "" >> "$REPORT_FILE"
            echo "=== Подробный отчет npm audit ===" >> "$REPORT_FILE"
            echo "$AUDIT_OUTPUT" >> "$REPORT_FILE"
        else
            echo "npm не установлен, невозможно проверить безопасность зависимостей" >> "$REPORT_FILE"
            PASS_STATUS="НЕ ПРОЙДЕНО"
        fi
        ;;
    "python")
        if command -v pip-audit >/dev/null 2>&1; then
            echo "=== Проверка безопасности зависимостей (pip-audit) ===" >> "$REPORT_FILE"
            # Выполнить проверку безопасности
            AUDIT_OUTPUT=$(pip-audit 2>&1)
            CRITICAL_COUNT=$(echo "$AUDIT_OUTPUT" | grep -c "Vulnerability")
            TOTAL_VULNERABILITIES=$CRITICAL_COUNT
            
            echo "Найдено уязвимостей: $TOTAL_VULNERABILITIES" >> "$REPORT_FILE"
            echo "- Критические/высокие: $CRITICAL_COUNT" >> "$REPORT_FILE"
            
            if [ "$CRITICAL_COUNT" -le "$CRITICAL_THRESHOLD" ]; then
                PASS_STATUS="ПРОЙДЕНО"
                echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
            else
                PASS_STATUS="НЕ ПРОЙДЕНО"
                echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                echo "Найдено критических уязвимостей больше порога ($CRITICAL_THRESHOLD)" >> "$REPORT_FILE"
            fi
            
            # Сохранить полный отчет
            echo "" >> "$REPORT_FILE"
            echo "=== Подробный отчет pip-audit ===" >> "$REPORT_FILE"
            echo "$AUDIT_OUTPUT" >> "$REPORT_FILE"
        else
            echo "pip-audit не установлен, невозможно проверить безопасность зависимостей" >> "$REPORT_FILE"
            PASS_STATUS="НЕ ПРОЙДЕНО"
        fi
        ;;
    "rust")
        if command -v cargo >/dev/null 2>&1; then
            echo "=== Проверка безопасности зависимостей (cargo-audit) ===" >> "$REPORT_FILE"
            # Проверить наличие cargo-audit
            if cargo audit --help >/dev/null 2>&1; then
                AUDIT_OUTPUT=$(cargo audit 2>&1)
                CRITICAL_COUNT=$(echo "$AUDIT_OUTPUT" | grep -c "severity: *critical\|severity: *high")
                TOTAL_VULNERABILITIES=$CRITICAL_COUNT
                
                echo "Найдено уязвимостей: $TOTAL_VULNERABILITIES" >> "$REPORT_FILE"
                echo "- Критические/высокие: $CRITICAL_COUNT" >> "$REPORT_FILE"
                
                if [ "$CRITICAL_COUNT" -le "$CRITICAL_THRESHOLD" ]; then
                    PASS_STATUS="ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                else
                    PASS_STATUS="НЕ ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                    echo "Найдено критических уязвимостей больше порога ($CRITICAL_THRESHOLD)" >> "$REPORT_FILE"
                fi
                
                # Сохранить полный отчет
                echo "" >> "$REPORT_FILE"
                echo "=== Подробный отчет cargo audit ===" >> "$REPORT_FILE"
                echo "$AUDIT_OUTPUT" >> "$REPORT_FILE"
            else
                echo "cargo-audit не установлен, невозможно проверить безопасность зависимостей" >> "$REPORT_FILE"
                PASS_STATUS="НЕ ПРОЙДЕНО"
            fi
        else
            echo "cargo не установлен, невозможно проверить безопасность зависимостей" >> "$REPORT_FILE"
            PASS_STATUS="НЕ ПРОЙДЕНО"
        fi
        ;;
    "go")
        if command -v go >/dev/null 2>&1; then
            echo "=== Проверка безопасности (golangci-lint + govulncheck) ===" >> "$REPORT_FILE"
            # Проверить наличие govulncheck
            if go install golang.org/x/vuln/cmd/govulncheck@latest && command -v govulncheck >/dev/null 2>&1; then
                AUDIT_OUTPUT=$(govulncheck ./... 2>&1)
                CRITICAL_COUNT=$(echo "$AUDIT_OUTPUT" | grep -c "vuln:")
                TOTAL_VULNERABILITIES=$CRITICAL_COUNT
                
                echo "Найдено уязвимостей: $TOTAL_VULNERABILITIES" >> "$REPORT_FILE"
                echo "- Критические: $CRITICAL_COUNT" >> "$REPORT_FILE"
                
                if [ "$CRITICAL_COUNT" -le "$CRITICAL_THRESHOLD" ]; then
                    PASS_STATUS="ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                else
                    PASS_STATUS="НЕ ПРОЙДЕНО"
                    echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                    echo "Найдено критических уязвимостей больше порога ($CRITICAL_THRESHOLD)" >> "$REPORT_FILE"
                fi
                
                # Сохранить полный отчет
                echo "" >> "$REPORT_FILE"
                echo "=== Подробный отчет govulncheck ===" >> "$REPORT_FILE"
                echo "$AUDIT_OUTPUT" >> "$REPORT_FILE"
            else
                echo "govulncheck не установлен, невозможно проверить безопасность" >> "$REPORT_FILE"
                PASS_STATUS="НЕ ПРОЙДЕНО"
            fi
        else
            echo "go не установлен, невозможно проверить безопасность" >> "$REPORT_FILE"
            PASS_STATUS="НЕ ПРОЙДЕНО"
        fi
        ;;
    *)
        echo "Тип проекта не поддерживается для проверки безопасности" >> "$REPORT_FILE"
        echo "Запускаем базовую проверку на наличие потенциальных уязвимостей" >> "$REPORT_FILE"
        
        # Базовая проверка на наличие потенциальных уязвимостей
        POTENTIAL_PASSWORDS=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" -o -name "*.sh" -o -name "*.md" 2>/dev/null | xargs grep -i "password\|pwd\|pass" 2>/dev/null | grep -v "^[[:space:]]*#" | grep -v "^.*//.*password" | wc -l)
        
        POTENTIAL_SQL_INJECTIONS=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.php" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" 2>/dev/null | xargs grep -i "select\|insert\|update\|delete" 2>/dev/null | grep -v "^[[:space:]]*" | grep "=" | wc -l)
        
        TOTAL_VULNERABILITIES=$((POTENTIAL_PASSWORDS + POTENTIAL_SQL_INJECTIONS))
        CRITICAL_COUNT=$POTENTIAL_PASSWORDS
        
        echo "Найдено потенциальных уязвимостей: $TOTAL_VULNERABILITIES" >> "$REPORT_FILE"
        echo "- Потенциальные жестко закодированные пароли: $POTENTIAL_PASSWORDS" >> "$REPORT_FILE"
        echo "- Потенциальные SQL-инъекции: $POTENTIAL_SQL_INJECTIONS" >> "$REPORT_FILE"
        
        if [ "$CRITICAL_COUNT" -le "$CRITICAL_THRESHOLD" ]; then
            PASS_STATUS="ПРОЙДЕНО"
            echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
        else
            PASS_STATUS="НЕ ПРОЙДЕНО"
            echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
            echo "Найдено критических уязвимостей больше порога ($CRITICAL_THRESHOLD)" >> "$REPORT_FILE"
        fi
        ;;
esac

echo "" >> "$REPORT_FILE"

# Добавить рекомендации
echo "=== Рекомендации по улучшению безопасности ===" >> "$REPORT_FILE"
echo "1. Регулярно обновляйте зависимости проекта" >> "$REPORT_FILE"
echo "2. Не храните учетные данные в открытом виде в коде" >> "$REPORT_FILE"
echo "3. Используйте подготовленные выражения для SQL-запросов" >> "$REPORT_FILE"
echo "4. Проверяйте и фильтруйте все входные данные" >> "$REPORT_FILE"
echo "5. Используйте безопасные методы аутентификации и авторизации" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Отчет о проверке безопасности сохранен в: $REPORT_FILE"
echo ""
echo "=== Проверка безопасности завершена ==="

# Возвращаем соответствующий код возврата
if [ "$PASS_STATUS" = "ПРОЙДЕНО" ]; then
    exit 0
else
    exit 1
fi