---
name: format-commit-message
description: Генерация стандартизированных сообщений коммитов в соответствии с конвенцией с атрибуцией Claude Code. Используется при создании автоматических коммитов, коммитов релизов или любых коммитов git, требующих последовательного форматирования.
---

# Форматирование сообщения коммита

Генерация сообщений коммитов в соответствии с конвенцией, следуя стандартам проекта с правильной атрибуцией.

## Когда использовать

- Коммиты релизов
- Автоматические обновления версий
- Коммиты рефакторинга
- Любые коммиты, требующие последовательного форматирования
- Обновления документации

## Инструкции

### Шаг 1: Сбор информации о коммите

Собрать необходимую информацию для сообщения коммита.

**Ожидаемый ввод**:
- `type`: Строка (feat|fix|chore|docs|refactor|test|style|perf)
- `scope`: Строка (необязательно, например, "auth", "api", "ui")
- `description`: Строка (краткое описание)
- `body`: Строка (необязательно, подробное объяснение)
- `breaking`: Boolean (необязательно, является ли это критическим изменением?)

### Шаг 2: Форматирование сообщения

Применить формат коммита в соответствии с конвенцией с проектными стандартами.

**Структура формата**:
```
{type}({scope}): {description}

{body}

{footer}
```

**Шаблон нижнего колонтитула**:
```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Критические изменения**:
Если `breaking: true`, добавить "BREAKING CHANGE: " в начало тела или как нижний колонтитул.

### Шаг 3: Проверка сообщения

Убедиться, что сообщение соответствует руководящим принципам.

**Правила проверки**:
- Тип должен быть допустимым (feat|fix|chore|docs|refactor|test|style|perf)
- Описание должно присутствовать и быть менее 72 символов
- Описание должно быть в нижнем регистре и без точки в конце
- Область должна быть в нижнем регистре, если присутствует
- Тело должно быть перенесено при 72 символах, если присутствует

### Шаг 4: Возврат отформатированного сообщения

Вернуть полное сообщение коммита, готовое для git commit.

**Ожидаемый вывод**:
```
feat(auth): add OAuth2 authentication support

Implemented OAuth2 flow with token refresh and secure storage.
Supports Google and GitHub providers.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Обработка ошибок

- **Неверный тип**: Вернуть ошибку с перечислением допустимых типов
- **Отсутствует описание**: Вернуть ошибку с запросом описания
- **Описание слишком длинное**: Вернуть ошибку с количеством символов
- **Неверный формат**: Описать проблему с форматом

## Примеры

### Пример 1: Простой коммит новой функции

**Ввод**:
```json
{
  "type": "feat",
  "description": "add dark mode toggle"
}
```

**Вывод**:
```
feat: add dark mode toggle

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Пример 2: Исправление с областью и телом

**Ввод**:
```json
{
  "type": "fix",
  "scope": "api",
  "description": "resolve memory leak in connection pool",
  "body": "Connection pooling was not properly releasing connections after timeout. Implemented automatic cleanup and connection recycling."
}
```

**Вывод**:
```
fix(api): resolve memory leak in connection pool

Connection pooling was not properly releasing connections after
timeout. Implemented automatic cleanup and connection recycling.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Пример 3: Критическое изменение

**Ввод**:
```json
{
  "type": "feat",
  "scope": "api",
  "description": "migrate to v2 authentication API",
  "breaking": true,
  "body": "Updated authentication to use new v2 endpoints with improved security."
}
```

**Вывод**:
```
feat(api): migrate to v2 authentication API

BREAKING CHANGE: Updated authentication to use new v2 endpoints with
improved security. All clients must update authentication tokens.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Пример 4: Коммит релиза

**Ввод**:
```json
{
  "type": "chore",
  "scope": "release",
  "description": "bump version to 0.8.0"
}
```

**Вывод**:
```
chore(release): bump version to 0.8.0

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Валидация

- [ ] Правильно форматирует все типы коммитов в соответствии с конвенцией
- [ ] Правильно обрабатывает необязательную область
- [ ] Переносит длинные описания и тела
- [ ] Включает атрибуцию Claude Code
- [ ] Правильно форматирует критические изменения
- [ ] Проверяет входные поля

## Вспомогательные файлы

- `template.md`: Ссылка на шаблон сообщения коммита (см. раздел Вспомогательные файлы)
