# Python Expertise Skill

## Описание
Навык эксперта Python: глубокие знания языка, библиотек, best practices.

## Компетенции

### Язык Python
- Синтаксис и семантика
- Типы данных и структуры
- Функции и классы
- Декораторы и контекстные менеджеры
- Генераторы и итераторы
- Async/await
- Метаклассы
- Descriptors

### Стандартная библиотека
- collections, itertools, functools
- pathlib, os, sys
- json, csv, xml
- re (regular expressions)
- datetime, time
- threading, multiprocessing
- asyncio
- unittest, doctest

### Популярные библиотеки

#### Web Frameworks
- FastAPI
- Django
- Flask
- Starlette

#### Data & ML
- pandas
- numpy
- scikit-learn
- matplotlib

#### Testing
- pytest
- hypothesis
- mock

#### Utilities
- requests
- pydantic
- sqlalchemy
- celery

## Best Practices

### Код стиль
```python
# Следуйте PEP 8
# Используйте type hints
def greet(name: str, greeting: str = "Hello") -> str:
    """Greet a person."""
    return f"{greeting}, {name}!"

# Используйте dataclasses
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str
    email: str
```

### Обработка ошибок
```python
# Специфичные исключения
try:
    result = process_data(data)
except ValidationError as e:
    logger.error(f"Validation failed: {e}")
    raise
except ProcessingError as e:
    logger.error(f"Processing failed: {e}")
    raise RetryableError(e)

# Контекстные менеджеры
with open('file.txt', 'r') as f:
    content = f.read()
```

### Производительность
```python
# Используйте генераторы для больших данных
def read_large_file(path: str):
    with open(path) as f:
        for line in f:
            yield line.strip()

# Кэширование
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_computation(n: int) -> int:
    return n ** 2

# List comprehensions вместо loops
squares = [x**2 for x in range(100)]
```

### Асинхронность
```python
import asyncio
import aiohttp

async def fetch_data(session: aiohttp.ClientSession, url: str) -> dict:
    async with session.get(url) as response:
        return await response.json()

async def main():
    async with aiohttp.ClientSession() as session:
        tasks = [
            fetch_data(session, url)
            for url in urls
        ]
        results = await asyncio.gather(*tasks)
```

## MCP Integration

### Использование Context7
```python
# Поиск библиотеки
library_id = mcp__context7__resolve-library-id(
    libraryName="fastapi",
    query="How to create async endpoint"
)

# Получение документации
docs = mcp__context7__query-docs(
    libraryId="/tiangolo/fastapi",
    query="Dependency injection example"
)
```

## Паттерны проектирования

### Singleton
```python
class Singleton:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
```

### Factory
```python
class AnimalFactory:
    @staticmethod
    def create(animal_type: str, name: str) -> Animal:
        if animal_type == "dog":
            return Dog(name)
        elif animal_type == "cat":
            return Cat(name)
        raise ValueError(f"Unknown animal type: {animal_type}")
```

### Repository
```python
class UserRepository:
    def __init__(self, db: Database):
        self.db = db
    
    def get_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id).first()
    
    def save(self, user: User) -> User:
        self.db.add(user)
        self.db.commit()
        return user
```

## Отладка

### Debugging техники
```python
# Logging
import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Breakpoint
def debug_function():
    breakpoint()  # Python 3.7+
    
# Profiling
import cProfile
cProfile.run('my_function()')
```

## Выходные артефакты
- Чистый Python код
- Type hints
- Docstrings
- Unit тесты
