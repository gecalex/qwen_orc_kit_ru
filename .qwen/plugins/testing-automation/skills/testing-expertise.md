# Testing Expertise Skill

## Описание
Навык эксперта по тестированию: методологии, фреймворки, best practices.

## Компетенции

### Типы тестирования

#### Unit тестирование
- Тестирование отдельных функций/классов
- Изоляция зависимостей (mocking)
- Быстрое выполнение
- Высокий coverage

#### Integration тестирование
- Тестирование взаимодействия компонентов
- Database integration
- API integration
- External services

#### E2E тестирование
- Полные пользовательские сценарии
- Browser automation
- Real user flows
- Cross-browser testing

### Test пирамида
```
        /\
       /  \      E2E (10%)
      /----\    
     /      \   Integration (30%)
    /--------\  
   /          \ Unit (60%)
  /------------\
```

## Pytest возможности

### Fixtures
```python
import pytest

@pytest.fixture
def sample_data():
    return {"id": 1, "name": "Test"}

@pytest.fixture(scope="session")
def database():
    db = create_test_db()
    yield db
    db.cleanup()

def test_with_fixture(sample_data):
    assert sample_data["id"] == 1
```

### Parametrization
```python
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input, expected):
    assert double(input) == expected
```

### Marks
```python
@pytest.mark.slow
def test_slow_operation():
    pass

@pytest.mark.skip(reason="Not implemented")
def test_future():
    pass

@pytest.mark.xfail
def test_expected_failure():
    pass
```

### Async тесты
```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    result = await async_operation()
    assert result == expected
```

## Mocking

### unittest.mock
```python
from unittest.mock import Mock, patch, MagicMock

# Simple mock
mock_service = Mock()
mock_service.get_user.return_value = {"id": 1}

# Patch decorator
@patch('module.function')
def test_with_patch(mock_func):
    mock_func.return_value = "mocked"
    
# Context manager
with patch('module.function') as mock_func:
    mock_func.return_value = "mocked"
```

### pytest-mock
```python
def test_with_pytest_mock(mocker):
    mock = mocker.patch('module.function')
    mock.return_value = "mocked"
```

## Coverage

### Конфигурация
```ini
# .coveragerc
[run]
source = src/
omit = 
    tests/*
    */migrations/*
    */__main__.py

[report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise NotImplementedError
```

### Запуск
```bash
# Basic coverage
pytest --cov=src

# HTML отчет
pytest --cov=src --cov-report=html

# XML для CI
pytest --cov=src --cov-report=xml

# Fail below threshold
pytest --cov=src --cov-fail-under=80
```

## TDD цикл

### Red-Green-Refactor
```
1. RED: Написать падающий тест
2. GREEN: Написать код для прохождения
3. REFACTOR: Улучшить код
```

### Пример
```python
# 1. RED - Тест
def test_add():
    assert add(2, 3) == 5

# 2. GREEN - Implementation
def add(a, b):
    return a + b

# 3. REFACTOR - Улучшения
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b
```

## Best Practices

### Naming conventions
```python
def test_<function>_<scenario>_<expected>():
    pass

# Examples
def test_add_positive_numbers_returns_sum():
    pass

def test_divide_by_zero_raises_error():
    pass
```

### AAA pattern
```python
def test_example():
    # Arrange
    user = User(name="Test")
    
    # Act
    result = user.greet()
    
    # Assert
    assert result == "Hello, Test!"
```

### Independent тесты
```python
# BAD - Зависимые тесты
def test_create():
    global user_id
    user_id = create_user()

def test_get():
    user = get_user(user_id)  # Зависит от test_create

# GOOD - Независимые тесты
def test_create():
    user = create_user()
    assert user.id is not None

def test_get():
    user = create_user()  # Создает своего пользователя
    fetched = get_user(user.id)
    assert fetched.id == user.id
```

## MCP Integration

### Поиск testing библиотек
```
mcp__context7__resolve-library-id
  libraryName: "pytest"
  query: "pytest fixtures best practices"
```

## Выходные артефакты
- Unit тесты
- Integration тесты
- E2E тесты
- Coverage отчеты
