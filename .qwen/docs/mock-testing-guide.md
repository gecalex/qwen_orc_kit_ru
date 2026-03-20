# Mock Testing Guide

Полное руководство по мокированию в тестах для Qwen Code Orchestrator Kit.

## Содержание

1. [Введение](#введение)
2. [Основы мокирования](#основы-мокирования)
3. [Mock First Rule](#mock-first-rule)
4. [Мокирование HTTP запросов](#мокирование-http-запросов)
5. [Мокирование баз данных](#мокирование-баз-данных)
6. [Мокирование файловых операций](#мокирование-файловых-операций)
7. [Мокирование внешних API](#мокирование-внешних-api)
8. [Маркеры тестов](#маркеры-тестов)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Введение

### Зачем нужно мокирование?

**Мокирование** — это техника изоляции тестируемого кода от внешних зависимостей путем замены реальных объектов на поддельные (mock), которые имитируют поведение реальных.

**Преимущества:**

| Преимущество | Описание |
|-------------|----------|
| 🚀 Скорость | Тесты выполняются быстрее без реальных вызовов |
| 🔒 Надежность | Тесты не зависят от доступности внешних сервисов |
| 🎯 Изоляция | Тестируется только ваш код, а не внешние зависимости |
| 💰 Экономия | Нет расходов на платные API вызовы |
| 🧪 Покрытие | Можно тестировать edge cases и ошибки |

### Когда использовать моки?

✅ **Использовать моки:**
- Тестирование бизнес-логики
- Интеграция с внешними API
- Работа с базой данных
- Файловые операции
- Сетевые запросы
- Дорогие операции

❌ **Не использовать моки:**
- End-to-end тесты
- Интеграционные тесты (иногда)
- Тесты производительности
- Тесты безопасности

---

## Основы мокирования

### unittest.mock

Python предоставляет встроенную библиотеку `unittest.mock` для мокирования.

```python
from unittest.mock import Mock, MagicMock, patch, AsyncMock
```

### Основные классы

**Mock** — базовый класс для создания mock объектов:

```python
from unittest.mock import Mock

mock = Mock()
mock.return_value = 42
mock(1, 2, 3)  # Возвращает 42
mock.assert_called_once_with(1, 2, 3)
```

**MagicMock** — расширенная версия Mock с поддержкой магических методов:

```python
from unittest.mock import MagicMock

mock = MagicMock()
mock.__str__.return_value = "custom string"
mock.__len__.return_value = 10
str(mock)  # "custom string"
len(mock)  # 10
```

**AsyncMock** — для асинхронных функций:

```python
from unittest.mock import AsyncMock

mock = AsyncMock()
mock.return_value = "async result"
result = await mock()  # "async result"
```

### Патчеры

**patch** — контекстный менеджер для замены объектов:

```python
from unittest.mock import patch

# Как декоратор
@patch('module.function')
def test_something(mock_func):
    mock_func.return_value = 42
    # Тест...

# Как контекстный менеджер
def test_something():
    with patch('module.function') as mock_func:
        mock_func.return_value = 42
        # Тест...

# Как объект
patcher = patch('module.function')
mock_func = patcher.start()
# Тест...
patcher.stop()
```

---

## Mock First Rule

### Принцип "Mock First"

При генерации тестов всегда следуйте порядку:

```
1. МОКИ → 2. ЛОГИКА → 3. МАРКЕРЫ
```

### Шаг 1: Создание моков

Определите все внешние зависимости и создайте для них моки:

```python
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_http_client():
    """Мок для HTTP клиента."""
    with patch('requests.get') as mock_get:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {'data': 'value'}
        mock_get.return_value = mock_response
        yield mock_get

@pytest.fixture
def mock_database():
    """Мок для базы данных."""
    with patch('sqlite3.connect') as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_connect.return_value = mock_conn
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = []
        yield mock_conn, mock_cursor
```

### Шаг 2: Написание тестовой логики

Используйте созданные фикстуры для тестирования:

```python
def test_fetch_data(mock_http_client, mock_database):
    """Тест получения данных."""
    from mymodule import fetch_and_store_data
    
    result = fetch_and_store_data('https://api.example.com/data')
    
    # Проверка результата
    assert result['status'] == 'success'
    
    # Проверка вызовов mock
    mock_http_client.assert_called_once_with('https://api.example.com/data')
    mock_database[1].execute.assert_called()
```

### Шаг 3: Добавление маркеров

Добавьте маркеры для классификации тестов:

```python
@pytest.mark.network
def test_real_api_call():
    """Тест с реальным API (требует сети)."""
    pass

@pytest.mark.slow
def test_large_dataset():
    """Медленный тест с большим набором данных."""
    pass

@pytest.mark.integration
def test_full_workflow():
    """Интеграционный тест полного workflow."""
    pass
```

---

## Мокирование HTTP запросов

### requests

```python
import pytest
from unittest.mock import patch, MagicMock
import requests

@pytest.fixture
def mock_requests_get():
    """Базовый мок для requests.get."""
    with patch('requests.get') as mock_get:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {'key': 'value'}
        mock_response.text = '{"key": "value"}'
        mock_response.headers = {'Content-Type': 'application/json'}
        mock_response.ok = True
        mock_get.return_value = mock_response
        yield mock_get

def test_api_call(mock_requests_get):
    """Тест API вызова."""
    from mymodule import fetch_data
    
    data = fetch_data('https://api.example.com/data')
    
    assert data == {'key': 'value'}
    mock_requests_get.assert_called_once_with('https://api.example.com/data')

@pytest.fixture
def mock_requests_with_side_effect():
    """Мок с разными ответами для разных URL."""
    def side_effect(url, *args, **kwargs):
        mock_resp = MagicMock()
        if 'users' in url:
            mock_resp.json.return_value = [{'id': 1, 'name': 'User'}]
        elif 'posts' in url:
            mock_resp.json.return_value = [{'id': 1, 'title': 'Post'}]
        else:
            mock_resp.status_code = 404
            mock_resp.json.return_value = {'error': 'Not found'}
        mock_resp.status_code = mock_resp.status_code if hasattr(mock_resp, 'status_code') else 200
        return mock_resp
    
    with patch('requests.get', side_effect=side_effect) as mock_get:
        yield mock_get

@pytest.fixture
def mock_requests_error():
    """Мок с ошибкой соединения."""
    with patch('requests.get') as mock_get:
        mock_get.side_effect = requests.exceptions.ConnectionError("Network error")
        yield mock_get

def test_connection_error(mock_requests_error):
    """Тест обработки ошибки соединения."""
    from mymodule import fetch_data
    
    with pytest.raises(requests.exceptions.ConnectionError):
        fetch_data('https://api.example.com/data')
```

### aiohttp (асинхронный)

```python
import pytest
from unittest.mock import AsyncMock, patch

@pytest.fixture
def mock_aiohttp_session():
    """Мок для aiohttp сессии."""
    with patch('aiohttp.ClientSession') as MockSession:
        session_instance = AsyncMock()
        MockSession.return_value.__aenter__.return_value = session_instance
        
        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={'data': 'value'})
        mock_response.text = AsyncMock(return_value='{"data": "value"}')
        
        session_instance.get.return_value.__aenter__.return_value = mock_response
        
        yield session_instance

async def test_async_api_call(mock_aiohttp_session):
    """Тест асинхронного API вызова."""
    from mymodule import async_fetch_data
    
    data = await async_fetch_data('https://api.example.com/data')
    
    assert data == {'data': 'value'}
```

---

## Мокирование баз данных

### SQLite

```python
import pytest
from unittest.mock import patch, MagicMock
import sqlite3

@pytest.fixture
def mock_sqlite():
    """Мок для SQLite."""
    with patch('sqlite3.connect') as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        
        mock_connect.return_value = mock_conn
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = [(1, 'item1'), (2, 'item2')]
        mock_cursor.fetchone.return_value = (1, 'item1')
        mock_cursor.execute.return_value = None
        mock_conn.commit.return_value = None
        mock_conn.close.return_value = None
        
        yield mock_conn, mock_cursor

def test_database_query(mock_sqlite):
    """Тест запроса к базе данных."""
    from mymodule import get_items
    
    conn, cursor = mock_sqlite
    items = get_items()
    
    assert len(items) == 2
    cursor.execute.assert_called_with('SELECT * FROM items')
```

### PostgreSQL (psycopg2)

```python
@pytest.fixture
def mock_psycopg2():
    """Мок для PostgreSQL."""
    with patch('psycopg2.connect') as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        
        mock_connect.return_value = mock_conn
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = []
        mock_conn.commit.return_value = None
        mock_conn.rollback.return_value = None
        
        yield mock_conn, mock_cursor
```

### Redis

```python
@pytest.fixture
def mock_redis():
    """Мок для Redis."""
    with patch('redis.Redis') as MockRedis:
        mock_client = MagicMock()
        MockRedis.return_value = mock_client
        
        mock_client.get.return_value = None
        mock_client.set.return_value = True
        mock_client.delete.return_value = 1
        mock_client.exists.return_value = False
        mock_client.keys.return_value = []
        mock_client.hgetall.return_value = {}
        
        yield mock_client

def test_redis_cache(mock_redis):
    """Тест кэширования в Redis."""
    from mymodule import get_cached_data
    
    data = get_cached_data('key')
    
    mock_redis.get.assert_called_with('key')
```

### MongoDB (pymongo)

```python
@pytest.fixture
def mock_mongodb():
    """Мок для MongoDB."""
    with patch('pymongo.MongoClient') as MockClient:
        mock_client = MagicMock()
        MockClient.return_value = mock_client
        
        mock_db = MagicMock()
        mock_client.__getitem__.return_value = mock_db
        
        mock_collection = MagicMock()
        mock_db.__getitem__.return_value = mock_collection
        
        mock_collection.find_one.return_value = None
        mock_collection.find.return_value = []
        mock_collection.insert_one.return_value = MagicMock(inserted_id='123')
        mock_collection.update_one.return_value = MagicMock(matched_count=1)
        
        yield mock_client
```

---

## Мокирование файловых операций

### Временные файлы и директории

```python
import pytest
from pathlib import Path

@pytest.fixture
def tmp_config(tmp_path):
    """Временный файл конфигурации."""
    config_file = tmp_path / "config.json"
    config_file.write_text('{"test": true, "debug": true}')
    yield config_file

@pytest.fixture
def tmp_dir_with_files(tmp_path):
    """Временная директория с файлами."""
    (tmp_path / "file1.txt").write_text("Content 1")
    (tmp_path / "file2.txt").write_text("Content 2")
    (tmp_path / "subdir").mkdir()
    (tmp_path / "subdir" / "nested.txt").write_text("Nested")
    yield tmp_path

def test_config_loading(tmp_config):
    """Тест загрузки конфигурации."""
    from mymodule import load_config
    
    config = load_config(tmp_config)
    
    assert config['test'] == True
    assert config['debug'] == True
```

### Mock для os.path

```python
import pytest
from unittest.mock import patch

@pytest.fixture
def mock_file_exists():
    """Мок для os.path.exists (файл существует)."""
    with patch('os.path.exists') as mock_exists:
        mock_exists.return_value = True
        yield mock_exists

@pytest.fixture
def mock_file_not_exists():
    """Мок для os.path.exists (файл не существует)."""
    with patch('os.path.exists') as mock_exists:
        mock_exists.return_value = False
        yield mock_exists

def test_file_check(mock_file_exists):
    """Тест проверки существования файла."""
    from mymodule import check_file
    
    assert check_file('test.txt') == True
    mock_file_exists.assert_called_with('test.txt')
```

### Mock для builtins.open

```python
@pytest.fixture
def mock_open_file():
    """Мок для встроенной функции open."""
    with patch('builtins.open') as mock_open:
        mock_file = MagicMock()
        mock_file.__enter__.return_value = mock_file
        mock_file.read.return_value = "file content"
        mock_file.write.return_value = None
        mock_open.return_value = mock_file
        yield mock_open

def test_file_read(mock_open_file):
    """Тест чтения файла."""
    from mymodule import read_file_content
    
    content = read_file_content('test.txt')
    
    assert content == "file content"
```

---

## Мокирование внешних API

### YouTube (yt-dlp)

```python
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_youtube_downloader():
    """Мок для yt-dlp."""
    with patch('yt_dlp.YoutubeDL') as MockYoutubeDL:
        mock_instance = MagicMock()
        MockYoutubeDL.return_value = mock_instance
        
        mock_instance.download.return_value = 0
        mock_instance.extract_info.return_value = {
            'id': 'test_video_id',
            'title': 'Test Video',
            'duration': 300,
            'uploader': 'Test Uploader',
            'formats': [
                {'format_id': '18', 'ext': 'mp4', 'resolution': '360p'},
                {'format_id': '22', 'ext': 'mp4', 'resolution': '720p'}
            ]
        }
        
        yield mock_instance

@pytest.fixture
def mock_youtube_error():
    """Мок для yt-dlp с ошибкой."""
    with patch('yt_dlp.YoutubeDL') as MockYoutubeDL:
        mock_instance = MagicMock()
        MockYoutubeDL.return_value = mock_instance
        
        mock_instance.download.side_effect = Exception("Video unavailable")
        mock_instance.extract_info.side_effect = Exception("Video unavailable")
        
        yield mock_instance

def test_video_download(mock_youtube_downloader):
    """Тест загрузки видео."""
    from mymodule import download_video
    
    result = download_video('https://youtube.com/watch?v=test')
    
    assert result['id'] == 'test_video_id'
    assert result['title'] == 'Test Video'

def test_video_download_error(mock_youtube_error):
    """Тест ошибки загрузки видео."""
    from mymodule import download_video
    
    with pytest.raises(Exception, match="Video unavailable"):
        download_video('https://youtube.com/watch?v=invalid')
```

### GitHub API

```python
@pytest.fixture
def mock_github_api():
    """Мок для GitHub API."""
    with patch('requests.get') as mock_get:
        def side_effect(url, *args, **kwargs):
            mock_resp = MagicMock()
            if 'repos' in url:
                mock_resp.json.return_value = {
                    'name': 'test-repo',
                    'full_name': 'user/test-repo',
                    'stargazers_count': 100
                }
            elif 'user' in url:
                mock_resp.json.return_value = {
                    'login': 'testuser',
                    'name': 'Test User'
                }
            else:
                mock_resp.status_code = 404
            mock_resp.status_code = mock_resp.status_code if hasattr(mock_resp, 'status_code') else 200
            return mock_resp
        
        mock_get.side_effect = side_effect
        yield mock_get
```

### OpenAI API

```python
@pytest.fixture
def mock_openai():
    """Мок для OpenAI API."""
    with patch('openai.OpenAI') as MockOpenAI:
        mock_client = MagicMock()
        MockOpenAI.return_value = mock_client
        
        mock_completion = MagicMock()
        mock_completion.choices = [
            MagicMock(
                message=MagicMock(content="Mocked response")
            )
        ]
        mock_completion.usage = MagicMock(
            prompt_tokens=10,
            completion_tokens=20,
            total_tokens=30
        )
        
        mock_client.chat.completions.create.return_value = mock_completion
        
        yield mock_client
```

### AWS S3 (boto3)

```python
@pytest.fixture
def mock_s3():
    """Мок для AWS S3."""
    with patch('boto3.client') as mock_boto:
        mock_client = MagicMock()
        mock_boto.return_value = mock_client
        
        mock_client.get_object.return_value = {
            'Body': MagicMock(read=lambda: b'file content')
        }
        mock_client.put_object.return_value = {'ETag': '"abc123"'}
        mock_client.list_objects_v2.return_value = {
            'Contents': [
                {'Key': 'file1.txt', 'Size': 100},
                {'Key': 'file2.txt', 'Size': 200}
            ]
        }
        
        yield mock_client
```

---

## Маркеры тестов

### Регистрация маркеров

Добавьте в `pytest.ini` или `conftest.py`:

```ini
# pytest.ini
[pytest]
markers =
    network: marks test as requiring network connection
    slow: marks test as slow running
    integration: marks test as integration test
    external_api: marks test as using external API
    requires_key: marks test as requiring API key
    unit: marks test as unit test
    e2e: marks test as end-to-end test
```

```python
# conftest.py
def pytest_configure(config):
    config.addinivalue_line("markers", "network: requires network")
    config.addinivalue_line("markers", "slow: slow running test")
    config.addinivalue_line("markers", "integration: integration test")
```

### Использование маркеров

```python
import pytest

# Тест с моками (быстрый, без сети)
def test_with_mocks(mock_requests_get):
    """Быстрый юнит тест."""
    pass

# Тест с реальным API (требует сети)
@pytest.mark.network
def test_real_api():
    """Тест с реальным API."""
    import requests
    response = requests.get('https://api.github.com')
    assert response.status_code == 200

# Медленный тест
@pytest.mark.slow
def test_large_processing():
    """Медленный тест обработки."""
    pass

# Интеграционный тест
@pytest.mark.integration
def test_full_workflow():
    """Полный workflow тест."""
    pass

# Комбинация маркеров
@pytest.mark.network
@pytest.mark.slow
def test_slow_network_test():
    """Медленный сетевой тест."""
    pass
```

### Запуск тестов с маркерами

```bash
# Запустить только тесты с моками (без сети)
pytest -m "not network"

# Запустить только сетевые тесты
pytest -m network

# Запустить быстрые тесты
pytest -m "not slow"

# Запустить интеграционные тесты
pytest -m integration

# Исключить медленные и сетевые тесты
pytest -m "not slow and not network"

# Запустить все тесты
pytest -m ""
```

---

## Best Practices

### 1. Изолируйте тесты

Каждый тест должен быть независимым:

```python
# ❌ ПЛОХО: Тесты зависят друг от друга
def test_1():
    global data
    data = fetch_data()

def test_2():
    # Зависит от test_1
    assert data is not None

# ✅ ХОРОШО: Каждый тест независим
def test_fetch_data(mock_api):
    data = fetch_data()
    assert data is not None

def test_process_data(mock_processor):
    data = get_test_data()
    result = process_data(data)
    assert result is not None
```

### 2. Используйте фикстуры

Переиспользуйте конфигурации моков через фикстуры:

```python
# conftest.py
@pytest.fixture
def mock_api():
    with patch('requests.get') as mock:
        mock.return_value.status_code = 200
        mock.return_value.json.return_value = {'data': 'value'}
        yield mock

# test_module.py
def test_feature_1(mock_api):
    pass

def test_feature_2(mock_api):
    pass
```

### 3. Проверяйте вызовы mock

Используйте assert для проверки взаимодействий:

```python
def test_api_call(mock_requests_get):
    from mymodule import fetch_data
    
    result = fetch_data('https://api.example.com/data')
    
    # Проверка вызова
    mock_requests_get.assert_called_once_with('https://api.example.com/data')
    
    # Проверка аргументов
    mock_requests_get.assert_called_with(
        'https://api.example.com/data',
        timeout=30
    )
    
    # Проверка количества вызовов
    assert mock_requests_get.call_count == 1
```

### 4. Тестируйте ошибки

Не только успешные сценарии:

```python
@pytest.fixture
def mock_api_error():
    with patch('requests.get') as mock:
        mock.side_effect = requests.exceptions.ConnectionError("Network error")
        yield mock

def test_connection_error(mock_api_error):
    from mymodule import fetch_data
    
    with pytest.raises(requests.exceptions.ConnectionError):
        fetch_data('https://api.example.com/data')
```

### 5. Используйте side_effect для сложных сценариев

```python
@pytest.fixture
def mock_api_sequence():
    with patch('requests.get') as mock:
        # Разные ответы для последовательных вызовов
        mock.side_effect = [
            MagicMock(status_code=200, json=lambda: {'page': 1}),
            MagicMock(status_code=200, json=lambda: {'page': 2}),
            MagicMock(status_code=404, json=lambda: {'error': 'Not found'}),
        ]
        yield mock

def test_pagination(mock_api_sequence):
    from mymodule import fetch_all_pages
    
    pages = fetch_all_pages()
    
    assert len(pages) == 2
    assert mock_api_sequence.call_count == 3
```

### 6. Документируйте фикстуры

Добавляйте docstring к каждой фикстуре:

```python
@pytest.fixture
def mock_youtube_downloader():
    """
    Мок для yt-dlp YoutubeDL.
    
    Возвращает:
        MagicMock: Настроенный mock для YoutubeDL с:
            - download() возвращает 0 (успех)
            - extract_info() возвращает тестовые метаданные
    
    Использование:
        def test_download(mock_youtube_downloader):
            result = download_video(url)
            assert result['id'] == 'test_id'
    """
    with patch('yt_dlp.YoutubeDL') as MockYoutubeDL:
        # ...
        yield mock_instance
```

---

## Troubleshooting

### Проблема: Mock не применяется

**Причина:** Неправильный путь для patch.

**Решение:** Patch должен указывать на место использования, а не определения:

```python
# ❌ ПЛОХО: Patch места определения
@patch('requests.get')

# ✅ ХОРОШО: Patch места использования
# Если в mymodule.py есть: import requests; requests.get(...)
@patch('mymodule.requests.get')
```

### Проблема: Mock не возвращает ожидаемое значение

**Причина:** Неправильная настройка return_value.

**Решение:**

```python
# ❌ ПЛОХО
mock.json.return_value = {'data': 'value'}
mock.json()  # Возвращает MagicMock

# ✅ ХОРОШО
mock_response = MagicMock()
mock_response.json.return_value = {'data': 'value'}
mock_get.return_value = mock_response
```

### Проблема: Тесты влияют друг на друга

**Причина:** Глобальное состояние или кэш.

**Решение:** Используйте фикстуры с proper cleanup:

```python
@pytest.fixture
def clean_cache():
    # Очистка перед тестом
    cache.clear()
    yield
    # Очистка после теста
    cache.clear()
```

### Проблема: Async mock не работает

**Причина:** Использование Mock вместо AsyncMock.

**Решение:**

```python
# ❌ ПЛОХО
mock = Mock()

# ✅ ХОРОШО
from unittest.mock import AsyncMock
mock = AsyncMock()
mock.return_value = "result"
```

---

## Приложения

### A. Шаблон conftest.py

```python
"""
conftest.py - Глобальные фикстуры для pytest.
"""

import pytest
from unittest.mock import patch, MagicMock, AsyncMock

# HTTP Mocks
@pytest.fixture
def mock_requests_get():
    with patch('requests.get') as mock:
        mock.return_value.status_code = 200
        mock.return_value.json.return_value = {}
        yield mock

# Database Mocks
@pytest.fixture
def mock_sqlite():
    with patch('sqlite3.connect') as mock:
        conn = MagicMock()
        cursor = MagicMock()
        mock.return_value = conn
        conn.cursor.return_value = cursor
        yield conn, cursor

# File System Mocks
@pytest.fixture
def tmp_config(tmp_path):
    config = tmp_path / "config.json"
    config.write_text('{"test": true}')
    yield config
```

### B. Шаблон теста

```python
"""
test_module.py - Шаблон теста.
"""

import pytest
from unittest.mock import patch, MagicMock

# Фикстуры (если не в conftest.py)
@pytest.fixture
def mock_dependency():
    with patch('module.dependency') as mock:
        mock.return_value = 'mocked'
        yield mock

# Тесты
def test_success_case(mock_dependency):
    """Тест успешного сценария."""
    from module import function
    
    result = function()
    
    assert result == 'expected'
    mock_dependency.assert_called_once()

def test_error_case(mock_dependency):
    """Тест ошибочного сценария."""
    mock_dependency.side_effect = Exception("Error")
    
    from module import function
    
    with pytest.raises(Exception):
        function()

@pytest.mark.network
def test_real_integration():
    """Интеграционный тест с реальным сервисом."""
    pass
```

### C. Checklist для создания тестов

- [ ] Определены все внешние зависимости
- [ ] Созданы фикстуры для моков
- [ ] Настроены return_value для success сценариев
- [ ] Настроены side_effect для error сценариев
- [ ] Написаны тесты с использованием фикстур
- [ ] Добавлены assert для проверки вызовов
- [ ] Добавлены маркеры (network, slow, integration)
- [ ] Тесты изолированы и независимы
- [ ] Тесты запускаются без сети
- [ ] Добавлены docstring к тестам и фикстурам
