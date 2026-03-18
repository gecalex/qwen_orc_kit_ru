#!/bin/bash
# Скрипт поиска агентов по ключевым словам
# Назначение: Поиск агентов по функциональности с использованием альтернативных механизмов (вне YAML-заголовков)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

AGENTS_DIR=".qwen/agents"

# Проверяем, существует ли директория с агентами
if [ ! -d "$AGENTS_DIR" ]; then
    log_error "Директория агентов не найдена: $AGENTS_DIR"
    exit 1
fi

# Проверяем, есть ли аргументы
if [ $# -eq 0 ]; then
    log_error "Использование: $0 <ключевое_слово> [дополнительные_ключевые_слова...]"
    log_info "Пример: $0 'security' 'authentication' 'authorization'"
    exit 1
fi

KEYWORDS=("$@")
RESULTS_FILE="search-results/agent-search-results-$(date +%Y%m%d_%H%M%S).txt"

# Создаем директорию для результатов
mkdir -p "$(dirname "$RESULTS_FILE")"

# Начинаем поиск
log_info "Поиск агентов по ключевым словам: ${KEYWORDS[*]}"

# Инициализируем файл результатов
{
    echo "# Результаты поиска агентов"
    echo "Дата: $(date)"
    echo "Ключевые слова: ${KEYWORDS[*]}"
    echo ""
    echo "## Найденные агенты"
    echo ""
} > "$RESULTS_FILE"

FOUND_COUNT=0

# Для каждого ключевого слова ищем совпадения
for keyword in "${KEYWORDS[@]}"; do
    log_info "Поиск по ключевому слову: $keyword"
    
    # Ищем совпадения в файлах агентов
    while IFS= read -r -d '' agent_file; do
        if [ -f "$agent_file" ]; then
            agent_name=$(basename "$agent_file" .md)
            
            # Проверяем, не был ли уже добавлен этот агент
            if ! grep -q "$agent_name" "$RESULTS_FILE" 2>/dev/null; then
                # Извлекаем описание и функциональность
                description=$(sed -n '/^---$/,/^---$/p' "$agent_file" | grep '^description:' | sed 's/description:[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'\$/\1/")
                
                if [ -z "$description" ]; then
                    description=$(head -n 20 "$agent_file" | grep -A 1 "^# " | tail -n 1 | sed 's/^# //' | sed 's/^## //')
                fi
                
                if [ -z "$description" ]; then
                    description="Описание недоступно"
                fi
                
                # Извлекаем функциональность из тела файла
                functionality=$(grep -A 5 -E "^## (Назначение|Purpose|Functionality)" "$agent_file" | grep -v "^## " | head -n 5 | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                
                # Добавляем информацию об агенте в результаты
                {
                    echo "### $agent_name"
                    echo "- **Описание**: $description"
                    echo "- **Функциональность**: ${functionality:-"Не указана"}"
                    echo "- **Путь**: $agent_file"
                    echo ""
                } >> "$RESULTS_FILE"
                
                ((FOUND_COUNT++))
                log_success "Найден агент: $agent_name"
            fi
        fi
    done < <(find "$AGENTS_DIR" -name "*.md" -type f -print0 | xargs -0 grep -l -i "$keyword" 2>/dev/null || find "$AGENTS_DIR" -name "*.md" -type f -print0)
done

# Добавляем итоговую статистику
{
    echo "## Статистика"
    echo ""
    echo "- Найдено агентов: $FOUND_COUNT"
    echo "- Ключевые слова поиска: ${KEYWORDS[*]}"
    echo "- Дата поиска: $(date)"
} >> "$RESULTS_FILE"

if [ $FOUND_COUNT -eq 0 ]; then
    log_warning "Агенты по ключевым словам '${KEYWORDS[*]}' не найдены"
    echo "" >> "$RESULTS_FILE"
    echo "Агенты по ключевым словам '${KEYWORDS[*]}' не найдены." >> "$RESULTS_FILE"
else
    log_success "Поиск завершен. Найдено $FOUND_COUNT агентов."
    log_info "Результаты сохранены в: $RESULTS_FILE"
    
    # Показываем краткую информацию о найденных агентах
    echo ""
    log_info "Найденные агенты:"
    grep "^### " "$RESULTS_FILE" | sed 's/^### //'
fi