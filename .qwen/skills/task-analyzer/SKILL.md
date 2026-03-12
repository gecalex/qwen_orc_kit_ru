---
name: task-analyzer
description: Анализирует задачи и определяет подходящих агентов для их выполнения. Используйте активно при автоматическом анализе задач и назначении исполнителей. Определяет тип задачи, домен, необходимые навыки и приоритет.
---

# Навык анализа задач

## Когда использовать
- При автоматическом анализе входящих задач
- При определении типа и домена задачи
- При сопоставлении задач и агентов
- При анализе требований к навыкам исполнителя
- При определении приоритета задачи

## Инструкции

### Фаза 1: Классификация задачи
1.1. Определить тип задачи:
- Баг (bug-fixing)
- Фича (feature-development)
- Улучшение (enhancement)
- Тестирование (testing)
- Безопасность (security)
- Документация (documentation)
- Инфраструктура (infrastructure)

1.2. Определить домен задачи:
- dev (общая разработка)
- frontend (фронтенд)
- backend (бэкенд)
- testing (тестирование)
- research (исследование)
- security (безопасность)

### Фаза 2: Анализ требований
2.1. Определить необходимые навыки:
- code-review
- security-analysis
- documentation
- testing
- deployment
- etc.

2.2. Определить приоритет:
- low (низкий)
- medium (средний)
- high (высокий)
- critical (критический)

### Фаза 3: Сопоставление с агентами
3.1. Найти агентов, подходящих для типа задачи
3.2. Проверить соответствие домена задачи и агента
3.3. Проверить наличие необходимых навыков у агентов
3.4. Рекомендовать наиболее подходящих агентов

## Формат ввода
```json
{
  "taskTitle": "string",
  "taskDescription": "string",
  "taskDomain": "string",
  "requiredSkills": ["string"],
  "priority": "string"
}
```

## Формат вывода
```json
{
  "taskType": "string",
  "domain": "string",
  "requiredSkills": ["string"],
  "priority": "string",
  "recommendedAgents": [
    {
      "agentName": "string",
      "matchScore": "number",
      "reason": "string"
    }
  ],
  "alternativeAgents": ["string"],
  "estimatedEffort": "string"
}
```

## Примеры

### Пример 1: Задача на исправление бага
**Вход:**
```json
{
  "taskTitle": "Исправить утечку памяти в компоненте",
  "taskDescription": "Компонент ProfileCard вызывает утечку памяти при частом рендере",
  "taskDomain": "frontend",
  "requiredSkills": ["debugging", "memory-management"],
  "priority": "high"
}
```

**Выход:**
```json
{
  "taskType": "bug-fixing",
  "domain": "frontend",
  "requiredSkills": ["debugging", "memory-management", "react"],
  "priority": "high",
  "recommendedAgents": [
    {
      "agentName": "work_frontend_component_generator",
      "matchScore": 0.9,
      "reason": "Специализируется на компонентах и имеет навыки отладки"
    },
    {
      "agentName": "work_testing_test_generator",
      "matchScore": 0.7,
      "reason": "Может создать тесты для проверки утечки памяти"
    }
  ],
  "alternativeAgents": ["work_dev_code_analyzer"],
  "estimatedEffort": "medium"
}
```

### Пример 2: Задача на добавление фичи
**Вход:**
```json
{
  "taskTitle": "Добавить аутентификацию через OAuth",
  "taskDescription": "Реализовать аутентификацию через Google и GitHub",
  "taskDomain": "backend",
  "requiredSkills": ["authentication", "oauth", "security"],
  "priority": "high"
}
```

**Выход:**
```json
{
  "taskType": "feature-development",
  "domain": "backend",
  "requiredSkills": ["authentication", "oauth", "security", "api-development"],
  "priority": "high",
  "recommendedAgents": [
    {
      "agentName": "work_backend_api_validator",
      "matchScore": 0.95,
      "reason": "Специализируется на API и безопасности"
    }
  ],
  "alternativeAgents": ["work_dev_code_analyzer", "security-analyzer"],
  "estimatedEffort": "high"
}
```

### Пример 3: Задача на тестирование
**Вход:**
```json
{
  "taskTitle": "Написать интеграционные тесты",
  "taskDescription": "Создать тесты для API endpoint'ов аутентификации",
  "taskDomain": "testing",
  "requiredSkills": ["testing", "api-testing", "integration"],
  "priority": "medium"
}
```

**Выход:**
```json
{
  "taskType": "testing",
  "domain": "testing",
  "requiredSkills": ["testing", "api-testing", "integration", "security"],
  "priority": "medium",
  "recommendedAgents": [
    {
      "agentName": "work_testing_test_generator",
      "matchScore": 1.0,
      "reason": "Специализируется на создании тестов"
    }
  ],
  "alternativeAgents": ["work_dev_code_analyzer"],
  "estimatedEffort": "medium"
}
```