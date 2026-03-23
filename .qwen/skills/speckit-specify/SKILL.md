---
name: speckit-specify
description: Создание спецификаций модулей через Speckit скрипт. Вторая команда после constitution.
tools:
 - run_shell_command
 - read_file
 - write_file
 - skill
---

# Skill: Создание спецификаций (Speckit)

## Когда использовать

Используй этот навык когда:
- Конституция уже создана
- Нужно создать спецификацию модуля
- Оркестратор предложил `speckit.specify`

## Инструкция

### Шаг 1: Получить название модуля
Запроси у оркестратора:
- Название модуля (например, "Notes", "Search", "Export")
- Краткое описание функциональности

### Шаг 2: Запуск скрипта
```bash
cd $PROJECT_ROOT
.qwen/specify/scripts/specify.sh "<название модуля>"
```

### Шаг 3: Ожидание завершения
Скрипт создаст в `.qwen/specify/specs/{ID}-{module}/`:
- `spec.md` — спецификация модуля
- `requirements.md` — требования
- `spec-summary.md` — краткое содержание
- `glossary.md` — глоссарий

### Шаг 4: Проверка результата
```bash
ls -la .qwen/specify/specs/
wc -l .qwen/specify/specs/*/spec.md
```

### Шаг 5: Возврат результата
Верни оркестратору:
- ✅ Статус: успех/неудача
- 📁 Путь к директории спецификации
- 📄 Список созданных файлов
- 📊 Количество строк

## Пример использования

**Оркестратор:**
```
task '{
  "subagent_type": "speckit-specify",
  "prompt": "Создай спецификацию для модуля Notes (заметки)"
}'
```

**Результат:**
```markdown
✅ Спецификация создана успешно!

**Модуль:** Notes (Заметки)
**Директория:** `.qwen/specify/specs/001-notes/`
**Файлы:**
- spec.md (245 строк)
- requirements.md (89 строк)
- spec-summary.md (34 строки)
- glossary.md (56 строк)

**Следующий шаг:** speckit.plan
```

## Обработка ошибок

**Если скрипт не найден:**
```bash
if [ ! -f ".qwen/specify/scripts/specify.sh" ]; then
    echo "❌ Скрипт specify.sh не найден"
    exit 1
fi
```

**Если название модуля не указано:**
```bash
if [ -z "$1" ]; then
    echo "❌ Название модуля не указано"
    echo "Использование: specify.sh <название модуля>"
    exit 1
fi
```

## Speckit Стандарт

**Порядок команд:**
1. `/speckit.constitution` ← ПЕРВАЯ
2. `/speckit.specify` ← ВТОРАЯ
3. `/speckit.clarify`
4. `/speckit.plan`
5. `/speckit.tasks`
6. `/speckit.implement`

**Источники:**
- https://github.com/github/spec-kit
- https://deepwiki.com/github/spec-kit/5.2-speckit.specify-feature-specification
