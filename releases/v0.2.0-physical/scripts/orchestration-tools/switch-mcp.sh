#!/bin/bash

# Скрипт переключения MCP-конфигураций
# Позволяет динамически переключаться между различными MCP-конфигурациями

set -e  # Прервать при ошибке

CONFIG_DIR="."
DEFAULT_CONFIG=".mcp.base.json"
CURRENT_CONFIG_FILE=".mcp.current"

echo "=== Скрипт переключения MCP-конфигураций ==="

# Проверить, существует ли файл текущей конфигурации
if [ -f "$CURRENT_CONFIG_FILE" ]; then
    CURRENT_CONFIG=$(cat "$CURRENT_CONFIG_FILE")
else
    CURRENT_CONFIG="$DEFAULT_CONFIG"
    echo "$CURRENT_CONFIG" > "$CURRENT_CONFIG_FILE"
fi

echo "Текущая конфигурация: $CURRENT_CONFIG"

# Показать меню выбора конфигурации
echo ""
echo "Доступные конфигурации:"
echo "1) BASE - минимальная конфигурация (~600 токенов)"
echo "2) DATABASE - для работы с базой данных (~2500 токенов)"
echo "3) FRONTEND - для UI/UX разработки (~2000 токенов)"
echo "4) FULL - все серверы (~5000 токенов)"
echo "0) ВЫХОД"
echo ""
read -p "Выберите номер конфигурации (0-4): " choice

case $choice in
    1)
        TARGET_CONFIG=".mcp.base.json"
        ;;
    2)
        TARGET_CONFIG=".mcp.database.json"
        ;;
    3)
        TARGET_CONFIG=".mcp.frontend.json"
        ;;
    4)
        TARGET_CONFIG=".mcp.full.json"
        ;;
    0)
        echo "Выход без изменений."
        exit 0
        ;;
    *)
        echo "Неверный выбор. Выход."
        exit 1
        ;;
esac

# Проверить существование выбранного файла конфигурации
if [ ! -f "$CONFIG_DIR/$TARGET_CONFIG" ]; then
    echo "Файл конфигурации $TARGET_CONFIG не найден!"
    echo "Создаю шаблон конфигурации..."
    
    case $TARGET_CONFIG in
        ".mcp.base.json")
            cat > "$CONFIG_DIR/$TARGET_CONFIG" << 'EOL'
{
  "mcpServers": {
    "context7": {
      "enabled": true,
      "description": "Documentation for libraries"
    },
    "server-sequential-thinking": {
      "enabled": true,
      "description": "Enhanced reasoning"
    }
  }
}
EOL
            ;;
        ".mcp.database.json")
            cat > "$CONFIG_DIR/$TARGET_CONFIG" << 'EOL'
{
  "mcpServers": {
    "context7": {
      "enabled": true,
      "description": "Documentation for libraries"
    },
    "server-sequential-thinking": {
      "enabled": true,
      "description": "Enhanced reasoning"
    },
    "supabase": {
      "enabled": true,
      "description": "Supabase integration"
    }
  }
}
EOL
            ;;
        ".mcp.frontend.json")
            cat > "$CONFIG_DIR/$TARGET_CONFIG" << 'EOL'
{
  "mcpServers": {
    "context7": {
      "enabled": true,
      "description": "Documentation for libraries"
    },
    "server-sequential-thinking": {
      "enabled": true,
      "description": "Enhanced reasoning"
    },
    "playwright": {
      "enabled": true,
      "description": "Browser automation"
    },
    "shadcn": {
      "enabled": true,
      "description": "UI components"
    }
  }
}
EOL
            ;;
        ".mcp.full.json")
            cat > "$CONFIG_DIR/$TARGET_CONFIG" << 'EOL'
{
  "mcpServers": {
    "context7": {
      "enabled": true,
      "description": "Documentation for libraries"
    },
    "server-sequential-thinking": {
      "enabled": true,
      "description": "Enhanced reasoning"
    },
    "supabase": {
      "enabled": true,
      "description": "Supabase integration"
    },
    "playwright": {
      "enabled": true,
      "description": "Browser automation"
    },
    "shadcn": {
      "enabled": true,
      "description": "UI components"
    },
    "n8n-workflows": {
      "enabled": true,
      "description": "Workflow automation"
    },
    "n8n-mcp": {
      "enabled": true,
      "description": "MCP server for n8n"
    }
  }
}
EOL
            ;;
    esac
    
    echo "Шаблон конфигурации создан: $TARGET_CONFIG"
fi

# Скопировать выбранную конфигурацию в основной файл
if [ "$CURRENT_CONFIG" != "$TARGET_CONFIG" ]; then
    echo "Переключаюсь с $CURRENT_CONFIG на $TARGET_CONFIG..."
    cp "$CONFIG_DIR/$TARGET_CONFIG" "$CONFIG_DIR/.mcp.json"
    echo "$TARGET_CONFIG" > "$CURRENT_CONFIG_FILE"
    echo "Конфигурация успешно изменена!"
    
    # Показать информацию о новой конфигурации
    echo ""
    echo "=== Информация о новой конфигурации ==="
    echo "Файл: $TARGET_CONFIG"
    echo "Серверы:"
    grep -o '"[^"]*": {' "$CONFIG_DIR/$TARGET_CONFIG" | grep -v "mcpServers" | sed 's/^[[:space:]]*"\([^"]*\)": {/\1/' | while read server; do
        enabled=$(grep -A 5 "$server" "$CONFIG_DIR/$TARGET_CONFIG" | grep "enabled" | cut -d':' -f2 | tr -d ' ,')
        if [ "$enabled" = "true" ]; then
            desc=$(grep -A 5 "$server" "$CONFIG_DIR/$TARGET_CONFIG" | grep "description" | cut -d':' -f2 | tr -d ' ",')
            echo "  - $server: $desc"
        fi
    done
else
    echo "Конфигурация не изменилась (уже установлена $TARGET_CONFIG)."
fi

echo ""
echo "Для применения изменений перезапустите Qwen Code CLI."
echo "=== Переключение конфигурации завершено ==="