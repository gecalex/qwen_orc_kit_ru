# Тесты для навыков системы

## Тесты для навыка generate-report-header

### Тест 1: Создание базового заголовка отчета
- **Вход**: `{ "reportType": "Тест", "agentName": "test-agent", "version": "1.0.0", "timestamp": "2026-01-31T10:00:00Z", "status": "success" }`
- **Ожидаемый результат**: Корректно сформированный заголовок с указанными параметрами

### Тест 2: Создание заголовка с дополнительными метаданными
- **Вход**: `{ "reportType": "Баг-охотник", "agentName": "bug-hunter", "version": "1.0.0", "timestamp": "2026-01-31T10:00:00Z", "status": "success", "additionalMetadata": { "bugsFound": 5 } }`
- **Ожидаемый результат**: Заголовок с корректно включенными дополнительными метаданными

### Тест 3: Создание заголовка с ошибкой
- **Вход**: `{ "reportType": "Аудит безопасности", "agentName": "security-analyzer", "version": "2.1.0", "timestamp": "2026-01-31T10:00:00Z", "status": "error" }`
- **Ожидаемый результат**: Заголовок с корректно указанным статусом ошибки

## Тесты для навыка run-quality-gate

### Тест 4: Успешная проверка типизации
- **Вход**: `{ "command": "echo 'No type errors found'", "isBlocking": true, "expectedResult": "No type errors found", "timeout": 30 }`
- **Ожидаемый результат**: Статус "passed", actionTaken: "Continuing execution"

### Тест 5: Неудачная блокирующая проверка
- **Вход**: `{ "command": "echo 'Type error: string is not assignable to number'", "isBlocking": true, "expectedResult": "No type errors found", "timeout": 30 }`
- **Ожидаемый результат**: Статус "failed", wasBlocking: true, actionTaken: "Blocked execution due to errors"

### Тест 6: Неудачная неблокирующая проверка
- **Вход**: `{ "command": "echo 'Warning: unused variable'", "isBlocking": false, "expectedResult": "No warnings found", "timeout": 30 }`
- **Ожидаемый результат**: Статус "failed", wasBlocking: false, actionTaken: "Logged warning, continuing execution"

## Тесты для навыка format-markdown-table

### Тест 7: Форматирование простой таблицы
- **Вход**: `{ "headers": ["Имя", "Возраст"], "rows": [["Иван", "30"], ["Мария", "25"]] }`
- **Ожидаемый результат**: Корректно отформатированная markdown таблица с заголовками и строками

### Тест 8: Форматирование таблицы с выравниванием
- **Вход**: `{ "headers": ["Функция", "Статус", "Время"], "rows": [["Создание", "Успешно", "2.5s"]], "alignments": ["left", "center", "right"] }`
- **Ожидаемый результат**: Таблица с корректным выравниванием столбцов

### Тест 9: Форматирование таблицы с заголовком
- **Вход**: `{ "title": "Статистика", "headers": ["Метрика", "Значение"], "rows": [["Покрытие", "85%"]] }`
- **Ожидаемый результат**: Таблица с заголовком и корректным форматированием

## Тесты для навыка parse-error-logs

### Тест 10: Разбор ошибок TypeScript
- **Вход**: `{ "logType": "typescript", "logContent": "src/example.ts(5,10): error TS2532: Object is possibly 'undefined'." }`
- **Ожидаемый результат**: Структурированные данные с информацией об ошибке TypeScript

### Тест 11: Разбор ошибок тестов Jest
- **Вход**: `{ "logType": "jest", "logContent": "FAIL src/__tests__/example.test.ts\n  ● Test failed\n    Expected: 5\n    Received: 4" }`
- **Ожидаемый результат**: Структурированные данные с информацией о сбое теста

### Тест 12: Разбор ошибок линтера
- **Вход**: `{ "logType": "eslint", "logContent": "src/example.ts\n  5:10  error  Missing semicolon  semi", "includeWarnings": true }`
- **Ожидаемый результат**: Структурированные данные с информацией об ошибке линтера

## Тесты для навыка parse-git-status

### Тест 13: Разбор статуса с измененными файлами
- **Вход**: `{ "gitStatusOutput": "M  src/example.ts\nA  docs/readme.md", "includeUntracked": true, "includeStaged": true, "includeUnstaged": true }`
- **Ожидаемый результат**: Структурированные данные с информацией о подготовленных и неподготовленных изменениях

### Тест 14: Разбор статуса с непроиндексированными файлами
- **Вход**: `{ "gitStatusOutput": "?? new-file.ts\n D deleted-file.ts", "includeUntracked": true, "includeStaged": true, "includeUnstaged": true }`
- **Ожидаемый результат**: Структурированные данные с информацией о непроиндексированных и удаленных файлах

### Тест 15: Разбор статуса с переименованными файлами
- **Вход**: `{ "gitStatusOutput": "R  old-name.ts -> new-name.ts", "includeUntracked": true, "includeStaged": true, "includeUnstaged": true }`
- **Ожидаемый результат**: Структурированные данные с информацией о переименованных файлах

## Тесты для навыка extract-version

### Тест 16: Извлечение SemVer версии
- **Вход**: `{ "input": "Версия приложения: 2.4.1", "inputType": "text", "format": "semver" }`
- **Ожидаемый результат**: Структурированные данные с извлеченной версией 2.4.1

### Тест 17: Извлечение версии с префиксом v
- **Вход**: `{ "input": "git tag v1.2.3-beta+build.456", "inputType": "commandOutput", "format": "withV" }`
- **Ожидаемый результат**: Структурированные данные с извлеченной версией v1.2.3-beta+build.456

### Тест 18: Извлечение нескольких версий
- **Вход**: `{ "input": "Зависимости: react@18.2.0, vue@3.2.45", "inputType": "text", "returnAllMatches": true }`
- **Ожидаемый результат**: Структурированные данные со всеми извлеченными версиями

## Интеграционные тесты

### Тест 19: Использование навыков вместе
- **Сценарий**: Использование parse-error-logs для разбора логов, затем generate-report-header для создания отчета об ошибках
- **Ожидаемый результат**: Корректно сформированный отчет с информацией из логов ошибок

### Тест 20: Комплексный сценарий проверки качества
- **Сценарий**: Использование run-quality-gate для проверки, parse-git-status для проверки состояния репозитория, extract-version для определения версии
- **Ожидаемый результат**: Комплексная проверка состояния проекта с использованием нескольких навыков