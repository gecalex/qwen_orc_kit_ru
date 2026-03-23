---
name: speckit-constitution
description: Создание конституции проекта через Speckit скрипт. Первая команда — нет зависимостей.
tools:
 - run_shell_command
 - read_file
 - skill
---

# Skill: Создание конституции проекта (Speckit)

## Когда использовать

Используй этот навык когда:
- Проект пустой (код состояния 10)
- Нужно создать конституцию проекта
- Оркестратор предложил `speckit.constitution`

## Инструкция

### Шаг 1: Запуск скрипта
```bash
cd $PROJECT_ROOT
.qwen/specify/scripts/constitution.sh
```

### Шаг 2: Ожидание завершения
Скрипт создаст:
- `.qwen/specify/memory/constitution.md` — конституция проекта
- `.qwen/specify/memory/coding-standards.md` — стандарты кода
- `.qwen/specify/memory/architecture-rules.md` — архитектурные правила
- `.qwen/specify/memory/review-checklist.md` — чек-лист ревью

### Шаг 3: Проверка результата
Проверь, что файл создан:
```bash
ls -la .qwen/specify/memory/constitution.md
wc -l .qwen/specify/memory/constitution.md
```

### Шаг 4: Возврат результата
Верни оркестратору:
- ✅ Статус: успех/неудача
- 📄 Путь к файлу
- 📊 Количество строк
- 📋 Краткое содержание (разделы)

## Пример использования

**Оркестратор:**
```
task '{
  "subagent_type": "speckit-constitution",
  "prompt": "Создай конституцию для Personal Knowledge Base"
}'
```

**Результат:**
```markdown
✅ Конституция создана успешно!

**Файл:** `.qwen/specify/memory/constitution.md`
**Строк:** 744
**Разделы:**
1. Миссия проекта
2. Архитектурные принципы
3. Стандарты кода
4. Безопасность
5. Тестирование
6. Git workflow
7. Документация
8. Зависимости
```

## Обработка ошибок

**Если скрипт не найден:**
```bash
if [ ! -f ".qwen/specify/scripts/constitution.sh" ]; then
    echo "❌ Скрипт constitution.sh не найден"
    exit 1
fi
```

**Если ошибка выполнения:**
- Записать ошибку в лог
- Сообщить оркестратору
- Предложить альтернативу (создать вручную)

## Speckit Стандарт

**Согласно официальной документации:**
- Конституция создаётся ПЕРВОЙ
- Нет зависимостей от spec.md или tasks.md
- Располагается в `.qwen/specify/memory/constitution.md`

**Источники:**
- https://github.com/github/spec-kit
- https://deepwiki.com/github/spec-kit/5.4-other-commands
