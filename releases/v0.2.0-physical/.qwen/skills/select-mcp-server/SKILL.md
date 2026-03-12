---
name: select-mcp-server
description: Определяет подходящие серверы MCP для конкретных типов задач. Используйте активно, когда оркестраторы или воркеры нуждаются в выборе подходящих серверов MCP для своих задач на основе категории задач, домена и требований. Интегрируется с mcpGuidance в файлах плана.
---

# Навык выбора MCP-сервера

## Когда использовать
- При определении необходимости MCP-сервера для выполнения задачи
- При выборе наиболее подходящего сервера из доступных
- При анализе требований к внешним сервисам
- При интеграции с mcpGuidance в файлах плана

## Инструкции

### Фаза 1: Анализ требований
1.1. Определить тип задачи (документация, база данных, рассуждение, тестирование, UI, рабочий процесс)
1.2. Определить домен задачи (react, vue, angular, node, python, etc.)
1.3. Определить специфические требования (контекстный поиск, безопасность, производительность)

### Фаза 2: Сопоставление с MCP-серверами
2.1. Сопоставить тип задачи с подходящими MCP-серверами:
- Документация/паттерны → context7
- Базы данных → supabase
- Сложные рассуждения → sequential-thinking
- Браузерные тесты → playwright
- UI компоненты → shadcn
- Рабочие процессы → n8n
- Универсальный → default

### Фаза 3: Рекомендация сервера
3.1. Сформировать рекомендацию на основе анализа
3.2. Указать причину выбора сервера
3.3. Перечислить альтернативные варианты (если применимо)

## Формат ввода
```json
{
  "taskType": "string",
  "domain": "string", 
  "requirements": ["string"]
}
```

## Формат вывода
```json
{
  "recommendedServer": "string",
  "alternatives": ["string"],
  "reason": "string",
  "configuration": "string"
}
```

## Примеры

### Пример 1: Задача документации
**Вход:**
```json
{
  "taskType": "documentation",
  "domain": "react",
  "requirements": ["context-search", "pattern-validation"]
}
```

**Выход:**
```json
{
  "recommendedServer": "mcp__context7__*",
  "alternatives": ["mcp__sequential_thinking__*"],
  "reason": "Поиск актуальных паттернов и API для React",
  "configuration": "context7"
}
```

### Пример 2: Задача базы данных
**Вход:**
```json
{
  "taskType": "database-migration",
  "domain": "supabase",
  "requirements": ["sql-generation", "migration-validation"]
}
```

**Выход:**
```json
{
  "recommendedServer": "mcp__supabase__*",
  "alternatives": [],
  "reason": "Операции с базами данных Supabase",
  "configuration": "supabase"
}
```

### Пример 3: Задача тестирования
**Вход:**
```json
{
  "taskType": "ui-testing",
  "domain": "frontend",
  "requirements": ["browser-automation", "integration-test"]
}
```

**Выход:**
```json
{
  "recommendedServer": "mcp__playwright__*",
  "alternatives": ["mcp__sequential_thinking__*"],
  "reason": "Автоматизация браузерных тестов",
  "configuration": "playwright"
}
```