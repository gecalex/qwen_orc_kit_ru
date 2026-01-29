#!/bin/bash
# Пользовательская контрольная точка качества: Покрытие кода
# Назначение: Обеспечение того, что покрытие тестами соответствует минимальному порогу
# Блокирующая: false (только предупреждение)

set -e

echo "🔍 Выполнение проверки покрытия кода..."

# Настраиваемый порог (по умолчанию 80%)
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-80}

# Проверить существует ли отчёт о покрытии
COVERAGE_FILE="coverage/coverage-summary.json"
if [ ! -f "$COVERAGE_FILE" ]; then
  echo "⚠️  Предупреждение: Отчёт о покрытии не найден"
  echo "   Сначала выполните 'npm run test:coverage'"
  exit 0
fi

# Извлечь проценты покрытия
LINES=$(cat "$COVERAGE_FILE" | grep -o '"lines":{"total":[0-9]*,"covered":[0-9]*' | grep -o '[0-9]*' | paste - - | awk '{if($1>0) print int($2*100/$1); else print 0}')
BRANCHES=$(cat "$COVERAGE_FILE" | grep -o '"branches":{"total":[0-9]*,"covered":[0-9]*' | grep -o '[0-9]*' | paste - - | awk '{if($1>0) print int($2*100/$1); else print 0}')
FUNCTIONS=$(cat "$COVERAGE_FILE" | grep -o '"functions":{"total":[0-9]*,"covered":[0-9]*' | grep -o '[0-9]*' | paste - - | awk '{if($1>0) print int($2*100/$1); else print 0}')
STATEMENTS=$(cat "$COVERAGE_FILE" | grep -o '"statements":{"total":[0-9]*,"covered":[0-9]*' | grep -o '[0-9]*' | paste - - | awk '{if($1>0) print int($2*100/$1); else print 0}')

echo "   Отчёт о покрытии:"
echo "   - Строки: $LINES%"
echo "   - Ветки: $BRANCHES%"
echo "   - Функции: $FUNCTIONS%"
echo "   - Выражения: $STATEMENTS%"
echo "   Порог: $COVERAGE_THRESHOLD%"
echo ""

# Проверить, есть ли метрика ниже порога
FAILED=0
if [ "$LINES" -lt "$COVERAGE_THRESHOLD" ]; then
  echo "⚠️  Покрытие строк ($LINES%) ниже порога ($COVERAGE_THRESHOLD%)"
  FAILED=1
fi
if [ "$BRANCHES" -lt "$COVERAGE_THRESHOLD" ]; then
  echo "⚠️  Покрытие веток ($BRANCHES%) ниже порога ($COVERAGE_THRESHOLD%)"
  FAILED=1
fi
if [ "$FUNCTIONS" -lt "$COVERAGE_THRESHOLD" ]; then
  echo "⚠️  Покрытие функций ($FUNCTIONS%) ниже порога ($COVERAGE_THRESHOLD%)"
  FAILED=1
fi
if [ "$STATEMENTS" -lt "$COVERAGE_THRESHOLD" ]; then
  echo "⚠️  Покрытие выражений ($STATEMENTS%) ниже порога ($COVERAGE_THRESHOLD%)"
  FAILED=1
fi

if [ "$FAILED" -eq 1 ]; then
  echo ""
  echo "Рекомендации:"
  echo "   - Добавить больше тестов для непокрытого кода"
  echo "   - Сосредоточиться на крайних случаях и путях ошибок"
  echo "   - Просмотреть отчёт о покрытии: open coverage/lcov-report/index.html"
  echo ""
  exit 1
fi

echo "✅ Покрытие кода пройдено"
echo "   Все метрики выше $COVERAGE_THRESHOLD%"
echo ""
exit 0
