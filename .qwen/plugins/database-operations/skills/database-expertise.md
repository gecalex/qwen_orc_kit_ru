# Database Expertise Skill

## Описание
Навык эксперта по базам данных: SQL, проектирование, оптимизация.

## Компетенции

### SQL диалекты
- PostgreSQL
- MySQL/MariaDB
- SQLite
- Oracle
- SQL Server

### Типы баз данных

#### Реляционные (SQL)
- PostgreSQL - продвинутые функции
- MySQL - популярность
- SQLite - embedded

#### NoSQL
- MongoDB - document store
- Redis - key-value
- Cassandra - column-family
- Neo4j - graph

## SQL возможности

### JOIN типы
```sql
-- INNER JOIN
SELECT * FROM users u
INNER JOIN orders o ON u.id = o.user_id;

-- LEFT JOIN
SELECT * FROM users u
LEFT JOIN orders o ON u.id = o.user_id;

-- RIGHT JOIN
SELECT * FROM users u
RIGHT JOIN orders o ON u.id = o.user_id;

-- FULL OUTER JOIN
SELECT * FROM users u
FULL OUTER JOIN orders o ON u.id = o.user_id;

-- CROSS JOIN
SELECT * FROM users u
CROSS JOIN products p;
```

### Window функции
```sql
-- ROW_NUMBER
SELECT id, name, 
       ROW_NUMBER() OVER (ORDER BY created_at) as rn
FROM users;

-- RANK
SELECT id, score,
       RANK() OVER (ORDER BY score DESC) as rank
FROM players;

-- LAG/LEAD
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) as prev_month
FROM monthly_sales;

-- NTILE
SELECT id, score,
       NTILE(4) OVER (ORDER BY score DESC) as quartile
FROM students;
```

### CTE (Common Table Expressions)
```sql
-- Простой CTE
WITH active_users AS (
    SELECT * FROM users WHERE is_active = true
)
SELECT * FROM active_users;

-- Рекурсивный CTE
WITH RECURSIVE hierarchy AS (
    SELECT id, parent_id, name, 0 as level
    FROM categories
    WHERE parent_id IS NULL
    
    UNION ALL
    
    SELECT c.id, c.parent_id, c.name, h.level + 1
    FROM categories c
    JOIN hierarchy h ON c.parent_id = h.id
)
SELECT * FROM hierarchy;
```

## Индексация

### Типы индексов
```sql
-- B-Tree (default)
CREATE INDEX idx_name ON users(name);

-- Hash
CREATE INDEX idx_email ON users USING HASH(email);

-- GIN (arrays, full-text)
CREATE INDEX idx_tags ON posts USING GIN(tags);

-- GiST (geometric)
CREATE INDEX idx_location ON venues USING GIST(location);

-- Composite
CREATE INDEX idx_name_email ON users(name, email);

-- Partial
CREATE INDEX idx_active ON users(email) WHERE is_active = true;

-- Covering
CREATE INDEX idx_covering ON users(id) INCLUDE(name, email);
```

### Когда использовать индексы
- WHERE условия
- JOIN условия
- ORDER BY
- GROUP BY
- UNIQUE constraints

### Когда НЕ использовать
- Маленькие таблицы
- Часто обновляемые колонки
- Низкая селективность

## Оптимизация запросов

### EXPLAIN анализ
```sql
-- PostgreSQL
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- MySQL
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
```

### Оптимизация техник
```sql
-- Использовать EXISTS вместо IN
SELECT * FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);

-- Избегать SELECT *
SELECT id, name, email FROM users;

-- Использовать LIMIT
SELECT * FROM large_table LIMIT 100;

-- Индексированные условия
SELECT * FROM users 
WHERE created_at >= '2026-01-01';
```

## Транзакции

### ACID свойства
- **A**tomicity - атомарность
- **C**onsistency - согласованность
- **I**solation - изоляция
- **D**urability - долговечность

### Уровни изоляции
```sql
-- Read Uncommitted (самый низкий)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- Read Committed (PostgreSQL default)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Repeatable Read (MySQL default)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Serializable (самый высокий)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

### Пример транзакции
```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine('postgresql://...')
Session = sessionmaker(bind=engine)

def transfer_money(from_id, to_id, amount):
    session = Session()
    try:
        from_account = session.query(Account).get(from_id)
        to_account = session.query(Account).get(to_id)
        
        from_account.balance -= amount
        to_account.balance += amount
        
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
```

## Миграции

### Alembic
```python
# Создать миграцию
alembic revision -m "add_users_table"

# Применить
alembic upgrade head

# Откатить
alembic downgrade -1
```

### Пример миграции
```python
from alembic import op
import sqlalchemy as sa

def upgrade():
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('email', sa.String(255), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('email')
    )
    op.create_index('ix_users_email', 'users', ['email'])

def downgrade():
    op.drop_index('ix_users_email', table_name='users')
    op.drop_table('users')
```

## MCP Integration

### Поиск database библиотек
```
mcp__context7__resolve-library-id
  libraryName: "sqlalchemy"
  query: "SQLAlchemy ORM session management"
```

## Выходные артефакты
- SQL запросы
- Схемы баз данных
- Миграции
- Оптимизированные запросы
