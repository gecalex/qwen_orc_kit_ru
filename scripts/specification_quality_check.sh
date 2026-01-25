#!/bin/bash
# Скрипт для проверки качества спецификаций

echo "Запуск проверки качества спецификаций..."

SPEC_FILE=$1

if [ -z "$SPEC_FILE" ]; then
  echo "Ошибка: Не указан файл спецификации для проверки"
  echo "Использование: $0 <путь-к-файлу-спецификации>"
  exit 1
fi

if [ ! -f "$SPEC_FILE" ]; then
  echo "Ошибка: Файл спецификации не найден: $SPEC_FILE"
  exit 1
fi

echo "Проверка файла: $SPEC_FILE"

# Проверка наличия обязательных разделов
required_sections=("## Краткое описание" "## Контекст" "## Акторы" "## Требования" "## Сценарии использования" "## Условия успеха" "## Ограничения" "## Предположения" "## Возможные риски")

missing_sections=()
for section in "${required_sections[@]}"; do
  if ! grep -q "^${section}$" "$SPEC_FILE"; then
    missing_sections+=("$section")
  fi
done

if [ ${#missing_sections[@]} -eq 0 ]; then
  echo "✓ Все обязательные разделы присутствуют"
else
  echo "✗ Отсутствуют следующие обязательные разделы:"
  for section in "${missing_sections[@]}"; do
    echo "  - $section"
  done
fi

# Проверка наличия функциональных и нефункциональных требований
has_functional_reqs=$(grep -c "^### Функциональные требования" "$SPEC_FILE")
has_nonfunctional_reqs=$(grep -c "^### Нефункциональные требования" "$SPEC_FILE")

if [ $has_functional_reqs -gt 0 ]; then
  echo "✓ Раздел 'Функциональные требования' найден"
else
  echo "✗ Раздел 'Функциональные требования' отсутствует"
fi

if [ $has_nonfunctional_reqs -gt 0 ]; then
  echo "✓ Раздел 'Нефункциональные требования' найден"
else
  echo "✗ Раздел 'Нефункциональные требования' отсутствует"
fi

# Проверка наличия хотя бы одного функционального требования
functional_items=$(grep -c "^[[:space:]]*[0-9]\+\.\+" "$SPEC_FILE" | head -1)
if [ $functional_items -gt 0 ]; then
  echo "✓ Обнаружены функциональные требования"
else
  echo "⚠ Не обнаружено функциональных требований"
fi

# Подсчет общего числа требований
total_requirements=$(grep -c "^[[:space:]]*[0-9]\+\.\+" "$SPEC_FILE")
echo "Количество требований: $total_requirements"

# Проверка измеримости условий успеха
success_criteria=$(grep -c -i "^[[:space:]]*-[[:space:]]*\|^[[:space:]]*[0-9]\+\.\+[[:space:]]*[0-9.]\+%\|^[[:space:]]*[0-9]\+\.\+[[:space:]]*[0-9]\+\s\+\(сек\|мин\|час\)\|^[[:space:]]*[0-9]\+\.\+[[:space:]]*[0-9]\+\s*MB\|^[[:space:]]*[0-9]\+\.\+[[:space:]]*[0-9]\+\s*%" "$SPEC_FILE")

if [ $success_criteria -gt 0 ]; then
  echo "✓ Обнаружены измеримые условия успеха: $success_criteria"
else
  echo "⚠ Не обнаружено измеримых условий успеха"
fi

# Проверка длины спецификации
line_count=$(wc -l < "$SPEC_FILE")
if [ $line_count -gt 50 ]; then
  echo "✓ Спецификация достаточной длины: $line_count строк"
else
  echo "⚠ Спецификация может быть недостаточно подробной: $line_count строк"
fi

echo ""
echo "Проверка качества спецификации завершена."
