#!/bin/bash

# Скрипт для обновления формата поля tools в агентах

AGENTS_DIR="/home/alex/MyProjects/qwen_orc_kit_ru/.qwen/agents"

# Массив агентов, которые нужно обновить
agents=(
    "orc_security_security_orchestrator.md"
    "orc_testing_quality_assurer.md"
    "work_backend_api_validator.md"
    "work_dev_code_analyzer.md"
    "work_frontend_component_generator.md"
    "work_meta_agent_creator.md"
    "work_planning_agent_requirer.md"
    "work_planning_executor_assigner.md"
    "work_planning_task_classifier.md"
    "work_research_trend_tracker.md"
    "work_testing_test_generator.md"
)

for agent in "${agents[@]}"; do
    echo "Обработка $agent..."
    
    # Прочитываем текущий заголовок
    tempfile=$(mktemp)
    
    # Извлекаем YAML заголовок
    sed -n '2,/^---$/p' "$AGENTS_DIR/$agent" > "$tempfile.header"
    
    # Извлекаем описание и цвет
    name=$(grep "^name:" "$tempfile.header" | head -1)
    description=$(grep "^description:" "$tempfile.header" | head -1)
    color=$(grep "^color:" "$tempfile.header" | head -1)
    
    # Создаем новый заголовок
    cat > "$tempfile.newheader" << EOF
---
$name
$description
tools:
 - read_file
 - write_file
 - edit
 - glob
 - grep_search
 - todo_write
 - skill
 - run_shell_command
$color
---
EOF
    
    # Создаем новый файл
    cat "$tempfile.newheader" > "$AGENTS_DIR/${agent}.new"
    
    # Добавляем остальную часть файла
    sed '1,/^---$/d' "$AGENTS_DIR/$agent" >> "$AGENTS_DIR/${agent}.new"
    
    # Заменяем старый файл
    mv "$AGENTS_DIR/${agent}.new" "$AGENTS_DIR/$agent"
    
    rm "$tempfile.header" "$tempfile.newheader" "$tempfile"
    
    echo "Готово: $agent"
done

echo "Все агенты обновлены!"