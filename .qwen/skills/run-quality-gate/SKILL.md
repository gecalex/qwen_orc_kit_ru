---
name: run-quality-gate
description: Выполнение проверки качества с настраиваемым поведением блокировки
user-invocable: false
---

# Навык выполнения контрольных точек качества

## Когда использовать
- При запуске проверки типов перед коммитом
- При выполнении сборки проекта
- При запуске тестов в процессе CI/CD
- При выполнении линтинга кода
- При запуске пользовательских команд проверки
- При реализации ворот качества в оркестраторах
- При обеспечении соответствия стандартам качества

## Инструкции

### Фаза 1: Подготовка к проверке
1.1. Определить команду для выполнения проверки
1.2. Установить режим блокировки (блокирующая или неблокирующая)
1.3. Установить ожидаемый результат
1.4. Установить таймаут выполнения

### Фаза 2: Выполнение проверки
2.1. Запустить команду проверки
2.2. Отследить результат выполнения
2.3. Записать вывод команды
2.4. Определить статус выполнения

### Фаза 3: Обработка результата
3.1. Сравнить результат с ожидаемым
3.2. Определить, является ли результат успешным
3.3. Если проверка блокирующая и результат неудовлетворительный - остановить процесс
3.4. Зарегистрировать результат в системе отчетности

## Формат ввода
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

## Формат вывода
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

## Примеры

### Пример 1: Проверка типизации TypeScript
**Вход:**
```json
{
  "command": "npx tsc --noEmit",
  "isBlocking": true,
  "expectedResult": "No type errors found",
  "timeout": 300
}
```

**Выход:**
```json
{
  "status": "passed",
  "output": "src/example.ts(5,10): error TS2532: Object is possibly 'undefined'.",
  "exitCode": 1,
  "executionTime": 4.2,
  "wasBlocking": true,
  "resultMatchedExpected": false,
  "actionTaken": "Blocked execution due to type errors"
}
```

### Пример 2: Проверка сборки
**Вход:**
```json
{
  "command": "npm run build",
  "isBlocking": true,
  "expectedResult": "Build completed successfully",
  "timeout": 600
}
```

**Выход:**
```json
{
  "status": "passed",
  "output": "Build successful. Output to dist/ directory.",
  "exitCode": 0,
  "executionTime": 15.7,
  "wasBlocking": true,
  "resultMatchedExpected": true,
  "actionTaken": "Continuing execution"
}
```

### Пример 3: Проверка линтинга
**Вход:**
```json
{
  "command": "npx eslint src/ --ext .js,.ts",
  "isBlocking": false,
  "expectedResult": "No lint errors found",
  "timeout": 120
}
```

**Выход:**
```json
{
  "status": "failed",
  "output": "src/example.js:5:10 error Missing semicolon",
  "exitCode": 1,
  "executionTime": 8.3,
  "wasBlocking": false,
  "resultMatchedExpected": false,
  "actionTaken": "Logged warning, continuing execution"
}
```

### Пример 4: Пользовательская проверка безопасности
**Вход:**
```json
{
  "command": "bash scripts/quality-gates/check-security.sh",
  "isBlocking": true,
  "expectedResult": "No critical vulnerabilities found",
  "timeout": 300
}
```

**Выход:**
```json
{
  "status": "passed",
  "output": "Security scan completed. No critical vulnerabilities detected.",
  "exitCode": 0,
  "executionTime": 45.2,
  "wasBlocking": true,
  "resultMatchedExpected": true,
  "actionTaken": "Continuing execution"
}
```

## Интеграция с оркестраторами

Навык может быть интегрирован в оркестраторы следующим образом:

```markdown
## Quality Gate N: Validate Phase N
- Check worker report exists
- Run quality gates (run-quality-gate Skill)
- If blocking fails: STOP, rollback, exit
- If passes: proceed to next phase
```

## Параметры конфигурации

- `command`: Команда для выполнения проверки
- `isBlocking`: Определяет, является ли проверка блокирующей
- `expectedResult`: Ожидаемый результат для успешного прохождения
- `timeout`: Максимальное время выполнения в секундах
- `workingDirectory`: Рабочая директория для выполнения команды (опционально)
- `environmentVariables`: Переменные окружения для выполнения команды (опционально)
- `continueOnFailure`: Продолжать выполнение даже при неудаче (опционально, по умолчанию false для блокирующих проверок)
