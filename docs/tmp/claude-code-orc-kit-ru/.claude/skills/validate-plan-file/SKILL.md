---
name: validate-plan-file
description: Проверка соответствия файлов плана оркестратора ожидаемой схеме JSON. Используется перед тем, как рабочие процессы читают файлы плана, или после создания оркестраторами для обеспечения правильной структуры и обязательных полей.
allowed-tools: Read
---

# Проверка файла плана

Проверка файлов плана оркестратора на соответствие ожидаемой схеме перед тем, как рабочие процессы их обрабатывают.

## Когда использовать

- Перед тем, как рабочие процессы читают файлы плана
- После создания файлов плана оркестраторами
- При отладке проблем с файлами плана
- При проверке контрольных точек качества

## Инструкции

### Шаг 1: Чтение файла плана

Использовать инструмент Read для загрузки файла плана.

**Ожидаемый ввод**:
- `file_path`: Путь к файлу плана (например, `.bug-detection-plan.json`, `.security-scan-plan.json`)

**Используемые инструменты**: Read

### Шаг 2: Определение схемы

Сопоставление шаблона имени файла с соответствующей схемой JSON.

**Сопоставление схем**:
- `.bug-*-plan.json` → `.claude/schemas/bug-plan.schema.json`
- `.security-*-plan.json` → `.claude/schemas/security-plan.schema.json`
- `.dead-code-*-plan.json` → `.claude/schemas/dead-code-plan.schema.json`
- `.dependency-*-plan.json` → `.claude/schemas/dependency-plan.schema.json`
- `.version-*-plan.json` → базовая схема (рабочий процесс обновления версии)

**Новое соглашение об именовании** (стандартизированное):
- Рабочий процесс ошибок: `.bug-detection-plan.json`, `.bug-fixing-plan.json`, `.bug-verification-plan.json`
- Рабочий процесс безопасности: `.security-scan-plan.json`, `.security-remediation-plan.json`, `.security-verification-plan.json`
- Рабочий процесс мертвого кода: `.dead-code-detection-plan.json`, `.dead-code-cleanup-plan.json`, `.dead-code-verification-plan.json`
- Рабочий процесс зависимостей: `.dependency-audit-plan.json`, `.dependency-update-plan.json`, `.dependency-verification-plan.json`

### Шаг 3: Загрузка и разбор схемы JSON

Использовать инструмент Read для загрузки соответствующего файла схемы из `.claude/schemas/`.

**Используемые инструменты**: Read

### Шаг 4: Проверка JSON по схеме

Проверка содержимого файла плана по загруженной схеме JSON.

**Проверка базовой схемы** (все файлы плана):
- `workflow`: Строка (обязательно, например, "bug-management", "security-audit")
- `phase`: Строка (обязательно, например, "detection", "fixing", "verification")
- `phaseNumber`: Целое число (необязательно, для последовательности)
- `config`: Объект (обязательно, конфигурация, специфичная для домена)
- `validation`: Объект (обязательно, с массивом `required` критериев проверки)
- `nextAgent`: Строка (необязательно, следующий агент для вызова)
- `timestamp`: Строка (необязательно, формат ISO-8601)
- `metadata`: Объект (необязательно, с `createdBy`, `iteration`, `maxIterations`)

**Проверка, специфичная для домена**:

**Планы ошибок**:
- `config.priority`: "critical"|"high"|"medium"|"low"|"all" (обязательно)
- `config.categories`: Массив типов ошибок (необязательно)
- `config.maxBugsPerRun`: Целое число (необязательно, по умолчанию 50)
- `config.verifyOnly`: Boolean (необязательно, по умолчанию false)

**Планы безопасности**:
- `config.severity`: "critical"|"high"|"medium"|"low"|"all" (обязательно)
- `config.categories`: Массив типов уязвимостей (необязательно)
- `config.maxVulnsPerRun`: Целое число (необязательно, по умолчанию 25)
- `config.skipSupabaseRLS`: Boolean (необязательно, по умолчанию false)

**Планы мертвого кода**:
- `config.type`: "critical"|"high"|"medium"|"low"|"all" (обязательно)
- `config.categories`: Массив типов мертвого кода (необязательно)
- `config.maxItemsPerRun`: Целое число (необязательно, по умолчанию 100)
- `config.safeMode`: Boolean (необязательно, по умолчанию true)

**Планы зависимостей**:
- `config.category`: "security"|"unused"|"outdated"|"all" (обязательно)
- `config.severity`: "critical"|"high"|"medium"|"low"|"all" (необязательно)
- `config.maxUpdatesPerRun`: Целое число (необязательно, по умолчанию 10)
- `config.updateStrategy`: "one-at-a-time"|"batch-compatible"|"all" (необязательно)

### Шаг 5: Возврат результата проверки

Вернуть подробный результат проверки с ошибками/предупреждениями.

**Ожидаемый вывод**:
```json
{
  "valid": true,
  "file": ".bug-detection-plan.json",
  "errors": [],
  "warnings": [],
  "schema": "bug-plan",
  "schemaPath": ".claude/schemas/bug-plan.schema.json"
}
```

## Обработка ошибок

- **Файл не найден**: Вернуть ошибку с путем к файлу
- **Неверный JSON**: Вернуть ошибку разбора с номером строки, если возможно
- **Файл схемы не найден**: Вернуть ошибку, если файл схемы отсутствует
- **Отсутствуют обязательные поля**: Перечислить все отсутствующие поля из проверки схемы JSON
- **Неверные типы полей**: Описать несоответствия типов (например, ожидается строка, получено число)
- **Неверные значения перечисления**: Сообщить, когда значение не входит в разрешенный список перечисления
- **Несоответствие схемы**: Предупредить, если файл не соответствует ожидаемому шаблону схемы
- **Ошибки массива проверки**: Сообщить о пропущенных или недействительных критериях проверки

## Примеры

### Пример 1: Действительный план обнаружения ошибок

**Ввод**:
```
file_path: .bug-detection-plan.json
```

**Содержимое**:
```json
{
  "workflow": "bug-management",
  "phase": "detection",
  "phaseNumber": 1,
  "config": {
    "priority": "all",
    "categories": ["type-errors", "runtime-errors"],
    "maxBugsPerRun": 50
  },
  "validation": {
    "required": ["report-exists", "type-check"],
    "optional": ["tests"]
  },
  "nextAgent": "bug-hunter",
  "timestamp": "2025-10-18T14:00:00Z",
  "metadata": {
    "createdBy": "bug-orchestrator",
    "iteration": 1,
    "maxIterations": 3
  }
}
```

**Вывод**:
```json
{
  "valid": true,
  "file": ".bug-detection-plan.json",
  "errors": [],
  "warnings": [],
  "schema": "bug-plan",
  "schemaPath": ".claude/schemas/bug-plan.schema.json"
}
```

### Пример 2: Отсутствует обязательное поле

**Ввод**:
```
file_path: .security-scan-plan.json
```

**Содержимое**:
```json
{
  "workflow": "security-audit",
  "phase": "scan",
  "config": {
    "categories": ["sql-injection"]
  },
  "validation": {
    "required": ["report-exists"]
  }
}
```

**Вывод**:
```json
{
  "valid": false,
  "file": ".security-scan-plan.json",
  "errors": [
    "Missing required property: config.severity",
    "Schema validation failed at /config/severity: required property missing"
  ],
  "warnings": [],
  "schema": "security-plan",
  "schemaPath": ".claude/schemas/security-plan.schema.json"
}
```

### Пример 3: Неверное значение перечисления

**Ввод**:
```
file_path: .dependency-audit-plan.json
```

**Содержимое**:
```json
{
  "workflow": "dependency-management",
  "phase": "audit",
  "config": {
    "category": "deprecated",
    "severity": "critical"
  },
  "validation": {
    "required": ["report-exists", "lockfile-valid"]
  },
  "nextAgent": "dependency-auditor"
}
```

**Вывод**:
```json
{
  "valid": false,
  "file": ".dependency-audit-plan.json",
  "errors": [
    "Invalid enum value at /config/category: 'deprecated' not in allowed values ['security', 'unused', 'outdated', 'all']"
  ],
  "warnings": [],
  "schema": "dependency-plan",
  "schemaPath": ".claude/schemas/dependency-plan.schema.json"
}
```

### Пример 4: Несоответствие рабочего процесса/фазы

**Ввод**:
```
file_path: .bug-fixing-plan.json
```

**Содержимое**:
```json
{
  "workflow": "security-audit",
  "phase": "fixing",
  "config": {
    "priority": "critical"
  },
  "validation": {
    "required": ["type-check"]
  }
}
```

**Вывод**:
```json
{
  "valid": false,
  "file": ".bug-fixing-plan.json",
  "errors": [
    "Schema mismatch: file pattern suggests 'bug-plan' schema but workflow field is 'security-audit'",
    "Invalid enum value at /phase: 'fixing' not in allowed values ['detection', 'fixing', 'verification'] for bug-plan"
  ],
  "warnings": [
    "Consider renaming file to match workflow: .security-remediation-plan.json"
  ],
  "schema": "bug-plan",
  "schemaPath": ".claude/schemas/bug-plan.schema.json"
}
```

## Проверка

- [ ] Проверяет наличие всех обязательных полей
- [ ] Проверяет типы полей правильно (строка, число, boolean, массив, объект)
- [ ] Проверяет значения перечисления по разрешенным спискам
- [ ] Определяет схему по шаблону имени файла
- [ ] Возвращает четкие сообщения об ошибках с путями JSON
- [ ] Корректно обрабатывает неправильно сформированный JSON
- [ ] Проверяет поля, специфичные для домена (приоритет, серьезность, категория)
- [ ] Проверяет согласованность рабочего процесса/фазы
- [ ] Проверяет массивы критериев проверки (обязательные/необязательные)
- [ ] Обрабатывает ошибки загрузки файла схемы

## Вспомогательные файлы

Расположены в `.claude/schemas/`:
- `base-plan.schema.json`: Базовая схема для всех файлов плана
- `bug-plan.schema.json`: Схема рабочего процесса управления ошибками
- `security-plan.schema.json`: Схема рабочего процесса аудита безопасности
- `dead-code-plan.schema.json`: Схема рабочего процесса очистки мертвого кода
- `dependency-plan.schema.json`: Схема рабочего процесса управления зависимостями

## Интеграция с оркестраторами

Все оркестраторы должны использовать этот навык после создания файлов плана:

```markdown
## Шаг 3: Создание файла плана

1. Записать план в `.{domain}-{phase}-plan.json`
2. Использовать навык validate-plan-file для проверки:
   - Ввод: file_path = ".{domain}-{phase}-plan.json"
   - Проверить result.valid === true
   - Если ошибки существуют, исправить файл плана и повторить
3. Сигнализировать готовность только после прохождения проверки
```

## Примечания

**Проверка схемы JSON**: Этот навык выполняет полную проверку схемы JSON Draft-07, включая:
- Проверку типов (строка, число, boolean, массив, объект)
- Обязательные свойства
- Ограничения перечисления
- Сопоставление шаблонов
- Проверку вложенных объектов (allOf, $ref)
- Проверку элементов массива

**Соглашение об именовании файлов**: Файлы плана должны следовать шаблону `.{domain}-{phase}-plan.json`, где:
- `{domain}`: bug|security|dead-code|dependency
- `{phase}`: detection|fixing|verification (ошибки), scan|remediation|verification (безопасность) и т.д.

**Ссылки на схемы**: Использует `$ref` схемы JSON для наследования базовой схемы. Все схемы доменов расширяют `base-plan.schema.json`.
