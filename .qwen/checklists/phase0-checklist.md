# Phase 0 Checklist

Чек-лист для Фазы 0 (Планирование).

---

## Чек-лист (7 пунктов)

- [ ] **1.1** Задача проанализирована оркестратором
- [ ] **1.2** Требования извлечены из задачи
- [ ] **1.3** Подзадачи идентифицированы
- [ ] **1.4** Исполнители назначены
- [ ] **1.5** План выполнения создан
- [ ] **1.6** Приоритеты установлены
- [ ] **1.7** План валидирован

---

## Выход Фазы 0

### phase0-plan.json
```json
{
  "task": "Название задачи",
  "requirements": [],
  "subtasks": [],
  "assignments": {},
  "timeline": {}
}
```

### phase0-assignments.json
```json
{
  "subtask_1": "agent_name",
  "subtask_2": "agent_name"
}
```

### dev-task-coordination-plan.json
```json
{
  "phase": 1,
  "config": {},
  "validation": {},
  "nextAgent": "work_*"
}
```

---

## Использование

```bash
# Автоматическая проверка
.qwen/checklists/validate-checklist.sh --name "Phase 0"
```

---

*Версия: 1.0.0 | Последнее обновление: 2026-03-21*
