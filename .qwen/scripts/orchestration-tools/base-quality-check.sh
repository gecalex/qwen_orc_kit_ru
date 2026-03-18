#!/bin/bash

# Скрипт базовой проверки качества
# Проверяет основные аспекты качества кода и архитектуры

set -e  # Прервать при ошибке

echo "=== Базовая проверка качества ==="

# Проверка наличия основных файлов документации
if [ ! -f "README.md" ]; then
    echo "⚠️  Отсутствует README.md"
else
    echo "✅ README.md найден"
fi

# Проверка наличия файлов спецификаций
if [ -d "specs/" ]; then
    echo "✅ Директория specs/ найдена"
    spec_count=$(find specs/ -name "*.md" | wc -l)
    echo "   Найдено спецификаций: $spec_count"
else
    echo "⚠️  Директория specs/ не найдена"
fi

# Проверка наличия файлов тестов
if [ -d "tests/" ]; then
    echo "✅ Директория tests/ найдена"
    test_count=$(find tests/ -name "*.md" -o -name "*.sh" -o -name "*.py" -o -name "*.js" | wc -l)
    echo "   Найдено тестов: $test_count"
else
    echo "⚠️  Директория tests/ не найдена"
fi

# Проверка наличия файлов агентов
if [ -d ".qwen/agents/" ]; then
    echo "✅ Директория .qwen/agents/ найдена"
else
    echo "⚠️  Директория .qwen/agents/ не найдена"
fi

# Проверка наличия файлов команд
if [ -d ".qwen/commands/" ]; then
    echo "✅ Директория .qwen/commands/ найдена"
else
    echo "⚠️  Директория .qwen/commands/ не найдена"
fi

# Проверка наличия файлов навыков
if [ -d ".qwen/skills/" ]; then
    echo "✅ Директория .qwen/skills/ найдена"
else
    echo "⚠️  Директория .qwen/skills/ не найдена"
fi

echo ""
echo "=== Проверка завершена ==="