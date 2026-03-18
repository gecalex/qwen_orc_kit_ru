#!/bin/bash
# Скрипт: .qwen/scripts/specification-tools/assign-agents-to-tasks.sh
# Назначение: Автоматическое определение и пометка нужных агентов в задачах из tasks.md

SPEC_DIR=$1
TASKS_FILE="$SPEC_DIR/tasks.md"

if [ -z "$SPEC_DIR" ]; then
    echo "Использование: $0 <путь-к-директории-спецификации>"
    echo "Пример: $0 specs/001-user-auth"
    exit 1
fi

if [ ! -f "$TASKS_FILE" ]; then
    echo "Файл задач не найден: $TASKS_FILE"
    exit 1
fi

echo "Анализ задач в: $TASKS_FILE"

# Создаем резервную копию файла задач
cp "$TASKS_FILE" "$TASKS_FILE.backup"
echo "Создана резервная копия: $TASKS_FILE.backup"

# Временный файл для обновленных задач
TEMP_TASKS_FILE=$(mktemp)

# Читаем файл задач и добавляем метки агентов
while IFS= read -r line; do
    # Проверяем, является ли строка задачей (содержит квадратные скобки)
    if [[ $line =~ ^[[:space:]]*-[[:space:]]*\[.*\][[:space:]]*T[0-9]+ ]]; then
        # Проверяем, есть ли уже метка агента
        if [[ $line =~ \[agent: ]]; then
            # Уже есть метка агента, просто копируем строку
            echo "$line" >> "$TEMP_TASKS_FILE"
        elif [[ $line =~ \[futures: ]]; then
            # Уже есть метка futures, просто копируем строку
            echo "$line" >> "$TEMP_TASKS_FILE"
        else
            # Нужно определить подходящий агент
            task_desc=$(echo "$line" | sed 's/.*] //')

            # Определяем агента на основе описания задачи
            agent=""
            if [[ $task_desc =~ (тест|test|unit|integration|contract) ]]; then
                agent="code-quality-checker"
            elif [[ $task_desc =~ (безопасн|security|auth|authent|authoriz) ]]; then
                agent="security-orchestrator"
            elif [[ $task_desc =~ (ошибк|bug|дефект|исправ) ]]; then
                agent="bug-fixer"
            elif [[ $task_desc =~ (анализ|поиск|найди|найти|ошибка|уязвим) ]]; then
                agent="bug-hunter"
            elif [[ $task_desc =~ (перевод|translate|документация|документ|comment|комментар) ]]; then
                agent="tech-translator-ru"
            elif [[ $task_desc =~ (спецификац|specifi|plan|архитект|архитектур) ]]; then
                agent="specification-analyst"
            else
                # Если не можем определить конкретного агента, помечаем как futures
                # Извлекаем ключевые слова для названия потенциального агента
                if [[ $task_desc =~ ([Cc]reate|[Cc]reating)[[:space:]]+([^.,[:space:]]+) ]]; then
                    # Извлекаем тип создаваемого объекта
                    obj_type=$(echo "${BASH_REMATCH[2]}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9]//g' | cut -d' ' -f1)
                    agent="futures:${obj_type}-handler"
                else
                    # Общий случай - помечаем как общий обработчик
                    agent="futures:general-handler"
                fi
            fi

            # Добавляем метку агента к задаче
            if [[ $agent =~ ^futures: ]]; then
                # Для futures добавляем метку futures
                updated_line=$(echo "$line" | sed "s/\(.*T[0-9]*[[:space:]]*\)\(.*\)/\1[${agent}] \2/")
            else
                # Для существующих агентов добавляем метку agent
                updated_line=$(echo "$line" | sed "s/\(.*T[0-9]*[[:space:]]*\)\(.*\)/\1[agent:${agent}] \2/")
            fi

            echo "$updated_line" >> "$TEMP_TASKS_FILE"
        fi
    else
        # Не задача, просто копируем строку
        echo "$line" >> "$TEMP_TASKS_FILE"
    fi
done < "$TASKS_FILE"

# Заменяем оригинальный файл задач обновленным
mv "$TEMP_TASKS_FILE" "$TASKS_FILE"

echo "Обновление задач завершено: $TASKS_FILE"
echo "Назначенные агенты и метки futures добавлены к задачам"
echo "Резервная копия сохранена как: $TASKS_FILE.backup"

# Подсчет добавленных меток
agent_count=$(grep -c "\[agent:" "$TASKS_FILE")
futures_count=$(grep -c "\[futures:" "$TASKS_FILE")

echo ""
echo "Статистика:"
echo "- Задач с назначенными агентами: $agent_count"
echo "- Задач с метками futures: $futures_count"
