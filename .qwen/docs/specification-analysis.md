# Specification Analysis

**Версия:** 1.0.0
**Дата:** 21 марта 2026
**Назначение:** Руководство по анализу спецификаций

---

## Обзор

Specification Analyzer - это набор инструментов для глубокого анализа качества спецификаций, проверки соответствия требованиям и построения матрицы трассировки.

### Компоненты

| Компонент | Файл | Назначение |
|-----------|------|------------|
| Deep Spec Analyzer | `deep-spec-analyzer.sh` | Глубокий анализ spec.md |
| Requirements Traceability | `requirements-traceability.sh` | Матрица трассировки требований |
| Spec Quality Metrics | `spec-quality-metrics.sh` | Метрики качества спецификаций |

---

## Установка

Анализаторы расположены в `.qwen/analyzers/` и не требуют дополнительной установки.

### Требования

- Bash 4.0+
- jq (для работы с JSON)
- awk (для обработки текста)

```bash
# Проверка зависимостей
command -v jq && echo "jq установлен" || echo "Требуется установка jq"
```

---

## Deep Spec Analyzer

### Назначение

Глубокий анализ спецификаций на:
- Полноту разделов
- Тестируемость требований
- Отсутствие деталей реализации
- Соответствие конституции
- Измеримость критериев успеха

### Использование

```bash
# Анализ конкретной спецификации
.qwen/analyzers/deep-spec-analyzer.sh specs/my-project

# Анализ всех спецификаций
.qwen/analyzers/deep-spec-analyzer.sh --all

# Подробный вывод
.qwen/analyzers/deep-spec-analyzer.sh specs/my-project --verbose

# JSON вывод
.qwen/analyzers/deep-spec-analyzer.sh specs/my-project --json

# Проверка конституции
.qwen/analyzers/deep-spec-analyzer.sh --constitution
```

### Пример вывода

```
Specification Analysis: my-project
==========================================

1. Полнота разделов
  ✅ Краткое описание
  ✅ Контекст
  ❌ Акторы - ОТСУТСТВУЕТ
  ✅ Требования
  ...

  Completeness: 8/9 разделов (89%)

2. Тестируемость требований
  Testability: 28/35 требований тестируемы (80%)
  ⚠️ Требование #12: неясный критерий успеха
  ⚠️ Требование #24: слишком общее

3. Детали реализации
  ⚠️ Найдено: 3

4. Измеримость критериев успеха
  Measurability: 5/7 критериев измеримы (71%)

5. Соответствие конституции
  ✅ Соответствует конституции

==========================================
Compliance Score:
  82/100

Рекомендации:
  1. Добавить отсутствующие разделы: Акторы
  2. Уточнить 7 нетестируемых требований
  3. Удалить 3 деталей реализации
  4. Добавить метрики к критериям успеха
```

### Обязательные разделы

| Раздел | Описание |
|--------|----------|
| Краткое описание | Краткая суть проекта |
| Контекст | Бизнес-контекст и предпосылки |
| Акторы | Участники системы |
| Требования | Функциональные требования |
| Сценарии использования | Use cases |
| Условия успеха | Критерии приемки |
| Ограничения | Технические и бизнес ограничения |
| Предположения | Допущения проекта |
| Риски | Потенциальные риски |

---

## Requirements Traceability

### Назначение

Построение матрицы трассировки требований:
- Сопоставление требований с задачами
- Проверка покрытия реализации
- Выявление пробелов

### Использование

```bash
# Анализ проекта
.qwen/analyzers/requirements-traceability.sh specs/my-project

# Анализ всех проектов
.qwen/analyzers/requirements-traceability.sh --all

# Вывод в CSV
.qwen/analyzers/requirements-traceability.sh specs/my-project --csv > traceability.csv

# Только пробелы
.qwen/analyzers/requirements-traceability.sh specs/my-project --gaps

# Markdown вывод (по умолчанию)
.qwen/analyzers/requirements-traceability.sh specs/my-project --markdown
```

### Пример вывода (Markdown)

```
Traceability Matrix: my-project
==========================================

## Traceability Matrix

| Требование | Описание | Задача | Статус | Реализация |
|------------|----------|--------|--------|------------|
| REQ-1 | Реализовать аутентификацию | TASK-1 | ✅ | ✅ |
| REQ-2 | Реализовать авторизацию | TASK-2 | ⏳ | ⚠️ Частично |
| REQ-3 | Логирование событий | - | ❌ Нет задачи | ❌ |

==========================================
Statistics:
  Всего требований: 3
  Сопоставлено задач: 2
  Без задач: 1
  Реализовано: 1
  Покрытие: 66%

Пробелы трассировки:
  Следующие требования не имеют соответствующих задач:
  - REQ-3: Логирование событий...

Рекомендации:
  1. Создать задачи для 1 требований без покрытия
  2. Завершить 1 незавершенных задач
```

### Пример вывода (CSV)

```csv
Requirement_ID,Requirement_Description,Task_ID,Task_Status,Implementation
REQ-1,"Реализовать аутентификацию",TASK-1,completed,✅
REQ-2,"Реализовать авторизацию",TASK-2,pending,⚠️ Частично
REQ-3,"Логирование событий",-,No Task,❌
```

---

## Spec Quality Metrics

### Назначение

Расчет метрик качества спецификаций:
- Полнота разделов (%)
- Тестируемость требований (%)
- Детали реализации (count)
- Измеримость критериев (%)
- Traceability coverage (%)

### Использование

```bash
# Метрики проекта
.qwen/analyzers/spec-quality-metrics.sh specs/my-project

# Метрики всех проектов
.qwen/analyzers/spec-quality-metrics.sh --all

# JSON вывод
.qwen/analyzers/spec-quality-metrics.sh specs/my-project --json

# С порогом качества
.qwen/analyzers/spec-quality-metrics.sh specs/my-project --threshold 80
```

### Пример вывода

```
Specification Quality Metrics: my-project
==========================================

Полнота разделов:
  8/9 разделов (89%)
  ██████████████████

Тестируемость требований:
  28/35 требований тестируемы (80%)
  ████████████████

Детали реализации:
  ✅ Не найдено

Измеримость критериев:
  5/7 критериев измеримы (71%)
  ██████████████

Traceability Coverage:
  28/35 требований покрыты задачами (80%)
  ████████████████

==========================================
Overall Quality Score:
  ✅ PASS
  Score: 82/100 (threshold: 70)
```

### Пример JSON вывода

```json
{
  "project": "my-project",
  "timestamp": "2026-03-21T10:30:00+00:00",
  "metrics": {
    "completeness": {
      "found": 8,
      "total": 9,
      "score": 89
    },
    "testability": {
      "testable": 28,
      "total": 35,
      "score": 80
    },
    "implementation_details": 0,
    "measurability": {
      "measurable": 5,
      "total": 7,
      "score": 71
    },
    "traceability": {
      "tasks": 28,
      "requirements": 35,
      "coverage": 80
    }
  },
  "overall_score": 82,
  "threshold": 70,
  "status": "✅ PASS"
}
```

### Метрики

| Метрика | Описание | Формула | Цель |
|---------|----------|---------|------|
| Completeness | Полнота разделов | found/total * 100 | ≥ 90% |
| Testability | Тестируемость требований | testable/total * 100 | ≥ 80% |
| Implementation Details | Детали реализации | count | 0 |
| Measurability | Измеримость критериев | measurable/total * 100 | ≥ 80% |
| Traceability | Покрытие задачами | tasks/requirements * 100 | ≥ 100% |

### Расчет общего качества

```
Overall = (Completeness * 30 + Testability * 25 + 
           Measurability * 20 + Traceability * 25) / 100
         
Штраф за детали реализации: -2 за каждую (макс. -20)
```

---

## Интеграция

### В Feedback System

Анализаторы автоматически интегрируются в Feedback System:

```bash
# Запуск всех проверок
.qwen/feedback/generate-all.sh
```

### В CI/CD

```yaml
# Пример для GitHub Actions
- name: Spec Quality Check
  run: |
    .qwen/analyzers/spec-quality-metrics.sh specs/${{ github.event.inputs.project }} --threshold 80
    .qwen/analyzers/deep-spec-analyzer.sh specs/${{ github.event.inputs.project }}
```

### Pre-commit проверка

```bash
# В pre-commit хук
.qwen/analyzers/deep-spec-analyzer.sh specs/my-project --json | \
  jq '.compliance_score >= 80' || exit 1
```

---

## Рабочие процессы

### Сценарий 1: Проверка перед разработкой

```bash
# 1. Анализ полноты спецификации
.qwen/analyzers/deep-spec-analyzer.sh specs/my-project

# 2. Проверка качества
.qwen/analyzers/spec-quality-metrics.sh specs/my-project --threshold 80

# 3. Если PASS - начало разработки
# 4. Если FAIL - доработка spec.md
```

### Сценарий 2: Проверка во время разработки

```bash
# 1. Проверка трассировки
.qwen/analyzers/requirements-traceability.sh specs/my-project --gaps

# 2. Создание недостающих задач
# 3. Повторная проверка
```

### Сценарий 3: Pre-release аудит

```bash
# 1. Полный анализ всех проектов
.qwen/analyzers/deep-spec-analyzer.sh --all
.qwen/analyzers/spec-quality-metrics.sh --all --json > release-metrics.json
.qwen/analyzers/requirements-traceability.sh --all --csv > traceability.csv

# 2. Анализ результатов
# 3. Исправление проблем
# 4. Релиз
```

---

## Интерпретация результатов

### Compliance Score

| Score | Статус | Действия |
|-------|--------|----------|
| 90-100 | ✅ Excellent | Готово к разработке |
| 80-89 | ✅ Good | Минимальные правки |
| 70-79 | ⚠️ Acceptable | Требует улучшений |
| 60-69 | ⚠️ Poor | Значительные правки |
| < 60 | ❌ Fail | Пересмотр spec |

### Типичные проблемы

| Проблема | Причина | Решение |
|----------|---------|---------|
| Низкая полнота | Отсутствуют разделы | Добавить разделы по шаблону |
| Низкая тестируемость | Размытые требования | Добавить критерии приемки |
| Детали реализации | Технические детали в spec | Переместить в tasks.md |
| Низкая измеримость | Нет метрик | Добавить числа/проценты |

---

## Расширение

### Добавление проверок

1. Откройте соответствующий скрипт
2. Добавьте новую функцию проверки
3. Интегрируйте в основную логику
4. Обновите документацию

### Кастомизация порогов

```bash
# Установка порога качества
.qwen/analyzers/spec-quality-metrics.sh specs/my-project --threshold 85
```

---

## Поддержание

### Регулярные задачи

| Задача | Частота | Команда |
|--------|---------|---------|
| Анализ новых spec | После создания | `deep-spec-analyzer.sh <dir>` |
| Проверка трассировки | Еженедельно | `requirements-traceability.sh --all` |
| Метрики качества | Перед релизом | `spec-quality-metrics.sh --all` |

---

## См. также

- [Error Knowledge Base](error-knowledge-base.md) - База знаний об ошибках
- [Feedback System](../feedback/README.md) - Система обратной связи
- [Constitution](../specify/constitution.md) - Конституция проекта
