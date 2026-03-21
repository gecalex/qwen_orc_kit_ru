# Health Check Checklist

Чек-лист проверки здоровья проекта.

---

## Чек-лист (4 пункта)

- [ ] **1.1** Git workflow соблюдается
- [ ] **1.2** Качество кода на уровне (Quality Gates)
- [ ] **1.3** Тесты покрывают критический функционал
- [ ] **1.4** Нет критических уязвимостей безопасности

---

## Быстрая проверка

```bash
# Запуск всех проверок
.qwen/feedback/generate-all.sh

# Проверка качества
.qwen/scripts/run_quality_gate.sh

# Проверка безопасности
skill: "security-scanner"
```

---

## Метрики здоровья

| Метрика | Цель | Статус |
|---------|------|--------|
| Git Workflow Score | ≥90% | ✅/⚠️/❌ |
| Quality Gate Pass | 100% | ✅/⚠️/❌ |
| Test Coverage | ≥80% | ✅/⚠️/❌ |
| Security Issues | 0 critical | ✅/⚠️/❌ |

---

## Использование

```bash
# Автоматическая проверка
.qwen/checklists/validate-checklist.sh --name "Health Check"
```

---

*Версия: 1.0.0 | Последнее обновление: 2026-03-21*
