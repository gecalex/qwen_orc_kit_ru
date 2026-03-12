---
name: extract-version
description: Анализ и проверка строк семантической версии из различных форматов. Используется для извлечения версий из текста, проверки соответствия semver или сравнения номеров версий.
---

# Навык извлечения версии

## Когда использовать
- При анализе строк версий из файлов конфигурации
- При проверке соответствия формату SemVer
- При сравнении номеров версий
- При извлечении версий из текста или вывода команд
- При анализе зависимостей и их версий
- При проверке совместимости версий
- При автоматическом определении текущей версии проекта

## Инструкции

### Фаза 1: Анализ входных данных
1.1. Определить формат входных данных (строка, файл, вывод команды)
1.2. Определить возможные форматы версий (SemVer, префикс v, дата и т.д.)
1.3. Подготовить регулярные выражения для извлечения версий
1.4. Определить приоритет форматов версий

### Фаза 2: Извлечение версий
2.1. Применить регулярные выражения к входным данным
2.2. Извлечь все возможные строки версий
2.3. Проверить каждую строку на соответствие формату SemVer
2.4. Классифицировать формат каждой версии

### Фаза 3: Валидация и нормализация
3.1. Проверить корректность извлеченных версий
3.2. Нормализовать формат версий к SemVer при возможности
3.3. Определить основную (наиболее подходящую) версию
3.4. Сформировать отчет о результатах извлечения

## Формат ввода
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

## Формат вывода
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

## Примеры

### Пример 1: Извлечение SemVer из строки
**Вход:**
```json
{
  "input": "Версия приложения: 2.4.1",
  "inputType": "text",
  "format": "semver"
}
```

**Выход:**
```json
{
  "primaryVersion": {
    "raw": "2.4.1",
    "normalized": "2.4.1",
    "isValid": true,
    "format": "semver",
    "components": {
      "major": 2,
      "minor": 4,
      "patch": 1,
      "preRelease": null,
      "buildMetadata": null
    }
  },
  "allVersions": [
    {
      "raw": "2.4.1",
      "normalized": "2.4.1",
      "isValid": true,
      "format": "semver",
      "position": 18
    }
  ],
  "metadata": {
    "totalFound": 1,
    "validCount": 1,
    "invalidCount": 0,
    "formatsDetected": ["semver"]
  }
}
```

### Пример 2: Извлечение версии с префиксом v
**Вход:**
```json
{
  "input": "git tag v1.2.3-beta+build.456",
  "inputType": "commandOutput",
  "format": "withV"
}
```

**Выход:**
```json
{
  "primaryVersion": {
    "raw": "v1.2.3-beta+build.456",
    "normalized": "1.2.3-beta+build.456",
    "isValid": true,
    "format": "withV",
    "components": {
      "major": 1,
      "minor": 2,
      "patch": 3,
      "preRelease": "beta",
      "buildMetadata": "build.456"
    }
  },
  "allVersions": [
    {
      "raw": "v1.2.3-beta+build.456",
      "normalized": "1.2.3-beta+build.456",
      "isValid": true,
      "format": "withV",
      "position": 8
    }
  ],
  "metadata": {
    "totalFound": 1,
    "validCount": 1,
    "invalidCount": 0,
    "formatsDetected": ["withV"]
  }
}
```

### Пример 3: Извлечение нескольких версий
**Вход:**
```json
{
  "input": "Зависимости: react@18.2.0, vue@3.2.45, angular~15.1.0",
  "inputType": "text",
  "returnAllMatches": true
}
```

**Выход:**
```json
{
  "primaryVersion": {
    "raw": "18.2.0",
    "normalized": "18.2.0",
    "isValid": true,
    "format": "semver",
    "components": {
      "major": 18,
      "minor": 2,
      "patch": 0,
      "preRelease": null,
      "buildMetadata": null
    }
  },
  "allVersions": [
    {
      "raw": "18.2.0",
      "normalized": "18.2.0",
      "isValid": true,
      "format": "semver",
      "position": 14
    },
    {
      "raw": "3.2.45",
      "normalized": "3.2.45",
      "isValid": true,
      "format": "semver",
      "position": 25
    },
    {
      "raw": "15.1.0",
      "normalized": "15.1.0",
      "isValid": true,
      "format": "semver",
      "position": 38
    }
  ],
  "metadata": {
    "totalFound": 3,
    "validCount": 3,
    "invalidCount": 0,
    "formatsDetected": ["semver"]
  }
}
```

### Пример 4: Извлечение версии из package.json
**Вход:**
```json
{
  "input": "{ \"name\": \"my-app\", \"version\": \"4.0.0-alpha.2\" }",
  "inputType": "file",
  "format": "semver"
}
```

**Выход:**
```json
{
  "primaryVersion": {
    "raw": "4.0.0-alpha.2",
    "normalized": "4.0.0-alpha.2",
    "isValid": true,
    "format": "semver",
    "components": {
      "major": 4,
      "minor": 0,
      "patch": 0,
      "preRelease": "alpha.2",
      "buildMetadata": null
    }
  },
  "allVersions": [
    {
      "raw": "4.0.0-alpha.2",
      "normalized": "4.0.0-alpha.2",
      "isValid": true,
      "format": "semver",
      "position": 32
    }
  ],
  "metadata": {
    "totalFound": 1,
    "validCount": 1,
    "invalidCount": 0,
    "formatsDetected": ["semver"]
  }
}
```

### Пример 5: Извлечение версии с использованием пользовательского регулярного выражения
**Вход:**
```json
{
  "input": "Версия: 2023.1.2 (сборка 4567)",
  "inputType": "text",
  "regexPattern": "\\b(\\d{4}\\.\\d+\\.\\d+(?:\\.\\d+)?)\\b",
  "format": "custom"
}
```

**Выход:**
```json
{
  "primaryVersion": {
    "raw": "2023.1.2",
    "normalized": "2023.1.2",
    "isValid": false,
    "format": "custom",
    "components": {
      "major": 2023,
      "minor": 1,
      "patch": 2,
      "preRelease": null,
      "buildMetadata": null
    }
  },
  "allVersions": [
    {
      "raw": "2023.1.2",
      "normalized": "2023.1.2",
      "isValid": false,
      "format": "custom",
      "position": 8
    }
  ],
  "metadata": {
    "totalFound": 1,
    "validCount": 0,
    "invalidCount": 1,
    "formatsDetected": ["custom"]
  }
}
```

## Поддерживаемые форматы версий

### SemVer (Semantic Versioning)
- Формат: `MAJOR.MINOR.PATCH`
- Пример: `1.2.3`
- С дополнительными элементами: `1.2.3-alpha.1+build.2012`

### С префиксом v
- Формат: `vMAJOR.MINOR.PATCH`
- Пример: `v1.2.3`

### На основе даты
- Формат: `YYYY.MM.DD` или `YY.MM.DD`
- Пример: `2023.1.15`

### Пользовательский
- Любой формат, определенный пользовательским регулярным выражением

## Правила валидации SemVer

1. Major, minor и patch должны быть неотрицательными целыми числами
2. Pre-release идентификаторы должны состоять из алфавитно-цифровых символов и дефисов
3. Build metadata может содержать любые символы, кроме `+`
4. Pre-release идентификаторы не должны начинаться с ведущих нулей
5. Major, minor и patch не должны содержать ведущие нули

## Параметры фильтрации

- `allowPreRelease`: Разрешить версии с pre-release идентификаторами (например, `-alpha`, `-beta`)
- `allowBuildMetadata`: Разрешить версии с build metadata (например, `+build.123`)
- `returnAllMatches`: Вернуть все найденные версии, а не только первую
- `regexPattern`: Пользовательское регулярное выражение для извлечения версий