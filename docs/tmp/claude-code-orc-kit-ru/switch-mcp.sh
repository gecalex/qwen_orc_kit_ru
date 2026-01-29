#!/bin/bash
# ===================================================================
# Переключатель конфигурации MCP
# ===================================================================
# Переключение между различными конфигурациями MCP-серверов
# Все конфигурации хранятся в директории ./mcp/

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Цветовые коды для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Директория конфигураций MCP
MCP_DIR="mcp"

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Переключатель конфигурации MCP${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Выберите конфигурацию MCP:"
echo ""
echo -e "${GREEN}1${NC} - BASE             (Context7 + Sequential Thinking)      ~600 токенов"
echo -e "${GREEN}2${NC} - SUPABASE         (Base + Supabase MegaCampusAI)        ~2500 токенов"
echo -e "${GREEN}3${NC} - SUPABASE + LEGACY (Base + Supabase + Legacy проект)   ~3000 токенов"
echo -e "${GREEN}4${NC} - N8N              (Base + n8n-workflows + n8n-mcp)      ~2500 токенов"
echo -e "${GREEN}5${NC} - FRONTEND         (Base + Playwright + ShadCN)          ~2000 токенов"
echo -e "${GREEN}6${NC} - SERENA           (Base + Serena LSP семантический поиск)   ~2500 токенов"
echo -e "${GREEN}7${NC} - FULL             (Все серверы включая Serena)        ~6500 токенов"
echo ""
echo -e "${YELLOW}0${NC} - СТАТУС           (Показать текущую конфигурацию)"
echo ""
read -p "Ваш выбор (0-7): " choice

case "$choice" in
  1)
    config="base"
    desc="BASE (Context7 + Sequential Thinking)"
    ;;
  2)
    config="supabase-only"
    desc="SUPABASE (только MegaCampusAI)"
    ;;
  3)
    config="supabase-full"
    desc="SUPABASE + LEGACY (Оба проекта)"
    ;;
  4)
    config="n8n"
    desc="N8N (Автоматизация рабочих процессов)"
    ;;
  5)
    config="frontend"
    desc="FRONTEND (Playwright + ShadCN)"
    ;;
  6)
    config="serena"
    desc="SERENA (Base + LSP семантический поиск)"
    ;;
  7)
    config="full"
    desc="FULL (Все серверы включая Serena)"
    ;;
  0)
    echo ""
    echo -e "${BLUE}Текущая конфигурация:${NC}"
    if [ -f .mcp.json ]; then
      servers=$(grep -oP '"[^"]+"\s*:\s*\{' .mcp.json | sed 's/"//g' | sed 's/://' | tr '\n' ', ' | sed 's/,$//')
      echo -e "  Активные серверы: ${GREEN}$servers${NC}"
    else
      echo -e "  ${RED}Файл .mcp.json не найден${NC}"
    fi
    echo ""
    echo "Доступные конфигурации:"
    [ -f "$MCP_DIR/.mcp.base.json" ] && echo -e "  ✓ $MCP_DIR/.mcp.base.json"
    [ -f "$MCP_DIR/.mcp.supabase-only.json" ] && echo -e "  ✓ $MCP_DIR/.mcp.supabase-only.json"
    [ -f "$MCP_DIR/.mcp.supabase-full.json" ] && echo -e "  ✓ $MCP_DIR/.mcp.supabase-full.json"
    [ -f "$MCP_DIR/.mcp.n8n.json" ] && echo -e "  ✓ $MCP_DIR/.mcp.n8n.json"
    [ -f "$MCP_DIR/.mcp.frontend.json" ] && echo -e "  ✓ $MCP_DIR/.mcp.frontend.json"
    [ -f "$MCP_DIR/.mcp.serena.json" ] && echo -e "  ✓ $MCP_DIR/.mcp.serena.json"
    [ -f "$MCP_DIR/.mcp.full.json" ] && echo -e "  ✓ $MCP_DIR/.mcp.full.json"
    exit 0
    ;;
  *)
    echo -e "${RED}Неверный выбор. Используйте числа 0-7.${NC}"
    exit 1
    ;;
esac

# Копирование конфигурации из директории mcp/ в корень
SOURCE_FILE="$MCP_DIR/.mcp.$config.json"
if [ -f "$SOURCE_FILE" ]; then
  cp "$SOURCE_FILE" .mcp.json
  echo ""
  echo -e "${GREEN}✅ Переключено на: $desc${NC}"
  echo -e "   Источник: ${BLUE}$SOURCE_FILE${NC}"
  echo ""
  echo -e "${YELLOW}⚠️  ВАЖНО: Перезапустите Claude Code для применения изменений!${NC}"
  echo ""
else
  echo -e "${RED}❌ Файл $SOURCE_FILE не найден${NC}"
  exit 1
fi
