---
name: validate-report-file
description: Проверка наличия всех обязательных разделов и правильного форматирования в отчетах, сгенерированных рабочими процессами. Используется в контрольных точках качества, для проверки полноты отчетов или при отладке отсутствующих разделов отчета.
allowed-tools: Read
---

# Проверка файла отчета

Проверка файлов отчетов, сгенерированных агентом, на полноту и правильную структуру.

## Когда использовать

- Проверка контрольных точек качества после завершения рабочего процесса
- Отладка отсутствующих разделов отчета
- Обеспечение согласованности отчетов
- Предварительная проверка перед отправкой

## Инструкции

### Шаг 1: Чтение файла отчета

Использовать инструмент Read для загрузки файла отчета.

**Ожидаемый ввод**:
- `file_path`: Путь к файлу отчета (например, `bug-hunting-report.md`)

**Используемые инструменты**: Read

### Шаг 2: Проверка обязательных разделов

Проверить наличие всех обязательных разделов.

**Обязательные разделы**:
1. **Заголовок** с метаданными:
   - Заголовок (# Тип отчета Report: Версия)
   - Временная метка создания
   - Индикатор статуса (✅/⚠️/❌)
   - Идентификатор версии

2. **Итоговое резюме**:
   - Заголовок ## Executive Summary
   - Ключевые метрики и выводы

3. **Подробные выводы**:
   - Варьируется в зависимости от типа отчета
   - Должен иметь хотя бы один раздел с деталями

4. **Результаты проверки**:
   - Заголовок ## Validation Results
   - Статус сборки/проверки типов
   - Общий статус проверки

5. **Следующие шаги**:
   - Заголовок ## Next Steps
   - Пункты действий или рекомендации

### Шаг 3: Проверка формата

Проверить форматирование и структуру.

**Правила форматирования**:
- Заголовок должен быть H1 (один #)
- Заголовки разделов должны быть H2 (##)
- Статус должен включать эмодзи (✅/⚠️/❌)
- Блоки кода должны использовать правильную разметку markdown
- Списки должны быть правильно отформатированы

### Шаг 4: Проверка согласованности статуса

Проверить, что индикаторы статуса согласованы.

**Проверки согласованности**:
- Статус заголовка соответствует статусу проверки
- Если статус "failed", проверка должна показывать сбои
- Если статус "success", проверка должна показывать прохождение

### Шаг 5: Возврат результата проверки

Вернуть подробный результат проверки.

**Ожидаемый вывод**:
```json
{
  "valid": true,
  "file": "bug-hunting-report.md",
  "sections": {
    "header": true,
    "executiveSummary": true,
    "detailedFindings": true,
    "validationResults": true,
    "nextSteps": true
  },
  "warnings": [],
  "errors": []
}
```

## Обработка ошибок

- **Файл не найден**: Вернуть ошибку с путем к файлу
- **Отсутствующие разделы**: Перечислить все отсутствующие обязательные разделы
- **Неверный формат**: Описать проблемы форматирования
- **Несогласованный статус**: Предупредить о несоответствии статусов

## Примеры

### Пример 1: Действительный отчет

**Ввод**:
```
file_path: bug-hunting-report.md
```

**Содержимое файла**:
```markdown
# Bug Hunting Report: 2025-10-17

**Generated**: 2025-10-17 14:30:00 UTC
**Status**: ✅ success

---

## Executive Summary

Found 23 bugs across 147 files.

## Detailed Findings

### Critical (3)
- Bug 1
- Bug 2
- Bug 3

## Validation Results

- Type-check: ✅ PASSED
- Build: ✅ PASSED

**Overall**: ✅ PASSED

## Next Steps

1. Review critical bugs
2. Schedule fixes
```

**Вывод**:
```json
{
  "valid": true,
  "file": "bug-hunting-report.md",
  "sections": {
    "header": true,
    "executiveSummary": true,
    "detailedFindings": true,
    "validationResults": true,
    "nextSteps": true
  },
  "warnings": [],
  "errors": []
}
```

### Пример 2: Отсутствующие разделы

**Ввод**:
```
file_path: incomplete-report.md
```

**Содержимое файла**:
```markdown
# Bug Report

Some bugs found.
```

**Вывод**:
```json
{
  "valid": false,
  "file": "incomplete-report.md",
  "sections": {
    "header": false,
    "executiveSummary": false,
    "detailedFindings": false,
    "validationResults": false,
    "nextSteps": false
  },
  "warnings": [],
  "errors": [
    "Missing header metadata (Generated, Status, Version)",
    "Missing section: Executive Summary",
    "Missing section: Detailed Findings",
    "Missing section: Validation Results",
    "Missing section: Next Steps"
  ]
}
```

### Пример 3: Несогласованный статус

**Ввод**:
```
file_path: inconsistent-report.md
```

**Содержимое файла**:
```markdown
# Bug Report: 2025-10-17

**Status**: ✅ success

## Executive Summary

Failed to scan files.

## Validation Results

**Overall**: ❌ FAILED
```

**Вывод**:
```json
{
  "valid": false,
  "file": "inconsistent-report.md",
  "sections": {
    "header": true,
    "executiveSummary": true,
    "detailedFindings": false,
    "validationResults": true,
    "nextSteps": false
  },
  "warnings": [
    "Status inconsistency: Header shows success (✅) but validation shows failed (❌)"
  ],
  "errors": [
    "Missing section: Detailed Findings",
    "Missing section: Next Steps"
  ]
}
```

## Проверка

- [ ] Проверяет наличие всех обязательных разделов
- [ ] Проверяет метаданные заголовка
- [ ] Проверяет согласованность статуса
- [ ] Обнаруживает проблемы форматирования
- [ ] Возвращает четкие сообщения об ошибках
- [ ] Корректно обрабатывает отсутствующие файлы

## Вспомогательные файлы

- `schema.json`: Схема структуры отчета (см. раздел Вспомогательные файлы)
