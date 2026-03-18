---
name: validate-plan-file
description: Проверяет файлы плана оркестратора на соответствие ожидаемой схеме JSON
user-invocable: false
---

# Validate Plan File

## Когда использовать
- Перед тем, как агенты читают файлы плана
- После создания файлов плана оркестраторами
- При проверке корректности структуры плана
- В контрольных точках качества перед выполнением плана

## Инструкции
1. Прочитайте файл плана с помощью `read_file`
2. Проверьте наличие обязательных полей:
   - `phase` (number) - номер фазы
   - `status` (string) - статус выполнения
   - `tasks` (array) - список задач
   - `nextAgent` (string) - следующий агент
3. Проверьте типы данных каждого поля
4. Проверьте наличие всех требуемых полей в каждой задаче:
   - `id` (string)
   - `description` (string)
   - `agentType` (string)
   - `status` (string)
5. Сформируйте результат проверки

## Формат ввода
Путь к файлу плана или содержимое файла плана в формате JSON

## Формат вывода
```json
{
  "valid": boolean,
  "errors": string[],
  "warnings": string[]
}
```

## Примеры

### Пример 1: Валидный файл плана
**Ввод:**
```json
{
  "phase": 2,
  "status": "pending",
  "tasks": [
    {
      "id": "task-1",
      "description": "Реализовать API endpoint",
      "agentType": "work_backend_api_validator",
      "status": "pending"
    }
  ],
  "nextAgent": "orc_dev_task_coordinator"
}
```

**Вывод:**
```json
{
  "valid": true,
  "errors": [],
  "warnings": []
}
```

### Пример 2: Файл с ошибками
**Ввод:**
```json
{
  "phase": "two",
  "tasks": []
}
```

**Вывод:**
```json
{
  "valid": false,
  "errors": [
    "Поле 'phase' должно быть числом, получено: string",
    "Отсутствует обязательное поле 'status'",
    "Отсутствует обязательное поле 'nextAgent'"
  ],
  "warnings": [
    "Список задач пуст"
  ]
}
```
