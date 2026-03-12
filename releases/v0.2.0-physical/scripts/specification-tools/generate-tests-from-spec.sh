#!/bin/bash
# Скрипт: scripts/specification-tools/generate-tests-from-spec.sh
# Назначение: Генерация тестов на основе требований из спецификаций для поддержки TDD

SPEC_FILE=$1

if [ -z "$SPEC_FILE" ]; then
    echo "Использование: $0 <путь-к-файлу-спецификации>"
    echo "Пример: $0 specs/001-user-auth/spec.md"
    exit 1
fi

if [ ! -f "$SPEC_FILE" ]; then
    echo "Файл спецификации не найден: $SPEC_FILE"
    exit 1
fi

SPEC_DIR=$(dirname "$SPEC_FILE")
SPEC_NAME=$(basename "$SPEC_DIR")
TESTS_DIR="$SPEC_DIR/tests"

echo "Генерация тестов для спецификации: $SPEC_NAME"
echo "Файл спецификации: $SPEC_FILE"

# Создаем директорию для тестов, если не существует
mkdir -p "$TESTS_DIR"

# Извлекаем функциональные требования из спецификации
FUNCTIONAL_REQUIREMENTS=$(mktemp)
grep -A 20 "### Функциональные требования" "$SPEC_FILE" | grep -E "^[[:space:]]*[0-9]+\." | head -20 > "$FUNCTIONAL_REQUIREMENTS"

# Извлекаем сценарии использования
USER_SCENARIOS=$(mktemp)
grep -A 30 "## Сценарии использования" "$SPEC_FILE" | grep -E "^[[:space:]]*-" | head -20 > "$USER_SCENARIOS"

# Создаем файл модульных тестов
UNIT_TESTS_FILE="$TESTS_DIR/unit_tests.md"
echo "# Модульные тесты для $SPEC_NAME" > "$UNIT_TESTS_FILE"
echo "" >> "$UNIT_TESTS_FILE"
echo "## Требования к тестированию" >> "$UNIT_TESTS_FILE"
echo "" >> "$UNIT_TESTS_FILE"

if [ -s "$FUNCTIONAL_REQUIREMENTS" ]; then
    echo "### Тесты на основе функциональных требований:" >> "$UNIT_TESTS_FILE"
    while IFS= read -r req; do
        if [ -n "$req" ]; then
            req_clean=$(echo "$req" | sed 's/^[[:space:]]*[0-9]*\. //')
            echo "- [ ] Тест для требования: \"$req_clean\"" >> "$UNIT_TESTS_FILE"
        fi
    done < "$FUNCTIONAL_REQUIREMENTS"
    echo "" >> "$UNIT_TESTS_FILE"
fi

# Создаем файл интеграционных тестов
INTEGRATION_TESTS_FILE="$TESTS_DIR/integration_tests.md"
echo "# Интеграционные тесты для $SPEC_NAME" > "$INTEGRATION_TESTS_FILE"
echo "" >> "$INTEGRATION_TESTS_FILE"
echo "## Тесты на основе сценариев использования:" >> "$INTEGRATION_TESTS_FILE"
echo "" >> "$INTEGRATION_TESTS_FILE"

if [ -s "$USER_SCENARIOS" ]; then
    counter=1
    while IFS= read -r scenario; do
        if [ -n "$scenario" ]; then
            scenario_clean=$(echo "$scenario" | sed 's/^[[:space:]]*- //')
            echo "- [ ] Интеграционный тест для сценария: \"$scenario_clean\"" >> "$INTEGRATION_TESTS_FILE"
            ((counter++))
        fi
    done < "$USER_SCENARIOS"
    echo "" >> "$INTEGRATION_TESTS_FILE"
fi

# Создаем файл контрактных тестов
CONTRACT_TESTS_FILE="$TESTS_DIR/contract_tests.md"
echo "# Контрактные тесты для $SPEC_NAME" > "$CONTRACT_TESTS_FILE"
echo "" >> "$CONTRACT_TESTS_FILE"
echo "## Тесты на основе API контрактов:" >> "$CONTRACT_TESTS_FILE"
echo "" >> "$CONTRACT_TESTS_FILE"
echo "# Эти тесты должны быть созданы на основе контрактов из $SPEC_DIR/contracts/" >> "$CONTRACT_TESTS_FILE"
echo "- [ ] Тест для каждого endpoint из контрактов" >> "$CONTRACT_TESTS_FILE"
echo "- [ ] Тесты для входных параметров" >> "$CONTRACT_TESTS_FILE"
echo "- [ ] Тесты для выходных данных" >> "$CONTRACT_TESTS_FILE"
echo "- [ ] Тесты для ошибочных сценариев" >> "$CONTRACT_TESTS_FILE"
echo "" >> "$CONTRACT_TESTS_FILE"

# Создаем сводный файл тест-плана
TEST_PLAN_FILE="$TESTS_DIR/test_plan.md"
echo "# Тест-план для $SPEC_NAME" > "$TEST_PLAN_FILE"
echo "" >> "$TEST_PLAN_FILE"
echo "## Обзор" >> "$TEST_PLAN_FILE"
echo "Этот файл содержит план тестирования для спецификации $SPEC_NAME." >> "$TEST_PLAN_FILE"
echo "Все тесты должны быть написаны до реализации функциональности (TDD)." >> "$TEST_PLAN_FILE"
echo "" >> "$TEST_PLAN_FILE"
echo "## Типы тестов" >> "$TEST_PLAN_FILE"
echo "- Модульные тесты: $UNIT_TESTS_FILE" >> "$TEST_PLAN_FILE"
echo "- Интеграционные тесты: $INTEGRATION_TESTS_FILE" >> "$TEST_PLAN_FILE"
echo "- Контрактные тесты: $CONTRACT_TESTS_FILE" >> "$TEST_PLAN_FILE"
echo "" >> "$TEST_PLAN_FILE"
echo "## Статус выполнения" >> "$TEST_PLAN_FILE"
echo "- [ ] Модульные тесты созданы" >> "$TEST_PLAN_FILE"
echo "- [ ] Интеграционные тесты созданы" >> "$TEST_PLAN_FILE"
echo "- [ ] Контрактные тесты созданы" >> "$TEST_PLAN_FILE"
echo "- [ ] Все тесты проходят (до реализации - должны падать)" >> "$TEST_PLAN_FILE"
echo "" >> "$TEST_PLAN_FILE"
echo "## Критерии завершения" >> "$TEST_PLAN_FILE"
echo "1. Все тесты написаны в соответствии с требованиями спецификации" >> "$TEST_PLAN_FILE"
echo "2. Все тесты НЕ проходят до реализации функциональности (TDD принцип)" >> "$TEST_PLAN_FILE"
echo "3. Все тесты проходят после реализации функциональности" >> "$TEST_PLAN_FILE"

# Удаляем временные файлы
rm "$FUNCTIONAL_REQUIREMENTS" "$USER_SCENARIOS"

echo ""
echo "Генерация тестов завершена!"
echo "Созданные файлы:"
echo "- $UNIT_TESTS_FILE (модульные тесты)"
echo "- $INTEGRATION_TESTS_FILE (интеграционные тесты)"
echo "- $CONTRACT_TESTS_FILE (контрактные тесты)"
echo "- $TEST_PLAN_FILE (тест-план)"

echo ""
echo "Следующие шаги:"
echo "1. Проверьте сгенерированные тесты на соответствие спецификации"
echo "2. Уточните и дополните тесты при необходимости"
echo "3. Реализуйте тесты до начала разработки функциональности (TDD)"
echo "4. Убедитесь, что тесты падают до реализации (красный цвет в TDD цикле)"
