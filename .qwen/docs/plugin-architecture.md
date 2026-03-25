# Plugin Architecture

## Обзор

Система плагинов Qwen Orchestrator Kit обеспечивает гранулярную загрузку функциональности и минимальный контекст для каждой задачи. Плагины позволяют добавлять специализированные возможности без увеличения базового контекста.

## Архитектура

```
.qwen/plugins/
├── plugin-manager.sh          # Управление плагинами
├── plugin-registry.json       # Реестр доступных плагинов
├── load-plugin.sh             # Загрузка плагина в контекст
├── plugin-dependencies.sh     # Управление зависимостями
├── README.md                  # Документация плагинов
│
├── python-development/        # Плагин Python разработки
│   ├── plugin.json            # Метаданные плагина
│   ├── agents/                # Агенты плагина
│   ├── commands/              # Команды плагина
│   └── skills/                # Навыки плагина
│
├── security-scanning/         # Плагин безопасности
├── testing-automation/        # Плагин тестирования
├── database-operations/       # Плагин баз данных
└── infrastructure-devops/     # Плагин DevOps
```

## Компоненты плагина

### plugin.json

Метаданные плагина в формате JSON:

```json
{
  "name": "plugin-name",
  "displayName": "Plugin Display Name",
  "version": "1.0.0",
  "description": "Описание плагина",
  "author": "Author Name",
  "license": "MIT",
  "category": "category",
  "tags": ["tag1", "tag2"],
  "enabled": true,
  "dependencies": [],
  "components": {
    "agents": [...],
    "commands": [...],
    "skills": [...]
  }
}
```

### Агенты (agents/)

Агенты определяют специализированные роли для выполнения задач:

- **Формат**: Markdown файлы
- **Содержание**: Роль, компетенции, рабочий процесс, примеры
- **Использование**: Назначение на задачи через оркестратор

### Команды (commands/)

Команды предоставляют CLI интерфейс для плагина:

- **Формат**: Markdown файлы с описанием команд
- **Содержание**: Синтаксис, опции, примеры
- **Использование**: Выполнение через plugin-manager

### Навыки (skills/)

Навыки определяют экспертные знания:

- **Формат**: Markdown файлы
- **Содержание**: Компетенции, best practices, примеры
- **Использование**: Контекст для агентов

## Жизненный цикл плагина

### 1. Установка

```bash
.qwen/plugins/plugin-manager.sh install <plugin-name>
```

**Процесс:**
1. Проверка существования плагина
2. Проверка зависимостей
3. Добавление в installed список
4. Автоматическое включение

### 2. Включение

```bash
.qwen/plugins/plugin-manager.sh enable <plugin-name>
```

**Процесс:**
1. Проверка установки
2. Включение зависимостей
3. Выполнение on-enable скрипта
4. Добавление в enabled список

### 3. Загрузка в контекст

```bash
.qwen/plugins/load-plugin.sh <plugin-name>
```

**Процесс:**
1. Проверка включения
2. Загрузка зависимостей
3. Загрузка компонентов (агенты, команды, навыки)
4. Выполнение on-load скрипта

### 4. Выключение

```bash
.qwen/plugins/plugin-manager.sh disable <plugin-name>
```

**Процесс:**
1. Проверка зависимых плагинов
2. Выполнение on-disable скрипта
3. Перемещение в disabled список

### 5. Удаление

```bash
.qwen/plugins/plugin-manager.sh uninstall <plugin-name>
```

**Процесс:**
1. Проверка зависимых плагинов
2. Выключение плагина
3. Удаление из installed списка
4. Очистка файлов (опционально)

## Зависимости

### Типы зависимостей

**Required (dependencies):**
- Обязательные для работы плагина
- Устанавливаются автоматически
- Блокируют включение при отсутствии

**Optional (optionalDependencies):**
- Расширяют функциональность
- Не блокируют работу
- Рекомендуются к установке

### Разрешение зависимостей

```bash
# Проверка зависимостей
.qwen/plugins/plugin-dependencies.sh check <plugin-name>

# Автоматическая установка
.qwen/plugins/plugin-dependencies.sh resolve <plugin-name>

# Показать дерево зависимостей
.qwen/plugins/plugin-dependencies.sh tree <plugin-name>
```

## Конфликты

Плагины могут объявлять конфликты:

```json
{
  "name": "plugin-a",
  "conflicts": ["plugin-b"]
}
```

При обнаружении конфликта:
1. Предупреждение пользователю
2. Блокировка одновременной активации
3. Предложение альтернативы

## Best Practices

### Для пользователей

1. **Минимальный контекст**: Устанавливайте только необходимые плагины
2. **Зависимости**: Проверяйте зависимости перед установкой
3. **Версионирование**: Следите за совместимостью версий
4. **Обновления**: Регулярно обновляйте плагины

### Для разработчиков

1. **Именование**: Используйте kebab-case для имен плагинов
2. **Версии**: Следуйте semver (major.minor.patch)
3. **Зависимости**: Минимизируйте зависимости
4. **Документация**: Документируйте все компоненты
5. **Тестирование**: Тестируйте с другими плагинами

## Примеры использования

### Python разработка

```bash
# Установить плагин
.qwen/plugins/plugin-manager.sh install python-development

# Загрузить в контекст
.qwen/plugins/load-plugin.sh python-development

# Использовать команды
python-dev lint src/
python-dev test tests/ --coverage
```

### Безопасность

```bash
# Установить плагин
.qwen/plugins/plugin-manager.sh install security-scanning

# Запустить сканирование
security-scan full --output-dir reports/
```

### Тестирование

```bash
# Установить плагин
.qwen/plugins/plugin-manager.sh install testing-automation

# Сгенерировать тесты
testing generate src/service.py --type unit
```

## Расширение

### Добавление нового плагина

1. Создать директорию плагина
2. Добавить plugin.json
3. Реализовать компоненты
4. Зарегистрировать в plugin-registry.json

### Публикация плагина

1. Создать репозиторий
2. Добавить документацию
3. Опубликовать в registry
4. Поддерживать обновления

## Troubleshooting

### Плагин не загружается

```bash
# Проверить статус
.qwen/plugins/plugin-manager.sh info <plugin-name>

# Проверить зависимости
.qwen/plugins/plugin-dependencies.sh check <plugin-name>

# Переустановить
.qwen/plugins/plugin-manager.sh uninstall <plugin-name>
.qwen/plugins/plugin-manager.sh install <plugin-name>
```

### Конфликт зависимостей

```bash
# Показать конфликты
.qwen/plugins/plugin-dependencies.sh conflicts

# Разрешить автоматически
.qwen/plugins/plugin-dependencies.sh resolve <plugin-name>
```

## API Reference

### plugin-manager.sh

| Команда | Описание |
|---------|----------|
| `install <name>` | Установить плагин |
| `uninstall <name>` | Удалить плагин |
| `enable <name>` | Включить плагин |
| `disable <name>` | Выключить плагин |
| `list [options]` | Список плагинов |
| `info <name>` | Информация о плагине |
| `update <name>` | Обновить плагин |

### load-plugin.sh

| Команда | Описание |
|---------|----------|
| `<name>` | Загрузить плагин |
| `unload <name>` | Выгрузить плагин |
| `reload <name>` | Перезагрузить плагин |
| `list` | Список загруженных |

### plugin-dependencies.sh

| Команда | Описание |
|---------|----------|
| `check <name>` | Проверить зависимости |
| `resolve <name>` | Разрешить зависимости |
| `tree <name>` | Дерево зависимостей |
| `graph` | Граф зависимостей |
| `conflicts` | Список конфликтов |

## См. также

- [Plugin Development Guide](plugin-development-guide.md) - Руководство по разработке плагинов
- [Plugins README](plugins/README.md) - Список доступных плагинов
