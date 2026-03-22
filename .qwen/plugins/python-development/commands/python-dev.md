# Python Development Commands

## Описание
Команды для Python разработки: создание, тестирование, линтинг кода.

## Доступные команды

### `python-dev create-module`
Создать новый Python модуль с boilerplate кодом.

**Использование:**
```bash
python-dev create-module <module_name> [--package] [--async]
```

**Опции:**
- `--package` - Создать как пакет с __init__.py
- `--async` - Включить async шаблоны

**Пример:**
```bash
python-dev create-module user_service --package
```

**Выход:**
- Модуль с type hints
- Docstrings
- Базовая структура

---

### `python-dev create-class`
Создать Python класс с методами.

**Использование:**
```bash
python-dev create-class <class_name> --module <module_name> [--dataclass] [--abstract]
```

**Опции:**
- `--dataclass` - Использовать @dataclass декоратор
- `--abstract` - Создать абстрактный базовый класс

**Пример:**
```bash
python-dev create-class User --module models --dataclass
```

---

### `python-dev lint`
Запустить линтинг кода.

**Использование:**
```bash
python-dev lint [path] [--fix] [--strict]
```

**Опции:**
- `--fix` - Автоматически исправить проблемы
- `--strict` - Строгий режим (все warnings как errors)

**Пример:**
```bash
python-dev lint src/ --fix
```

**Инструменты:**
- black (форматирование)
- flake8 (linting)
- isort (импорты)
- mypy (type checking)

---

### `python-dev test`
Запустить тесты.

**Использование:**
```bash
python-dev test [path] [--coverage] [--watch]
```

**Опции:**
- `--coverage` - Сгенерировать coverage отчет
- `--watch` - Запустить в watch режиме

**Пример:**
```bash
python-dev test tests/ --coverage
```

---

### `python-dev refactor`
Рефакторинг кода.

**Использование:**
```bash
python-dev refactor <file> --type <refactor_type>
```

**Типы рефакторинга:**
- `extract-method` - Извлечь метод
- `rename` - Переименовать
- `move` - Переместить в другой модуль

**Пример:**
```bash
python-dev refactor src/service.py --type extract-method
```

---

### `python-dev docstring`
Сгенерировать docstrings.

**Использование:**
```bash
python-dev docstring <file> [--style google|numpy|sphinx]
```

**Пример:**
```bash
python-dev docstring src/module.py --style google
```

---

### `python-dev type-check`
Запустить проверку типов.

**Использование:**
```bash
python-dev type-check [path] [--strict]
```

**Пример:**
```bash
python-dev type-check src/ --strict
```

---

### `python-dev format`
Форматировать код.

**Использование:**
```bash
python-dev format [path]
```

**Пример:**
```bash
python-dev format src/
```

---

## Конфигурация

### .python-dev.json
```json
{
  "pythonVersion": "3.11",
  "linters": {
    "black": {
      "lineLength": 100,
      "targetVersion": "py311"
    },
    "flake8": {
      "maxLineLength": 100,
      "ignore": ["E203", "W503"]
    },
    "mypy": {
      "strict": true,
      "ignoreMissingImports": false
    }
  },
  "test": {
    "framework": "pytest",
    "coverage": {
      "threshold": 80,
      "failUnder": true
    }
  }
}
```

---

## Интеграция с MCP

При выполнении команд используйте:
- `mcp__context7__resolve-library-id` для поиска библиотек
- `mcp__context7__query-docs` для получения документации API

---

## Best Practices

1. Всегда запускайте линтинг перед коммитом
2. Поддерживайте coverage > 80%
3. Используйте type hints для всех функций
4. Пишите docstrings для публичных API
5. Следуйте PEP 8
