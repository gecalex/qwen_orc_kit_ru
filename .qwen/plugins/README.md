# Plugins for Qwen Orchestrator Kit

## Обзор

Система плагинов обеспечивает гранулярную загрузку функциональности и минимальный контекст для каждой задачи.

## Доступные плагины

### 🐍 Python Development

**Версия:** 1.0.0  
**Категория:** Development  
**Описание:** Плагин для Python разработки: создание кода, тестирование, линтинг.

**Компоненты:**
- 🤖 Агенты: python-developer, python-tester, python-linter
- ⚙️ Команды: python-dev
- 📚 Навыки: python-expertise

**Установка:**
```bash
.qwen/plugins/plugin-manager.sh install python-development
```

---

### 🔒 Security Scanning

**Версия:** 1.0.0  
**Категория:** Security  
**Описание:** Сканирование безопасности: поиск уязвимостей, анализ кода.

**Компоненты:**
- 🤖 Агенты: security-scanner, vulnerability-analyzer
- ⚙️ Команды: security-scan
- 📚 Навыки: security-analysis

**Установка:**
```bash
.qwen/plugins/plugin-manager.sh install security-scanning
```

---

### 🧪 Testing Automation

**Версия:** 1.0.0  
**Категория:** Testing  
**Описание:** Автоматизация тестирования: unit, integration, e2e тесты.

**Компоненты:**
- 🤖 Агенты: test-writer, integration-tester, e2e-tester
- ⚙️ Команды: testing
- 📚 Навыки: testing-expertise

**Установка:**
```bash
.qwen/plugins/plugin-manager.sh install testing-automation
```

---

### 🗄️ Database Operations

**Версия:** 1.0.0  
**Категория:** Database  
**Описание:** Операции с базами данных: проектирование, миграции, оптимизация.

**Компоненты:**
- 🤖 Агенты: database-architect, sql-specialist
- ⚙️ Команды: database
- 📚 Навыки: database-expertise

**Установка:**
```bash
.qwen/plugins/plugin-manager.sh install database-operations
```

---

### 🚀 Infrastructure & DevOps

**Версия:** 1.0.0  
**Категория:** DevOps  
**Описание:** DevOps и инфраструктура: CI/CD, контейнеризация, оркестрация.

**Компоненты:**
- 🤖 Агенты: devops-engineer, kubernetes-specialist
- ⚙️ Команды: devops
- 📚 Навыки: devops-expertise

**Установка:**
```bash
.qwen/plugins/plugin-manager.sh install infrastructure-devops
```

---

## Быстрый старт

### 1. Установка плагина

```bash
.qwen/plugins/plugin-manager.sh install <plugin-name>
```

### 2. Проверка статуса

```bash
.qwen/plugins/plugin-manager.sh list
```

### 3. Загрузка в контекст

```bash
.qwen/plugins/load-plugin.sh <plugin-name>
```

### 4. Использование команд

```bash
# Пример для Python плагина
python-dev lint src/
python-dev test tests/ --coverage

# Пример для Security плагина
security-scan code src/
security-scan dependencies
```

## Управление плагинами

### Plugin Manager

```bash
# Установка
.qwen/plugins/plugin-manager.sh install <name>

# Удаление
.qwen/plugins/plugin-manager.sh uninstall <name>

# Включение
.qwen/plugins/plugin-manager.sh enable <name>

# Выключение
.qwen/plugins/plugin-manager.sh disable <name>

# Список
.qwen/plugins/plugin-manager.sh list [--installed|--available]

# Информация
.qwen/plugins/plugin-manager.sh info <name>
```

### Load Plugin

```bash
# Загрузка
.qwen/plugins/load-plugin.sh <name>

# Выгрузка
.qwen/plugins/load-plugin.sh unload <name>

# Перезагрузка
.qwen/plugins/load-plugin.sh reload <name>

# Список загруженных
.qwen/plugins/load-plugin.sh list
```

### Dependencies

```bash
# Проверка зависимостей
.qwen/plugins/plugin-dependencies.sh check <name>

# Автоматическая установка
.qwen/plugins/plugin-dependencies.sh resolve <name>

# Дерево зависимостей
.qwen/plugins/plugin-dependencies.sh tree <name>

# Граф зависимостей
.qwen/plugins/plugin-dependencies.sh graph

# Конфликты
.qwen/plugins/plugin-dependencies.sh conflicts
```

## Категории плагинов

| Категория | Описание | Плагины |
|-----------|----------|---------|
| Development | Разработка кода | python-development |
| Security | Безопасность | security-scanning |
| Testing | Тестирование | testing-automation |
| Database | Базы данных | database-operations |
| DevOps | Инфраструктура | infrastructure-devops |

## Зависимости между плагинами

```
python-development
└── (нет зависимостей)

security-scanning
└── (нет зависимостей)

testing-automation
└── (нет зависимостей)

database-operations
└── (нет зависимостей)

infrastructure-devops
└── security-scanning (optional)
```

## Примеры использования

### Python разработка

```bash
# Установить и загрузить
.qwen/plugins/plugin-manager.sh install python-development
.qwen/plugins/load-plugin.sh python-development

# Линтинг
python-dev lint src/ --fix

# Тестирование
python-dev test tests/ --coverage

# Форматирование
python-dev format src/
```

### Безопасность

```bash
# Установить и загрузить
.qwen/plugins/plugin-manager.sh install security-scanning
.qwen/plugins/load-plugin.sh security-scanning

# Полное сканирование
security-scan full --output-dir reports/

# Проверка зависимостей
security-scan dependencies --format json
```

### Тестирование

```bash
# Установить и загрузить
.qwen/plugins/plugin-manager.sh install testing-automation
.qwen/plugins/load-plugin.sh testing-automation

# Генерация тестов
testing generate src/service.py --type unit

# Запуск тестов
testing run tests/ --coverage
```

## Разработка плагинов

### Создание нового плагина

1. Используйте шаблон:
```bash
cp -r .qwen/templates/plugin-template .qwen/plugins/my-plugin
```

2. Настройте plugin.json
3. Создайте агентов, команды, навыки
4. Протестируйте плагин

### Документация

- [Plugin Architecture](../docs/plugin-architecture.md) - Архитектура
- [Plugin Development Guide](../docs/plugin-development-guide.md) - Руководство по разработке

## Troubleshooting

### Плагин не загружается

```bash
# Проверить статус
.qwen/plugins/plugin-manager.sh info <name>

# Проверить зависимости
.qwen/plugins/plugin-dependencies.sh check <name>

# Переустановить
.qwen/plugins/plugin-manager.sh uninstall <name>
.qwen/plugins/plugin-manager.sh install <name>
```

### Конфликты

```bash
# Показать конфликты
.qwen/plugins/plugin-dependencies.sh conflicts
```

## Обновление плагинов

```bash
# Обновить плагин
.qwen/plugins/plugin-manager.sh update <name>

# Обновить все
for plugin in $(.qwen/plugins/plugin-manager.sh list --installed -q); do
    .qwen/plugins/plugin-manager.sh update $plugin
done
```

## Вклад

Для добавления новых плагинов:

1. Следуйте [Plugin Development Guide](../docs/plugin-development-guide.md)
2. Создайте pull request
3. Пройдите code review

## Лицензия

Все плагины распространяются под лицензией MIT, если не указано иное.
