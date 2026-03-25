# Стандарт разработки оркестраторов

**Версия:** 1.0.0  
**Дата:** 21 марта 2026  
**Статус:** Активный  
**Проект:** Qwen Code Orchestrator Kit v0.6.0

---

## 1. Структура оркестратора

### 1.1. YAML Заголовок

Каждый оркестратор должен начинаться с YAML заголовка:

```yaml
---
name: orc_<domain>_<role>
description: Краткое описание назначения оркестратора
type: orchestrator
domain: <domain-area>
tools:
  - mcp__git__*
  - mcp__filesystem__*
  - skill: validate-plan-file
  - skill: run-quality-gate
  - skill: generate-report-header
priority: high
timeout: 600000
---
```

### 1.2. Раздел "Когда использовать"

Оркестратор должен явно указывать условия использования:

```markdown
## Когда использовать

- ✅ Координация многошаговых задач разработки
- ✅ Управление несколькими воркерами
- ✅ Требуются Quality Gate проверки
- ✅ Необходима стандартизированная отчетность

## Когда НЕ использовать

- ❌ Простые одношаговые задачи (использовать воркера)
- ❌ Задачи без необходимости координации
- ❌ Прямая работа с кодом (делегировать воркеру)
```

### 1.3. Паттерн выполнения задач

Стандартный паттерн выполнения для всех оркестраторов:

```
┌─────────────────────────────────────────────────────────┐
│                    ОРКЕСТРАТОР                          │
├─────────────────────────────────────────────────────────┤
│  1. Pre-Flight проверки                                 │
│     - Git workflow validation                           │
│     - Проверка зависимостей                             │
│     - Валидация контекста                               │
│                                                         │
│  2. Сбор контекста                                     │
│     - Чтение спецификаций                               │
│     - Анализ текущего состояния                         │
│     - Определение требований                            │
│                                                         │
│  3. Планирование                                       │
│     - Создание плана выполнения                         │
│     - Назначение исполнителей                           │
│     - Определение Quality Gates                         │
│                                                         │
│  4. Делегирование (task)                               │
│     - Вызов воркеров                                    │
│     - Передача контекста                                │
│     - Ожидание результатов                              │
│                                                         │
│  5. Верификация                                        │
│     - Проверка результатов                              │
│     - Валидация артефактов                              │
│     - Контроль качества                                 │
│                                                         │
│  6. Quality Gate                                       │
│     - Запуск проверок качества                          │
│     - Обработка ошибок                                  │
│     - Принятие решения (pass/fail)                      │
│                                                         │
│  7. Логирование                                        │
│     - Генерация отчета                                  │
│     - Сохранение артефактов                             │
│     - Обновление состояния                              │
└─────────────────────────────────────────────────────────┘
```

### 1.4. Quality Gates Интеграция

Каждый оркестратор должен интегрироваться с системой Quality Gates:

```bash
# Предварительная проверка
.qwen/scripts/quality-gates/check-pre-flight.sh

# Проверка после фазы
.qwen/scripts/quality-gates/check-phase-<N>.sh

# Финальная проверка
.qwen/scripts/quality-gates/check-final.sh
```

**Типы проверок:**
- `type-check` - Проверка типов TypeScript
- `build` - Сборка проекта
- `tests` - Запуск тестов
- `lint` - Линтинг кода
- `security` - Проверка безопасности

### 1.5. Timeout Configuration

Настройки timeout для различных типов задач:

| Тип задачи | Timeout | Действие при timeout |
|------------|---------|---------------------|
| Планирование | 5 минут | Graceful shutdown |
| Разработка | 10 минут | Graceful shutdown + save state |
| Тестирование | 5 минут | Graceful shutdown + partial report |
| Документирование | 3 минуты | Graceful shutdown |
| Анализ | 5 минут | Graceful shutdown |

**Обработка timeout:**

```bash
# 1. Инициировать graceful shutdown
.qwen/scripts/orchestration-tools/graceful-shutdown.sh "<task-id>" "timeout"

# 2. Сохранить частичный прогресс
.qwen/scripts/orchestration-tools/save-partial-progress.sh "<task-id>"

# 3. Сгенерировать отчет с ошибкой
.qwen/scripts/reports/generate-timeout-report.sh "<task-id>"

# 4. Предложить fallback опции
echo "Доступные опции восстановления:"
echo "  1. Продолжить с контрольной точки"
echo "  2. Откатить и начать заново"
echo "  3. Упрощенное выполнение"
```

### 1.6. Graceful Shutdown

Процедура корректной остановки:

```yaml
gracefulShutdown:
  enabled: true
  triggers:
    - timeout
    - error
    - manual_interrupt
  actions:
    - save_state
    - generate_report
    - cleanup_resources
    - notify_orchestrator
```

---

## 2. Единый шаблон оркестратора

### 2.1. Базовая структура

```markdown
# {Agent Name}

**Тип:** Оркестратор / Воркер  
**Домен:** {domain}  
**Инструменты:** {список}

## Когда использовать
{conditions}

## Паттерн выполнения
1. Pre-Flight проверки
2. Сбор контекста
3. Делегирование (task)
4. Верификация
5. Quality Gate
6. Логирование
```

### 2.2. Полный шаблон

```markdown
---
name: orc_<domain>_<role>
description: <краткое описание>
type: orchestrator
domain: <domain>
tools:
  - <инструменты>
priority: <high|medium|low>
timeout: <мс>
---

# {Agent Name}

## Назначение

{Подробное описание назначения оркестратора}

## Когда использовать

### ✅ Использовать когда:
- {condition 1}
- {condition 2}

### ❌ Не использовать когда:
- {condition 1}
- {condition 2}

## Инструменты

### MCP Серверы:
- `mcp__git__*` - Git операции
- `mcp__filesystem__*` - Работа с файлами

### Навыки:
- `skill: validate-plan-file` - Валидация планов
- `skill: run-quality-gate` - Проверка качества
- `skill: generate-report-header` - Генерация отчетов

## Паттерн выполнения

### Фаза 0: Планирование
1. Проверка существующих планов
2. Анализ спецификаций
3. Создание плана выполнения
4. Назначение исполнителей

### Фаза 1-N: Выполнение
1. Pre-Flight проверки
2. Делегирование задач воркерам
3. Сбор результатов
4. Верификация
5. Quality Gate

### Финальная фаза: Завершение
1. Сбор всех отчетов
2. Генерация резюме
3. Обновление артефактов
4. Очистка временных файлов

## Quality Gates

### Предварительные проверки
- [ ] Git workflow validation
- [ ] Проверка зависимостей
- [ ] Валидация контекста

### Фазовые проверки
- [ ] Type check
- [ ] Build verification
- [ ] Test execution

### Финальные проверки
- [ ] Code quality
- [ ] Security scan
- [ ] Documentation completeness

## Timeout Configuration

| Тип задачи | Timeout | Действие |
|------------|---------|----------|
| Planning | 5 мин | Graceful shutdown |
| Execution | 10 мин | Save state + shutdown |
| Verification | 5 мин | Partial report |

## Отчетность

### Формат отчета
Использовать `generate-report-header` skill для стандартизации.

### Артефакты
- План выполнения: `specs/{ID}/plans/`
- Отчеты воркеров: `specs/{ID}/reports/`
- Финальный отчет: `specs/{ID}/summary.md`

## Обработка ошибок

### Graceful Shutdown
При timeout или ошибке:
1. Сохранить состояние
2. Сгенерировать отчет
3. Предложить fallback

### Fallback стратегии
1. Продолжение с контрольной точки
2. Упрощенное выполнение
3. Откат и перезапуск

## Примеры использования

### Пример 1: Координация разработки
```bash
# Запуск оркестратора
orc_dev_task_coordinator --spec <spec-id> --phase dev
```

### Пример 2: Координация тестирования
```bash
# Запуск оркестратора
orc_testing_quality_assurer --spec <spec-id> --phase test
```

## Связанные компоненты

### Воркеры:
- `work_<domain>_<role>` - Основной исполнитель

### Навыки:
- `skill:<name>` - Вспомогательные функции

### Скрипты:
- `.qwen/scripts/quality-gates/` - Проверки качества
- `.qwen/scripts/orchestration-tools/` - Инструменты оркестрации
```

---

## 3. Правила оркестрации

### 3.1. Принцип минимальных привилегий

Оркестратор должен запрашивать только необходимые инструменты:

```yaml
# ✅ Правильно
tools:
  - mcp__git__status
  - mcp__git__commit
  - mcp__filesystem__read

# ❌ Неправильно (избыточные права)
tools:
  - mcp__git__*
  - mcp__filesystem__*
  - mcp__github__*
```

### 3.2. Делегирование в 95% случаев

Оркестратор НЕ должен выполнять работу воркеров:

```yaml
# ✅ Оркестратор делегирует
orchestrator:
  - анализировать задачу
  - назначить воркера
  - проверить результат

# ❌ Оркестратор выполняет работу воркера
orchestrator:
  - писать код
  - запускать тесты
  - исправлять ошибки
```

### 3.3. Верификация результатов

Каждый результат воркера должен быть верифицирован:

```bash
# 1. Проверка существования артефактов
test -f "<artifact-path>" || exit 1

# 2. Валидация формата
.qwen/scripts/validation/validate-artifact.sh "<artifact-path>"

# 3. Проверка качества
.qwen/scripts/quality-gates/check-output.sh "<artifact-path>"
```

### 3.4. Логирование вызовов

Все вызовы должны логироваться:

```bash
# Формат лога
[TIMESTAMP] [LEVEL] [COMPONENT] MESSAGE

# Примеры
[2026-03-21T10:30:00] [INFO] [orc_dev_task_coordinator] Starting phase 1
[2026-03-21T10:30:05] [INFO] [orc_dev_task_coordinator] Delegating to work_dev_code_analyzer
[2026-03-21T10:35:00] [INFO] [orc_dev_task_coordinator] Phase 1 completed successfully
[2026-03-21T10:35:01] [ERROR] [orc_dev_task_coordinator] Quality gate failed: type-check
```

---

## 4. Интеграция с системой

### 4.1. Pre-Task Git Workflow

```bash
# Перед началом ЛЮБОЙ задачи
.qwen/scripts/git/check-workflow.sh
.qwen/scripts/git/create-feature-branch.sh "<task-name>"
```

### 4.2. Pre-Commit Review

```bash
# Перед каждым коммитом
.qwen/scripts/git/pre-commit-review.sh "<type>: <description>"
```

### 4.3. Post-Phase Tagging

```bash
# После завершения фазы
.qwen/scripts/git/auto-tag-release.sh "vX.Y.Z" "Release vX.Y.Z: Description"
```

---

## 5. Контрольные точки качества

### 5.1. Pre-Flight Checks

```bash
.qwen/scripts/quality-gates/check-pre-flight.sh
```

**Проверки:**
- [ ] Git workflow корректен
- [ ] Нет незакоммиченных изменений
- [ ] Ветка синхронизирована с remote
- [ ] Зависимости установлены

### 5.2. Phase Checks

```bash
.qwen/scripts/quality-gates/check-phase-<N>.sh
```

**Проверки:**
- [ ] Type check прошел
- [ ] Build успешен
- [ ] Тесты проходят

### 5.3. Final Checks

```bash
.qwen/scripts/quality-gates/check-final.sh
```

**Проверки:**
- [ ] Code quality соответствует стандартам
- [ ] Security scan чист
- [ ] Документация полная

---

## 6. Приложение: Чеклист создания оркестратора

### 6.1. Предварительная подготовка

- [ ] Определен домен оркестратора
- [ ] Выбраны необходимые инструменты
- [ ] Определены воркеры для делегирования
- [ ] Настроены Quality Gates

### 6.2. Создание файла

- [ ] YAML заголовок заполнен
- [ ] Раздел "Когда использовать" определен
- [ ] Паттерн выполнения описан
- [ ] Timeout configuration указан
- [ ] Graceful shutdown настроен

### 6.3. Интеграция

- [ ] Pre-Flight проверки добавлены
- [ ] Quality Gates интегрированы
- [ ] Логирование настроено
- [ ] Отчетность стандартизирована

### 6.4. Тестирование

- [ ] Оркестратор проходит валидацию
- [ ] Делегирование работает корректно
- [ ] Quality Gates выполняются
- [ ] Отчеты генерируются правильно

---

**Документ утвержден:** Qwen Code Orchestrator Kit Team  
**Дата утверждения:** 21 марта 2026  
**Следующий пересмотр:** 21 июня 2026
