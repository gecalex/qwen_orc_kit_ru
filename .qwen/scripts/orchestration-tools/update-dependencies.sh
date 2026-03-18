#!/bin/bash

# Скрипт обновления зависимостей
# Обновляет зависимости проекта с учетом безопасности и совместимости

set -e  # Прервать при ошибке

OUTPUT_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$OUTPUT_DIR/dependency_report_$TIMESTAMP.md"

# Создать директорию для отчетов, если не существует
mkdir -p "$OUTPUT_DIR"

echo "=== Аудит зависимостей ==="
echo "Время: $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Определить тип проекта и соответствующие файлы зависимостей
PROJECT_TYPE="unknown"
if [ -f "package.json" ]; then
    PROJECT_TYPE="nodejs"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
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
echo "" >> "$REPORT_FILE"

# Подсчет зависимостей в зависимости от типа проекта
DEP_COUNT=0
OUTDATED_COUNT=0
VULNERABLE_COUNT=0

case $PROJECT_TYPE in
    "nodejs")
        if command -v npm >/dev/null 2>&1; then
            echo "=== Анализ зависимостей Node.js ===" >> "$REPORT_FILE"
            DEP_COUNT=$(npm ls --depth=0 2>/dev/null | grep -c "deduped\|^├── \|└── " || echo 0)
            OUTDATED_COUNT=$(npm outdated 2>/dev/null | tail -n +2 | wc -l)
            echo "Всего зависимостей: $DEP_COUNT" >> "$REPORT_FILE"
            echo "Устаревших зависимостей: $OUTDATED_COUNT" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            
            # Проверка уязвимостей
            if npm audit --audit-level=high >/dev/null 2>&1; then
                VULNERABLE_COUNT=$(npm audit --audit-level=high --json 2>/dev/null | grep -c "critical\|high" || echo 0)
                echo "Зависимостей с уязвимостями (critical/high): $VULNERABLE_COUNT" >> "$REPORT_FILE"
            else
                echo "Не удалось выполнить проверку уязвимостей" >> "$REPORT_FILE"
            fi
        else
            echo "npm не установлен, невозможно проанализировать зависимости Node.js" >> "$REPORT_FILE"
        fi
        ;;
    "python")
        if command -v pip >/dev/null 2>&1; then
            echo "=== Анализ зависимостей Python ===" >> "$REPORT_FILE"
            if [ -f "requirements.txt" ]; then
                DEP_COUNT=$(grep -c "==" requirements.txt 2>/dev/null || echo 0)
                echo "Всего зависимостей: $DEP_COUNT" >> "$REPORT_FILE"
                
                # Проверка устаревших зависимостей
                if command -v pip-review >/dev/null 2>&1; then
                    OUTDATED_COUNT=$(pip-review --local --interactive --dry-run 2>/dev/null | grep -c "INSTALLED\|LATEST" || echo 0)
                    echo "Устаревших зависимостей: $OUTDATED_COUNT" >> "$REPORT_FILE"
                else
                    echo "pip-review не установлен, невозможно проверить устаревшие зависимости" >> "$REPORT_FILE"
                fi
                
                # Проверка уязвимостей
                if command -v pip-audit >/dev/null 2>&1; then
                    VULNERABLE_COUNT=$(pip-audit --quiet 2>&1 | grep -c "Vulnerability" || echo 0)
                    echo "Зависимостей с уязвимостями: $VULNERABLE_COUNT" >> "$REPORT_FILE"
                else
                    echo "pip-audit не установлен, невозможно проверить уязвимости" >> "$REPORT_FILE"
                fi
            else
                echo "Файл requirements.txt не найден" >> "$REPORT_FILE"
            fi
        else
            echo "pip не установлен, невозможно проанализировать зависимости Python" >> "$REPORT_FILE"
        fi
        ;;
    *)
        echo "Тип проекта не поддерживается скриптом, анализ зависимостей будет ограничен" >> "$REPORT_FILE"
        # Простой подсчет файлов зависимостей
        if [ -f "requirements.txt" ]; then
            DEP_COUNT=$(grep -c "==" requirements.txt 2>/dev/null || echo 0)
            echo "Потенциальных зависимостей (по requirements.txt): $DEP_COUNT" >> "$REPORT_FILE"
        fi
        if [ -f "package.json" ]; then
            DEP_COUNT=$(grep -c "version" package.json 2>/dev/null || echo 0)
            echo "Потенциальных зависимостей (по package.json): $DEP_COUNT" >> "$REPORT_FILE"
        fi
        ;;
esac

echo "" >> "$REPORT_FILE"

# Поиск потенциальных проблем с зависимостями
echo "=== Потенциальные проблемы с зависимостями ===" >> "$REPORT_FILE"

# Поиск неиспользуемых зависимостей (ограниченная проверка)
if [ "$PROJECT_TYPE" = "nodejs" ] && command -v depcheck >/dev/null 2>&1; then
    UNUSED_DEPS=$(npx depcheck 2>/dev/null | grep -A 20 "Unused dependencies" | grep -v "Unused dependencies" || echo "")
    if [ -n "$UNUSED_DEPS" ]; then
        echo "Неиспользуемые зависимости:" >> "$REPORT_FILE"
        echo "$UNUSED_DEPS" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
elif [ "$PROJECT_TYPE" = "python" ] && command -v pip-autoremove >/dev/null 2>&1; then
    UNUSED_DEPS=$(pip-autoremove --list 2>/dev/null || echo "")
    if [ -n "$UNUSED_DEPS" ]; then
        echo "Потенциально неиспользуемые зависимости:" >> "$REPORT_FILE"
        echo "$UNUSED_DEPS" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
fi

# Добавить рекомендации
echo "=== Рекомендации по управлению зависимостями ===" >> "$REPORT_FILE"
echo "1. Регулярно обновляйте зависимости до актуальных версий" >> "$REPORT_FILE"
echo "2. Проверяйте зависимости на наличие уязвимостей" >> "$REPORT_FILE"
echo "3. Удаляйте неиспользуемые зависимости" >> "$REPORT_FILE"
echo "4. Используйте lock-файлы для фиксации версий зависимостей" >> "$REPORT_FILE"
echo "5. Рассмотрите использование инструментов для автоматического аудита зависимостей" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Отчет об аудите зависимостей сохранен в: $REPORT_FILE"
echo ""
echo "=== Аудит зависимостей завершен ==="