# Agent Assignment Checklist

Чек-лист для назначения агентов на задачи.

---

## Чек-лист (6 пунктов)

- [ ] **1.1** Агент имеет соответствующую специализацию
- [ ] **1.2** Агент доступен (не занят другой задачей)
- [ ] **1.3** Агент имеет необходимые навыки (skills)
- [ ] **1.4** Приоритет агента соответствует приоритету задачи
- [ ] **1.5** nextAgent определен для передачи управления
- [ ] **1.6** Fallback агент определен

---

## Матрица назначения

| Тип задачи | Оркестратор | Воркеры |
|------------|-------------|---------|
| Планирование | orc_planning_task_analyzer | work_planning_* |
| Разработка | orc_dev_task_coordinator | work_dev_* |
| Тестирование | orc_testing_quality_assurer | work_testing_* |
| Документация | orc_doc_technical_writer | work_doc_* |
| Безопасность | orc_security_security_orchestrator | work_security_* |
| Исследование | orc_research_data_analyzer | work_research_* |

---

## Приоритеты

- **critical**: Немедленное выполнение
- **high**: В текущем спринте
- **medium**: В ближайшем спринте
- **low**: По возможности

---

## Использование

```bash
# Автоматическая проверка
.qwen/checklists/validate-checklist.sh --name "Agent Assignment"
```

---

*Версия: 1.0.0 | Последнее обновление: 2026-03-21*
