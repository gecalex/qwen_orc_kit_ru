# Database Commands

## Описание
Команды для операций с базами данных: миграции, запросы, оптимизация.

## Доступные команды

### `database migrate`
Создать и применить миграции.

**Использование:**
```bash
database migrate <action> [name]
```

**Действия:**
- `create <name>` - Создать новую миграцию
- `apply` - Применить все миграции
- `rollback` - Откатить последнюю миграцию
- `status` - Показать статус миграций

**Пример:**
```bash
database migrate create add_users_table
database migrate apply
```

---

### `database query`
Выполнить SQL запрос.

**Использование:**
```bash
database query <sql> [--format table|json|csv] [--output file]
```

**Опции:**
- `--format` - Формат вывода
- `--output` - Сохранить в файл

**Пример:**
```bash
database query "SELECT * FROM users WHERE active = true" --format json
```

---

### `database schema`
Управление схемой базы данных.

**Использование:**
```bash
database schema <action> [table]
```

**Действия:**
- `list` - Список всех таблиц
- `describe <table>` - Описание таблицы
- `export` - Экспорт схемы
- `import <file>` - Импорт схемы

**Пример:**
```bash
database schema describe users
database schema export --output schema.sql
```

---

### `database seed`
Заполнить базу данными.

**Использование:**
```bash
database seed [seeder] [--reset]
```

**Опции:**
- `--reset` - Очистить перед заполнением

**Пример:**
```bash
database seed users --reset
```

---

### `database backup`
Создать резервную копию.

**Использование:**
```bash
database backup [--full] [--output file]
```

**Опции:**
- `--full` - Полная копия (schema + data)
- `--output` - Путь к файлу

**Пример:**
```bash
database backup --full --output backup-2026-03-21.sql
```

---

### `database optimize`
Оптимизировать базу данных.

**Использование:**
```bash
database optimize [--analyze] [--vacuum]
```

**Опции:**
- `--analyze` - Обновить статистику
- `--vacuum` - Выполнить vacuum

**Пример:**
```bash
database optimize --analyze --vacuum
```

---

### `database index`
Управление индексами.

**Использование:**
```bash
database index <action> [name]
```

**Действия:**
- `list` - Список индексов
- `create <name> <table> <columns>` - Создать индекс
- `drop <name>` - Удалить индекс
- `analyze <name>` - Анализ использования

**Пример:**
```bash
database index create idx_users_email users email
```

---

### `database connection`
Управление подключениями.

**Использование:**
```bash
database connection <action>
```

**Действия:**
- `test` - Проверить подключение
- `pool` - Статистика pool
- `kill <id>` - Завершить подключение

**Пример:**
```bash
database connection test
```

---

## Конфигурация

### .database.json
```json
{
  "default": "development",
  "connections": {
    "development": {
      "type": "postgresql",
      "host": "localhost",
      "port": 5432,
      "database": "app_dev",
      "username": "dev_user",
      "password": "${DB_PASSWORD}"
    },
    "production": {
      "type": "postgresql",
      "host": "${DB_HOST}",
      "port": 5432,
      "database": "app_prod",
      "username": "${DB_USER}",
      "password": "${DB_PASSWORD}",
      "ssl": true
    }
  },
  "migration": {
    "tool": "alembic",
    "directory": "migrations/",
    "table": "alembic_version"
  },
  "pool": {
    "minSize": 5,
    "maxSize": 20,
    "idleTimeout": 30000
  }
}
```

---

## Миграции Alembic

### Создать миграцию
```bash
alembic revision -m "add_users_table"
```

### Применить миграции
```bash
alembic upgrade head
```

### Откатить миграцию
```bash
alembic downgrade -1
```

---

## Best Practices

1. Всегда используйте миграции для изменений схемы
2. Тестируйте миграции на staging
3. Делайте backup перед миграциями
4. Используйте connection pooling
5. Индексируйте часто используемые запросы
