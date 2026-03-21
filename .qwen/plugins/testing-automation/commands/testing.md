# Testing Commands

## Описание
Команды для автоматизации тестирования: запуск тестов, генерация, coverage.

## Доступные команды

### `testing run`
Запустить тесты.

**Использование:**
```bash
testing run [path] [--framework pytest|jest|unittest] [--options]
```

**Опции:**
- `--framework` - Фреймворк для тестирования
- `--parallel` - Запустить параллельно
- `--watch` - Watch режим
- `--verbose` - Подробный вывод

**Пример:**
```bash
testing run tests/ --framework pytest --parallel
```

---

### `testing generate`
Сгенерировать тесты для кода.

**Использование:**
```bash
testing generate <file> [--type unit|integration] [--coverage]
```

**Опции:**
- `--type` - Тип тестов (unit, integration)
- `--coverage` - Включить coverage проверки

**Пример:**
```bash
testing generate src/service.py --type unit
```

**Генерирует:**
- Test функции для каждой публичной функции
- Mock объекты для зависимостей
- Parametrized тесты для граничных случаев

---

### `testing coverage`
Сгенерировать coverage отчет.

**Использование:**
```bash
testing coverage [--format html|xml|text] [--threshold N]
```

**Опции:**
- `--format` - Формат отчета
- `--threshold` - Минимальный порог coverage

**Пример:**
```bash
testing coverage --format html --threshold 80
```

**Отчеты:**
- HTML с подсветкой кода
- XML для CI интеграции
- Text для консоли

---

### `testing watch`
Запустить тесты в watch режиме.

**Использование:**
```bash
testing watch [path] [--only-failures]
```

**Опции:**
- `--only-failures` - Запускать только упавшие тесты

**Пример:**
```bash
testing watch src/
```

---

### `testing report`
Сгенерировать тестовый отчет.

**Использование:**
```bash
testing report [--format junit|html|markdown] [--output file]
```

**Пример:**
```bash
testing report --format junit --output test-results.xml
```

---

### `testing fixtures`
Управление тестовыми fixtures.

**Использование:**
```bash
testing fixtures <action> [name]
```

**Действия:**
- `list` - Список всех fixtures
- `create <name>` - Создать новый fixture
- `update <name>` - Обновить fixture
- `delete <name>` - Удалить fixture

**Пример:**
```bash
testing fixtures create sample_user
```

---

### `testing mock`
Сгенерировать mock объекты.

**Использование:**
```bash
testing mock <class_or_function> [--output file]
```

**Пример:**
```bash
testing mock UserService --output tests/mocks/user_service.py
```

---

### `testing e2e`
Запустить E2E тесты.

**Использование:**
```bash
testing e2e [suite] [--browser chromium|firefox|webkit] [--headed]
```

**Опции:**
- `--browser` - Браузер для тестов
- `--headed` - Запустить с UI (не headless)

**Пример:**
```bash
testing e2e login --browser chromium
```

---

## Конфигурация

### .testing.json
```json
{
  "defaultFramework": "pytest",
  "pytest": {
    "addopts": "-v --tb=short",
    "testpaths": ["tests/"],
    "python_files": ["test_*.py"],
    "python_functions": ["test_*"]
  },
  "coverage": {
    "source": ["src/"],
    "omit": ["tests/", "*/migrations/*"],
    "threshold": 80,
    "failUnder": true
  },
  "e2e": {
    "defaultBrowser": "chromium",
    "headless": true,
    "timeout": 30000,
    "video": "on-first-retry",
    "screenshot": "only-on-failure"
  }
}
```

---

## CI/CD Интеграция

### GitHub Actions
```yaml
- name: Run Tests
  run: testing run --coverage
  
- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage.xml
```

---

## Best Practices

1. Пишите тесты до реализации (TDD)
2. Поддерживайте coverage > 80%
3. Используйте fixtures для общих данных
4. Изолируйте тесты друг от друга
5. Запускайте тесты в CI/CD
