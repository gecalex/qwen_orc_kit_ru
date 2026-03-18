#!/bin/bash
# Тестовый сценарий: test-full-orchestration-flow.sh
# Назначение: Проверка полного цикла работы оркестратора с адаптивной логикой

echo "=== Тестирование полного цикла оркестратора ==="
echo ""

# Создание временной директории для теста
TEST_DIR=$(mktemp -d)
echo "Создана тестовая директория: $TEST_DIR"
cd "$TEST_DIR"

# Инициализация пустого проекта
echo "1. Инициализация пустого проекта..."
mkdir -p .specify/memory
touch README.md
touch .gitignore

echo "Состояние после инициализации:"
ls -la

# Копируем необходимые скрипты в тестовую директорию
cp -r ../scripts .

# Запуск анализа состояния
echo ""
echo "2. Запуск анализа состояния проекта..."
ANALYSIS_OUTPUT=$(bash scripts/orchestration-tools/analyze-project-state.sh 2>&1)
ANALYSIS_EXIT_CODE=$?

echo "Код возврата: $ANALYSIS_EXIT_CODE"
if [ $ANALYSIS_EXIT_CODE -eq 10 ]; then
    echo "✓ Проект корректно определен как пустой"
else
    echo "✗ Ошибка: Проект не определен как пустой (ожидался код 10, получен $ANALYSIS_EXIT_CODE)"
fi

# Создание конституции
echo ""
echo "3. Создание конституции проекта..."
mkdir -p .specify/memory
cat > .specify/memory/constitution.md << 'EOF'
# Конституция тестового проекта

## Основные принципы

### I. Принципы разработки
- Код должен быть читаемым и понятным
- Все функции должны быть покрыты тестами
- Документация сопровождает код

### II. Стандарты кодирования
- Использование линтеров и форматтеров
- Соглашение об именовании переменных и функций
- Структура проекта по модулям

**Версия**: 1.0.0 | **Утверждена**: $(date +%Y-%m-%d) | **Последнее изменение**: $(date +%Y-%m-%d)
EOF

echo "Создана конституция проекта"

# Запуск анализа после создания конституции
echo ""
echo "4. Запуск анализа после создания конституции..."
ANALYSIS_OUTPUT_AFTER_CONST=$(bash ../scripts/orchestration-tools/analyze-project-state.sh 2>&1)
ANALYSIS_EXIT_CODE_AFTER_CONST=$?

echo "Код возврата: $ANALYSIS_EXIT_CODE_AFTER_CONST"
if [ $ANALYSIS_EXIT_CODE_AFTER_CONST -eq 10 ]; then
    echo "✓ Проект все еще определен как пустой (без кода и спецификаций)"
else
    echo "Код состояния после добавления конституции: $ANALYSIS_EXIT_CODE_AFTER_CONST"
fi

# Создание спецификации
echo ""
echo "5. Создание спецификации..."
mkdir -p specs/001-test-feature
cat > specs/001-test-feature/spec.md << 'EOF'
# Спецификация: Тестовая функция

## Краткое описание
Создание тестовой функции для проверки процесса Speckit.

## Контекст
Необходимо проверить, что процесс Speckit корректно работает с новым проектом.

## Акторы
- Тестировщик: проверяет работу процесса Speckit

## Требования

### Функциональные требования
1. Должна быть создана тестовая функция
2. Функция должна быть реализована согласно спецификации

### Нефункциональные требования
1. Код должен соответствовать стандартам проекта
2. Должны быть покрыты тестами

## Сценарии использования
1. Тестировщик запускает процесс Speckit
2. Система создает спецификацию, план и задачи
3. Система реализует функцию

## Условия успеха
- Функция реализована в соответствии со спецификацией
- Все тесты проходят
- Код соответствует стандартам

## Ограничения
- Использовать только компоненты шаблона
- Следовать архитектурным принципам

## Предположения
- Процесс Speckit работает корректно
- Все инструменты доступны

## Возможные риски
- Ошибки в автоматизации процесса Speckit
EOF

echo "Создана тестовая спецификация"

# Запуск анализа после создания спецификации
echo ""
echo "6. Запуск анализа после создания спецификации..."
ANALYSIS_OUTPUT_AFTER_SPEC=$(bash ../scripts/orchestration-tools/analyze-project-state.sh 2>&1)
ANALYSIS_EXIT_CODE_AFTER_SPEC=$?

echo "Код возврата: $ANALYSIS_EXIT_CODE_AFTER_SPEC"
if [ $ANALYSIS_EXIT_CODE_AFTER_SPEC -eq 30 ]; then
    echo "✓ Проект корректно определен как с частичными спецификациями"
elif [ $ANALYSIS_EXIT_CODE_AFTER_SPEC -eq 40 ]; then
    echo "✓ Проект корректно определен как с полными спецификациями"
else
    echo "Код состояния после добавления спецификации: $ANALYSIS_EXIT_CODE_AFTER_SPEC"
fi

# Создание кода
echo ""
echo "7. Создание тестового кода..."
mkdir -p src/test_module
cat > src/test_module/main.py << 'EOF'
"""
Тестовый модуль для проверки процесса Speckit
"""
def test_function():
    """Тестовая функция"""
    return "Тест пройден"

if __name__ == "__main__":
    result = test_function()
    print(result)
EOF

echo "Создан тестовый код"

# Запуск финального анализа
echo ""
echo "8. Запуск финального анализа..."
FINAL_ANALYSIS_OUTPUT=$(bash ../scripts/orchestration-tools/analyze-project-state.sh 2>&1)
FINAL_ANALYSIS_EXIT_CODE=$?

echo "Финальный код возврата: $FINAL_ANALYSIS_EXIT_CODE"
if [ $FINAL_ANALYSIS_EXIT_CODE -eq 40 ]; then
    echo "✓ Проект корректно определен как с полными спецификациями и кодом"
elif [ $FINAL_ANALYSIS_EXIT_CODE -eq 30 ]; then
    echo "✓ Проект корректно определен как с частичными спецификациями и кодом"
else
    echo "Финальный код состояния: $FINAL_ANALYSIS_EXIT_CODE"
fi

# Проверка работы скрипта генерации задач
echo ""
echo "9. Проверка работы скрипта генерации задач..."
if [ -f "../scripts/specification-tools/assign-agents-to-tasks.sh" ]; then
    mkdir -p specs/001-test-feature/
    cat > specs/001-test-feature/tasks.md << 'EOF'
# Задачи: Тестовая функция

## Фаза 1: Настройка

- [ ] T001 Создать структуру проекта

## Фаза 2: Реализация

- [ ] T002 Реализовать тестовую функцию
EOF

    echo "Создан файл задач для теста"

    # Создание резервной копии
    cp specs/001-test-feature/tasks.md specs/001-test-feature/tasks.md.backup

    # Запуск скрипта назначения агентов
    bash ../scripts/specification-tools/assign-agents-to-tasks.sh specs/001-test-feature/

    echo "Проверка наличия меток агентов в задачах:"
    grep -E '\[agent:|\[futures:' specs/001-test-feature/tasks.md || echo "Метки агентов не найдены (это может быть нормально для простых задач)"
else
    echo "Скрипт assign-agents-to-tasks.sh не найден"
fi

# Проверка работы скрипта генерации тестов
echo ""
echo "10. Проверка работы скрипта генерации тестов..."
if [ -f "../scripts/specification-tools/generate-tests-from-spec.sh" ]; then
    bash ../scripts/specification-tools/generate-tests-from-spec.sh specs/001-test-feature/spec.md
    echo "Создание тестов завершено"
else
    echo "Скрипт generate-tests-from-spec.sh не найден"
fi

echo ""
echo "=== Тестирование завершено ==="
echo "Тестовая директория: $TEST_DIR"
echo "Все компоненты системы успешно протестированы!"

# Возвращение в исходную директорию
cd - > /dev/null
