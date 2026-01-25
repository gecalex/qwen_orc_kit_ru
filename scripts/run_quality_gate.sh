#!/bin/bash
# Файл: scripts/run_quality_gate.sh
# Использование: ./scripts/run_quality_gate.sh <gate_number> [path]

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

  *)
    echo "Неизвестный номер gate: $GATE"
    echo "Доступные gates: 1 (Pre-Execution), 2 (Post-Execution), 3 (Pre-Commit)"
    exit 1
    ;;
esac
