# Шаблон сообщения коммита

## Формат

```
{type}({scope}): {description}

{body}

🤖 Сгенерировано с помощью [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Допустимые типы

- **feat**: Новая функция
- **fix**: Исправление ошибки
- **chore**: Задачи обслуживания, обновление зависимостей
- **docs**: Изменения документации
- **refactor**: Рефакторинг кода без изменения поведения
- **test**: Добавление или обновление тестов
- **style**: Изменения стиля кода (форматирование, пробелы)
- **perf**: Улучшения производительности

## Руководящие принципы

1. **Тип** (обязательно): Использовать строчные буквы
2. **Область** (опционально): Компонент или область, на которую оказывается влияние (строчные буквы, без пробелов)
3. **Описание** (обязательно): Краткое резюме (< 72 символа, строчные буквы, без точки)
4. **Тело** (опционально): Подробное объяснение, перенос на 72 символе
5. **Подвал** (добавляется автоматически): Атрибуция Claude Code

## Критические изменения

Добавьте префикс "BREAKING CHANGE: " к телу или как отдельный раздел подвала.

## Примеры

### Простой
```
feat: add user authentication
```

### С областью
```
fix(api): resolve CORS configuration error
```

### С телом
```
refactor(database): optimize query performance

Replaced N+1 queries with batch loading strategy.
Reduced average query time by 60%.
```

### Критическое изменение
```
feat(api): migrate to REST API v2

BREAKING CHANGE: Authentication tokens from v1 are no longer valid.
All clients must obtain new tokens using the v2 /auth endpoint.
```
