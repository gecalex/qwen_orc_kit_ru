#!/bin/bash
# Скрипт: scripts/release-tools/clean-for-template.sh
# Назначение: Очистка проекта от файлов, специфичных для текущего проекта, для подготовки шаблона

set -e  # Прерывать выполнение при ошибках

echo "=== Подготовка проекта к использованию в качестве шаблона ==="

# Создание резервной копии
echo "Создание резервной копии..."
tar -czf "backup-$(date +%Y%m%d-%H%M%S).tar.gz" --exclude="backup*" --exclude="template-*" . > /dev/null 2>&1
echo "Резервная копия создана"

# Удаление системных файлов Git
echo "Удаление файлов Git..."
rm -rf .git/
rm -f .gitignore  # Восстановим позже с обобщенным содержимым

# Удаление специфичных для проекта директорий
echo "Удаление специфичных директорий..."
rm -rf specs/
rm -rf state/
rm -rf examples/specs/
rm -rf FEATURE_DIR/
rm -rf workspace/ 2>/dev/null || true
rm -rf dist/ 2>/dev/null || true
rm -rf build/ 2>/dev/null || true
rm -rf target/ 2>/dev/null || true
rm -rf node_modules/ 2>/dev/null || true
rm -rf .venv/ 2>/dev/null || true
rm -rf venv/ 2>/dev/null || true
rm -rf env/ 2>/dev/null || true
rm -rf __pycache__/ 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -type d -exec rm -rf {}+ 2>/dev/null || true

# Удаление файлов IDE
echo "Удаление файлов конфигурации IDE..."
rm -rf .vscode/ 2>/dev/null || true
rm -rf .idea/ 2>/dev/null || true
rm -f .editorconfig 2>/dev/null || true

# Удаление временных файлов
echo "Удаление временных файлов..."
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name "*.bak" -delete 2>/dev/null || true
find . -name "*.backup" -delete 2>/dev/null || true
find . -name "*.log" -delete 2>/dev/null || true
rm -f .DS_Store 2>/dev/null || true
rm -f Thumbs.db 2>/dev/null || true

# Удаление специфичных файлов проекта
echo "Удаление специфичных файлов проекта..."
rm -f specs/README.md 2>/dev/null || true
rm -f specs/demo-feature/ 2>/dev/null || true

# Создание обобщенного .gitignore
echo "Создание обобщенного .gitignore..."
cat > .gitignore << 'EOF'
# Системные файлы
.git/
*.log
*.tmp
*.bak
*.backup
.DS_Store
Thumbs.db

# Виртуальные окружения
.venv/
venv/
env/
.env

# Компилированные файлы Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python

# Директории сборки
dist/
build/
target/
*.egg-info/

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.nyc_output/
coverage/
.nyc_output/

# IDE
.vscode/
.idea/
*.swp
*.swo

# Артефакты
*.tar.gz
backup-*.tar.gz
template-*.tar.gz
EOF

# Замена специфичных имен в файлах на плейсхолдеры
echo "Замена специфичных имен на плейсхолдеры..."
# Заменяем специфичные имена проекта на плейсхолдеры
find . -type f \( -name "*.md" -o -name "*.txt" -o -name "*.toml" -o -name "*.py" -o -name "*.sh" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) -exec sed -i.bak 's/qwen_orc_kit_ru/{{PROJECT_NAME}}/g' {} \; 2>/dev/null || true
find . -type f \( -name "*.md" -o -name "*.txt" -o -name "*.toml" -o -name "*.py" -o -name "*.sh" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) -exec sed -i.bak 's/Qwen Code Orchestrator Kit/{{PROJECT_TEMPLATE_NAME}}/g' {} \; 2>/dev/null || true
find . -type f \( -name "*.md" -o -name "*.txt" -o -name "*.toml" -o -name "*.py" -o -name "*.sh" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) -exec sed -i.bak 's/gecalex/{{ORGANIZATION_NAME}}/g' {} \; 2>/dev/null || true

# Удаление временных файлов редактирования
find . -name "*.bak" -delete 2>/dev/null || true

# Создание шаблона README для нового проекта
echo "Создание шаблона README.md..."
cat > README.md << 'TEMPLATE_EOF'
# {{PROJECT_NAME}}

Добро пожаловать в {{PROJECT_NAME}} - проект, созданный на основе шаблона Qwen Code Orchestrator Kit.

## Описание проекта

Этот проект создан с использованием шаблона Qwen Code Orchestrator Kit - инструмента для оркестрации задач разработки с использованием ИИ-агентов.

## Структура проекта

```
.specify/                 # Шаблоны и скрипты для спецификаций
├── memory/              # Постоянная память для агентов
├── scripts/             # Bash-скрипты для автоматизации
├── templates/           # Шаблоны для различных документов
└── ...
docs/                   # Документация проекта
├── architecture/        # Архитектурная документация
└── ...
.qwen/                  # Конфигурация Qwen CLI
├── agents/              # Агенты
└── commands/            # Команды
└── ...
specs/                  # Спецификации функциональности
scripts/                # Скрипты для контрольных точек качества
state/                  # Состояние системы и артефакты выполнения задач
```

## Начало работы

1. Убедитесь, что у вас установлены необходимые инструменты
2. Ознакомьтесь с архитектурной документацией в `docs/architecture/`
3. Изучите доступные агенты в `.qwen/agents/`
4. Попробуйте выполнить простую задачу с использованием оркестратора

## Использование

Для запуска процесса разработки на основе спецификаций:

1. Создайте конституцию проекта: `speckit.constitution`
2. Создайте спецификацию: `speckit.specify "описание функции"`
3. Уточните спецификацию: `speckit.clarify`
4. Создайте план: `speckit.plan`
5. Сгенерируйте задачи: `speckit.tasks`
6. Выполните реализацию: `speckit.implement`

Для получения более подробной информации см. документацию в `docs/architecture/specification-driven-development.md`.
TEMPLATE_EOF

echo "=== Очистка завершена ==="
echo "Проект подготовлен к использованию в качестве шаблона."
echo "Теперь можно использовать его для инициализации новых проектов."
