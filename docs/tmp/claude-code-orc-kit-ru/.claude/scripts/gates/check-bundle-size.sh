#!/bin/bash
# Пользовательская контрольная точка качества: Проверка размера бандла
# Назначение: Обеспечение того, что продакшен бандл остаётся в пределах размерных ограничений
# Блокирующая: false (только предупреждение)

set -e

echo "🔍 Выполнение проверки размера бандла..."

# Настраиваемый порог (по умолчанию 500KB)
BUNDLE_SIZE_LIMIT=${BUNDLE_SIZE_LIMIT:-512000}  # 500KB в байтах

# Найти файл бандла
BUNDLE_FILE="dist/bundle.js"
if [ ! -f "$BUNDLE_FILE" ]; then
  echo "⚠️  Предупреждение: Файл бандла не найден в $BUNDLE_FILE"
  echo "   Сначала выполните 'npm run build'"
  exit 0  # Не блокирующий, просто предупреждение
fi

# Получить фактический размер
ACTUAL_SIZE=$(wc -c < "$BUNDLE_FILE")
ACTUAL_SIZE_KB=$((ACTUAL_SIZE / 1024))
LIMIT_KB=$((BUNDLE_SIZE_LIMIT / 1024))

echo "   Бандл: $BUNDLE_FILE"
echo "   Размер: $ACTUAL_SIZE_KB KB"
echo "   Лимит: $LIMIT_KB KB"

if [ "$ACTUAL_SIZE" -gt "$BUNDLE_SIZE_LIMIT" ]; then
  echo ""
  echo "⛔ РАЗМЕР БАНДЛА ПРЕВЫШАЕТ лимит!"
  echo "   Фактический: $ACTUAL_SIZE_KB KB"
  echo "   Лимит: $LIMIT_KB KB"
  echo "   Превышение на: $((ACTUAL_SIZE_KB - LIMIT_KB)) KB"
  echo ""
  echo "Рекомендации:"
  echo "   - Проанализировать бандл с помощью: npm run analyze"
  echo "   - Удалить неиспользуемые зависимости"
  echo "   - Использовать разделение кода"
  echo "   - Включить tree shaking"
  exit 1
fi

echo "✅ Размер бандла OK: $ACTUAL_SIZE_KB KB (лимит: $LIMIT_KB KB)"
echo ""
exit 0
