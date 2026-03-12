---
name: parse-git-status
description: Разбор вывода git status в структурированные данные, показывающие подготовленные, измененные и непроиндексированные файлы. Используется для предварительной проверки, проверки чистоты рабочего каталога или перечисления измененных файлов перед коммитами.
---

# Навык разбора статуса Git

## Когда использовать
- При проверке чистоты рабочего каталога перед выполнением операций
- При анализе измененных файлов перед коммитом
- При подготовке отчетов о состоянии репозитория
- При определении файлов, затронутых изменениями
- При проверке статуса перед слиянием или переключением веток
- При автоматизации процессов CI/CD

## Инструкции

### Фаза 1: Получение статуса
1.1. Выполнить команду `git status --porcelain` для получения структурированного вывода
1.2. Захватить вывод команды
1.3. Определить формат вывода (porcelain v1 или v2)
1.4. Подготовить структуру для разбора

### Фаза 2: Разбор статуса
2.1. Разделить вывод на строки
2.2. Для каждой строки определить статус файла
2.3. Извлечь имя файла и статусы (рабочий каталог и индекс)
2.4. Классифицировать файлы по типам изменений

### Фаза 3: Структурирование данных
3.1. Сгруппировать файлы по статусам (новые, измененные, удаленные и т.д.)
3.2. Определить, есть ли непроиндексированные изменения
3.3. Определить, есть ли подготовленные изменения
3.4. Сформировать отчет о состоянии репозитория

## Формат ввода
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

## Формат вывода
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

## Примеры

### Пример 1: Простой статус с изменениями
**Вход:**
```json
{
  "gitStatusOutput": "M  src/example.ts\nA  docs/new-feature.md\n?? tests/example.test.ts",
  "includeUntracked": true,
  "includeStaged": true,
  "includeUnstaged": true
}
```

**Выход:**
```json
{
  "repositoryState": {
    "isClean": false,
    "hasUncommittedChanges": true,
    "hasStagedChanges": true,
    "hasUnstagedChanges": true,
    "hasUntrackedFiles": true
  },
  "files": {
    "staged": [
      {
        "fileName": "docs/new-feature.md",
        "status": "added",
        "indexStatus": "A",
        "workingTreeStatus": " "
      }
    ],
    "unstaged": [
      {
        "fileName": "src/example.ts",
        "status": "modified",
        "indexStatus": " ",
        "workingTreeStatus": "M"
      }
    ],
    "untracked": [
      {
        "fileName": "tests/example.test.ts",
        "status": "untracked",
        "indexStatus": " ",
        "workingTreeStatus": "?"
      }
    ]
  },
  "summary": {
    "totalModified": 1,
    "totalAdded": 1,
    "totalDeleted": 0,
    "totalRenamed": 0,
    "totalUntracked": 1
  }
}
```

### Пример 2: Статус с переименованными файлами
**Вход:**
```json
{
  "gitStatusOutput": "R  old-name.ts -> new-name.ts\n D deleted-file.ts",
  "includeUntracked": true,
  "includeStaged": true,
  "includeUnstaged": true
}
```

**Выход:**
```json
{
  "repositoryState": {
    "isClean": false,
    "hasUncommittedChanges": true,
    "hasStagedChanges": true,
    "hasUnstagedChanges": true,
    "hasUntrackedFiles": false
  },
  "files": {
    "staged": [
      {
        "fileName": "new-name.ts",
        "status": "renamed",
        "indexStatus": "R",
        "workingTreeStatus": " ",
        "oldFileName": "old-name.ts"
      }
    ],
    "unstaged": [
      {
        "fileName": "deleted-file.ts",
        "status": "deleted",
        "indexStatus": " ",
        "workingTreeStatus": "D"
      }
    ],
    "untracked": []
  },
  "summary": {
    "totalModified": 0,
    "totalAdded": 0,
    "totalDeleted": 1,
    "totalRenamed": 1,
    "totalUntracked": 0
  }
}
```

### Пример 3: Чистый репозиторий
**Вход:**
```json
{
  "gitStatusOutput": "",
  "includeUntracked": true,
  "includeStaged": true,
  "includeUnstaged": true
}
```

**Выход:**
```json
{
  "repositoryState": {
    "isClean": true,
    "hasUncommittedChanges": false,
    "hasStagedChanges": false,
    "hasUnstagedChanges": false,
    "hasUntrackedFiles": false
  },
  "files": {
    "staged": [],
    "unstaged": [],
    "untracked": []
  },
  "summary": {
    "totalModified": 0,
    "totalAdded": 0,
    "totalDeleted": 0,
    "totalRenamed": 0,
    "totalUntracked": 0
  }
}
```

### Пример 4: Статус с фильтрацией по паттерну
**Вход:**
```json
{
  "gitStatusOutput": "M  src/example.ts\nA  docs/readme.md\nM  tests/example.test.ts\n?? config.json",
  "includeUntracked": true,
  "includeStaged": true,
  "includeUnstaged": true,
  "filePattern": "src/*"
}
```

**Выход:**
```json
{
  "repositoryState": {
    "isClean": false,
    "hasUncommittedChanges": true,
    "hasStagedChanges": false,
    "hasUnstagedChanges": true,
    "hasUntrackedFiles": false
  },
  "files": {
    "staged": [],
    "unstaged": [
      {
        "fileName": "src/example.ts",
        "status": "modified",
        "indexStatus": " ",
        "workingTreeStatus": "M"
      }
    ],
    "untracked": []
  },
  "summary": {
    "totalModified": 1,
    "totalAdded": 0,
    "totalDeleted": 0,
    "totalRenamed": 0,
    "totalUntracked": 0
  }
}
```

## Коды статусов Git

### Индекс (staging area)
- `A` - добавленный файл
- `M` - измененный файл
- `D` - удаленный файл
- `R` - переименованный файл
- `C` - скопированный файл
- `U` - файл с конфликтом слияния

### Рабочее дерево
- `M` - измененный файл
- `D` - удаленный файл
- `?` - непроиндексированный файл
- `!` - проигнорированный файл
- `T` - измененный тип файла

## Параметры фильтрации

- `includeUntracked`: Включать непроиндексированные файлы в результат
- `includeStaged`: Включать подготовленные изменения в результат
- `includeUnstaged`: Включать непроиндексированные изменения в результат
- `filePattern`: Фильтровать файлы по glob-паттерну
- `excludePattern`: Исключать файлы по glob-паттерну