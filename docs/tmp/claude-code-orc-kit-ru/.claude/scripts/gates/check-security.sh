#!/bin/bash
# Пользовательская контрольная точка качества: Аудит безопасности
# Назначение: Проверка наличия высоких/критических уязвимостей в зависимостях
# Блокирующая: true (необходимо исправить перед объединением)

set -e

echo "🔍 Выполнение аудита безопасности..."

# Проверить существует ли package.json
if [ ! -f "package.json" ]; then
  echo "⚠️  Предупреждение: package.json не найден"
  echo "   Пропуск аудита безопасности"
  exit 0
fi

# Запустить npm audit для высоких/критических уязвимостей
echo "   Проверка наличия высоких/критических уязвимостей..."
echo ""

if npm audit --audit-level=high --json > /tmp/audit-results.json 2>&1; then
  VULN_COUNT=$(cat /tmp/audit-results.json | grep -o '"total":[0-9]*' | head -1 | grep -o '[0-9]*' || echo "0")

  echo "✅ Аудит безопасности пройден"
  echo "   Высокие/критические уязвимости не найдены"
  echo ""
  rm -f /tmp/audit-results.json
  exit 0
else
  # Разбор результатов
  VULN_COUNT=$(cat /tmp/audit-results.json | grep -o '"total":[0-9]*' | head -1 | grep -o '[0-9]*' || echo "unknown")

  echo "⛔ Аудит безопасности НЕ ПРОЙДЕН"
  echo "   Найдено $VULN_COUNT высоких/критических уязвимостей"
  echo ""
  echo "Детали:"
  npm audit --audit-level=high
  echo ""
  echo "Для исправления:"
  echo "   - Запустить: npm audit fix"
  echo "   - Или вручную обновить затронутые пакеты"
  echo "   - Перезапустить аудит безопасности после исправлений"
  echo ""
  rm -f /tmp/audit-results.json
  exit 1
fi
