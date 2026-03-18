#!/bin/bash
# Простой тест для проверки базовой функциональности системы

echo "Запуск тестов для Qwen Code Orchestrator Kit..."

# Тест 1: Проверка наличия агентов
echo "Тест 1: Проверка наличия базовых агентов..."
AGENTS_DIR=".qwen/agents"
EXPECTED_AGENTS=("bug-fixer.md" "bug-hunter.md" "code-quality-checker.md" "security-orchestrator.md" "tech-translator-ru.md")

MISSING_AGENTS=()
for agent in "${EXPECTED_AGENTS[@]}"; do
  if [ ! -f "$AGENTS_DIR/$agent" ]; then
    MISSING_AGENTS+=("$agent")
  fi
done

if [ ${#MISSING_AGENTS[@]} -eq 0 ]; then
  echo "✓ Все базовые агенты присутствуют"
else
  echo "✗ Отсутствуют агенты: ${MISSING_AGENTS[*]}"
  exit 1
fi

# Тест 2: Проверка скриптов контрольных точек
echo "Тест 2: Проверка скриптов контрольных точек качества..."
if [ -f "scripts/run_quality_gate.sh" ]; then
  echo "✓ Скрипт run_quality_gate.sh существует"
else
  echo "✗ Скрипт run_quality_gate.sh отсутствует"
  exit 1
fi

if [ -f "scripts/auto_quality_check.sh" ]; then
  echo "✓ Скрипт auto_quality_check.sh существует"
else
  echo "✗ Скрипт auto_quality_check.sh отсутствует"
  exit 1
fi

# Тест 3: Проверка шаблонов
echo "Тест 3: Проверка шаблонов..."
if [ -f ".specify/templates/spec-template.md" ]; then
  echo "✓ Шаблон спецификации существует"
else
  echo "✗ Шаблон спецификации отсутствует"
  exit 1
fi

# Тест 4: Проверка директорий
echo "Тест 4: Проверка наличия необходимых директорий..."
DIRECTORIES=("specs" "state" "scripts" ".qwen/agents" ".specify/templates")

MISSING_DIRS=()
for dir in "${DIRECTORIES[@]}"; do
  if [ ! -d "$dir" ]; then
    MISSING_DIRS+=("$dir")
  fi
done

if [ ${#MISSING_DIRS[@]} -eq 0 ]; then
  echo "✓ Все необходимые директории существуют"
else
  echo "✗ Отсутствуют директории: ${MISSING_DIRS[*]}"
  exit 1
fi

# Тест 5: Проверка документации
echo "Тест 5: Проверка наличия документации..."
DOCS=("README.md" "CONTRIBUTING.md" "INSTALLATION.md" "QUICKSTART.md")
MISSING_DOCS=()

for doc in "${DOCS[@]}"; do
  if [ ! -f "$doc" ]; then
    MISSING_DOCS+=("$doc")
  fi
done

if [ ${#MISSING_DOCS[@]} -eq 0 ]; then
  echo "✓ вся основная документация существует"
else
  echo "✗ Отсутствует документация: ${MISSING_DOCS[*]}"
  exit 1
fi

echo ""
echo "Все тесты пройдены успешно!"
echo "Система Qwen Code Orchestrator Kit готова к использованию."
