#!/bin/bash

# Скрипт автоматического исправления стандартов для агентов Qwen Code CLI

PROJECT_ROOT="/home/alex/MyProjects/qwen_orc_kit_ru"
AGENTS_DIR="$PROJECT_ROOT/.qwen/agents"
SKILLS_DIR="$PROJECT_ROOT/.qwen/skills"
LOG_FILE="$PROJECT_ROOT/logs/standard-fix-log-$(date +%Y%m%d_%H%M%S).txt"

# Создаем директорию для логов
mkdir -p "$PROJECT_ROOT/logs"

# Функция для логирования
log_fix() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_fix "=== Запуск автоматического исправления стандартов ==="

# Функция для исправления формата tools в YAML заголовке
fix_tools_format() {
    local file="$1"
    local temp_file=$(mktemp)
    
    # Проверяем, есть ли неправильный формат
    if grep -A 50 "^---$" "$file" | grep -q "tools: \["; then
        log_fix "Исправление формата поля tools в файле: $(basename "$file")"
        
        # Сохраняем начало файла до tools
        sed '/^---$/,/^---$/{ /^---$/!b; }; p; d' "$file" > "$temp_file.begin"
        
        # Находим и исправляем секцию tools
        awk '
        BEGIN { in_yaml = 0; in_tools = 0; tools_started = 0; }
        /^---$/ { 
            if (!in_yaml) { in_yaml = 1; print; next; } 
            else { in_yaml = 0; print; next; } 
        }
        in_yaml && /^[[:space:]]*tools:/ { 
            in_tools = 1; 
            tools_started = 1;
            gsub(/^[[:space:]]*/, ""); 
            print "tools:"; 
            next; 
        }
        in_yaml && in_tools && /\[$/ { 
            # Пропускаем строку с [
            next; 
        }
        in_yaml && in_tools && /^\]/ { 
            # Пропускаем строку с ]
            in_tools = 0;
            next;
        }
        in_yaml && in_tools && /^[[:space:]]*-[[:space:]]*"[^"]*"/ { 
            # Обработка строк вида - "tool_name"
            gsub(/^[[:space:]]*-/, " -");
            gsub(/"/, "");
            print;
            next;
        }
        in_yaml && in_tools && /^[[:space:]]*-[[:space:]]*'[^']*'/ { 
            # Обработка строк вида - 'tool_name'
            gsub(/^[[:space:]]*-/, " -");
            gsub(/'/, "");
            print;
            next;
        }
        in_yaml && in_tools && /^[[:space:]]*-[[:space:]]*[a-zA-Z_]/ { 
            # Обработка строк вида - tool_name
            gsub(/^[[:space:]]*-/, " -");
            print;
            next;
        }
        # Если мы вышли из YAML секции, сбрасываем флаги
        /^[[:space:]]*[^-#[:space:]]/ && in_yaml && !in_tools { in_yaml = 0; }
        # Печатаем все остальные строки
        !in_tools || !in_yaml { print; }
        ' "$file" > "$temp_file.fixed"
        
        # Если tools не были исправлены (потому что формат был другим), просто копируем оригинал
        if [ ! -s "$temp_file.fixed" ]; then
            cp "$file" "$temp_file.fixed"
        fi
        
        # Собираем файл обратно
        cat "$temp_file.begin" "$temp_file.fixed" > "$file.tmp"
        
        # Добавляем остальную часть файла после YAML заголовка
        sed '1,/^---$/d' "$file" >> "$file.tmp"
        
        mv "$file.tmp" "$file"
        
        log_fix "  Формат поля tools исправлен в $(basename "$file")"
    fi
}

# Обработка всех агентов
log_fix "Обработка агентов..."
for agent_file in "$AGENTS_DIR"/*.md; do
    if [ -f "$agent_file" ]; then
        log_fix "Обработка агента: $(basename "$agent_file")"
        fix_tools_format "$agent_file"
    fi
done

# Обработка всех навыков
log_fix "Обработка навыков..."
for skill_dir in "$SKILLS_DIR"/*/; do
    if [ -d "$skill_dir" ]; then
        skill_file="$skill_dir/SKILL.md"
        if [ -f "$skill_file" ]; then
            log_fix "Обработка навыка: $(basename "$skill_dir")"
            fix_tools_format "$skill_file"
        fi
    fi
done

log_fix ""
log_fix "=== Автоматическое исправление стандартов завершено ==="
log_fix "Логи сохранены в: $LOG_FILE"

echo ""
echo "Скрипт автоматического исправления стандартов завершен."
echo "Проверьте логи в файле: $LOG_FILE"