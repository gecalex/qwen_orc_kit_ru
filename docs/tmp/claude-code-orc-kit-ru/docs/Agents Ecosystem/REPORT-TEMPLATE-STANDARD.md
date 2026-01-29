# Стандартизированный шаблон отчета

**Дата создания**: 2025-10-17
**Дата обновления**: 2025-10-18
**Фаза**: 4 - Задача 4.2
**Статус**: Стандартный шаблон для всех отчетов рабочих агентов (v2.0)
**Назначение**: Определить согласованную структуру, формат метаданных и разделы валидации для всех отчетов, созданных агентами

---

## Содержание

1. [Обзор](#обзор)
2. [Стандартные метрики](#стандартные-метрики)
3. [Правила организации файлов](#правила-организации-файлов)
4. [Структура отчета](#структура-отчета)
5. [Формат метаданных](#формат-метаданных)
6. [Обязательные разделы](#обязательные-разделы)
7. [Формат раздела валидации](#формат-раздела-валидации)
8. [Типы отчетов](#типы-отчетов)
9. [Примеры](#примеры)

---

## Обзор

### Назначение

Все рабочие агенты должны генерировать отчеты, следуя этому стандартизированному шаблону, чтобы обеспечить:
- **Согласованность**: Предсказуемая структура во всех типах отчетов
- **Парсабельность**: Машины могут проверять и извлекать данные
- **Полноту**: Все необходимая информация присутствует
- **Отслеживаемость**: Метаданные позволяют отслеживать и аудировать

### Использование

Рабочие агенты должны:
1. Использовать навык `generate-report-header` для генерации заголовка
2. Следовать обязательной структуре разделов
3. Включать все результаты валидации
4. Использовать согласованные индикаторы статуса
5. Сохранять отчеты со стандартным именованием

---

## Стандартные метрики

### Все отчеты должны включать

Каждый отчет, независимо от типа, должен включать эти стандартные метрики для согласованности и отслеживаемости:

#### Основные метрики (Обязательные)

| Метрика | Формат | Описание | Пример |
|--------|--------|-------------|---------|
| **Временная метка** | ISO-8601 | Когда отчет был сгенерирован | `2025-10-18T14:30:00Z` |
| **Продолжительность** | Человекочитаемый | Время выполнения | `3m 45s`, `1h 12m`, `45s` |
| **Рабочий процесс** | Имя домена | Какой домен рабочего процесса | `bugs`, `security`, `dead-code`, `dependencies` |
| **Фаза** | Тип фазы | Фаза рабочего процесса | `detection`, `fixing`, `verification` |
| **Статус валидации** | Эмодзи + Текст | Общий результат валидации | `✅ PASSED`, `⛔ FAILED`, `⚠️ PARTIAL` |

#### Дополнительные метрики

| Метрика | Формат | Описание | Пример |
|--------|--------|-------------|---------|
| **Приоритет/Серьезность** | Уровень | Приоритет/серьезность проблемы | `critical`, `high`, `medium`, `low` |
| **Обработанные файлы** | Число | Проанализированные/измененные файлы | `42 files` |
| **Найденные проблемы** | Число | Всего обнаруженных проблем | `15 bugs`, `3 critical CVEs` |
| **Внесенные изменения** | Булево | Произошли ли модификации | `true`, `false` |
| **Журнал изменений** | Путь к файлу | Путь к журналу изменений | `.bug-changes.json` |

### Метрики, специфичные для домена

Каждый домен добавляет специфичные метрики помимо стандартного набора:

#### Домен багов
- **Баги по приоритету**: Разбивка багов (critical: 2, high: 5 и т.д.)
- **Исправленные баги**: Количество решенных багов
- **Оставшиеся баги**: Невыполненные баги после исправлений

#### Домен безопасности
- **CVE по серьезности**: Разбивка уязвимостей
- **Политики RLS**: Количество проанализированных/исправленных политик
- **Проблемы аутентификации**: Проблемы аутентификации/авторизации

#### Домен мертвого кода
- **Удаленные строки**: Всего строк мертвого кода удалено
- **Измененные файлы**: Файлы очищены
- **Категории очистки**: Неиспользуемые импорты, отладочный код и т.д.

#### Домен зависимостей
- **Обновленные пакеты**: Количество обновленных зависимостей
- **Исправления безопасности**: Уязвимости устранены
- **Изменения версий**: Разбивка по major/minor/patch

---

## Правила организации файлов

### Стратегия размещения файлов

Четкие правила, где сохранять разные типы файлов, чтобы избежать засорения корневого каталога:

#### Временные файлы (Автоочистка)

**Расположение**: Корень проекта
**Время жизни**: Автоочистка через 7 дней или по завершении рабочего процесса
**Шаблон**: `.{workflow}-*` или `{temp-name}-report.md`

| Тип файла | Шаблон | Триггер очистки | Пример |
|-----------|---------|-----------------|---------|
| Файлы планов | `.{domain}-{phase}-plan.json` | После завершения рабочего агента | `.bug-detection-plan.json` |
| Временные отчеты | `{task}-report.md` | Через 7 дней | `bug-hunting-report.md` |
| Журналы изменений | `.{domain}-changes.json` | После успешной валидации | `.bug-changes.json` |
| Файлы блокировки | `.locks/*.lock` | Через 30 мин или по завершении | `.locks/active-fixer.lock` |
| Каталог резервных копий | `.rollback/` | После успешной валидации | `.rollback/src-file.ts.backup` |

**Политика очистки**:
```bash
# Рабочие агенты должны очищать временные файлы после успеха
rm -f .{domain}-changes.json
rm -rf .rollback/

# Оркестраторы должны очищать файлы планов
rm -f .{domain}-{phase}-plan.json

# Файлы блокировки автоматически истекают через 30 минут
```

#### Постоянные файлы

**Расположение**: `docs/reports/{domain}/{date}/`
**Время жизни**: Постоянные (ручной архив)
**Шаблон**: `{date}-{domain}-{type}.md`

| Тип отчета | Расположение | Именование | Пример |
|-------------|----------|--------|---------|
| Отчеты о багах | `docs/reports/bugs/{YYYY-MM}/` | `{date}-bug-hunting-report.md` | `docs/reports/bugs/2025-10/2025-10-18-bug-hunting-report.md` |
| Аудиты безопасности | `docs/reports/security/{YYYY-MM}/` | `{date}-security-audit.md` | `docs/reports/security/2025-10/2025-10-18-security-audit.md` |
| Мертвый код | `docs/reports/cleanup/{YYYY-MM}/` | `{date}-dead-code-report.md` | `docs/reports/cleanup/2025-10/2025-10-18-dead-code-report.md` |
| Зависимости | `docs/reports/deps/{YYYY-MM}/` | `{date}-dependency-audit.md` | `docs/reports/deps/2025-10/2025-10-18-dependency-audit.md` |
| Сводки | `docs/reports/summaries/` | `{date}-health-summary.md` | `docs/reports/summaries/2025-10-18-health-summary.md` |

**Политика архивирования**:
```bash
# Архивировать отчеты старше 90 дней
mv docs/reports/{domain}/{old-month}/ docs/reports/archive/{domain}/{year}/
```

#### Специальные каталоги

| Каталог | Назначение | Очистка | Примеры файлов |
|-----------|---------|---------|---------------|
| `.locks/` | Активные блокировки рабочего процесса | Авто (30 мин) | `active-fixer.lock` |
| `.rollback/` | Резервные файлы для отката | После успеха | `src-file.ts.backup` |
| `.claude/schemas/` | JSON-схемы (постоянные) | Вручную | `bug-plan.schema.json` |
| `.claude/skills/` | Навыки (постоянные) | Вручную | `rollback-changes/SKILL.md` |
| `docs/reports/archive/` | Старые отчеты | Вручную | `archive/bugs/2025/` |

### Реализация в рабочих агентах

Рабочие агенты должны следовать этим правилам:

**Перед генерацией отчета**:
```markdown
1. Определить тип отчета (временный против постоянного)
2. Если временный: Сохранить в корень с заметкой об очистке
3. Если постоянный: Создать структуру каталогов с датой
4. Добавить инструкции по очистке в раздел "Следующие шаги"
```

**После успешного выполнения**:
```markdown
1. Очистка временных файлов (.{domain}-changes.json, .rollback/)
2. Удаление файлов планов (.{domain}-{phase}-plan.json)
3. Перемещение временного отчета в постоянное расположение (если требуется архивация)
```

**В разделе отчета "Следующие шаги"**:
```markdown
### Очистка
- [ ] Проверить отчет и подтвердить результаты
- [ ] Выполнить: `rm -f .bug-changes.json .bug-detection-plan.json`
- [ ] Выполнить: `rm -rf .rollback/`
- [ ] Архивировать отчет: `mv bug-hunting-report.md docs/reports/bugs/2025-10/2025-10-18-bug-hunting-report.md`
```

---

## Структура отчета

### Структура высокого уровня

```markdown
# {Тип отчета} Отчет: {Версия/Идентификатор}

---
[Метаданные в YAML frontmatter]
---

[Заголовок с временной меткой генерации, статусом, версией]

---

## Итоги

[Ключевые находки и метрики]

---

## Подробные находки

[Специфичные для домена находки]

---

## Результаты валидации

[Статус и детали валидации]

---

## Следующие шаги

[Действия, которые можно рекомендовать]

---

[По желанию: Приложения, необработанные данные, журналы]
```

---

## Формат метаданных

### YAML Frontmatter

Разместить в **самом начале** отчета, перед заголовком.

```yaml
---
report_type: bug-hunting | security-audit | dead-code | dependency-audit | version-update | code-health | verification
generated: ISO-8601 временная метка (YYYY-MM-DDTHH:mm:ssZ)
version: семантическая версия или идентификатор даты
status: success | partial | failed | in_progress
agent: имя-рабочего-агента
duration: время выполнения (например, "3m 45s", "1h 12m")
files_processed: число (необязательно)
issues_found: число (необязательно)
---
```

### Поля метаданных

#### Обязательные поля

- **report_type**: Один из допустимых типов отчетов (см. раздел Типы отчетов)
- **generated**: ISO-8601 временная метка
- **version**: Идентификатор версии или дата (формат YYYY-MM-DD)
- **status**: Общий статус отчета

#### Дополнительные поля

- **agent**: Рабочий агент, который сгенерировал отчет
- **duration**: Сколько времени заняла операция
- **files_processed**: Количество проанализированных файлов
- **issues_found**: Всего обнаруженных проблем
- **custom_field**: Специфичные для домена поля по необходимости

### Значения статуса

| Статус | Эмодзи | Описание |
|--------|-------|-------------|
| `success` | ✅ | Операция завершена успешно |
| `partial` | ⚠️ | Завершено с предупреждениями или частичными сбоями |
| `failed` | ❌ | Операция критически провалена |
| `in_progress` | 🔄 | Операция в настоящее время выполняется |

---

## Обязательные разделы

### 1. Название и заголовок

**Формат**:
```markdown
# {Тип отчета} Отчет: {Версия}

**Сгенерировано**: {Временная метка}
**Статус**: {Эмодзи} {Статус}
**Версия**: {Версия}
**Агент**: {Имя агента} (необязательно)
**Продолжительность**: {Продолжительность} (необязательно)
**Обработанные файлы**: {Количество} (необязательно)

---
```

**Правила**:
- Название должно быть H1 (один #)
- Использовать стандартизованные имена типов отчетов
- Включить эмодзи статуса
- Использовать навык `generate-report-header`

### 2. Итоги

**Формат**:
```markdown
## Итоги

[Краткий обзор операции и ключевых находок]

### Ключевые метрики

- **Метрика 1**: Значение
- **Метрика 2**: Значение
- **Метрика 3**: Значение

### Основные моменты

- ✅ Крупный успех/завершение
- ⚠️ Предупреждение или проблема
- ❌ Критическая проблема (если есть)
```

**Требования**:
- Начать с заголовка H2
- Включить 3-5 ключевых метрик
- Выделить самые важные находки
- Использовать эмодзи для визуальной ясности

### 3. Подробные находки

**Формат**: Варьируется в зависимости от типа отчета (см. раздел Типы отчетов)

**Общие требования**:
- Начать с заголовка H2
- Организовать по серьезности/приоритету/категории
- Включить действия, которые можно предпринять
- Использовать списки для нескольких элементов
- Включить фрагменты кода, если актуально

### 4. Результаты валидации

**Формат**:
```markdown
## Результаты валидации

### Валидация сборки

- **Проверка типов**: ✅ PASSED / ❌ FAILED
  ```bash
  pnpm type-check
  # Код выхода: 0
  # Вывод: No errors found
  ```

- **Сборка**: ✅ PASSED / ❌ FAILED
  ```bash
  pnpm build
  # Код выхода: 0
  # Вывод: Build successful
  ```

### Валидация тестов (Необязательно)

- **Тесты**: ✅ PASSED / ⚠️ PARTIAL / ❌ FAILED
  ```bash
  pnpm test
  # Код выхода: 0
  # Вывод: 42/42 tests passed
  ```

### Общий статус

**Валидация**: ✅ PASSED / ⚠️ PARTIAL / ❌ FAILED

[Объяснение, если не полностью пройдено]
```

**Требования**:
- Включить результаты проверки типов и сборки
- Показать фактически запущенные команды
- Включить коды выхода
- Показать соответствующие выдержки из вывода
- Общий статус в конце

### 5. Следующие шаги

**Формат**:
```markdown
## Следующие шаги

### Немедленные действия (Обязательно)

1. [Элемент действия с конкретными шагами]
2. [Элемент действия с конкретными шагами]

### Рекомендуемые действия (Необязательно)

- [Рекомендация 1]
- [Рекомендация 2]

### Последующие действия

- [Долгосрочное действие или мониторинг]
```

**Требования**:
- Начать с заголовка H2
- Разделить обязательные и необязательные действия
- Быть конкретным и действенным
- Включить ответственных лиц, если известно

---

## Формат раздела валидации

### Стандартные проверки валидации

Все отчеты должны проверять:

#### 1. Проверка типов

```markdown
### Проверка типов

**Команда**: `pnpm type-check`

**Статус**: ✅ PASSED

**Вывод**:
\```
tsc --noEmit
No errors found.
\```

**Код выхода**: 0
```

#### 2. Сборка

```markdown
### Сборка

**Команда**: `pnpm build`

**Статус**: ✅ PASSED

**Вывод**:
\```
vite build
✓ built in 3.45s
dist/index.js  125.3 kB
\```

**Код выхода**: 0
```

#### 3. Тесты (Необязательно)

```markdown
### Тесты

**Команда**: `pnpm test`

**Статус**: ✅ PASSED (42/42)

**Вывод**:
\```
jest
PASS  src/utils.test.ts
PASS  src/types.test.ts
...
Tests: 42 passed, 42 total
\```

**Код выхода**: 0
```

### Общий статус валидации

```markdown
### Общий статус

**Валидация**: ✅ PASSED

Все проверки валидации успешно завершены. Блокирующих проблем не обнаружено.
```

---

## Report Types

### 1. Bug Hunting Report

**report_type**: `bug-hunting`

**Required Metadata**:
- files_processed
- issues_found
- critical_count, high_count, medium_count, low_count

**Detailed Findings Structure**:
```markdown
## Detailed Findings

### Critical (3)

1. **[File:Line] Issue Title**
   - **Severity**: Critical
   - **Description**: [What's wrong]
   - **Impact**: [What happens]
   - **Location**: `path/to/file.ts:123`
   - **Fix**: [How to fix]

### High (8)

[Same structure]

### Medium (12)

[Same structure]

### Low (5)

[Same structure]
```

**Example**: See Examples section

---

### 2. Security Audit Report

**report_type**: `security-audit`

**Required Metadata**:
- vulnerabilities_found
- critical_vulns, high_vulns, medium_vulns, low_vulns
- rls_policies_checked (if Supabase)

**Detailed Findings Structure**:
```markdown
## Detailed Findings

### OWASP Top 10 Scan

#### A01:2021 - Broken Access Control

- ✅ No issues found
- Checked: Authentication middleware, authorization logic

#### A02:2021 - Cryptographic Failures

- ⚠️ 1 issue found
  - **Issue**: Hardcoded secret in configuration
  - **Location**: `config/secrets.ts:15`
  - **Severity**: High
  - **Remediation**: Move to environment variables

### SQL Injection Scan

[Results]

### Cross-Site Scripting (XSS)

[Results]

### RLS Policy Validation (if Supabase)

[Results]
```

**Example**: See Examples section

---

### 3. Dead Code Report

**report_type**: `dead-code`

**Required Metadata**:
- files_scanned
- dead_code_items
- commented_code_lines
- debug_artifacts

**Detailed Findings Structure**:
```markdown
## Detailed Findings

### Critical Dead Code (5)

1. **Unused Export: `oldFunction`**
   - **File**: `src/utils.ts:45-67`
   - **Type**: Exported function never imported
   - **Lines**: 23 lines
   - **Safe to Remove**: ✅ Yes

### Commented Code (12)

1. **Large Comment Block**
   - **File**: `src/legacy.ts:100-250`
   - **Lines**: 151 lines commented
   - **Safe to Remove**: ⚠️ Review recommended

### Debug Artifacts (8)

1. **Console.log statements**
   - **File**: `src/api.ts:34, 67, 89`
   - **Count**: 3 occurrences
   - **Safe to Remove**: ✅ Yes
```

**Example**: See Examples section

---

### 4. Dependency Audit Report

**report_type**: `dependency-audit`

**Required Metadata**:
- dependencies_checked
- outdated_count
- vulnerable_count
- unused_count

**Detailed Findings Structure**:
```markdown
## Detailed Findings

### Security Vulnerabilities (5)

#### Critical CVEs (2)

1. **lodash@4.17.20**
   - **CVE**: CVE-2021-23337
   - **Severity**: Critical (CVSS 9.1)
   - **Fix**: Update to lodash@4.17.21
   - **Command**: `npm install lodash@4.17.21`

### Outdated Packages (23)

#### Major Updates Available (5)

1. **react: 17.0.2 → 18.2.0**
   - **Type**: Major (Breaking)
   - **Release Date**: 2022-03-29
   - **Migration**: [Link to migration guide]

### Unused Dependencies (3)

1. **moment**
   - **Reason**: Not imported anywhere
   - **Action**: Remove from package.json
   - **Savings**: 2.3 MB
```

**Example**: See Examples section

---

### 5. Version Update Report

**report_type**: `version-update`

**Required Metadata**:
- old_version
- new_version
- files_updated
- references_updated

**Detailed Findings Structure**:
```markdown
## Detailed Findings

### Version Changes

- **Old Version**: 0.7.0
- **New Version**: 0.8.0
- **Change Type**: Minor

### Files Updated (15)

#### Package Files (2)

1. **package.json**
   - **Line 3**: `"version": "0.7.0"` → `"version": "0.8.0"`

2. **packages/client/package.json**
   - **Line 3**: `"version": "0.7.0"` → `"version": "0.8.0"`

#### Documentation Files (8)

1. **README.md**
   - **Line 10**: Version badge updated
   - **Line 45**: Installation version updated

### Historical References Preserved (12)

- CHANGELOG.md entries for 0.7.0 preserved
- Release notes for previous versions unchanged
```

**Example**: See Examples section

---

### 6. Code Health Report

**report_type**: `code-health`

**Required Metadata**:
- overall_score
- bugs_found
- security_issues
- dead_code_items
- dependency_issues

**Detailed Findings Structure**:
```markdown
## Detailed Findings

### Overall Health Score: 72/100 (Good)

### Domain Results

#### Bugs (Bug Orchestrator)

- **Status**: ✅ Completed
- **Issues Found**: 23
- **Critical**: 3
- **Report**: `bug-hunting-report.md`

#### Security (Security Orchestrator)

- **Status**: ⚠️ Partial
- **Vulnerabilities**: 7
- **Critical**: 2 unfixed
- **Report**: `security-audit-report.md`

#### Dead Code (Dead Code Orchestrator)

- **Status**: ✅ Completed
- **Items Removed**: 45
- **Lines Deleted**: 1,234
- **Report**: `dead-code-report.md`

#### Dependencies (Dependency Orchestrator)

- **Status**: ✅ Completed
- **Outdated**: 0 critical
- **Vulnerable**: 1 low
- **Report**: `dependency-audit-report.md`
```

**Example**: See Examples section

---

### 7. Verification Report

**report_type**: `verification`

**Required Metadata**:
- original_report
- verification_type (final|retry|followup)
- comparison_performed

**Detailed Findings Structure**:
```markdown
## Detailed Findings

### Verification Type: Final Scan

### Original Report Comparison

- **Original Issues**: 23
- **Current Issues**: 2
- **Resolved**: 21
- **New Issues**: 0
- **Regression**: ❌ None

### Remaining Issues (2)

1. **Medium Priority: Type inference issue**
   - **Status**: Known limitation
   - **Documented**: Yes
   - **Blocking**: No

### Validation

- Type Check: ✅ PASSED
- Build: ✅ PASSED
- Tests: ✅ PASSED (42/42)
```

**Example**: See Examples section

---

## Examples

### Example 1: Bug Hunting Report

```markdown
---
report_type: bug-hunting
generated: 2025-10-17T14:30:00Z
version: 2025-10-17
status: success
agent: bug-hunter
duration: 3m 45s
files_processed: 147
issues_found: 23
critical_count: 3
high_count: 8
medium_count: 12
low_count: 0
---

# Bug Hunting Report: 2025-10-17

**Generated**: 2025-10-17 14:30:00 UTC
**Status**: ✅ success
**Version**: 2025-10-17
**Agent**: bug-hunter
**Duration**: 3m 45s
**Files Processed**: 147

---

## Executive Summary

Comprehensive bug scan completed successfully. Found 23 bugs across 147 TypeScript files.

### Key Metrics

- **Critical Bugs**: 3 (require immediate attention)
- **High-Priority Bugs**: 8 (fix this sprint)
- **Medium-Priority Bugs**: 12 (schedule next sprint)
- **Files Scanned**: 147
- **Scan Duration**: 3m 45s

### Highlights

- ✅ Scan completed without errors
- ❌ 3 critical bugs require immediate attention
- ⚠️ Memory leak detected in connection pool (Critical)
- ✅ No security vulnerabilities in bug patterns

---

## Detailed Findings

### Critical (3)

1. **[src/api/database.ts:45] Memory Leak in Connection Pool**
   - **Severity**: Critical
   - **Priority**: P0
   - **Description**: Connection pool not releasing connections after timeout
   - **Impact**: Memory exhaustion after ~2 hours of operation
   - **Location**: `src/api/database.ts:45-67`
   - **Fix**: Implement automatic connection cleanup and recycling
   - **Estimated Time**: 2 hours

2. **[src/auth/session.ts:123] Race Condition in Session Management**
   - **Severity**: Critical
   - **Priority**: P0
   - **Description**: Concurrent requests can create duplicate sessions
   - **Impact**: Data inconsistency, potential security issue
   - **Location**: `src/auth/session.ts:123-145`
   - **Fix**: Add mutex lock or atomic transaction
   - **Estimated Time**: 1.5 hours

3. **[src/utils/parser.ts:89] Unhandled Promise Rejection**
   - **Severity**: Critical
   - **Priority**: P0
   - **Description**: Promise rejection in parser crashes the process
   - **Impact**: Service crashes on malformed input
   - **Location**: `src/utils/parser.ts:89-102`
   - **Fix**: Add try-catch around async parser calls
   - **Estimated Time**: 30 minutes

### High (8)

1. **[src/components/Form.tsx:234] Type Error in Props**
   - **Severity**: High
   - **Priority**: P1
   - **Description**: Missing required prop `onSubmit` not caught by types
   - **Impact**: Runtime errors when form is submitted
   - **Location**: `src/components/Form.tsx:234`
   - **Fix**: Add proper TypeScript interface for props
   - **Estimated Time**: 20 minutes

[... additional high-priority bugs ...]

### Medium (12)

1. **[src/hooks/useData.ts:56] Inefficient Re-rendering**
   - **Severity**: Medium
   - **Priority**: P2
   - **Description**: Hook causes unnecessary re-renders on every state change
   - **Impact**: Performance degradation with large lists
   - **Location**: `src/hooks/useData.ts:56-78`
   - **Fix**: Add useMemo to expensive calculations
   - **Estimated Time**: 15 minutes

[... additional medium-priority bugs ...]

---

## Validation Results

### Type Check

**Command**: `pnpm type-check`

**Status**: ✅ PASSED

**Output**:
\```
tsc --noEmit
No type errors found.
Checked 147 files in 2.34s
\```

**Exit Code**: 0

### Build

**Command**: `pnpm build`

**Status**: ✅ PASSED

**Output**:
\```
vite build
✓ 147 modules transformed
✓ built in 3.45s
dist/index.js  125.3 kB
dist/styles.css  45.2 kB
\```

**Exit Code**: 0

### Tests (Optional)

**Command**: `pnpm test`

**Status**: ✅ PASSED (42/42)

**Output**:
\```
jest
PASS  src/api/database.test.ts
PASS  src/auth/session.test.ts
PASS  src/utils/parser.test.ts
...
Tests: 42 passed, 42 total
Time:  4.567s
\```

**Exit Code**: 0

### Overall Status

**Validation**: ✅ PASSED

All validation checks completed successfully. Codebase is stable and buildable despite bugs found.

---

## Next Steps

### Immediate Actions (Required)

1. **Fix Critical Bugs** (P0)
   - Start with memory leak in connection pool (highest impact)
   - Then race condition in session management
   - Finally unhandled promise rejection

2. **Run Regression Tests**
   - After each critical fix, run full test suite
   - Verify no new issues introduced

3. **Deploy Fixes**
   - Critical fixes should be deployed immediately
   - Consider hotfix release

### Recommended Actions (Optional)

- Schedule high-priority bugs for current sprint
- Create tickets for medium-priority bugs
- Consider adding integration tests for race conditions

### Follow-Up

- Повторно запустить сканирование багов после исправлений для проверки устранения
- Мониторить использование памяти в продакшене после исправления пула подключений
- Обновить документацию с усвоенными уроками

---

## Приложение A: Просканированные файлы

Всего: 147 файлов

- TypeScript файлы: 125
- React компоненты: 45
- Тестовые файлы: 42
- Конфигурации: 5

---

## Приложение B: Конфигурация сканирования

- **Режим**: Тщательный
- **Паттерны**: TypeScript, React
- **Исключено**: node_modules, dist, .git
- **Таймаут**: Отсутствует
- **Максимальная глубина**: Неограничена
```

---

### Пример 2: Отчет аудита безопасности

```markdown
---
report_type: security-audit
generated: 2025-10-17T15:45:00Z
version: final
status: partial
agent: security-scanner
duration: 5m 12s
vulnerabilities_found: 7
critical_vulns: 2
high_vulns: 3
medium_vulns: 2
low_vulns: 0
rls_policies_checked: 15
---

# Отчет аудита безопасности: final

**Сгенерировано**: 2025-10-17 15:45:00 UTC
**Статус**: ⚠️ partial
**Версия**: final
**Агент**: security-scanner
**Продолжительность**: 5m 12s
**Найдено уязвимостей**: 7

---

## Итоги

Аудит безопасности завершен с **2 критическими уязвимостями**, требующими немедленного внимания.

### Ключевые метрики

- **Оценка безопасности**: 65/100 (Требует улучшения)
- **Критические уязвимости**: 2 (НЕОТЛОЖНО)
- **Высокие уязвимости**: 3 (Этот спринт)
- **Проверенные политики RLS**: 15 (3 отсутствуют)
- **Покрытие OWASP Top 10**: 80%

### Основные моменты

- ❌ 2 критические уязвимости требуют немедленного исправления
- ❌ Найдены жестко закодированные учетные данные в файлах конфигурации
- ⚠️ 3 отсутствующие политики RLS в таблицах Supabase
- ✅ Уязвимости SQL-инъекций не обнаружены
- ✅ Промежуточное ПО аутентификации настроено правильно

---

## Подробные находки

### Сканирование OWASP Top 10

#### A01:2021 - Нарушен контроль доступа

- ⚠️ **3 проблемы найдены**

1. **Отсутствующая политика RLS в таблице `users`**
   - **Серьезность**: Критическая
   - **Расположение**: Таблица Supabase `users`
   - **Проблема**: Политика безопасности на уровне строк не определена
   - **Влияние**: Все аутентифицированные пользователи могут читать все пользовательские данные
   - **Устранение**: Добавить политику RLS:
     \```sql
     ALTER TABLE users ENABLE ROW LEVEL SECURITY;

     CREATE POLICY "Users can only see own data"
     ON users FOR SELECT
     USING (auth.uid() = id);
     \```

2. **Отсутствующая проверка авторизации в админ-эндпоинте**
   - **Серьезность**: Высокая
   - **Расположение**: `src/api/admin.ts:45`
   - **Проблема**: Админ-эндпоинт не проверяет роль администратора
   - **Влияние**: Любой аутентифицированный пользователь может получить доступ к админ-функциям
   - **Устранение**: Добавить промежуточное ПО проверки роли

#### A02:2021 - Криптографические сбои

- ❌ **1 критическая проблема найдена**

1. **Жестко закодированный секрет в конфигурации**
   - **Серьезность**: Критическая
   - **Расположение**: `config/secrets.ts:15`
   - **Проблема**: Жестко закодированный JWT секрет в исходном коде
   - **Влияние**: Любой, у кого есть доступ к коду, может подделывать токены
   - **Устранение**:
     1. Немедленно сменить раскрытый секрет
     2. Переместить в переменную окружения
     3. Добавить в .gitignore

#### A03:2021 - Инъекции

- ✅ **Проблем не найдено**
  - Все запросы к базе данных используют параметризованные выражения
  - Конкатенация сырого SQL не обнаружена

#### A04:2021 - Небезопасный дизайн

- ⚠️ **1 проблема найдена**

1. **Токен сброса пароля не истекает**
   - **Серьезность**: Средняя
   - **Расположение**: `src/auth/reset.ts:67`
   - **Проблема**: Токены сброса никогда не истекают
   - **Влияние**: Старые ссылки сброса остаются действительными неограниченно
   - **Устранение**: Добавить 1-часовое истечение токенов

[... дополнительные категории OWASP ...]

---

## Результаты валидации

### Проверка типов

**Команда**: `pnpm type-check`

**Статус**: ✅ PASSED

### Сборка

**Команда**: `pnpm build`

**Статус**: ✅ PASSED

### Тесты безопасности

**Команда**: `pnpm test:security`

**Статус**: ⚠️ PARTIAL (2/5 провалено)

**Вывод**:
\```
FAIL  src/api/admin.test.ts
  ● Admin API › should require admin role
    Expected 403, received 200

FAIL  src/auth/reset.test.ts
  ● Password Reset › tokens should expire
    Token still valid after 2 hours
\```

### Общий статус

**Валидация**: ⚠️ PARTIAL

Найдены критические уязвимости. Система функциональна, но безопасность требует улучшения.

---

## Следующие шаги

### Немедленные действия (НЕОТЛОЖНО)

1. **Сменить раскрытый JWT секрет**
   - Сгенерировать новый секрет
   - Обновить переменные окружения
   - Аннулировать все существующие токены
   - Развернуть немедленно

2. **Добавить отсутствующие политики RLS**
   - Таблица `users` (Критическая)
   - Таблица `posts` (Высокая)
   - Таблица `comments` (Высокая)

3. **Исправить авторизацию администратора**
   - Добавить проверку роли в админ-эндпоинты
   - Протестировать с не-админ пользователями
   - Развернуть с заменой секрета

### Рекомендуемые действия (Этот спринт)

- Добавить истечение токенов сброса пароля
- Реализовать ограничение частоты запросов на эндпоинты аутентификации
- Проверить и обновить документацию по безопасности

### Последующие действия

- Назначить ежемесячные аудиты безопасности
- Настроить автоматическое сканирование уязвимостей
- Обучить команду безопасным практикам программирования

---

## Приложение: Шаблоны политик RLS

\```sql
-- Таблица пользователей
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see own data"
ON users FOR SELECT
USING (auth.uid() = id);

-- Таблица постов
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public posts readable"
ON posts FOR SELECT
USING (is_public = true OR auth.uid() = user_id);
\```
```

---

## Контрольный список валидации

Используйте этот контрольный список при проверке отчетов:

### Структура отчета
- [ ] YAML frontmatter присутствует и действителен
- [ ] Заголовок соответствует формату: `# {Тип} Отчет: {Версия}`
- [ ] Заголовок включает все обязательные метаданные
- [ ] Все 5 обязательных разделов присутствуют

### Качество содержания
- [ ] Итоги кратки и понятны
- [ ] Ключевые метрики количественно определены
- [ ] Подробные находки конкретны и действенны
- [ ] Результаты валидации показывают фактически запущенные команды
- [ ] Следующие шаги конкретны и приоритизированы

### Согласованность статуса
- [ ] Статус заголовка соответствует YAML frontmatter
- [ ] Эмодзи статуса соответствует тексту статуса
- [ ] Статус валидации соответствует общему статусу
- [ ] Если провален, предоставлено объяснение

### Соответствие формату
- [ ] Форматирование Markdown корректно
- [ ] Блоки кода используют правильное выделение синтаксиса
- [ ] Списки правильно отформатированы
- [ ] Заголовки используют правильные уровни (H1, H2, H3)

---

## Использование рабочими агентами

### Шаг 1: Создать файл отчета

```markdown
Использовать навык generate-report-header для создания заголовка.
```

### Шаг 2: Добавить YAML Frontmatter

```markdown
Добавить YAML frontmatter в самом начале со всеми обязательными метаданными.
```

### Шаг 3: Заполнить итоги

```markdown
Резюмировать ключевые находки с 3-5 метриками.
```

### Шаг 4: Добавить подробные находки

```markdown
Следовать специфичной для типа отчета структуре подробных находок.
```

### Шаг 5: Запустить валидации

```markdown
Запустить проверку типов, сборку и необязательные тесты. Документировать результаты.
```

### Шаг 6: Добавить следующие шаги

```markdown
Предоставить конкретные, действенные следующие шаги, разделенные по приоритету.
```

### Шаг 7: Самопроверка

```markdown
Использовать навык validate-report-file для проверки полноты отчета.
```

### Шаг 8: Сохранить отчет

```markdown
Сохранить со стандартным именованием: {тип-отчета}-отчет-{версия}.md
```

---

**Версия шаблона**: 1.0
**Последнее обновление**: 2025-10-17
**Статус**: ✅ COMPLETE - Стандартный шаблон для всех отчетов
**Следующая задача**: Задача 3.4 - Создать спецификацию агента проверки (необязательно)
