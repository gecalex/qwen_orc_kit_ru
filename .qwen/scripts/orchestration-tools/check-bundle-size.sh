#!/bin/bash

# Скрипт проверки размера бандла
# Проверяет размер собранного проекта (бандла) и сравнивает с пороговым значением

set -e  # Прервать при ошибке

OUTPUT_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$OUTPUT_DIR/bundle_size_report_$TIMESTAMP.md"

# Создать директорию для отчетов, если не существует
mkdir -p "$OUTPUT_DIR"

echo "=== Проверка размера бандла ==="
echo "Время: $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Установить порог размера бандла (в мегабайтах)
BUNDLE_SIZE_THRESHOLD_MB=5  # Максимально допустимый размер бандла в MB

echo "Порог размера бандла: ${BUNDLE_SIZE_THRESHOLD_MB}MB" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Определить тип проекта и соответствующие директории сборки
PROJECT_TYPE="unknown"
BUNDLE_PATH=""

if [ -f "package.json" ]; then
    # Проверить, является ли проект Node.js/React/Vue и т.д.
    if grep -q "react" package.json; then
        PROJECT_TYPE="react"
        BUNDLE_PATH="build"
    elif grep -q "vue" package.json; then
        PROJECT_TYPE="vue"
        BUNDLE_PATH="dist"
    elif grep -q "@angular/core" package.json; then
        PROJECT_TYPE="angular"
        BUNDLE_PATH="dist"
    else
        PROJECT_TYPE="nodejs"
        BUNDLE_PATH="dist"
    fi
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    PROJECT_TYPE="python"
    BUNDLE_PATH="dist"
elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="rust"
    BUNDLE_PATH="target/release"
elif [ -f "go.mod" ]; then
    PROJECT_TYPE="go"
    BUNDLE_PATH="build"
fi

echo "Тип проекта: $PROJECT_TYPE" >> "$REPORT_FILE"
echo "Предполагаемый путь к бандлу: $BUNDLE_PATH" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

BUNDLE_SIZE_BYTES=0
BUNDLE_SIZE_MB=0
PASS_STATUS="Неизвестно"

# Проверить размер бандла
if [ -d "$BUNDLE_PATH" ]; then
    BUNDLE_SIZE_BYTES=$(du -sb "$BUNDLE_PATH" 2>/dev/null | cut -f1)
    BUNDLE_SIZE_MB=$(echo "$BUNDLE_SIZE_BYTES" | awk '{printf "%.2f", $1/1024/1024}')
    
    echo "Размер бандла: ${BUNDLE_SIZE_MB}MB (${BUNDLE_SIZE_BYTES} байт)" >> "$REPORT_FILE"
    
    if (( $(echo "$BUNDLE_SIZE_MB <= $BUNDLE_SIZE_THRESHOLD_MB" | bc -l) )); then
        PASS_STATUS="ПРОЙДЕНО"
        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
        echo "Размер бандла находится в пределах допустимого порога" >> "$REPORT_FILE"
    else
        PASS_STATUS="НЕ ПРОЙДЕНО"
        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
        echo "Размер бандла превышает допустимый порог в ${BUNDLE_SIZE_THRESHOLD_MB}MB" >> "$REPORT_FILE"
    fi
else
    # Если директория бандла не существует, попробовать собрать проект
    echo "Директория бандла $BUNDLE_PATH не найдена, пробуем собрать проект..." >> "$REPORT_FILE"
    
    case $PROJECT_TYPE in
        "react")
            if command -v npm >/dev/null 2>&1; then
                echo "Запускаем сборку React-приложения..." >> "$REPORT_FILE"
                npm run build 2>>"$REPORT_FILE" || echo "Ошибка сборки" >> "$REPORT_FILE"
                if [ -d "$BUNDLE_PATH" ]; then
                    BUNDLE_SIZE_BYTES=$(du -sb "$BUNDLE_PATH" 2>/dev/null | cut -f1)
                    BUNDLE_SIZE_MB=$(echo "$BUNDLE_SIZE_BYTES" | awk '{printf "%.2f", $1/1024/1024}')
                    echo "Размер бандла: ${BUNDLE_SIZE_MB}MB (${BUNDLE_SIZE_BYTES} байт)" >> "$REPORT_FILE"
                    
                    if (( $(echo "$BUNDLE_SIZE_MB <= $BUNDLE_SIZE_THRESHOLD_MB" | bc -l) )); then
                        PASS_STATUS="ПРОЙДЕНО"
                        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                        echo "Размер бандла находится в пределах допустимого порога" >> "$REPORT_FILE"
                    else
                        PASS_STATUS="НЕ ПРОЙДЕНО"
                        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                        echo "Размер бандла превышает допустимый порог в ${BUNDLE_SIZE_THRESHOLD_MB}MB" >> "$REPORT_FILE"
                    fi
                else
                    echo "Не удалось собрать проект или найти бандл" >> "$REPORT_FILE"
                    PASS_STATUS="ОШИБКА"
                fi
            else
                echo "npm не установлен, невозможно собрать проект" >> "$REPORT_FILE"
                PASS_STATUS="НЕ ПРОЙДЕНО"
            fi
            ;;
        "vue")
            if command -v npm >/dev/null 2>&1; then
                echo "Запускаем сборку Vue-приложения..." >> "$REPORT_FILE"
                npm run build 2>>"$REPORT_FILE" || echo "Ошибка сборки" >> "$REPORT_FILE"
                if [ -d "$BUNDLE_PATH" ]; then
                    BUNDLE_SIZE_BYTES=$(du -sb "$BUNDLE_PATH" 2>/dev/null | cut -f1)
                    BUNDLE_SIZE_MB=$(echo "$BUNDLE_SIZE_BYTES" | awk '{printf "%.2f", $1/1024/1024}')
                    echo "Размер бандла: ${BUNDLE_SIZE_MB}MB (${BUNDLE_SIZE_BYTES} байт)" >> "$REPORT_FILE"
                    
                    if (( $(echo "$BUNDLE_SIZE_MB <= $BUNDLE_SIZE_THRESHOLD_MB" | bc -l) )); then
                        PASS_STATUS="ПРОЙДЕНО"
                        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                        echo "Размер бандла находится в пределах допустимого порога" >> "$REPORT_FILE"
                    else
                        PASS_STATUS="НЕ ПРОЙДЕНО"
                        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                        echo "Размер бандла превышает допустимый порог в ${BUNDLE_SIZE_THRESHOLD_MB}MB" >> "$REPORT_FILE"
                    fi
                else
                    echo "Не удалось собрать проект или найти бандл" >> "$REPORT_FILE"
                    PASS_STATUS="ОШИБКА"
                fi
            else
                echo "npm не установлен, невозможно собрать проект" >> "$REPORT_FILE"
                PASS_STATUS="НЕ ПРОЙДЕНО"
            fi
            ;;
        "angular")
            if command -v ng >/dev/null 2>&1; then
                echo "Запускаем сборку Angular-приложения..." >> "$REPORT_FILE"
                ng build --prod 2>>"$REPORT_FILE" || echo "Ошибка сборки" >> "$REPORT_FILE"
                if [ -d "$BUNDLE_PATH" ]; then
                    BUNDLE_SIZE_BYTES=$(du -sb "$BUNDLE_PATH" 2>/dev/null | cut -f1)
                    BUNDLE_SIZE_MB=$(echo "$BUNDLE_SIZE_BYTES" | awk '{printf "%.2f", $1/1024/1024}')
                    echo "Размер бандла: ${BUNDLE_SIZE_MB}MB (${BUNDLE_SIZE_BYTES} байт)" >> "$REPORT_FILE"
                    
                    if (( $(echo "$BUNDLE_SIZE_MB <= $BUNDLE_SIZE_THRESHOLD_MB" | bc -l) )); then
                        PASS_STATUS="ПРОЙДЕНО"
                        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                        echo "Размер бандла находится в пределах допустимого порога" >> "$REPORT_FILE"
                    else
                        PASS_STATUS="НЕ ПРОЙДЕНО"
                        echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                        echo "Размер бандла превышает допустимый порог в ${BUNDLE_SIZE_THRESHOLD_MB}MB" >> "$REPORT_FILE"
                    fi
                else
                    echo "Не удалось собрать проект или найти бандл" >> "$REPORT_FILE"
                    PASS_STATUS="ОШИБКА"
                fi
            else
                echo "Angular CLI (ng) не установлен, невозможно собрать проект" >> "$REPORT_FILE"
                PASS_STATUS="НЕ ПРОЙДЕНО"
            fi
            ;;
        "python")
            if command -v python >/dev/null 2>&1; then
                echo "Проверяем размер Python-пакета..." >> "$REPORT_FILE"
                # Попробовать собрать пакет с помощью setuptools или poetry
                if [ -f "setup.py" ]; then
                    python setup.py sdist bdist_wheel 2>>"$REPORT_FILE" || echo "Ошибка сборки" >> "$REPORT_FILE"
                    if [ -d "dist" ]; then
                        BUNDLE_SIZE_BYTES=$(du -sb dist 2>/dev/null | cut -f1)
                        BUNDLE_SIZE_MB=$(echo "$BUNDLE_SIZE_BYTES" | awk '{printf "%.2f", $1/1024/1024}')
                        echo "Размер бандла: ${BUNDLE_SIZE_MB}MB (${BUNDLE_SIZE_BYTES} байт)" >> "$REPORT_FILE"
                        
                        if (( $(echo "$BUNDLE_SIZE_MB <= $BUNDLE_SIZE_THRESHOLD_MB" | bc -l) )); then
                            PASS_STATUS="ПРОЙДЕНО"
                            echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                            echo "Размер бандла находится в пределах допустимого порога" >> "$REPORT_FILE"
                        else
                            PASS_STATUS="НЕ ПРОЙДЕНО"
                            echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                            echo "Размер бандла превышает допустимый порог в ${BUNDLE_SIZE_THRESHOLD_MB}MB" >> "$REPORT_FILE"
                        fi
                    else
                        echo "Не удалось собрать проект или найти бандл" >> "$REPORT_FILE"
                        PASS_STATUS="ОШИБКА"
                    fi
                elif command -v poetry >/dev/null 2>&1; then
                    poetry build 2>>"$REPORT_FILE" || echo "Ошибка сборки" >> "$REPORT_FILE"
                    if [ -d "dist" ]; then
                        BUNDLE_SIZE_BYTES=$(du -sb dist 2>/dev/null | cut -f1)
                        BUNDLE_SIZE_MB=$(echo "$BUNDLE_SIZE_BYTES" | awk '{printf "%.2f", $1/1024/1024}')
                        echo "Размер бандла: ${BUNDLE_SIZE_MB}MB (${BUNDLE_SIZE_BYTES} байт)" >> "$REPORT_FILE"
                        
                        if (( $(echo "$BUNDLE_SIZE_MB <= $BUNDLE_SIZE_THRESHOLD_MB" | bc -l) )); then
                            PASS_STATUS="ПРОЙДЕНО"
                            echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                            echo "Размер бандла находится в пределах допустимого порога" >> "$REPORT_FILE"
                        else
                            PASS_STATUS="НЕ ПРОЙДЕНО"
                            echo "Статус: $PASS_STATUS" >> "$REPORT_FILE"
                            echo "Размер бандла превышает допустимый порог в ${BUNDLE_SIZE_THRESHOLD_MB}MB" >> "$REPORT_FILE"
                        fi
                    else
                        echo "Не удалось собрать проект или найти бандл" >> "$REPORT_FILE"
                        PASS_STATUS="ОШИБКА"
                    fi
                else
                    echo "Ни setup.py, ни poetry не найдены/установлены для сборки Python-пакета" >> "$REPORT_FILE"
                    PASS_STATUS="НЕ ПРОЙДЕНО"
                fi
            else
                echo "python не установлен, невозможно собрать проект" >> "$REPORT_FILE"
                PASS_STATUS="НЕ ПРОЙДЕНО"
            fi
            ;;
        *)
            echo "Тип проекта не поддерживается для автоматической сборки" >> "$REPORT_FILE"
            PASS_STATUS="НЕ ПРОЙДЕНО"
            ;;
    esac
fi

echo "" >> "$REPORT_FILE"

# Добавить рекомендации
echo "=== Рекомендации по оптимизации размера бандла ===" >> "$REPORT_FILE"
echo "1. Используйте tree-shaking для удаления неиспользуемого кода" >> "$REPORT_FILE"
echo "2. Оптимизируйте изображения и статические ресурсы" >> "$REPORT_FILE"
echo "3. Используйте lazy loading для загрузки компонентов по требованию" >> "$REPORT_FILE"
echo "4. Минимизируйте и сжимайте JavaScript и CSS файлы" >> "$REPORT_FILE"
echo "5. Избегайте включения лишних зависимостей в бандл" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Отчет о размере бандла сохранен в: $REPORT_FILE"
echo ""
echo "=== Проверка размера бандла завершена ==="

# Возвращаем соответствующий код возврата
if [ "$PASS_STATUS" = "ПРОЙДЕНО" ]; then
    exit 0
else
    exit 1
fi