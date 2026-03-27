#!/bin/bash

# =============================================================================
# auto-report.sh - Автоматическое создание отчёта о баге
# =============================================================================
# Назначение: Автоматическое создание отчёта о баге после обнаружения
# 
# Функционал:
#   - Парсинг результатов тестов
#   - Расчет приоритета (через calculate-bug-priority)
#   - Создание отчёта в универсальном формате
#   - Обновление bug-registry.json
#
# ВАЖНО: БЕЗ HARDCODE! Универсально для любого проекта.
#
# Использование:
#   .qwen/scripts/bug-tracking/auto-report.sh [test_output_file]
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Инициализация
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../config.sh"

# Входные данные
TEST_OUTPUT="${1:-/tmp/pytest-output.txt}"

# -----------------------------------------------------------------------------
# Функции
# -----------------------------------------------------------------------------

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[OK]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка наличия файла с результатами
check_test_output() {
  if [ ! -f "$TEST_OUTPUT" ]; then
    log_error "Файл с результатами тестов не найден: $TEST_OUTPUT"
    exit 1
  fi
  log_success "Файл с результатами найден"
}

# Парсинг результатов
parse_test_results() {
  log_info "Парсинг результатов тестов..."
  
  FAILED=$(grep -c "FAILED" "$TEST_OUTPUT" || echo "0")
  ERRORS=$(grep -c "ERROR" "$TEST_OUTPUT" || echo "0")
  WARNINGS=$(grep -c "warnings summary" "$TEST_OUTPUT" || echo "0")
  
  # Извлечь детали failed тестов
  FAILED_TESTS=$(grep "FAILED\|ERROR" "$TEST_OUTPUT" | head -20)
  
  log_success "Результаты: Failed=$FAILED, Errors=$ERRORS, Warnings=$WARNINGS"
}

# Автоматическое определение severity
auto_detect_severity() {
  if [ "$ERRORS" -gt 0 ]; then
    echo "critical"
  elif [ "$FAILED" -gt 10 ]; then
    echo "high"
  elif [ "$FAILED" -gt 0 ]; then
    echo "medium"
  else
    echo "low"
  fi
}

# Автоматическое определение impact
auto_detect_impact() {
  # Подсчитать общее количество тестов
  local total=$(grep -c "passed\|failed\|ERROR" "$TEST_OUTPUT" || echo "1")
  local ratio=$((FAILED * 100 / total))
  
  if [ "$ratio" -ge 75 ]; then
    echo "all"
  elif [ "$ratio" -ge 50 ]; then
    echo "many"
  elif [ "$ratio" -ge 25 ]; then
    echo "some"
  else
    echo "few"
  fi
}

# Автоматическое определение probability
auto_detect_probability() {
  # Для автотестов всегда "always"
  echo "always"
}

# Расчет приоритета
calculate_priority() {
  log_info "Расчет приоритета бага..."
  
  local severity=$(auto_detect_severity)
  local impact=$(auto_detect_impact)
  local probability=$(auto_detect_probability)
  
  # Использовать skill calculate-bug-priority
  if [ -f "$SCRIPT_DIR/../../skills/calculate-bug-priority/SKILL.md" ]; then
    # Bash реализация
    case "$severity" in
      critical) severity_score=10 ;;
      high) severity_score=7 ;;
      medium) severity_score=4 ;;
      low) severity_score=1 ;;
      *) severity_score=4 ;;
    esac
    
    case "$impact" in
      all) impact_score=10 ;;
      many) impact_score=7 ;;
      some) impact_score=4 ;;
      few) impact_score=1 ;;
      *) impact_score=4 ;;
    esac
    
    case "$probability" in
      always) probability_score=10 ;;
      often) probability_score=7 ;;
      sometimes) probability_score=4 ;;
      rarely) probability_score=1 ;;
      *) probability_score=4 ;;
    esac
    
    total_score=$((severity_score + impact_score + probability_score))
    
    if [ "$total_score" -ge 25 ]; then
      PRIORITY="P0"
      PRIORITY_LABEL="Critical"
    elif [ "$total_score" -ge 18 ]; then
      PRIORITY="P1"
      PRIORITY_LABEL="High"
    elif [ "$total_score" -ge 10 ]; then
      PRIORITY="P2"
      PRIORITY_LABEL="Medium"
    else
      PRIORITY="P3"
      PRIORITY_LABEL="Low"
    fi
    
    log_success "Приоритет: $PRIORITY ($PRIORITY_LABEL, Score=$total_score)"
  else
    log_warning "calculate-bug-priority skill не найден, используем упрощенный расчет"
    
    if [ "$ERRORS" -gt 0 ]; then
      PRIORITY="P0"
      PRIORITY_LABEL="Critical"
    elif [ "$FAILED" -gt 10 ]; then
      PRIORITY="P1"
      PRIORITY_LABEL="High"
    elif [ "$FAILED" -gt 0 ]; then
      PRIORITY="P2"
      PRIORITY_LABEL="Medium"
    else
      PRIORITY="P3"
      PRIORITY_LABEL="Low"
    fi
  fi
}

# Создание отчёта
create_bug_report() {
  log_info "Создание отчёта о баге..."
  
  BUG_ID="${PRIORITY}-$(date +%Y%m%d-%H%M%S)"
  BUG_FILE="$BUGS_DIR/${BUG_ID}.md"
  
  cat > "$BUG_FILE" << EOF
---
bug_id: $BUG_ID
priority: $PRIORITY
priority_label: $PRIORITY_LABEL
status: open
created: $(date -Iseconds)
project: ${PROJECT_NAME:-unknown}
project_type: ${PROJECT_TYPE:-unknown}
source: auto-detection
---

# Bug Report: $BUG_ID

## Description
Автоматически обнаружен в тестах

## Test Results
- Failed: $FAILED
- Errors: $ERRORS
- Warnings: $WARNINGS

## Failed Tests
$FAILED_TESTS

## Priority Calculation
- Priority: $PRIORITY ($PRIORITY_LABEL)
- Severity: $(auto_detect_severity)
- Impact: $(auto_detect_impact)
- Probability: $(auto_detect_probability)

## Recommended Action
Запустить bug-hunter для анализа

## Metadata
- Test Output: $TEST_OUTPUT
- Bug File: $BUG_FILE
EOF

  log_success "Отчёт создан: $BUG_FILE"
}

# Обновление реестра
update_registry() {
  log_info "Обновление bug-registry.json..."
  
  if [ ! -f "$BUG_REGISTRY" ]; then
    echo '{"bugs": []}' > "$BUG_REGISTRY"
  fi
  
  # Создать временный файл
  local temp_file="${BUG_REGISTRY}.tmp"
  
  # Обновить реестр
  jq --arg id "$BUG_ID" \
     --arg priority "$PRIORITY" \
     --arg label "$PRIORITY_LABEL" \
     --arg created "$(date -Iseconds)" \
     '.bugs += [{"bug_id": $id, "priority": $priority, "priority_label": $label, "status": "open", "created": $created}]' \
     "$BUG_REGISTRY" > "$temp_file"
  
  mv "$temp_file" "$BUG_REGISTRY"
  
  log_success "bug-registry.json обновлён"
}

# Отправка в ШАБЛОН
send_to_template() {
  log_info "Отправка отчёта в ШАБЛОН..."
  
  if [ -f "$BUG_TRACKING_SCRIPTS/send-to-template.sh" ]; then
    "$BUG_TRACKING_SCRIPTS/send-to-template.sh" "$BUG_FILE"
    log_success "Отчёт отправлен в ШАБЛОН"
  else
    log_warning "send-to-template.sh не найден, отчёт сохранён локально"
  fi
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Автоматическое создание отчёта о баге${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Проверки
  check_test_output
  
  # Парсинг
  parse_test_results
  
  # Расчет приоритета
  calculate_priority
  
  # Создание отчёта
  create_bug_report
  
  # Обновление реестра
  update_registry
  
  # Отправка в ШАБЛОН
  send_to_template
  
  echo ""
  echo -e "${GREEN}✅ Отчёт о баге создан${NC}"
  echo ""
  echo "Bug ID: $BUG_ID"
  echo "Priority: $PRIORITY ($PRIORITY_LABEL)"
  echo "File: $BUG_FILE"
  echo "Registry: $BUG_REGISTRY"
}

# Запуск
main "$@"
