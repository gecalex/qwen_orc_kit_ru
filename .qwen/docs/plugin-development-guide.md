# Plugin Development Guide

## Введение

Это руководство по разработке плагинов для Qwen Orchestrator Kit. Следуя этим инструкциям, вы создадите совместимые и качественные плагины.

## Быстрый старт

### 1. Использование шаблона

```bash
# Скопировать шаблон
cp -r .qwen/templates/plugin-template .qwen/plugins/my-plugin

# Переименовать и настроить
cd .qwen/plugins/my-plugin
```

### 2. Минимальная структура

```
my-plugin/
├── plugin.json           # Обязательно
├── agents/               # Хотя бы один агент
│   └── specialist.md
├── commands/             # Хотя бы одна команда
│   └── main.md
└── skills/               # Хотя бы один навык
    └── expertise.md
```

## plugin.json спецификация

### Обязательные поля

```json
{
  "name": "my-plugin",           // Уникальное имя (kebab-case)
  "displayName": "My Plugin",    // Отображаемое имя
  "version": "1.0.0",            // Semver версия
  "description": "Описание",     // Краткое описание
  "author": "Author Name",       // Автор
  "license": "MIT"               // Лицензия
}
```

### Рекомендуемые поля

```json
{
  "category": "development",     // Категория
  "tags": ["tag1", "tag2"],      // Теги для поиска
  "repository": "https://...",   // URL репозитория
  "minOrchestratorVersion": "0.6.0"  // Минимальная версия
}
```

### Компоненты

```json
{
  "components": {
    "agents": [
      {
        "name": "specialist",
        "file": "agents/specialist.md",
        "description": "Специалист для задач"
      }
    ],
    "commands": [
      {
        "name": "main",
        "file": "commands/main.md",
        "description": "Основные команды"
      }
    ],
    "skills": [
      {
        "name": "expertise",
        "file": "skills/expertise.md",
        "description": "Экспертные знания"
      }
    ]
  }
}
```

### Зависимости

```json
{
  "dependencies": [
    "base-plugin"              // Обязательные
  ],
  "optionalDependencies": [
    "enhancement-plugin"       // Опциональные
  ],
  "conflicts": [
    "conflicting-plugin"       // Конфликты
  ]
}
```

## Создание агента

### Структура файла

```markdown
# Agent Name

## Назначение
Краткое описание назначения агента.

## Роль
Описание роли и экспертизы.

## Компетенции
- Компетенция 1
- Компетенция 2
- Компетенция 3

## Рабочий процесс
1. Шаг 1
2. Шаг 2
3. Шаг 3

## Примеры

### Пример 1
```python
# Код примера
```

## MCP Integration
Описание интеграции с MCP.

## Выходные артефакты
- Артефакт 1
- Артефакт 2
```

### Best Practices для агентов

1. **Четкая роль**: Определите конкретную область ответственности
2. **Компетенции**: Перечислите конкретные навыки
3. **Примеры**: Включите рабочие примеры кода
4. **MCP**: Укажите использование MCP серверов

## Создание команды

### Структура файла

```markdown
# Command Group Name

## Описание
Описание группы команд.

## Доступные команды

### `command action`
Описание команды.

**Использование:**
```bash
command action [options]
```

**Опции:**
- `--option` - Описание

**Пример:**
```bash
command action --option value
```
```

### Best Practices для команд

1. **Именование**: Используйте глаголы для действий
2. **Опции**: Документируйте все опции
3. **Примеры**: Показывайте типичное использование
4. **Ошибки**: Описывайте возможные ошибки

## Создание навыка

### Структура файла

```markdown
# Skill Name

## Описание
Описание навыка и области применения.

## Компетенции

### Тема 1
Подробное описание.

```python
# Пример кода
```

### Тема 2
Подробное описание.

## Best Practices
- Практика 1
- Практика 2

## MCP Integration
Описание интеграции.

## Выходные артефакты
- Результат 1
- Результат 2
```

## Версионирование

### Semver

Следуйте семантическому версионированию:

- **MAJOR**: Несовместимые изменения
- **MINOR**: Новые функции (обратно совместимые)
- **PATCH**: Исправления ошибок

### CHANGELOG

Ведите файл изменений:

```markdown
# Changelog

## [1.1.0] - 2026-03-21

### Added
- Новая функция

### Changed
- Изменение существующей функции

### Fixed
- Исправление ошибки
```

## Тестирование

### Локальное тестирование

```bash
# Установить плагин
.qwen/plugins/plugin-manager.sh install my-plugin

# Проверить зависимости
.qwen/plugins/plugin-dependencies.sh check my-plugin

# Загрузить в контекст
.qwen/plugins/load-plugin.sh my-plugin

# Проверить компоненты
.qwen/plugins/plugin-manager.sh info my-plugin
```

### Тестирование совместимости

1. Тест с другими плагинами
2. Проверка конфликтов
3. Валидация зависимостей

## Публикация

### Подготовка к публикации

1. ✅ Все компоненты документированы
2. ✅ plugin.json заполнен полностью
3. ✅ Зависимости указаны
4. ✅ Тесты пройдены
5. ✅ CHANGELOG обновлен

### Регистрация в registry

Добавьте запись в `plugin-registry.json`:

```json
{
  "registry": {
    "my-plugin": {
      "name": "my-plugin",
      "displayName": "My Plugin",
      "version": "1.0.0",
      "description": "Описание",
      "author": "Author",
      "category": "category",
      "tags": ["tag1", "tag2"],
      "repository": "https://github.com/...",
      "dependencies": [],
      "minOrchestratorVersion": "0.6.0",
      "status": "stable"
    }
  }
}
```

## Структура проекта

### Рекомендуемая структура

```
my-plugin/
├── plugin.json
├── README.md
├── CHANGELOG.md
├── LICENSE
│
├── agents/
│   ├── agent-1.md
│   └── agent-2.md
│
├── commands/
│   └── main.md
│
├── skills/
│   └── expertise.md
│
├── scripts/
│   ├── on-enable.sh
│   ├── on-disable.sh
│   ├── on-load.sh
│   └── on-unload.sh
│
└── tests/
    └── test-plugin.sh
```

### Скрипты жизненного цикла

**on-enable.sh:**
```bash
#!/bin/bash
echo "Plugin enabled"
# Инициализация при включении
```

**on-disable.sh:**
```bash
#!/bin/bash
echo "Plugin disabled"
# Очистка при выключении
```

**on-load.sh:**
```bash
#!/bin/bash
echo "Plugin loaded"
# Инициализация при загрузке
```

**on-unload.sh:**
```bash
#!/bin/bash
echo "Plugin unloaded"
# Очистка при выгрузке
```

## Отладка

### Логирование

Используйте стандартные сообщения:

```bash
log_info "Information message"
log_success "Success message"
log_warning "Warning message"
log_error "Error message"
```

### Общие проблемы

**Плагин не загружается:**
- Проверьте plugin.json на валидность JSON
- Убедитесь, что все файлы компонентов существуют
- Проверьте зависимости

**Конфликты:**
- Проверьте поле conflicts в plugin.json
- Убедитесь, что конфликтующие плагины не активны

**Зависимости:**
- Используйте `plugin-dependencies.sh check`
- Установите отсутствующие зависимости

## Примеры плагинов

### Простой плагин

```json
{
  "name": "simple-plugin",
  "displayName": "Simple Plugin",
  "version": "1.0.0",
  "description": "Простой плагин",
  "components": {
    "agents": [
      {
        "name": "helper",
        "file": "agents/helper.md",
        "description": "Помощник"
      }
    ],
    "commands": [
      {
        "name": "help",
        "file": "commands/help.md",
        "description": "Команды помощи"
      }
    ],
    "skills": [
      {
        "name": "basics",
        "file": "skills/basics.md",
        "description": "Базовые навыки"
      }
    ]
  }
}
```

### Продвинутый плагин

```json
{
  "name": "advanced-plugin",
  "displayName": "Advanced Plugin",
  "version": "2.0.0",
  "description": "Продвинутый плагин с зависимостями",
  "dependencies": ["base-plugin"],
  "optionalDependencies": ["enhancement-plugin"],
  "conflicts": ["conflicting-plugin"],
  "components": {
    "agents": [
      {"name": "expert", "file": "agents/expert.md"},
      {"name": "assistant", "file": "agents/assistant.md"}
    ],
    "commands": [
      {"name": "main", "file": "commands/main.md"},
      {"name": "admin", "file": "commands/admin.md"}
    ],
    "skills": [
      {"name": "advanced", "file": "skills/advanced.md"},
      {"name": "expert", "file": "skills/expert.md"}
    ]
  },
  "configuration": {
    "setting1": "default1",
    "setting2": "default2"
  }
}
```

## Ресурсы

### Документация

- [Plugin Architecture](plugin-architecture.md) - Архитектура плагинов
- [Plugins README](../plugins/README.md) - Список плагинов

### Шаблоны

- `templates/plugin-template/` - Базовый шаблон плагина

### Инструменты

- `plugin-manager.sh` - Управление плагинами
- `load-plugin.sh` - Загрузка в контекст
- `plugin-dependencies.sh` - Управление зависимостями

## Поддержка

Для вопросов и проблем:

1. Проверьте документацию
2. Используйте `plugin-manager.sh info` для диагностики
3. Откройте issue в репозитории
