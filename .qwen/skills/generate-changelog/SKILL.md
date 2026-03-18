---
name: generate-changelog
description: Генерация записей CHANGELOG на основе коммитов Git
user-invocable: false
---

# Generate Changelog

## Когда использовать
- Перед созданием релиза
- После мержа крупной функциональности
- При подготовке release-ветки
- Когда CHANGELOG.md устарел

## Инструкции

### Фаза 1: Получение списка коммитов
1.1. Получить последний тег версии:
```bash
git describe --tags --abbrev=0
```

1.2. Получить список коммитов с последнего тега:
```bash
git log <LAST_TAG>..HEAD --oneline
```

1.3. Получить детальную информацию о каждом коммите:
```bash
git log <LAST_TAG>..HEAD --pretty=format:"%h|%s|%b"
```

### Фаза 2: Классификация изменений
2.1. Сгруппировать коммиты по типам Conventional Commits:
- `feat:` → Added
- `fix:` → Fixed
- `docs:` → Changed (документация)
- `style:` → Changed (стиль)
- `refactor:` → Changed
- `test:` → Added/Changed
- `chore:` → Changed/Removed
- `perf:` → Changed
- `ci:` → Changed
- `build:` → Changed

2.2. Извлечь номера issues (если есть):
- Формат: `Closes #123`, `Fixes #456`

### Фаза 3: Генерация секции CHANGELOG
3.1. Создать заголовок версии:
```markdown
## [<VERSION>] - <DATE>
```

3.2. Добавить секции:
```markdown
### Added
- Новые функции и компоненты

### Changed
- Изменения в существующей функциональности

### Deprecated
- Устаревшие функции (скоро будут удалены)

### Removed
- Удаленные функции

### Fixed
- Исправленные ошибки

### Security
- Исправления уязвимостей
```

3.3. Для каждого коммита:
- Префикс типа удалить (feat:, fix:, etc.)
- Оставить краткое описание
- Добавить ссылку на issue (если есть)

### Фаза 4: Обновление CHANGELOG.md
4.1. Прочитать текущий CHANGELOG.md

4.2. Вставить новую секцию после `[Unreleased]`

4.3. Обновить дату и версию

4.4. Сохранить файл

## Формат ввода
```json
{
  "version": "string (например, '0.2.0')",
  "date": "string (например, '2026-03-18')",
  "fromTag": "string (например, 'v0.1.0')",
  "includeUnreleased": "boolean"
}
```

## Формат вывода
Markdown секция для CHANGELOG.md

## Примеры

### Пример 1: Генерация для релиза v0.2.0

**Вход:**
```json
{
  "version": "0.2.0",
  "date": "2026-03-18",
  "fromTag": "v0.1.0"
}
```

**Выход:**
```markdown
## [0.2.0] - 2026-03-18

### Added
- Система агентов безопасности (security-analyzer, security-orchestrator)
- Система анализа зависимостей (dependency-analyzer)
- Контрольные точки качества (Quality Gates)
- MCP конфигурации (BASE, DATABASE, FRONTEND, FULL)

### Changed
- Перемещены docs/ → .qwen/docs/
- Перемещены scripts/ → .qwen/scripts/
- Обновлены стандарты именования агентов

### Fixed
- Исправлены проблемы с дубликатами агентов
- Исправлены SKILL.md файлы с шаблонными заполнителями

### Removed
- Удалены дубликаты агентов (7 файлов)
- Удалена устаревшая релизная копия
```

### Пример 2: Генерация для Unreleased

**Вход:**
```json
{
  "version": "Unreleased",
  "includeUnreleased": true
}
```

**Выход:**
```markdown
## [Unreleased]

### Added
- Миграция внутренней документации в .qwen/
- Скрипты обслуживания

### Changed
- Обновлен .gitignore
```

## Интеграция с оркестраторами

Навык должен вызываться в оркестраторах при подготовке релиза:

```markdown
## Pre-Release Gate
- Check CHANGELOG.md is up to date
- Run generate-changelog skill
- Review and commit changes
```

## Параметры конфигурации

- `version`: Версия для CHANGELOG
- `date`: Дата в формате YYYY-MM-DD
- `fromTag`: Тег для сравнения
- `includeUnreleased`: Включить незакоммиченные изменения

## Лучшие практики

1. **Генерируйте CHANGELOG перед каждым релизом**
2. **Используйте Conventional Commits** для автоматической классификации
3. **Проверяйте сгенерированный текст** перед коммитом
4. **Добавляйте ссылки на issues** когда возможно
5. **Группируйте похожие изменения** вместе
