---
name: speckit-run
description: Универсальный запуск Speckit скриптов. Запускает любой скрипт из .qwen/specify/scripts/
tools:
 - run_shell_command
 - read_file
 - skill
---

# Skill: Универсальный запуск Speckit (Speckit Run)

## Когда использовать

Используй этот навык когда:
- Нужно запустить любой Speckit скрипт
- Оркестратор указал конкретный скрипт
- Требуется выполнение команды с аргументами

## Доступные скрипты

| Скрипт | Назначение | Аргументы |
|--------|------------|-----------|
| `constitution.sh` | Создание конституции | Нет |
| `specify.sh` | Создание спецификаций | `<название модуля>` |
| `clarify.sh` | Уточнение спецификаций | `<ID спецификации>` |
| `plan.sh` | Планирование | `<ID спецификации>` |
| `tasks.sh` | Разбивка на задачи | `<ID спецификации>` |
| `analyze.sh` | Анализ проекта | `<ID спецификации>` |
| `implement.sh` | Реализация | `<ID спецификации>` |
| `checklist.sh` | Создание чек-листа | `<ID спецификации>` |
| `taskstoissues.sh` | Экспорт в GitHub Issues | `<ID спецификации>` |

## Инструкция

### Шаг 1: Получить команду
Запроси у оркестратора:
- Название скрипта (например, `plan.sh`)
- Аргументы (если нужны)

### Шаг 2: Проверка существования
```bash
SCRIPT_PATH=".qwen/specify/scripts/<script_name>"
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Скрипт не найден: $SCRIPT_PATH"
    exit 1
fi
```

### Шаг 3: Запуск скрипта
```bash
cd $PROJECT_ROOT
chmod +x "$SCRIPT_PATH"
"$SCRIPT_PATH" <arguments>
```

### Шаг 4: Ожидание завершения
Дождаться завершения скрипта.

### Шаг 5: Проверка результата
```bash
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Скрипт выполнен успешно"
else
    echo "❌ Ошибка выполнения (код: $EXIT_CODE)"
fi
```

### Шаг 6: Возврат результата
Верни оркестратору:
- ✅ Статус: успех/неудача
- 📁 Созданные файлы
- 📊 Вывод скрипта
- ⏱️ Время выполнения

## Пример использования

**Оркестратор:**
```
task '{
  "subagent_type": "speckit-run",
  "prompt": "Запусти plan.sh для спецификации 001-notes"
}'
```

**Результат:**
```markdown
✅ Скрипт выполнен успешно!

**Скрипт:** `plan.sh`
**Аргументы:** `001-notes`
**Время:** 2m 34s
**Созданные файлы:**
- `.qwen/specify/specs/001-notes/plan.md` (156 строк)
- `.qwen/specify/specs/001-notes/data-model.md` (89 строк)
- `.qwen/specify/specs/001-notes/research.md` (45 строк)

**Следующий шаг:** speckit.tasks
```

## Обработка ошибок

**Скрипт не найден:**
```bash
if [ ! -f ".qwen/specify/scripts/$SCRIPT_NAME" ]; then
    echo "❌ Скрипт не найден: .qwen/specify/scripts/$SCRIPT_NAME"
    echo "Доступные скрипты:"
    ls -1 .qwen/specify/scripts/*.sh
    exit 1
fi
```

**Ошибка выполнения:**
```bash
"$SCRIPT_PATH" "$@" 2>&1 | tee /tmp/speckit-run.log
EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Ошибка выполнения (код: $EXIT_CODE)"
    echo "Лог: /tmp/speckit-run.log"
    exit $EXIT_CODE
fi
```

## Speckit Стандарт

**Полный порядок команд:**
1. `/speckit.constitution` — конституция
2. `/speckit.specify` — спецификации
3. `/speckit.clarify` — уточнение
4. `/speckit.plan` — планирование
5. `/speckit.tasks` — задачи
6. `/speckit.analyze` — анализ
7. `/speckit.implement` — реализация
8. `/speckit.checklist` — чек-лист
9. `/speckit.taskstoissues` — экспорт в GitHub

**Источники:**
- https://github.com/github/spec-kit
- https://deepwiki.com/github/spec-kit/5.4-other-commands
