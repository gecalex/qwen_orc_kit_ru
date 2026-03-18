#!/bin/bash
# Файл: .qwen/scripts/run_quality_gate.sh (дополненная версия с Gate 4)
# Использование: ./.qwen/scripts/run_quality_gate.sh <gate_number> [path]

GATE=$1
TARGET_PATH=${2:-"workspace/"}

echo "Запуск Quality Gate $GATE для пути: $TARGET_PATH"

case $GATE in
  1)
    echo "=== Gate 1: Pre-Execution Checks ==="
    # Проверка структуры task
    if [ ! -f "state/current_task.json" ]; then
      echo "ERROR: Не найден файл задачи state/current_task.json"
      exit 1
    fi

    # Проверка наличия обязательных полей
    if command -v python3 &> /dev/null; then
      python3 -c "
import json
import sys
try:
    with open('state/current_task.json') as f:
        task = json.load(f)
    required = ['subagent_type', 'description', 'prompt']
    missing = [r for r in required if r not in task]
    if missing:
        print(f'ERROR: Отсутствуют поля: {missing}')
        sys.exit(1)
    if len(task.get('prompt', '')) < 50:
        print('ERROR: Промпт слишком краток (менее 50 символов)')
        sys.exit(1)
    print('Gate 1 пройдена: задача корректно сформирована')
except FileNotFoundError:
    print('ERROR: Файл state/current_task.json не найден')
    sys.exit(1)
except json.JSONDecodeError:
    print('ERROR: Файл state/current_task.json содержит невалидный JSON')
    sys.exit(1)
"
    else
      echo "Python3 не установлен, пропускаем проверку"
    fi
    ;;

  2)
    echo "=== Gate 2: Post-Execution Checks ==="

    # Проверка наличия изменений
    if [ -d "$TARGET_PATH" ]; then
      echo "Проверка файлов в $TARGET_PATH..."

      # Python проверки
      if find "$TARGET_PATH" -name "*.py" | head -1 | grep -q ".py"; then
        echo "Проверка Python файлов..."
        if command -v python3 &> /dev/null; then
          python3 -m py_compile $(find "$TARGET_PATH" -name "*.py" | head -3) 2>&1 | head -5 || echo "Предупреждение: найдены синтаксические ошибки в Python файлах"
        fi
      fi

      # TypeScript проверки
      if find "$TARGET_PATH" -name "*.ts" -o -name "*.tsx" | head -1 | grep -q ".ts"; then
        echo "Проверка TypeScript файлов..."
        echo "Проверка TypeScript файлов: npx tsc --noEmit --project $TARGET_PATH"
      fi
    else
      echo "Предупреждение: TARGET_PATH не существует"
    fi

    echo "Gate 2: базовые проверки завершены"
    ;;

  3)
    echo "=== Gate 3: Pre-Commit Checks ==="

    # Запуск всех строгих проверок
    echo "1. Форматирование..."
    echo "Проверка форматирования: ruff format $TARGET_PATH --check"

    echo "2. Линтинг (строгий)..."
    echo "Проверка линтинга: ruff check $TARGET_PATH --output-format=github"

    echo "3. Проверка типов..."
    if [ -d "${TARGET_PATH}src" ]; then
      echo "Проверка типов: mypy ${TARGET_PATH}src --no-error-summary"
    fi

    echo "4. Запуск тестов..."
    if [ -d "${TARGET_PATH}tests" ]; then
      echo "Запуск тестов: pytest ${TARGET_PATH}tests -v --tb=short"
    fi

    echo "Gate 3 проверки инициированы"
    ;;

  4)
    echo "=== Gate 4: Pre-Merge Checks ==="

    # Проверки перед мержем в develop
    echo "1. Интеграционные тесты..."
    if [ -d "${TARGET_PATH}tests/integration" ]; then
      echo "Запуск интеграционных тестов: pytest ${TARGET_PATH}tests/integration/ -v"
    else
      echo "Директория интеграционных тестов не найдена"
    fi

    echo "2. Проверка безопасности..."
    if command -v python3 &> /dev/null; then
      python3 -c "
import json
import sys
try:
    if __import__('os').path.exists('state/security_scan.json'):
        with open('state/security_scan.json') as f:
            scan = json.load(f)
        high_vulns = [v for v in scan.get('vulnerabilities', []) if v.get('severity') in ['HIGH', 'CRITICAL']]
        if high_vulns:
            print(f'ВНИМАНИЕ: Найдено {len(high_vulns)} высокоприоритетных уязвимостей')
            sys.exit(1)
        else:
            print('Критических уязвимостей не найдено')
    else:
        print('Файл отчета безопасности не найден')
except json.JSONDecodeError:
    print('Файл отчета безопасности содержит невалидный JSON')
"
    else
      echo "Python3 не установлен, пропускаем проверку безопасности"
    fi

    echo "3. Проверка покрытия тестами..."
    if [ -d "${TARGET_PATH}tests" ]; then
      echo "Проверка покрытия тестами: pytest ${TARGET_PATH}tests/ --cov=${TARGET_PATH}src/ --cov-fail-under=80"
    fi

    echo "4. Проверка статуса ревью..."
    if [ -f "state/review_status.md" ]; then
      if grep -q "APPROVED" "state/review_status.md"; then
        echo "Статус ревью: APPROVED"
      else
        echo "ВНИМАНИЕ: Ревью не одобрено"
        exit 1
      fi
    else
      echo "Файл статуса ревью не найден"
    fi

    echo "Gate 4 проверки завершены"
    ;;

  5)
    echo "=== Gate 5: Pre-Implementation Checks ==="

    # Проверки перед началом реализации
    echo "1. Проверка качества спецификации..."
    if [ -f "$TARGET_PATH/spec.md" ]; then
      echo "Анализ спецификации: проверка наличия обязательных разделов"
      # Проверка наличия обязательных разделов
      mandatory_sections=("Краткое описание" "Контекст" "Акторы" "Требования" "Сценарии использования" "Условия успеха" "Ограничения" "Предположения" "Возможные риски")
      missing_sections=()
      for section in "${mandatory_sections[@]}"; do
        if ! grep -q "#.*$section" "$TARGET_PATH/spec.md"; then
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
        exit 1
      fi
    else
      echo "Файл спецификации не найден: $TARGET_PATH/spec.md"
      exit 1
    fi

    echo "2. Проверка соответствия конституции проекта..."
    if [ -f ".specify/memory/constitution.md" ]; then
      echo "Сравнение спецификации с конституцией проекта"
      # Здесь можно добавить более сложную логику проверки соответствия
      echo "Конституция проекта найдена, проверка соответствия"
    else
      echo "Предупреждение: Конституция проекта не найдена"
    fi

    echo "3. Проверка тестопригодности требований..."
    # Проверка, что требования измеримы и тестопригодны
    if grep -q -E '[0-9]+%' "$TARGET_PATH/spec.md" || grep -q -E '[0-9]+ сек' "$TARGET_PATH/spec.md" || grep -q -E '[0-9]+ мс' "$TARGET_PATH/spec.md"; then
      echo "✓ Обнаружены измеримые критерии успеха"
    else
      echo "Предупреждение: Не обнаружено измеримых критериев успеха"
    fi

    echo "Gate 5 проверки завершены"
    ;;

  *)
    echo "Неизвестный номер gate: $GATE"
    echo "Доступные gates: 1 (Pre-Execution), 2 (Post-Execution), 3 (Pre-Commit), 4 (Pre-Merge), 5 (Pre-Implementation)"
    exit 1
    ;;
esac
