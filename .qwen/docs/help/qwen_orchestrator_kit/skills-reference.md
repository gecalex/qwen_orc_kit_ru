# Справочник по навыкам Qwen Orchestrator Kit

## Обзор

Навыки (skills) - это переиспользуемые функции, которые агенты могут вызывать для выполнения часто используемых операций. Навыки обеспечивают согласованность и упрощают разработку агентов.

## Каталог навыков

### 1. generate-report-header (Генерация заголовков отчетов)

**Назначение**: Создает стандартизованные заголовки отчетов с метаданными для всех отчетов, генерируемых агентом.

**Когда использовать**: 
- При создании любого отчета агентом
- При формировании заголовков для отчетов об ошибках
- При создании отчетов по аудиту безопасности
- При генерации отчетов о зависимостях

**Формат ввода**:
```json
{
  "reportType": "string",
  "agentName": "string",
  "version": "string",
  "timestamp": "ISO 8601 string",
  "status": "success|error|warning|info",
  "additionalMetadata": {}
}
```

**Формат вывода**:
```markdown
# {reportType} Отчет: {version}

**Агент**: {agentName}  
**Статус**: {status}  
**Дата создания**: {timestamp}  
**Дополнительные метаданные**: {additionalMetadata}

---

## Исполнительное резюме

[Краткое описание содержания отчета]

---
```

### 2. run-quality-gate (Выполнение контрольных точек качества)

**Назначение**: Выполнение проверки качества с настраиваемым поведением блокировки. Используется при запуске проверки типов, сборки, тестов, линтинга или пользовательских команд проверки.

**Когда использовать**:
- При запуске проверки типов перед коммитом
- При выполнении сборки проекта
- При запуске тестов в процессе CI/CD
- При выполнении линтинга кода

**Формат ввода**:
```json
{
  "command": "string",
  "isBlocking": "boolean",
  "expectedResult": "string",
  "timeout": "integer (seconds)",
  "workingDirectory": "string (optional)",
  "environmentVariables": {},
  "continueOnFailure": "boolean (optional)"
}
```

**Формат вывода**:
```json
{
  "status": "passed|failed|blocked|timeout",
  "output": "string",
  "exitCode": "integer",
  "executionTime": "float (seconds)",
  "wasBlocking": "boolean",
  "resultMatchedExpected": "boolean",
  "actionTaken": "string"
}
```

### 3. format-markdown-table (Форматирование таблиц markdown)

**Назначение**: Генерация правильно отформатированных таблиц markdown из данных с правильным выравниванием и интервалами.

**Когда использовать**:
- При создании таблиц в отчетах
- При генерации сравнительных таблиц
- При форматировании статистических данных
- При создании сводных таблиц

**Формат ввода**:
```json
{
  "headers": ["string"],
  "rows": [
    ["string"]
  ],
  "alignments": ["left|center|right"] (optional),
  "title": "string (optional)",
  "caption": "string (optional)"
}
```

**Формат вывода**:
```markdown
[title (если указан)]

| [header1] | [header2] | ... |
|:---------|:---------:|----:|
| [cell1]   | [cell2]   | ... |
| ...       | ...       | ... |

[caption (если указан)]
```

### 4. parse-error-logs (Разбор логов ошибок)

**Назначение**: Разбор ошибок сборки, сбоев тестов, вывода проверки типов и журналов проверки в структурированные данные.

**Когда использовать**:
- При обработке вывода команд npm/pnpm
- При анализе ошибок TypeScript
- При разборе сбоев тестов Jest
- При анализе результатов проверки типов

**Формат ввода**:
```json
{
  "logType": "typescript|jest|npm|eslint|other",
  "logContent": "string",
  "maxErrors": "integer (optional, default: 10)",
  "includeWarnings": "boolean (optional, default: false)",
  "fileFilter": "string (optional, path pattern)"
}
```

**Формат вывода**:
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

### 5. parse-git-status (Разбор статуса Git)

**Назначение**: Разбор вывода git status в структурированные данные, показывающие подготовленные, измененные и непроиндексированные файлы.

**Когда использовать**:
- При проверке чистоты рабочего каталога перед выполнением операций
- При анализе измененных файлов перед коммитом
- При подготовке отчетов о состоянии репозитория
- При определении файлов, затронутых изменениями

**Формат ввода**:
```json
{
  "gitStatusOutput": "string",
  "includeUntracked": "boolean (optional, default: true)",
  "includeStaged": "boolean (optional, default: true)",
  "includeUnstaged": "boolean (optional, default: true)",
  "filePattern": "string (optional, glob pattern)",
  "excludePattern": "string (optional, glob pattern)"
}
```

**Формат вывода**:
```json
{
  "repositoryState": {
    "isClean": "boolean",
    "hasUncommittedChanges": "boolean",
    "hasStagedChanges": "boolean",
    "hasUnstagedChanges": "boolean",
    "hasUntrackedFiles": "boolean"
  },
  "files": {
    "staged": [
      {
        "fileName": "string",
        "status": "added|modified|deleted|renamed|copied",
        "indexStatus": "A|M|D|R|C",
        "workingTreeStatus": " ",
        "oldFileName": "string (for renamed files)"
      }
    ],
    "unstaged": [
      {
        "fileName": "string",
        "status": "modified|deleted|untracked|typeChanged",
        "indexStatus": " ",
        "workingTreeStatus": "M|D|?|T",
        "oldFileName": "string (for renamed files)"
      }
    ],
    "untracked": [
      {
        "fileName": "string",
        "status": "untracked",
        "indexStatus": " ",
        "workingTreeStatus": "?"
      }
    ]
  },
  "summary": {
    "totalModified": "integer",
    "totalAdded": "integer",
    "totalDeleted": "integer",
    "totalRenamed": "integer",
    "totalUntracked": "integer"
  }
}
```

### 6. extract-version (Извлечение версии)

**Назначение**: Анализ и проверка строк семантической версии из различных форматов.

**Когда использовать**:
- При анализе строк версий из файлов конфигурации
- При проверке соответствия формату SemVer
- При сравнении номеров версий
- При извлечении версий из текста или вывода команд

**Формат ввода**:
```json
{
  "input": "string",
  "inputType": "text|file|commandOutput",
  "format": "semver|withV|date|custom (optional, default: semver)",
  "allowPreRelease": "boolean (optional, default: true)",
  "allowBuildMetadata": "boolean (optional, default: true)",
  "regexPattern": "string (optional, custom regex)",
  "returnAllMatches": "boolean (optional, default: false)"
}
```

**Формат вывода**:
```json
{
  "primaryVersion": {
    "raw": "string",
    "normalized": "string",
    "isValid": "boolean",
    "format": "semver|withV|date|custom",
    "components": {
      "major": "integer",
      "minor": "integer",
      "patch": "integer",
      "preRelease": "string (optional)",
      "buildMetadata": "string (optional)"
    }
  },
  "allVersions": [
    {
      "raw": "string",
      "normalized": "string",
      "isValid": "boolean",
      "format": "semver|withV|date|custom",
      "position": "integer (position in input)"
    }
  ],
  "metadata": {
    "totalFound": "integer",
    "validCount": "integer",
    "invalidCount": "integer",
    "formatsDetected": ["string"]
  }
}
```

## Использование навыков в агентах

Агенты могут вызывать навыки с помощью инструмента `skill`:

```
skill: "generate-report-header" {
  "reportType": "Анализ безопасности",
  "agentName": "security-analyzer",
  "version": "1.0.0",
  "timestamp": "2026-01-31T10:00:00Z",
  "status": "success"
}
```

## Создание новых навыков

Для создания нового навыка:

1. Создайте директорию в `.qwen/skills/{название-навыка}/`
2. Внутри создайте файл `SKILL.md` со следующей структурой:
   - YAML заголовок с именем и описанием
   - Раздел "Когда использовать" - описывает, когда использовать навык
   - Раздел "Инструкции" - пошаговое описание логики
   - Форматы ввода и вывода
   - Примеры использования

### Структура файла навыка

```markdown
---
name: имя-навыка
description: Краткое описание функций навыка
---

# Имя навыка

## Когда использовать
- Сценарий 1
- Сценарий 2

## Инструкции
1. Шаг 1
2. Шаг 2

## Формат ввода
{Ожидаемая структура ввода}

## Формат вывода
{Ожидаемая структура вывода}

## Примеры
{Примеры использования}
```

## Рекомендации по разработке навыков

1. **Фокус на одну задачу**: Навык должен выполнять одну конкретную задачу
2. **Повторное использование**: Создавайте навыки, которые могут использоваться в нескольких агентах
3. **Ясные интерфейсы**: Обеспечьте четкие форматы ввода и вывода
4. **Обработка ошибок**: Включите обработку ошибок и граничные случаи
5. **Документация**: Хорошо документируйте, когда и как использовать навык