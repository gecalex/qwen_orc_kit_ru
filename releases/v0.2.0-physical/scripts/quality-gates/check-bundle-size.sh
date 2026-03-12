#!/bin/bash
# Скрипт проверки размера бандла
# Назначение: Проверяет размер собранного приложения
# Блокирующая: false (только предупреждение)

set -e

echo "=== Проверка размера бандла ==="

# Определение директории сборки
BUILD_DIRS=("dist" "build" "out" "_next/static" "public/dist")

BUILD_DIR=""
for dir in "${BUILD_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        BUILD_DIR="$dir"
        break
    fi
done

if [ -z "$BUILD_DIR" ]; then
    echo "⚠️  Директория сборки не найдена, пропускаем проверку размера бандла"
    exit 0
fi

echo "Проверка размера бандла в директории: $BUILD_DIR"

# Подсчет размера бандла
BUNDLE_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)

# Подсчет размера в байтах для сравнения
BUNDLE_SIZE_BYTES=$(du -sb "$BUILD_DIR" | cut -f1)

echo "📦 Размер бандла: $BUNDLE_SIZE"

# Проверка максимального размера (100MB)
MAX_SIZE_BYTES=104857600  # 100MB в байтах

if [ "$BUNDLE_SIZE_BYTES" -lt "$MAX_SIZE_BYTES" ]; then
    echo "✅ Размер бандла в пределах нормы (< 100MB)"
else
    SIZE_MB=$((BUNDLE_SIZE_BYTES / 1024 / 1024))
    MAX_SIZE_MB=$((MAX_SIZE_BYTES / 1024 / 1024))
    echo "⚠️  Размер бандла превышает рекомендуемый лимит ($MAX_SIZE_MB MB)"
    echo "   Текущий размер: ${SIZE_MB}MB"
    
    # Показать самые большие файлы
    echo ""
    echo "📁 10 крупнейших файлов в бандле:"
    find "$BUILD_DIR" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 10
fi

echo "Проверка размера бандла завершена"