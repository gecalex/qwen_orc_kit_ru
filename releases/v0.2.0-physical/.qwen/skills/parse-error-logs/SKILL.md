---
name: parse-error-logs
description: Разбор ошибок сборки, сбоев тестов, вывода проверки типов и журналов проверки в структурированные данные. Используется при обработке вывода npm/pnpm, ошибок TypeScript, сбоев Jest или любых результатов команд проверки для контрольных точек качества.
---

# Навык разбора логов ошибок

## Когда использовать
- При обработке вывода команд npm/pnpm
- При анализе ошибок TypeScript
- При разборе сбоев тестов Jest
- При анализе результатов проверки типов
- При обработке вывода линтеров
- При разборе результатов команд проверки качества
- При анализе логов сборки

## Инструкции

### Фаза 1: Определение типа логов
1.1. Определить тип логов (TypeScript, Jest, npm, линтер и т.д.)
1.2. Выбрать соответствующий парсер
1.3. Подготовить шаблоны для разбора
1.4. Определить формат вывода

### Фаза 2: Разбор логов
2.1. Прочитать содержимое логов
2.2. Применить регулярные выражения для извлечения информации
2.3. Извлечь тип ошибки, уровень важности, местоположение
2.4. Структурировать данные в унифицированный формат

### Фаза 3: Валидация и нормализация
3.1. Проверить корректность извлеченных данных
3.2. Нормализовать уровни важности (error, warning, info)
3.3. Убедиться, что все обязательные поля заполнены
3.4. Сгруппировать похожие ошибки (если применимо)

## Формат ввода
```json
{
  "logType": "typescript|jest|npm|eslint|other",
  "logContent": "string",
  "maxErrors": "integer (optional, default: 10)",
  "includeWarnings": "boolean (optional, default: false)",
  "fileFilter": "string (optional, path pattern)"
}
```

## Формат вывода
```json
{
  "parsedErrors": [
    {
      "type": "error|warning|info",
      "severity": "critical|high|medium|low",
      "location": {
        "file": "string",
        "line": "integer",
        "column": "integer"
      },
      "message": "string",
      "errorCode": "string (optional)",
      "details": "string (optional)"
    }
  ],
  "summary": {
    "totalErrors": "integer",
    "criticalErrors": "integer",
    "highSeverityErrors": "integer",
    "warnings": "integer"
  },
  "hasCriticalErrors": "boolean"
}
```

## Примеры

### Пример 1: Ошибки TypeScript
**Вход:**
```json
{
  "logType": "typescript",
  "logContent": "src/example.ts(5,10): error TS2532: Object is possibly 'undefined'.\nsrc/example.ts(10,15): error TS2339: Property 'length' does not exist on type 'string | undefined'.",
  "maxErrors": 5
}
```

**Выход:**
```json
{
  "parsedErrors": [
    {
      "type": "error",
      "severity": "high",
      "location": {
        "file": "src/example.ts",
        "line": 5,
        "column": 10
      },
      "message": "Object is possibly 'undefined'",
      "errorCode": "TS2532",
      "details": "Variable might be undefined at runtime"
    },
    {
      "type": "error",
      "severity": "high",
      "location": {
        "file": "src/example.ts",
        "line": 10,
        "column": 15
      },
      "message": "Property 'length' does not exist on type 'string | undefined'",
      "errorCode": "TS2339",
      "details": "Cannot access property on union type without checking"
    }
  ],
  "summary": {
    "totalErrors": 2,
    "criticalErrors": 0,
    "highSeverityErrors": 2,
    "warnings": 0
  },
  "hasCriticalErrors": false
}
```

### Пример 2: Ошибки тестов Jest
**Вход:**
```json
{
  "logType": "jest",
  "logContent": "FAIL src/__tests__/example.test.ts\n  ● Test suite failed to run\n\n    TypeError: Cannot read property 'map' of undefined\n\n      at Object.<anonymous> (src/example.ts:15:20)\n\n  ● Sum function › should return sum of two numbers\n\n    expect(received).toBe(expected) // Object.is equality\n\n    Expected: 5\n    Received: 4\n\n      at Object.<anonymous> (src/__tests__/example.test.ts:8:14)",
  "includeWarnings": true
}
```

**Выход:**
```json
{
  "parsedErrors": [
    {
      "type": "error",
      "severity": "critical",
      "location": {
        "file": "src/example.ts",
        "line": 15,
        "column": 20
      },
      "message": "Cannot read property 'map' of undefined",
      "errorCode": "TypeError",
      "details": "Runtime error in test suite"
    },
    {
      "type": "error",
      "severity": "high",
      "location": {
        "file": "src/__tests__/example.test.ts",
        "line": 8,
        "column": 14
      },
      "message": "expect(received).toBe(expected) // Object.is equality",
      "details": "Expected: 5, Received: 4"
    }
  ],
  "summary": {
    "totalErrors": 2,
    "criticalErrors": 1,
    "highSeverityErrors": 1,
    "warnings": 0
  },
  "hasCriticalErrors": true
}
```

### Пример 3: Ошибки линтера ESLint
**Вход:**
```json
{
  "logType": "eslint",
  "logContent": "src/example.ts\n  5:10  error  Missing semicolon  semi\n  10:15  warning  Unexpected console statement  no-console\n\n✖ 2 problems (1 error, 1 warning)",
  "includeWarnings": true
}
```

**Выход:**
```json
{
  "parsedErrors": [
    {
      "type": "error",
      "severity": "medium",
      "location": {
        "file": "src/example.ts",
        "line": 5,
        "column": 10
      },
      "message": "Missing semicolon",
      "errorCode": "semi",
      "details": "Semicolon is required"
    },
    {
      "type": "warning",
      "severity": "low",
      "location": {
        "file": "src/example.ts",
        "line": 10,
        "column": 15
      },
      "message": "Unexpected console statement",
      "errorCode": "no-console",
      "details": "Console statements should be avoided in production code"
    }
  ],
  "summary": {
    "totalErrors": 1,
    "criticalErrors": 0,
    "highSeverityErrors": 0,
    "warnings": 1
  },
  "hasCriticalErrors": false
}
```

### Пример 4: Ошибки npm
**Вход:**
```json
{
  "logType": "npm",
  "logContent": "npm ERR! code ELIFECYCLE\nnpm ERR! errno 1\nnpm ERR! my-project@1.0.0 build: `tsc`\nnpm ERR! Exit status 1\nnpm ERR!\nnpm ERR! Failed at the my-project@1.0.0 build script.",
  "maxErrors": 3
}
```

**Выход:**
```json
{
  "parsedErrors": [
    {
      "type": "error",
      "severity": "critical",
      "location": {
        "file": "package.json",
        "line": null,
        "column": null
      },
      "message": "Build script failed with exit status 1",
      "errorCode": "ELIFECYCLE",
      "details": "The 'build' script in package.json failed"
    }
  ],
  "summary": {
    "totalErrors": 1,
    "criticalErrors": 1,
    "highSeverityErrors": 0,
    "warnings": 0
  },
  "hasCriticalErrors": true
}
```

## Поддерживаемые форматы логов

### TypeScript
- Ошибки компиляции (TSXXXX)
- Проблемы с типами
- Ошибки импорта/экспорта

### Jest
- Сбои тестов
- Ошибки выполнения
- Проблемы с настройкой тестов

### ESLint/Prettier
- Ошибки линтинга
- Предупреждения
- Проблемы форматирования

### NPM/PNPM/Yarn
- Ошибки выполнения скриптов
- Проблемы с зависимостями
- Ошибки установки

## Параметры фильтрации

- `maxErrors`: Максимальное количество ошибок для возврата
- `includeWarnings`: Включать предупреждения в результат
- `fileFilter`: Фильтровать ошибки по определенным файлам или паттернам