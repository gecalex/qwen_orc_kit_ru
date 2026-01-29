---
name: parse-error-logs
description: Разбор ошибок сборки, сбоев тестов, вывода проверки типов и журналов проверки в структурированные данные. Используется при обработке вывода npm/pnpm, ошибок TypeScript, сбоев Jest или любых результатов команд проверки для контрольных точек качества.
allowed-tools: Read
---

# Разбор журналов ошибок

Разбор ошибок и вывода проверки из различных инструментов в структурированные, пригодные для использования данные.

## Когда использовать

- Проверка контрольных точек качества (проверка типов, сборка, тесты)
- Разбор ошибок компилятора TypeScript
- Извлечение информации о сбоях тестов
- Обработка вывода команд npm/pnpm
- Резюмирование результатов проверки
- Подача данных об ошибках в исправитель ошибок или другие рабочие процессы

## Инструкции

### Шаг 1: Получение необработанного вывода

Принять необработанный вывод команды в качестве входных данных.

**Ожидаемый ввод**:
- `output`: Строка (необработанный stdout/stderr от команды)
- `type`: Строка (typescript|jest|npm|build|generic)

### Шаг 2: Идентификация шаблонов ошибок

Обнаружение шаблонов ошибок на основе типа.

**Шаблоны TypeScript**:
```
error TS2322: Type 'string' is not assignable to type 'number'.
src/file.ts(10,5): error TS2322
```

**Шаблоны Jest**:
```
FAIL src/test.spec.ts
● Test Suite › test name
  Expected: 5
  Received: 3
```

**Шаблоны npm/pnpm**:
```
ERR! code ENOENT
ERR! syscall open
ERR! path /path/to/file
```

**Шаблоны сборки**:
```
ERROR in ./src/file.ts
Module not found: Error: Can't resolve 'module'
```

### Шаг 3: Извлечение деталей ошибки

Разбор каждой ошибки в структурированный формат.

**Для каждой ошибки извлекать**:
- `file`: Путь к файлу (если доступен)
- `line`: Номер строки (если доступен)
- `column`: Номер столбца (если доступен)
- `code`: Код ошибки (например, "TS2322", "ENOENT")
- `message`: Сообщение об ошибке
- `severity`: error|warning|info
- `type`: Классификация (type-error, test-failure, dependency и т.д.)

### Шаг 4: Классификация и подсчет

Группировка ошибок по типу и подсчет количества.

**Категории**:
- Ошибки типов
- Сбои тестов
- Проблемы с зависимостями
- Ошибки сборки
- Ошибки линтинга
- Ошибки выполнения

### Шаг 5: Возврат структурированных данных

Вернуть полный анализ ошибок.

**Ожидаемый вывод**:
```json
{
  "success": false,
  "totalErrors": 15,
  "totalWarnings": 3,
  "summary": {
    "typeErrors": 8,
    "testFailures": 5,
    "buildErrors": 2
  },
  "errors": [
    {
      "file": "src/utils.ts",
      "line": 42,
      "column": 10,
      "code": "TS2322",
      "message": "Type 'string' is not assignable to type 'number'",
      "severity": "error",
      "type": "type-error"
    }
  ],
  "warnings": [
    {
      "file": "src/deprecated.ts",
      "line": 15,
      "code": "TS6133",
      "message": "'oldFunction' is declared but never used",
      "severity": "warning",
      "type": "unused-variable"
    }
  ]
}
```

## Обработка ошибок

- **Пустой вывод**: Вернуть успех с нулевым количеством ошибок
- **Нераспознанный формат**: Вернуть общий разбор с исходным сообщением
- **Частичный разбор**: Включить то, что было разобрано, отметить неразборные строки
- **Неверный тип**: Выдать предупреждение и по умолчанию использовать разбор "generic"

## Примеры

### Пример 1: Ошибки TypeScript

**Ввод**:
```json
{
  "output": "src/app.ts(10,5): error TS2322: Type 'string' is not assignable to type 'number'.\nsrc/utils.ts(25,12): error TS2304: Cannot find name 'undefined'.",
  "type": "typescript"
}
```

**Вывод**:
```json
{
  "success": false,
  "totalErrors": 2,
  "totalWarnings": 0,
  "summary": {
    "typeErrors": 2
  },
  "errors": [
    {
      "file": "src/app.ts",
      "line": 10,
      "column": 5,
      "code": "TS2322",
      "message": "Type 'string' is not assignable to type 'number'",
      "severity": "error",
      "type": "type-error"
    },
    {
      "file": "src/utils.ts",
      "line": 25,
      "column": 12,
      "code": "TS2304",
      "message": "Cannot find name 'undefined'",
      "severity": "error",
      "type": "type-error"
    }
  ],
  "warnings": []
}
```

### Пример 2: Сбои тестов Jest

**Ввод**:
```json
{
  "output": "FAIL src/utils.test.ts\n  ● Math › addition\n    expect(received).toBe(expected)\n    Expected: 5\n    Received: 3\n      at Object.<anonymous> (src/utils.test.ts:10:15)",
  "type": "jest"
}
```

**Вывод**:
```json
{
  "success": false,
  "totalErrors": 1,
  "totalWarnings": 0,
  "summary": {
    "testFailures": 1
  },
  "errors": [
    {
      "file": "src/utils.test.ts",
      "line": 10,
      "column": 15,
      "code": null,
      "message": "expect(received).toBe(expected) - Expected: 5, Received: 3",
      "severity": "error",
      "type": "test-failure",
      "testName": "Math › addition"
    }
  ],
  "warnings": []
}
```

### Пример 3: Успешная сборка

**Ввод**:
```json
{
  "output": "✓ Built successfully\nCompleted in 2.3s",
  "type": "build"
}
```

**Вывод**:
```json
{
  "success": true,
  "totalErrors": 0,
  "totalWarnings": 0,
  "summary": {},
  "errors": [],
  "warnings": []
}
```

### Пример 4: Смешанные ошибки и предупреждения

**Ввод**:
```json
{
  "output": "Warning: React Hook useEffect has a missing dependency\nerror TS2339: Property 'foo' does not exist on type 'Bar'",
  "type": "typescript"
}
```

**Вывод**:
```json
{
  "success": false,
  "totalErrors": 1,
  "totalWarnings": 1,
  "summary": {
    "typeErrors": 1,
    "lintWarnings": 1
  },
  "errors": [
    {
      "code": "TS2339",
      "message": "Property 'foo' does not exist on type 'Bar'",
      "severity": "error",
      "type": "type-error"
    }
  ],
  "warnings": [
    {
      "message": "React Hook useEffect has a missing dependency",
      "severity": "warning",
      "type": "lint-warning"
    }
  ]
}
```

## Валидация

- [ ] Правильно разбирает ошибки TypeScript
- [ ] Разбирает сбои тестов Jest
- [ ] Разбирает ошибки npm/pnpm
- [ ] Разбирает ошибки сборки
- [ ] Извлекает файл, строку, столбец при наличии
- [ ] Классифицирует ошибки по типу
- [ ] Возвращает итоговые подсчеты
- [ ] Обрабатывает успешный вывод (нулевые ошибки)
- [ ] Обрабатывает смешанные ошибки и предупреждения

## Вспомогательные файлы

- `patterns.json`: Регулярные выражения для распространенных форматов ошибок
