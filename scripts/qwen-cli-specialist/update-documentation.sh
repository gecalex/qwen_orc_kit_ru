#!/bin/bash

# Скрипт автоматического обновления документации агента-специалиста по Qwen Orchestrator Kit

PROJECT_ROOT="/home/alex/MyProjects/qwen_orc_kit_ru"
DOCS_DIR="$PROJECT_ROOT/docs/help/qwen_orchestrator_kit"
TEMPLATES_DIR="$PROJECT_ROOT/.qwen/templates"
AGENTS_DIR="$PROJECT_ROOT/.qwen/agents"
SKILLS_DIR="$PROJECT_ROOT/.qwen/skills"
LOG_FILE="$PROJECT_ROOT/logs/doc-update-$(date +%Y%m%d_%H%M%S).log"

# Функция для логирования
log_update() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_update "=== Запуск автоматического обновления документации ==="

# Создаем резервную копию
BACKUP_DIR="$PROJECT_ROOT/backups/doc-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$DOCS_DIR" "$BACKUP_DIR/"
log_update "Создана резервная копия документации в: $BACKUP_DIR"

# Обновляем информацию о существующих компонентах
log_update "Обновление информации о компонентах..."

# Подсчитываем количество агентов
ORC_COUNT=$(find "$AGENTS_DIR" -name "orc_*.md" 2>/dev/null | wc -l)
WORK_COUNT=$(find "$AGENTS_DIR" -name "work_*.md" 2>/dev/null | wc -l)
TOTAL_AGENTS=$((ORC_COUNT + WORK_COUNT))

log_update "Найдено оркестраторов: $ORC_COUNT"
log_update "Найдено воркеров: $WORK_COUNT"
log_update "Всего агентов: $TOTAL_AGENTS"

# Подсчитываем количество навыков
SKILL_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l)
log_update "Найдено навыков: $SKILL_COUNT"

# Подсчитываем количество шаблонов
TEMPLATE_COUNT=$(find "$TEMPLATES_DIR" -name "*.md" 2>/dev/null | wc -l)
log_update "Найдено шаблонов: $TEMPLATE_COUNT"

# Обновляем README с актуальной информацией
README_FILE="$DOCS_DIR/README.md"
if [ -f "$README_FILE" ]; then
    log_update "Обновление README с актуальной статистикой..."
    
    # Создаем временную версию README с обновленной информацией
    TEMP_README=$(mktemp)
    
    # Копируем существующий README, обновляя статистику
    sed \
        -e "s/Найдено оркестраторов: [0-9]*/Найдено оркестраторов: $ORC_COUNT/" \
        -e "s/Найдено воркеров: [0-9]*/Найдено воркеров: $WORK_COUNT/" \
        -e "s/Всего агентов: [0-9]*/Всего агентов: $TOTAL_AGENTS/" \
        -e "s/Найдено навыков: [0-9]*/Найдено навыков: $SKILL_COUNT/" \
        -e "s/Найдено шаблонов: [0-9]*/Найдено шаблонов: $TEMPLATE_COUNT/" \
        "$README_FILE" > "$TEMP_README"
    
    # Заменяем оригинальный файл
    mv "$TEMP_README" "$README_FILE"
    
    log_update "README обновлен с актуальной статистикой"
else
    log_update "❌ Файл README не найден: $README_FILE"
fi

# Обновляем информацию в спецификации
SPEC_FILE="$DOCS_DIR/specification.md"
if [ -f "$SPEC_FILE" ]; then
    log_update "Обновление спецификации с актуальной информацией..."
    
    # Обновляем дату последнего изменения
    sed -i "s/Создано: [0-9.]\{10\}/Создано: $(date +%d.%m.%Y)/" "$SPEC_FILE"
    log_update "Дата в спецификации обновлена"
else
    log_update "❌ Файл спецификации не найден: $SPEC_FILE"
fi

# Обновляем информацию в плане
PLAN_FILE="$DOCS_DIR/plan.md"
if [ -f "$PLAN_FILE" ]; then
    log_update "Обновление плана с актуальной информацией..."
    
    # Обновляем дату
    sed -i "s/Дата: [0-9.]\{10\}/Дата: $(date +%d.%m.%Y)/" "$PLAN_FILE"
    log_update "Дата в плане обновлена"
else
    log_update "❌ Файл плана не найден: $PLAN_FILE"
fi

# Создаем отчет о компонентах
COMPONENTS_REPORT="$DOCS_DIR/components-summary.md"
log_update "Создание отчета о компонентах: $COMPONENTS_REPORT"

cat > "$COMPONENTS_REPORT" << EOF
# Отчет о компонентах системы

**Дата создания**: $(date)

## Статистика компонентов

| Тип компонента | Количество |
|----------------|------------|
| Оркестраторы | $ORC_COUNT |
| Воркеры | $WORK_COUNT |
| Всего агентов | $TOTAL_AGENTS |
| Навыки | $SKILL_COUNT |
| Шаблоны | $TEMPLATE_COUNT |

## Структура директорий

### Агенты
- Общее количество: $TOTAL_AGENTS
- Оркестраторы: $ORC_COUNT
- Воркеры: $WORK_COUNT

### Навыки
- Общее количество: $SKILL_COUNT
- Директория: \`$SKILLS_DIR\`

### Шаблоны
- Общее количество: $TEMPLATE_COUNT
- Директория: \`$TEMPLATES_DIR\`

## Статус документации

- [x] README.md - основное описание
- [x] specification.md - спецификация
- [x] plan.md - план реализации
- [x] tasks.md - задачи реализации
- [x] getting-started.md - начало работы
- [x] yaml-standards.md - стандарты YAML
- [x] template-guidelines.md - рекомендации по шаблонам
- [x] quality-assurance.md - процессы обеспечения качества
- [x] mcp-integration.md - интеграция с MCP
- [x] components-summary.md - этот файл

## Актуальность

Этот отчет автоматически генерируется агентом-специалистом по Qwen Orchestrator Kit и отражает текущее состояние системы.
EOF

log_update "Отчет о компонентах создан"

log_update ""
log_update "=== Обновление документации завершено ==="
log_update "Логи доступны в: $LOG_FILE"
log_update "Отчет о компонентах создан в: $COMPONENTS_REPORT"

log_update ""
log_update "🎉 Документация успешно обновлена с актуальной информацией!"