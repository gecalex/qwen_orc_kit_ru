---
name: external-api-mocking
description: Мокирование внешних API. Генерация mock fixtures для pytest, mock для requests/urllib, mock для yt-dlp и API клиентов, маркеры тестов.
---

# External API Mocking Skill

## Когда использовать
- При написании тестов для кода с внешними зависимостями
- Для изоляции тестов от внешних сервисов
- При тестировании кода без доступа к сети
- Для ускорения выполнения тестов
- Для тестирования edge cases и ошибок API

## Инструкции

### 1. Генерация Mock Fixtures для Pytest

**Базовый шаблон фикстуры:**

```python
import pytest
from unittest.mock import Mock, patch, MagicMock
import json

@pytest.fixture
def mock_response():
    """Базовый мок для HTTP ответа."""
    mock = MagicMock()
    mock.status_code = 200
    mock.json.return_value = {"status": "success", "data": {}}
    mock.text = '{"status": "success", "data": {}}'
    mock.headers = {"Content-Type": "application/json"}
    mock.ok = True
    return mock

@pytest.fixture
def mock_http_session(mock_response):
    """Мок для HTTP сессии."""
    with patch('requests.Session') as mock_session:
        mock_session.return_value.get.return_value = mock_response
        mock_session.return_value.post.return_value = mock_response
        mock_session.return_value.put.return_value = mock_response
        mock_session.return_value.delete.return_value = mock_response
        yield mock_session
```

**Фикстуры для различных API:**

```python
@pytest.fixture
def mock_youtube_api():
    """Мок для YouTube API."""
    with patch('googleapiclient.discovery.build') as mock_build:
        mock_client = MagicMock()
        mock_build.return_value = mock_client
        
        # Mock для search
        mock_client.search().list().execute.return_value = {
            'items': [
                {'id': {'videoId': 'test_video_id'}}
            ]
        }
        
        # Mock для videos
        mock_client.videos().list().execute.return_value = {
            'items': [
                {
                    'id': 'test_video_id',
                    'snippet': {
                        'title': 'Test Video',
                        'description': 'Test Description'
                    }
                }
            ]
        }
        
        yield mock_client

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
                mock_resp.json.return_value = {}
            mock_resp.status_code = 200
            return mock_resp
        
        mock_get.side_effect = side_effect
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
        mock_cursor.fetchone.return_value = None
        mock_cursor.execute.return_value = None
        
        yield mock_conn, mock_cursor
```

### 2. Mock для Requests/Urllib

**Mock для requests:**

```python
from unittest.mock import patch, MagicMock
import requests

# Базовый mock для requests.get
@patch('requests.get')
def test_api_call(mock_get):
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {'key': 'value'}
    mock_get.return_value = mock_response
    
    # Ваш тестовый код
    response = requests.get('https://api.example.com/data')
    assert response.status_code == 200
    assert response.json() == {'key': 'value'}

# Mock с side_effect для различных URL
@patch('requests.get')
def test_multiple_endpoints(mock_get):
    def side_effect(url, *args, **kwargs):
        mock_resp = MagicMock()
        if 'users' in url:
            mock_resp.json.return_value = [{'id': 1, 'name': 'User'}]
        elif 'posts' in url:
            mock_resp.json.return_value = [{'id': 1, 'title': 'Post'}]
        else:
            mock_resp.status_code = 404
        mock_resp.status_code = 200
        return mock_resp
    
    mock_get.side_effect = side_effect
    
    # Тесты...

# Mock для обработки ошибок
@patch('requests.get')
def test_api_error(mock_get):
    mock_get.side_effect = requests.exceptions.ConnectionError("Network error")
    
    # Тест обработки ошибки
    with pytest.raises(requests.exceptions.ConnectionError):
        requests.get('https://api.example.com/data')
```

**Mock для urllib:**

```python
from unittest.mock import patch, MagicMock
from urllib.request import urlopen
import json

@patch('urllib.request.urlopen')
def test_urllib_call(mock_urlopen):
    mock_response = MagicMock()
    mock_response.read.return_value = json.dumps({'status': 'ok'}).encode('utf-8')
    mock_response.getcode.return_value = 200
    mock_urlopen.return_value = mock_response
    
    # Ваш тестовый код
    with urlopen('https://api.example.com/data') as response:
        data = json.loads(response.read().decode('utf-8'))
        assert data['status'] == 'ok'
```

### 3. Mock для yt-dlp и Других API Клиентов

**Mock для yt-dlp:**

```python
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_youtube_downloader():
    """Мок для yt-dlp YoutubeDL."""
    with patch('yt_dlp.YoutubeDL') as MockYoutubeDL:
        mock_instance = MagicMock()
        MockYoutubeDL.return_value = mock_instance
        
        # Mock для download
        mock_instance.download.return_value = 0  # 0 означает успех
        
        # Mock для extract_info
        mock_instance.extract_info.return_value = {
            'id': 'test_video_id',
            'title': 'Test Video Title',
            'duration': 300,
            'uploader': 'Test Uploader',
            'formats': [
                {'format_id': '18', 'ext': 'mp4', 'resolution': '360p'},
                {'format_id': '22', 'ext': 'mp4', 'resolution': '720p'}
            ]
        }
        
        yield mock_instance

# Использование в тесте
def test_video_download(mock_youtube_downloader):
    from mymodule import download_video
    
    result = download_video('https://youtube.com/watch?v=test')
    
    assert result['id'] == 'test_video_id'
    mock_youtube_downloader.download.assert_called_once()

@pytest.fixture
def mock_youtube_with_error():
    """Мок для yt-dlp с ошибкой."""
    with patch('yt_dlp.YoutubeDL') as MockYoutubeDL:
        mock_instance = MagicMock()
        MockYoutubeDL.return_value = mock_instance
        
        # Mock для ошибки при download
        mock_instance.download.side_effect = Exception("Download failed")
        
        yield mock_instance

def test_video_download_error(mock_youtube_with_error):
    from mymodule import download_video
    
    with pytest.raises(Exception, match="Download failed"):
        download_video('https://youtube.com/watch?v=test')
```

**Mock для других популярных клиентов:**

```python
# Mock для boto3 (AWS)
@pytest.fixture
def mock_s3_client():
    """Мок для AWS S3 клиента."""
    with patch('boto3.client') as mock_boto:
        mock_client = MagicMock()
        mock_boto.return_value = mock_client
        
        mock_client.get_object.return_value = {
            'Body': MagicMock(read=lambda: b'file content')
        }
        mock_client.put_object.return_value = {'ETag': '"abc123"'}
        mock_client.list_objects_v2.return_value = {
            'Contents': [{'Key': 'file1.txt'}, {'Key': 'file2.txt'}]
        }
        
        yield mock_client

# Mock для openai
@pytest.fixture
def mock_openai_client():
    """Мок для OpenAI клиента."""
    with patch('openai.OpenAI') as MockOpenAI:
        mock_client = MagicMock()
        MockOpenAI.return_value = mock_client
        
        mock_client.chat.completions.create.return_value = MagicMock(
            choices=[
                MagicMock(
                    message=MagicMock(content="Mocked response")
                )
            ]
        )
        
        yield mock_client

# Mock для redis
@pytest.fixture
def mock_redis_client():
    """Мок для Redis клиента."""
    with patch('redis.Redis') as MockRedis:
        mock_client = MagicMock()
        MockRedis.return_value = mock_client
        
        mock_client.get.return_value = None
        mock_client.set.return_value = True
        mock_client.delete.return_value = 1
        mock_client.exists.return_value = False
        
        yield mock_client

# Mock для pymongo
@pytest.fixture
def mock_mongo_client():
    """Мок для MongoDB клиента."""
    with patch('pymongo.MongoClient') as MockMongo:
        mock_client = MagicMock()
        MockMongo.return_value = mock_client
        
        mock_db = MagicMock()
        mock_client.__getitem__.return_value = mock_db
        
        mock_collection = MagicMock()
        mock_db.__getitem__.return_value = mock_collection
        
        mock_collection.find_one.return_value = None
        mock_collection.insert_one.return_value = MagicMock(inserted_id='123')
        mock_collection.update_one.return_value = MagicMock(matched_count=1)
        
        yield mock_client
```

### 4. Маркеры Тестов

**Определение маркеров в conftest.py:**

```python
# conftest.py
import pytest

def pytest_configure(config):
    """Регистрация кастомных маркеров."""
    config.addinivalue_line(
        "markers", 
        "network: marks test as requiring network connection"
    )
    config.addinivalue_line(
        "markers", 
        "slow: marks test as slow running"
    )
    config.addinivalue_line(
        "markers", 
        "integration: marks test as integration test"
    )
    config.addinivalue_line(
        "markers", 
        "external_api: marks test as using external API"
    )
    config.addinivalue_line(
        "markers", 
        "requires_key: marks test as requiring API key"
    )
```

**Использование маркеров в тестах:**

```python
import pytest

# Тест, требующий сети (пропускается без флага --network)
@pytest.mark.network
def test_real_api_call():
    """Тест с реальным API вызовом."""
    response = requests.get('https://api.github.com')
    assert response.status_code == 200

# Тест с моком (быстрый, не требует сети)
def test_mocked_api_call(mock_github_api):
    """Тест с мокированным API."""
    response = requests.get('https://api.github.com/user')
    assert response.json()['login'] == 'testuser'

# Медленный тест
@pytest.mark.slow
def test_large_data_processing():
    """Медленный тест обработки данных."""
    # Длительная операция...
    pass

# Интеграционный тест
@pytest.mark.integration
def test_full_workflow():
    """Полный рабочий процесс."""
    # Тестирование полного workflow...
    pass

# Тест с внешним API
@pytest.mark.external_api
@pytest.mark.requires_key
def test_paid_api_service():
    """Тест платного API сервиса."""
    # Требует API ключ...
    pass

# Комбинация маркеров
@pytest.mark.network
@pytest.mark.slow
def test_slow_network_operation():
    """Медленная сетевая операция."""
    pass
```

**Запуск тестов с маркерами:**

```bash
# Запустить только тесты с моками (без сети)
pytest -m "not network"

# Запустить только сетевые тесты
pytest -m network

# Запустить быстрые тесты
pytest -m "not slow"

# Запустить интеграционные тесты
pytest -m integration

# Запустить все тесты, включая требующие API ключ
pytest -m "external_api and requires_key"

# Исключить медленные и сетевые тесты
pytest -m "not slow and not network"

# Запустить тесты с несколькими маркерами
pytest -m "network and slow"
```

**pytest.ini конфигурация:**

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

# По умолчанию исключать сетевые и медленные тесты
addopts = -m "not network and not slow"

# Настройка timeout для тестов
timeout = 300  # 5 минут
```

## Формат ввода

```json
{
  "apiType": "requests|urllib|yt-dlp|boto3|openai|redis|mongo|custom",
  "endpoints": ["array of endpoint patterns"],
  "mockBehavior": {
    "successResponse": {},
    "errorResponse": {},
    "sideEffects": []
  },
  "testMarkers": ["network", "slow", "integration"]
}
```

## Формат вывода

```python
# Сгенерированные фикстуры и тесты
@pytest.fixture
def mock_<api_name>():
    """Мок для <api_name>."""
    # Implementation...

@pytest.mark.<marker>
def test_<functionality>(mock_<api_name>):
    """Тест для <functionality>."""
    # Test implementation...
```

## Примеры

### Пример 1: Mock для REST API

```python
# tests/fixtures/mock_rest_api.py
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_rest_api():
    """Комплексный мок для REST API."""
    with patch('requests.Session') as MockSession:
        session_instance = MagicMock()
        MockSession.return_value = session_instance
        
        # Настройка ответов для различных endpoints
        def request_side_effect(method, url, *args, **kwargs):
            mock_resp = MagicMock()
            
            if '/users' in url:
                if method == 'GET':
                    mock_resp.json.return_value = [
                        {'id': 1, 'name': 'User 1'},
                        {'id': 2, 'name': 'User 2'}
                    ]
                elif method == 'POST':
                    mock_resp.json.return_value = {'id': 3, 'name': 'New User'}
                    mock_resp.status_code = 201
            elif '/products' in url:
                mock_resp.json.return_value = {
                    'products': [{'id': 1, 'name': 'Product'}]
                }
            else:
                mock_resp.status_code = 404
                mock_resp.json.return_value = {'error': 'Not found'}
            
            mock_resp.status_code = mock_resp.status_code if hasattr(mock_resp, 'status_code') else 200
            mock_resp.ok = mock_resp.status_code < 400
            return mock_resp
        
        session_instance.request.side_effect = request_side_effect
        yield session_instance

# tests/test_api_client.py
def test_get_users(mock_rest_api):
    from myapp.api_client import APIClient
    
    client = APIClient()
    users = client.get_users()
    
    assert len(users) == 2
    assert users[0]['name'] == 'User 1'
```

### Пример 2: Mock для YouTube Download

```python
# tests/fixtures/mock_youtube.py
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_youtube_download():
    """Мок для загрузки YouTube видео."""
    with patch('yt_dlp.YoutubeDL') as MockYoutubeDL:
        ytdl_instance = MagicMock()
        MockYoutubeDL.return_value = ytdl_instance
        
        # Успешная загрузка
        ytdl_instance.download.return_value = 0
        ytdl_instance.extract_info.return_value = {
            'id': 'dQw4w9WgXcQ',
            'title': 'Rick Astley - Never Gonna Give You Up',
            'duration': 212,
            'uploader': 'Rick Astley',
            'thumbnail': 'https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg'
        }
        
        yield ytdl_instance

@pytest.fixture
def mock_youtube_error():
    """Мок для ошибки YouTube."""
    with patch('yt_dlp.YoutubeDL') as MockYoutubeDL:
        ytdl_instance = MagicMock()
        MockYoutubeDL.return_value = ytdl_instance
        
        # Ошибка при загрузке
        ytdl_instance.download.side_effect = Exception(
            "ERROR: Video unavailable"
        )
        
        yield ytdl_instance

# tests/test_video_downloader.py
def test_download_success(mock_youtube_download):
    from myapp.downloader import VideoDownloader
    
    downloader = VideoDownloader()
    result = downloader.download('https://youtube.com/watch?v=dQw4w9WgXcQ')
    
    assert result['id'] == 'dQw4w9WgXcQ'
    assert result['title'] == 'Rick Astley - Never Gonna Give You Up'

def test_download_error(mock_youtube_error):
    from myapp.downloader import VideoDownloader
    
    downloader = VideoDownloader()
    
    with pytest.raises(Exception, match="Video unavailable"):
        downloader.download('https://youtube.com/watch?v=invalid')
```

## Best Practices

1. **Изолируйте тесты** - каждый тест должен использовать свои моки
2. **Используйте фикстуры** - для переиспользования mock конфигураций
3. **Маркируйте тесты** - для удобной фильтрации при запуске
4. **Тестируйте ошибки** - не только успешные сценарии
5. **Проверяйте вызовы** - используйте `assert_called_with` для проверки аргументов
6. **Избегайте реальных API** - в CI/CD используйте только моки
7. **Документируйте моки** - добавляйте docstring к каждой фикстуре
