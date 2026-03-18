#!/bin/bash

# Скрипт для создания физического релизного варианта проекта Qwen Orchestrator Kit
# Копирует только файлы, которые должны быть в релизе, исключая файлы разработки

set -e  # Прерывать выполнение при ошибке

# Проверка аргументов
if [ $# -ne 1 ]; then
    echo "Использование: $0 <путь-к-релизной-директории>"
    exit 1
fi

RELEASE_DIR="$1"
SOURCE_DIR="$(pwd)"

echo "Создание физического релизного варианта в: $RELEASE_DIR"

# Создание целевой директории
mkdir -p "$RELEASE_DIR"

# Копирование файлов, разрешенных в релизе
echo "Копирование файлов в релизную директорию..."

# Основные файлы проекта
cp -f "$SOURCE_DIR/QWEN.md" "$RELEASE_DIR/" 2>/dev/null || true
cp -f "$SOURCE_DIR/README.md" "$RELEASE_DIR/" 2>/dev/null || true
cp -f "$SOURCE_DIR/LICENSE" "$RELEASE_DIR/" 2>/dev/null || true
cp -f "$SOURCE_DIR/INSTALLATION.md" "$RELEASE_DIR/" 2>/dev/null || true
cp -f "$SOURCE_DIR/QUICKSTART.md" "$RELEASE_DIR/" 2>/dev/null || true
cp -f "$SOURCE_DIR/USAGE_INSTRUCTIONS.md" "$RELEASE_DIR/" 2>/dev/null || true
cp -f "$SOURCE_DIR/CONTRIBUTING.md" "$RELEASE_DIR/" 2>/dev/null || true
cp -f "$SOURCE_DIR/CHANGELOG.md" "$RELEASE_DIR/" 2>/dev/null || true
cp -f "$SOURCE_DIR/RELEASE_NOTES.md" "$RELEASE_DIR/" 2>/dev/null || true

# MCP конфигурации
for mcp_config in "$SOURCE_DIR"/.mcp.*.json; do
    if [ -f "$mcp_config" ]; then
        cp -f "$mcp_config" "$RELEASE_DIR/"
    fi
done
cp -f "$SOURCE_DIR/.mcp.json" "$RELEASE_DIR/" 2>/dev/null || true

# Директория .qwen (без временных файлов)
mkdir -p "$RELEASE_DIR/.qwen"
mkdir -p "$RELEASE_DIR/.qwen/agents"
mkdir -p "$RELEASE_DIR/.qwen/skills"
mkdir -p "$RELEASE_DIR/.qwen/templates"
mkdir -p "$RELEASE_DIR/.qwen/commands"
mkdir -p "$RELEASE_DIR/.qwen/skill-templates"

# Копирование агентов
for agent in "$SOURCE_DIR"/.qwen/agents/*.md; do
    if [ -f "$agent" ]; then
        cp -f "$agent" "$RELEASE_DIR/.qwen/agents/"
    fi
done

# Копирование навыков (только основные файлы, без временных)
for skill_dir in "$SOURCE_DIR"/.qwen/skills/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        mkdir -p "$RELEASE_DIR/.qwen/skills/$skill_name"
        # Копируем только основные файлы навыков
        cp -f "$skill_dir"*.md "$RELEASE_DIR/.qwen/skills/$skill_name/" 2>/dev/null || true
        cp -f "$skill_dir"*.json "$RELEASE_DIR/.qwen/skills/$skill_name/" 2>/dev/null || true
    fi
done

# Копирование шаблонов
for template in "$SOURCE_DIR"/.qwen/templates/*.md; do
    if [ -f "$template" ]; then
        cp -f "$template" "$RELEASE_DIR/.qwen/templates/"
    fi
done

# Копирование команд (включая все speckit команды, но исключая разработческие файлы вне speckit)
for command_file in "$SOURCE_DIR"/.qwen/commands/*.md; do
    if [ -f "$command_file" ]; then
        cmd_basename=$(basename "$command_file")
        # Копируем все speckit команды (они являются основными компонентами)
        if [[ "$cmd_basename" =~ ^speckit\. ]]; then
            cp -f "$command_file" "$RELEASE_DIR/.qwen/commands/"
        # А также копируем другие команды, если они не являются разработческими
        elif [[ ! "$cmd_basename" =~ ^(.+-create|.+-(cleanup|remove|list|init|setup|analyze|check|validate|audit|scan|fix|hunt|detect|orchestrate)\.) ]]; then
            cp -f "$command_file" "$RELEASE_DIR/.qwen/commands/"
        fi
    fi
done

# Копирование архитектурной документации (исключая разработческие документы)
mkdir -p "$RELEASE_DIR/docs"
mkdir -p "$RELEASE_DIR/docs/architecture"
for doc in "$SOURCE_DIR"/docs/architecture/*.md; do
    if [ -f "$doc" ]; then
        doc_basename=$(basename "$doc")
        # Исключаем разработческие документы
        if [[ ! "$doc_basename" =~ ^(GIT_WORKFLOW\.md|planning-phase\.md|worktree-guidelines\.md|specification-driven-development\.md|agent-creation-process\.md|quality-gates\.md)$ ]]; then
            cp -f "$doc" "$RELEASE_DIR/docs/architecture/"
        fi
    fi
done

# Копирование скриптов
mkdir -p "$RELEASE_DIR/scripts"
for script_dir in "$SOURCE_DIR"/.qwen/scripts/*/; do
    if [ -d "$script_dir" ]; then
        script_name=$(basename "$script_dir")
        # Исключаем разработческие директории, но включаем .specify (критически важно для speckit)
        if [[ ! "$script_name" =~ ^(tmp|\.tmp|planning-tools|analysis-tools|quality-gates|validation|agent-creation|monitoring|orchestration-tools)$ ]]; then
            cp -r "$script_dir" "$RELEASE_DIR/.qwen/scripts/"
        fi
    fi
done

# Копирование директории .specify (критически важно для speckit)
if [ -d "$SOURCE_DIR/.specify/" ]; then
    cp -r "$SOURCE_DIR/.specify/" "$RELEASE_DIR/.specify/"
fi

# Копирование примеров (без спецификаций)
mkdir -p "$RELEASE_DIR/examples"
for example_item in "$SOURCE_DIR"/examples/*; do
    if [ -d "$example_item" ]; then
        example_name=$(basename "$example_item")
        if [ "$example_name" != "specs" ]; then
            cp -r "$example_item" "$RELEASE_DIR/examples/"
        fi
    elif [ -f "$example_item" ]; then
        cp -f "$example_item" "$RELEASE_DIR/examples/"
    fi
done

# Копирование файлов конфигурации
cp -f "$SOURCE_DIR"/release-config.toml "$RELEASE_DIR/" 2>/dev/null || true

# Копирование основного .gitignore (без правил для разработки)
cp -f "$SOURCE_DIR/.gitignore" "$RELEASE_DIR/" 2>/dev/null || true

echo "Физический релизный вариант создан в: $RELEASE_DIR"

# Подсчет файлов в релизной директории
total_files=$(find "$RELEASE_DIR" -type f | wc -l)
echo "Всего файлов в релизной директории: $total_files"

echo "Готово!"