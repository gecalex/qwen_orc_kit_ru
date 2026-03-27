---
name: template-feedback
description: Сбор обратной связи о ШАБЛОНЕ (qwen_orc_kit_ru). Запускает тесты, находит ошибки в ШАБЛОНЕ, создаёт отчёты. Использовать для тестирования ШАБЛОНА.
---

# Skill: Template Feedback

## When to Use

Используйте этот skill для:

- ✅ Сбора обратной связи о ШАБЛОНЕ (qwen_orc_kit_ru)
- ✅ Обнаружения ошибок в компонентах ШАБЛОНА
- ✅ Тестирования обновлений ШАБЛОНА
- ✅ Автоматического создания отчётов об ошибках

**НЕ используйте для:**

- ❌ Поиска багов в проекте (PKB_test)
- ❌ Поиска багов в коде проекта
- ❌ Тестирования проекта

## Instructions

### Шаг 1: Запустить скрипт

```bash
cd /home/alex/MyProjects/qwen_orc_kit_ru
.qwen/scripts/bug-tracking/run-template-feedback.sh
```

### Шаг 2: Проверить результат

```bash
# Проверить созданные отчёты
ls -la .qwen/state/bugs/

# Проверить реестр
cat .qwen/state/template-feedback-registry.json | jq .
```

### Шаг 3: Отправить отчёт в ШАБЛОН

```bash
# Если есть ошибки ШАБЛОНА
.qwen/scripts/bug-tracking/send-template-feedback.sh .qwen/state/bugs/P*.md
```

## Examples

### Пример 1: Запуск сбора обратной связи

```bash
# Запустить skill
skill: template-feedback

# Результат:
# ✅ Директории созданы
# ✅ Тесты запущены
# ✅ Отчёт создан: .qwen/state/bugs/P2-20260327-120000.md
# ✅ Реестр обновлён
```

### Пример 2: Проверка ошибок ШАБЛОНА

```bash
# Посмотреть отчёт
cat .qwen/state/bugs/P2-*.md

# Пример содержимого:
# Template Bugs Only:
# .qwen/scripts/bug-tracking/template-feedback-report.sh: line 60: parse error
```

## Related Scripts

- `.qwen/scripts/bug-tracking/run-template-feedback.sh` — запуск
- `.qwen/scripts/bug-tracking/template-feedback-report.sh` — создание отчёта
- `.qwen/scripts/bug-tracking/send-template-feedback.sh` — отправка в ШАБЛОН
- `.qwen/scripts/bug-tracking/receive-template-feedback.sh` — приём в ШАБЛОНЕ
