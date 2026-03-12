#!/bin/bash

# Скрипт обработки вебхуков
# Обрабатывает события и отправляет уведомления через вебхуки

set -e  # Прервать при ошибке

EVENT_TYPE="${1:-unknown}"  # Тип события (start, stop, error и т.д.)
CONFIG_FILE="${2:-.qwen/settings.local.json}"

LOG_FILE="logs/webhook_events.log"

# Создать директорию для логов, если не существует
mkdir -p "$(dirname "$LOG_FILE")"

# Функция для отправки вебхука
send_webhook() {
    local url="$1"
    local method="$2"
    local headers="$3"
    local payload="$4"
    local description="$5"
    
    echo "$(date): Отправка вебхука '$description' на $url" >> "$LOG_FILE"
    
    # Формируем заголовки для curl
    local curl_headers=""
    if [ -n "$headers" ]; then
        while IFS= read -r header; do
            curl_headers="$curl_headers -H $header"
        done < <(echo "$headers" | jq -r 'to_entries[] | "\(.key):\(.value)"')
    fi
    
    # Отправляем запрос
    local response
    response=$(eval "curl -s -o /tmp/webhook_response.txt -w '%{http_code}' $curl_headers -X $method -d '$payload' -H 'Content-Type: application/json' '$url'")
    
    local status_code="$response"
    
    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
        echo "$(date): Вебхук '$description' успешно отправлен (код: $status_code)" >> "$LOG_FILE"
        return 0
    else
        echo "$(date): Ошибка отправки вебхука '$description' (код: $status_code)" >> "$LOG_FILE"
        cat /tmp/webhook_response.txt >> "$LOG_FILE"
        return 1
    fi
}

# Функция для выполнения команды
execute_command() {
    local command="$1"
    local description="$2"
    
    echo "$(date): Выполнение команды '$description': $command" >> "$LOG_FILE"
    
    if eval "$command"; then
        echo "$(date): Команда '$description' успешно выполнена" >> "$LOG_FILE"
        return 0
    else
        echo "$(date): Ошибка выполнения команды '$description'" >> "$LOG_FILE"
        return 1
    fi
}

# Проверить существование файла конфигурации
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Файл конфигурации $CONFIG_FILE не найден"
    echo "Создаю шаблон конфигурации..."
    
    # Создать директорию для конфигурации, если не существует
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Создать шаблон конфигурации
    cat > "$CONFIG_FILE.example" << 'EOL'
{
  "hooks": {
    "Stop": [
      {
        "type": "command",
        "command": "notify-send 'Qwen Code CLI' 'Task completed!'",
        "description": "Desktop notification on task completion (Linux)"
        }
    ],
    "Start": [],
    "Error": []
  },
  "settings": {
    "timeout": 10000,
    "retry_attempts": 3,
    "retry_delay_ms": 1000
  }
}
EOL
    
    echo "Шаблон конфигурации создан: $CONFIG_FILE.example"
    exit 1
fi

# Загрузить конфигурацию
HOOKS=$(jq -r ".hooks[\"$EVENT_TYPE\"][]" "$CONFIG_FILE" 2>/dev/null)

if [ "$HOOKS" = "" ] || [ "$HOOKS" = "null" ]; then
    echo "$(date): Нет вебхуков для события $EVENT_TYPE" >> "$LOG_FILE"
    exit 0
fi

# Обработать каждый вебхук для данного типа события
echo "$(date): Обработка события $EVENT_TYPE" >> "$LOG_FILE"

while IFS= read -r hook; do
    if [ "$hook" = "" ] || [ "$hook" = "null" ]; then
        continue
    fi
    
    hook_type=$(echo "$hook" | jq -r '.type')
    description=$(echo "$hook" | jq -r '.description // "Unknown hook"')
    
    case "$hook_type" in
        "webhook")
            url=$(echo "$hook" | jq -r '.url')
            method=$(echo "$hook" | jq -r '.method // "POST"')
            headers=$(echo "$hook" | jq -r '{} | . += if (.headers | type == "object") then .headers else {} end')
            payload=$(echo "$hook" | jq -r '.payload | @json')
            
            if [ "$url" != "null" ] && [ "$url" != "" ]; then
                send_webhook "$url" "$method" "$headers" "$payload" "$description"
            else
                echo "$(date): URL вебхука не указан для '$description'" >> "$LOG_FILE"
            fi
            ;;
        "command")
            command=$(echo "$hook" | jq -r '.command')
            if [ "$command" != "null" ] && [ "$command" != "" ]; then
                execute_command "$command" "$description"
            else
                echo "$(date): Команда не указана для '$description'" >> "$LOG_FILE"
            fi
            ;;
        *)
            echo "$(date): Неизвестный тип вебхука '$hook_type' для '$description'" >> "$LOG_FILE"
            ;;
    esac
done < <(echo "$HOOKS")

echo "$(date): Завершена обработка события $EVENT_TYPE" >> "$LOG_FILE"
echo "Обработка вебхуков для события $EVENT_TYPE завершена"