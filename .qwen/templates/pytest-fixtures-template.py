"""
Pytest Fixtures Template - Шаблоны для тестовых фикстур

Назначение: Предоставляет готовые шаблоны фикстур для мокирования
внешних зависимостей в тестах.

Использование:
    1. Скопируйте нужные фикстуры в ваш conftest.py
    2. Адаптируйте под ваши нужды
    3. Используйте в тестах через параметры функций
"""

import pytest
from unittest.mock import Mock, MagicMock, patch, AsyncMock
from pathlib import Path
import json
import tempfile
import shutil


# =============================================================================
# HTTP / API Mocks
# =============================================================================

@pytest.fixture
def mock_response():
    """
    Базовый мок для HTTP ответа.
    
    Использование:
        def test_api(mock_response):
            mock_response.json.return_value = {'key': 'value'}
    """
    mock = MagicMock()
    mock.status_code = 200
    mock.json.return_value = {"status": "success", "data": {}}
    mock.text = '{"status": "success", "data": {}}'
    mock.content = b'{"status": "success", "data": {}}'
    mock.headers = {
        "Content-Type": "application/json",
        "Content-Length": "35"
    }
    mock.ok = True
    mock.reason = "OK"
    mock.encoding = "utf-8"
    return mock


@pytest.fixture
def mock_http_session(mock_response):
    """
    Мок для HTTP сессии requests.
    
    Использование:
        def test_session(mock_http_session):
            session = requests.Session()
            response = session.get('https://api.example.com/data')
    """
    with patch('requests.Session') as mock_session:
        instance = mock_session.return_value
        instance.get.return_value = mock_response
        instance.post.return_value = mock_response
        instance.put.return_value = mock_response
        instance.delete.return_value = mock_response
        instance.patch.return_value = mock_response
        instance.head.return_value = mock_response
        yield mock_session


@pytest.fixture
def mock_requests_get(mock_response):
    """
    Мок для requests.get.
    
    Использование:
        def test_get(mock_requests_get):
            response = requests.get('https://api.example.com')
            assert response.status_code == 200
    """
    with patch('requests.get') as mock_get:
        mock_get.return_value = mock_response
        yield mock_get


@pytest.fixture
def mock_requests_post(mock_response):
    """
    Мок для requests.post.
    
    Использование:
        def test_post(mock_requests_post):
            response = requests.post('https://api.example.com', json={})
    """
    with patch('requests.post') as mock_post:
        mock_post.return_value = mock_response
        yield mock_post


@pytest.fixture
def mock_requests_with_side_effect():
    """
    Мок для requests с side_effect для различных URL.
    
    Использование:
        def test_multiple_endpoints(mock_requests_with_side_effect):
            # Разные ответы для разных URL
    """
    def side_effect(url, *args, **kwargs):
        mock_resp = MagicMock()
        
        if 'users' in url:
            mock_resp.json.return_value = [
                {'id': 1, 'name': 'User 1'},
                {'id': 2, 'name': 'User 2'}
            ]
        elif 'products' in url:
            mock_resp.json.return_value = {
                'products': [{'id': 1, 'name': 'Product'}]
            }
        elif 'error' in url:
            mock_resp.status_code = 500
            mock_resp.json.return_value = {'error': 'Internal Server Error'}
        else:
            mock_resp.json.return_value = {}
        
        mock_resp.status_code = 200 if mock_resp.status_code != 500 else 500
        mock_resp.ok = mock_resp.status_code < 400
        return mock_resp
    
    with patch('requests.get', side_effect=side_effect) as mock_get:
        yield mock_get


@pytest.fixture
def mock_requests_error():
    """
    Мок для requests с ошибкой соединения.
    
    Использование:
        def test_connection_error(mock_requests_error):
            with pytest.raises(requests.exceptions.ConnectionError):
                requests.get('https://api.example.com')
    """
    import requests
    
    with patch('requests.get') as mock_get:
        mock_get.side_effect = requests.exceptions.ConnectionError(
            "Network connection failed"
        )
        yield mock_get


@pytest.fixture
def mock_requests_timeout():
    """
    Мок для requests с timeout ошибкой.
    
    Использование:
        def test_timeout(mock_requests_timeout):
            with pytest.raises(requests.exceptions.Timeout):
                requests.get('https://api.example.com', timeout=5)
    """
    import requests
    
    with patch('requests.get') as mock_get:
        mock_get.side_effect = requests.exceptions.Timeout(
            "Request timed out after 5 seconds"
        )
        yield mock_get


# =============================================================================
# YouTube / yt-dlp Mocks
# =============================================================================

@pytest.fixture
def mock_youtube_downloader():
    """
    Мок для yt-dlp YoutubeDL.
    
    Использование:
        def test_download(mock_youtube_downloader):
            with YoutubeDL() as ydl:
                ydl.download(['https://youtube.com/watch?v=test'])
    """
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
            'channel': 'Test Channel',
            'upload_date': '20240101',
            'view_count': 1000000,
            'like_count': 50000,
            'thumbnail': 'https://i.ytimg.com/vi/test_video_id/maxresdefault.jpg',
            'description': 'Test video description',
            'formats': [
                {
                    'format_id': '18',
                    'ext': 'mp4',
                    'resolution': '360p',
                    'filesize': 50000000
                },
                {
                    'format_id': '22',
                    'ext': 'mp4',
                    'resolution': '720p',
                    'filesize': 150000000
                }
            ],
            'webpage_url': 'https://youtube.com/watch?v=test_video_id'
        }
        
        yield mock_instance


@pytest.fixture
def mock_youtube_downloader_error():
    """
    Мок для yt-dlp с ошибкой.
    
    Использование:
        def test_download_error(mock_youtube_downloader_error):
            with pytest.raises(Exception):
                download_video(url)
    """
    with patch('yt_dlp.YoutubeDL') as MockYoutubeDL:
        mock_instance = MagicMock()
        MockYoutubeDL.return_value = mock_instance
        
        # Mock для ошибки при download
        mock_instance.download.side_effect = Exception(
            "ERROR: Video unavailable or private"
        )
        
        # Mock для ошибки при extract_info
        mock_instance.extract_info.side_effect = Exception(
            "ERROR: Video unavailable"
        )
        
        yield mock_instance


@pytest.fixture
def mock_youtube_private_video():
    """
    Мок для yt-dlp с приватным видео.
    
    Использование:
        def test_private_video(mock_youtube_private_video):
            # Тест обработки приватного видео
    """
    with patch('yt_dlp.YoutubeDL') as MockYoutubeDL:
        mock_instance = MagicMock()
        MockYoutubeDL.return_value = mock_instance
        
        mock_instance.extract_info.side_effect = Exception(
            "ERROR: This video is private"
        )
        
        yield mock_instance


# =============================================================================
# Database Mocks
# =============================================================================

@pytest.fixture
def mock_sqlite_connection():
    """
    Мок для SQLite соединения.
    
    Использование:
        def test_database(mock_sqlite_connection):
            conn = sqlite3.connect('test.db')
            cursor = conn.cursor()
    """
    with patch('sqlite3.connect') as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        
        mock_connect.return_value = mock_conn
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = []
        mock_cursor.fetchone.return_value = None
        mock_cursor.execute.return_value = None
        mock_conn.commit.return_value = None
        mock_conn.close.return_value = None
        
        yield mock_conn, mock_cursor


@pytest.fixture
def mock_postgres_connection():
    """
    Мок для PostgreSQL соединения (psycopg2).
    
    Использование:
        def test_postgres(mock_postgres_connection):
            conn = psycopg2.connect(...)
    """
    with patch('psycopg2.connect') as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        
        mock_connect.return_value = mock_conn
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = []
        mock_cursor.fetchone.return_value = None
        mock_cursor.execute.return_value = None
        mock_conn.commit.return_value = None
        mock_conn.rollback.return_value = None
        
        yield mock_conn, mock_cursor


@pytest.fixture
def mock_redis_client():
    """
    Мок для Redis клиента.
    
    Использование:
        def test_redis(mock_redis_client):
            redis_client = redis.Redis()
            redis_client.get('key')
    """
    with patch('redis.Redis') as MockRedis:
        mock_client = MagicMock()
        MockRedis.return_value = mock_client
        
        # Basic operations
        mock_client.get.return_value = None
        mock_client.set.return_value = True
        mock_client.delete.return_value = 1
        mock_client.exists.return_value = False
        mock_client.keys.return_value = []
        mock_client.mget.return_value = []
        
        # Hash operations
        mock_client.hget.return_value = None
        mock_client.hset.return_value = 1
        mock_client.hgetall.return_value = {}
        mock_client.hdel.return_value = 1
        
        # List operations
        mock_client.lpush.return_value = 1
        mock_client.rpop.return_value = None
        mock_client.lrange.return_value = []
        
        # Pub/Sub
        mock_client.publish.return_value = 1
        mock_client.subscribe.return_value = None
        
        yield mock_client


@pytest.fixture
def mock_mongo_client():
    """
    Мок для MongoDB клиента (pymongo).
    
    Использование:
        def test_mongo(mock_mongo_client):
            client = pymongo.MongoClient()
            db = client['test_db']
    """
    with patch('pymongo.MongoClient') as MockMongo:
        mock_client = MagicMock()
        MockMongo.return_value = mock_client
        
        # Database access
        mock_db = MagicMock()
        mock_client.__getitem__.return_value = mock_db
        mock_client.__getattr__.return_value = mock_db
        
        # Collection access
        mock_collection = MagicMock()
        mock_db.__getitem__.return_value = mock_collection
        mock_db.__getattr__.return_value = mock_collection
        mock_db.list_collection_names.return_value = []
        
        # Collection operations
        mock_collection.find_one.return_value = None
        mock_collection.find.return_value = []
        mock_collection.insert_one.return_value = MagicMock(inserted_id='123456')
        mock_collection.insert_many.return_value = MagicMock(inserted_ids=['1', '2', '3'])
        mock_collection.update_one.return_value = MagicMock(matched_count=1, modified_count=1)
        mock_collection.update_many.return_value = MagicMock(matched_count=5, modified_count=5)
        mock_collection.delete_one.return_value = MagicMock(deleted_count=1)
        mock_collection.delete_many.return_value = MagicMock(deleted_count=5)
        mock_collection.count_documents.return_value = 0
        mock_collection.aggregate.return_value = []
        
        yield mock_client


# =============================================================================
# Cloud Services Mocks
# =============================================================================

@pytest.fixture
def mock_s3_client():
    """
    Мок для AWS S3 клиента (boto3).
    
    Использование:
        def test_s3(mock_s3_client):
            s3 = boto3.client('s3')
            s3.get_object(Bucket='bucket', Key='key')
    """
    with patch('boto3.client') as mock_boto:
        mock_client = MagicMock()
        mock_boto.return_value = mock_client
        
        # S3 operations
        mock_client.get_object.return_value = {
            'Body': MagicMock(read=lambda: b'file content'),
            'ContentLength': 12,
            'ContentType': 'text/plain'
        }
        mock_client.put_object.return_value = {
            'ETag': '"abc123def456"',
            'ServerSideEncryption': 'AES256'
        }
        mock_client.delete_object.return_value = {
            'DeleteMarker': False
        }
        mock_client.list_objects_v2.return_value = {
            'Contents': [
                {'Key': 'file1.txt', 'Size': 100},
                {'Key': 'file2.txt', 'Size': 200}
            ],
            'IsTruncated': False
        }
        mock_client.head_object.return_value = {
            'ContentLength': 100,
            'ContentType': 'text/plain',
            'LastModified': '2024-01-01T00:00:00Z'
        }
        mock_client.generate_presigned_url.return_value = 'https://presigned.url'
        
        yield mock_client


@pytest.fixture
def mock_gcs_client():
    """
    Мок для Google Cloud Storage клиента.
    
    Использование:
        def test_gcs(mock_gcs_client):
            from google.cloud import storage
            client = storage.Client()
    """
    with patch('google.cloud.storage.Client') as MockClient:
        mock_client = MagicMock()
        MockClient.return_value = mock_client
        
        # Bucket operations
        mock_bucket = MagicMock()
        mock_client.bucket.return_value = mock_bucket
        mock_client.get_bucket.return_value = mock_bucket
        mock_client.create_bucket.return_value = mock_bucket
        mock_client.list_buckets.return_value = [mock_bucket]
        
        # Blob operations
        mock_blob = MagicMock()
        mock_bucket.blob.return_value = mock_blob
        mock_bucket.list_blobs.return_value = [mock_blob]
        
        mock_blob.download_as_string.return_value = b'content'
        mock_blob.download_to_filename.return_value = None
        mock_blob.upload_from_string.return_value = None
        mock_blob.upload_from_filename.return_value = None
        mock_blob.exists.return_value = True
        mock_blob.delete.return_value = None
        
        yield mock_client


# =============================================================================
# AI/ML Service Mocks
# =============================================================================

@pytest.fixture
def mock_openai_client():
    """
    Мок для OpenAI клиента.
    
    Использование:
        def test_openai(mock_openai_client):
            client = openai.OpenAI()
            response = client.chat.completions.create(...)
    """
    with patch('openai.OpenAI') as MockOpenAI:
        mock_client = MagicMock()
        MockOpenAI.return_value = mock_client
        
        # Chat completions
        mock_completion = MagicMock()
        mock_completion.choices = [
            MagicMock(
                message=MagicMock(
                    content="This is a mocked response from OpenAI API"
                ),
                finish_reason="stop"
            )
        ]
        mock_completion.usage = MagicMock(
            prompt_tokens=10,
            completion_tokens=20,
            total_tokens=30
        )
        
        mock_client.chat.completions.create.return_value = mock_completion
        
        # Embeddings
        mock_embedding = MagicMock()
        mock_embedding.data = [
            MagicMock(embedding=[0.1, 0.2, 0.3])
        ]
        mock_embedding.usage = MagicMock(total_tokens=5)
        
        mock_client.embeddings.create.return_value = mock_embedding
        
        yield mock_client


@pytest.fixture
def mock_anthropic_client():
    """
    Мок для Anthropic Claude клиента.
    
    Использование:
        def test_anthropic(mock_anthropic_client):
            client = anthropic.Client()
            response = client.messages.create(...)
    """
    with patch('anthropic.Anthropic') as MockClient:
        mock_client = MagicMock()
        MockClient.return_value = mock_client
        
        # Messages
        mock_message = MagicMock()
        mock_message.content = [
            MagicMock(text="This is a mocked response from Claude")
        ]
        mock_message.stop_reason = "end_turn"
        mock_message.usage = MagicMock(
            input_tokens=10,
            output_tokens=20
        )
        
        mock_client.messages.create.return_value = mock_message
        
        yield mock_client


# =============================================================================
# File System Mocks
# =============================================================================

@pytest.fixture
def tmp_config(tmp_path):
    """
    Временная конфигурация для тестов.
    
    Использование:
        def test_config(tmp_config):
            config = load_config(tmp_config)
    """
    config_file = tmp_path / "config.json"
    config_file.write_text(json.dumps({
        "test": True,
        "debug": True,
        "api_key": "test_key",
        "timeout": 30
    }))
    yield config_file


@pytest.fixture
def tmp_empty_dir(tmp_path):
    """
    Пустая временная директория.
    
    Использование:
        def test_empty_dir(tmp_empty_dir):
            assert len(list(tmp_empty_dir.iterdir())) == 0
    """
    yield tmp_path


@pytest.fixture
def tmp_dir_with_files(tmp_path):
    """
    Временная директория с тестовыми файлами.
    
    Использование:
        def test_files(tmp_dir_with_files):
            for f in tmp_dir_with_files.iterdir():
                process(f)
    """
    # Создаем тестовые файлы
    (tmp_path / "file1.txt").write_text("Content 1")
    (tmp_path / "file2.txt").write_text("Content 2")
    (tmp_path / "file3.py").write_text("print('hello')")
    (tmp_path / "subdir").mkdir()
    (tmp_path / "subdir" / "nested.txt").write_text("Nested content")
    
    yield tmp_path


@pytest.fixture
def mock_file_system():
    """
    Мок для файловых операций.
    
    Использование:
        def test_fs(mock_file_system):
            with open('file.txt', 'r') as f:
                content = f.read()
    """
    with patch('builtins.open', new_callable=MagicMock) as mock_open:
        mock_file = MagicMock()
        mock_file.__enter__.return_value = mock_file
        mock_file.read.return_value = "mocked content"
        mock_file.write.return_value = None
        mock_open.return_value = mock_file
        
        yield mock_open


@pytest.fixture
def mock_path_exists():
    """
    Мок для os.path.exists.
    
    Использование:
        def test_path(mock_path_exists):
            assert os.path.exists('file.txt')
    """
    with patch('os.path.exists') as mock_exists:
        mock_exists.return_value = True
        yield mock_exists


@pytest.fixture
def mock_path_not_exists():
    """
    Мок для os.path.exists (файл не существует).
    
    Использование:
        def test_not_exists(mock_path_not_exists):
            assert not os.path.exists('missing.txt')
    """
    with patch('os.path.exists') as mock_exists:
        mock_exists.return_value = False
        yield mock_exists


# =============================================================================
# Async Mocks
# =============================================================================

@pytest.fixture
def mock_async_response():
    """
    Мок для асинхронного HTTP ответа (aiohttp).
    
    Использование:
        async def test_async(mock_async_response):
            async with aiohttp.ClientSession() as session:
                async with session.get(url) as resp:
                    data = await resp.json()
    """
    mock = AsyncMock()
    mock.status = 200
    mock.json = AsyncMock(return_value={"status": "success"})
    mock.text = AsyncMock(return_value='{"status": "success"}')
    mock.read = AsyncMock(return_value=b'{"status": "success"}')
    mock.headers = {"Content-Type": "application/json"}
    return mock


@pytest.fixture
def mock_aiohttp_session(mock_async_response):
    """
    Мок для aiohttp сессии.
    
    Использование:
        async def test_session(mock_aiohttp_session):
            async with aiohttp.ClientSession() as session:
                async with session.get(url) as resp:
                    pass
    """
    with patch('aiohttp.ClientSession') as mock_session:
        instance = mock_session.return_value
        instance.__aenter__.return_value = instance
        instance.get.return_value.__aenter__.return_value = mock_async_response
        instance.post.return_value.__aenter__.return_value = mock_async_response
        yield mock_session


@pytest.fixture
def mock_asyncio_sleep():
    """
    Мок для asyncio.sleep (мгновенное выполнение).
    
    Использование:
        async def test_sleep(mock_asyncio_sleep):
            await asyncio.sleep(10)  # Выполнится мгновенно
    """
    with patch('asyncio.sleep') as mock_sleep:
        mock_sleep.return_value = None
        yield mock_sleep


# =============================================================================
# Environment Mocks
# =============================================================================

@pytest.fixture
def mock_env_vars():
    """
    Мок для переменных окружения.
    
    Использование:
        def test_env(mock_env_vars):
            assert os.getenv('API_KEY') == 'test_key'
    """
    with patch.dict('os.environ', {
        'API_KEY': 'test_api_key',
        'DATABASE_URL': 'postgresql://localhost/test',
        'DEBUG': 'true',
        'LOG_LEVEL': 'DEBUG'
    }, clear=True):
        yield


@pytest.fixture
def clean_env():
    """
    Чистое окружение без переменных.
    
    Использование:
        def test_clean(clean_env):
            assert os.getenv('CUSTOM_VAR') is None
    """
    with patch.dict('os.environ', {}, clear=True):
        yield


# =============================================================================
# Logging Mocks
# =============================================================================

@pytest.fixture
def mock_logger():
    """
    Мок для логгера.
    
    Использование:
        def test_logging(mock_logger):
            logger.info("test message")
            mock_logger.info.assert_called_once()
    """
    with patch('logging.getLogger') as mock_get_logger:
        mock_logger = MagicMock()
        mock_get_logger.return_value = mock_logger
        yield mock_logger


# =============================================================================
# Time Mocks
# =============================================================================

@pytest.fixture
def mock_datetime():
    """
    Мок для datetime (фиксированное время).
    
    Использование:
        def test_time(mock_datetime):
            now = datetime.now()
            assert now.year == 2024
    """
    import datetime
    
    class MockDateTime(datetime.datetime):
        @classmethod
        def now(cls, tz=None):
            return cls(2024, 1, 1, 12, 0, 0)
    
    with patch('datetime.datetime', MockDateTime):
        yield


@pytest.fixture
def mock_time():
    """
    Мок для time.time (фиксированное время).
    
    Использование:
        def test_timestamp(mock_time):
            ts = time.time()
            assert ts == 1704110400
    """
    with patch('time.time') as mock_time:
        mock_time.return_value = 1704110400.0  # 2024-01-01 12:00:00 UTC
        yield mock_time
