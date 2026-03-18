#!/bin/bash

# Основной скрипт запуска агента-специалиста по Qwen Orchestrator Kit

PROJECT_ROOT="/home/alex/MyProjects/qwen_orc_kit_ru"
LOG_DIR="$PROJECT_ROOT/logs"
MAIN_LOG="$LOG_DIR/qwen-cli-specialist-main-$(date +%Y%m%d_%H%M%S).log"

# Создаем директорию для логов
mkdir -p "$LOG_DIR"

# Функция для логирования
log_main() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$MAIN_LOG"
}

log_main "=== Запуск агента-специалиста по Qwen Orchestrator Kit ==="
log_main "Проект: $PROJECT_ROOT"
log_main ""

# Запускаем проверки соответствия стандартам
log_main "1. Запуск проверок соответствия стандартам..."
bash "$PROJECT_ROOT/.qwen/scripts/qwen-cli-specialist/run-checks.sh"
CHECKS_RESULT=$?
log_main "   Результат проверок: $([ $CHECKS_RESULT -eq 0 ] && echo 'УСПЕШНО' || echo 'ОШИБКИ')"
log_main ""

# Обновляем документацию
log_main "2. Обновление документации..."
bash "$PROJECT_ROOT/.qwen/scripts/qwen-cli-specialist/update-documentation.sh"
UPDATE_RESULT=$?
log_main "   Результат обновления: $([ $UPDATE_RESULT -eq 0 ] && echo 'УСПЕШНО' || echo 'ОШИБКИ')"
log_main ""

# Запускаем мониторинг
log_main "3. Запуск мониторинга соответствия стандартам..."
bash "$PROJECT_ROOT/.qwen/scripts/monitoring/standards-monitoring.sh"
MONITORING_RESULT=$?
log_main "   Результат мониторинга: $([ $MONITORING_RESULT -eq 0 ] && echo 'УСПЕШНО' || echo 'ОШИБКИ')"
log_main ""

# Подводим итоги
log_main "=== Итоги работы агента-специалиста ==="

ALL_RESULTS=($CHECKS_RESULT $UPDATE_RESULT $MONITORING_RESULT)
ERROR_COUNT=0
for result in "${ALL_RESULTS[@]}"; do
    if [ $result -ne 0 ]; then
        ((ERROR_COUNT++))
    fi
done

log_main "Выполнено проверок: ${#ALL_RESULTS[@]}"
log_main "Количество ошибок: $ERROR_COUNT"

if [ $ERROR_COUNT -eq 0 ]; then
    log_main ""
    log_main "🎉 Все проверки пройдены успешно!"
    log_main "Агент-специалист завершил работу с результатом: УСПЕШНО"
    exit 0
else
    log_main ""
    log_main "⚠️  Обнаружены ошибки в $ERROR_COUNT из ${#ALL_RESULTS[@]} проверок"
    log_main "Агент-специалист завершил работу с результатом: ОШИБКИ"
    exit 1
fi

log_main ""
log_main "Основной лог работы доступен в: $MAIN_LOG"
log_main "Дополнительные логи в директории: $LOG_DIR"