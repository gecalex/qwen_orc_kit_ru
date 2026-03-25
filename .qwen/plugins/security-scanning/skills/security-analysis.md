# Security Analysis Skill

## Описание
Навык анализа безопасности: выявление уязвимостей, оценка рисков, рекомендации.

## Компетенции

### Типы уязвимостей

#### OWASP Top 10
1. **Injection** - SQL, NoSQL, OS, LDAP
2. **Broken Authentication** - Session management
3. **Sensitive Data Exposure** - Encryption
4. **XML External Entities** - XXE attacks
5. **Broken Access Control** - Authorization
6. **Security Misconfiguration** - Default settings
7. **Cross-Site Scripting** - XSS attacks
8. **Insecure Deserialization** - Object injection
9. **Known Vulnerabilities** - Outdated components
10. **Insufficient Logging** - Monitoring gaps

### Python специфичные уязвимости

#### Hardcoded credentials
```python
# BAD
PASSWORD = "secret123"
API_KEY = "sk-1234567890"

# GOOD
import os
PASSWORD = os.environ.get('PASSWORD')
API_KEY = os.environ.get('API_KEY')
```

#### Command injection
```python
# BAD
import os
os.system(f"ls {user_input}")

# GOOD
import subprocess
subprocess.run(['ls', user_input], check=True)
```

#### SQL injection
```python
# BAD
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")

# GOOD
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```

#### Insecure deserialization
```python
# BAD
import pickle
data = pickle.loads(user_input)

# GOOD
import json
data = json.loads(user_input)
```

#### YAML unsafe loading
```python
# BAD
import yaml
data = yaml.load(user_input)

# GOOD
import yaml
data = yaml.safe_load(user_input)
```

### Анализ зависимостей

#### Проверка уязвимостей
```bash
# Safety
safety check

# Pip-audit
pip-audit

# Snyk
snyk test
```

#### Обновление зависимостей
```bash
# Обновить все
pip-review --auto

# Обновить конкретную
pip install --upgrade package
```

### Security сканеры

#### Bandit
```bash
# Запуск
bandit -r src/

# С отчетом
bandit -r src/ -f json -o report.json

# Исключить пути
bandit -r src/ -x tests/,venv/
```

#### Semgrep
```bash
# Запуск правил
semgrep --config=p/security-audit .

# Кастомные правила
semgrep --config=my-rules.yaml .
```

## Оценка рисков

### CVSS scoring
```
Base Score = f(Impact, Exploitability)

Impact = SubScore(ImpactSubScore)
Exploitability = SubScore(ExploitabilitySubScore)

Severity:
- 9.0-10.0: Critical
- 7.0-8.9: High
- 4.0-6.9: Medium
- 0.1-3.9: Low
```

### Risk матрица
```
                    Likelihood
                  Low   Medium  High
Impact High      Med   High    Critical
       Medium    Low   Med     High
       Low       Low   Low     Med
```

## Рекомендации по исправлению

### Приоритизация
1. **Critical** - Немедленное исправление (24 часа)
2. **High** - Исправить в спринте
3. **Medium** - Запланировать
4. **Low** - Улучшение

### Паттерны исправления

#### Input validation
```python
from pydantic import BaseModel, EmailStr, validator

class UserInput(BaseModel):
    email: EmailStr
    age: int
    
    @validator('age')
    def validate_age(cls, v):
        if v < 0 or v > 150:
            raise ValueError('Invalid age')
        return v
```

#### Authentication
```python
from passlib.context import CryptContext
from datetime import datetime, timedelta
import jwt

pwd_context = CryptContext(schemes=["bcrypt"])

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(password: str, hash: str) -> bool:
    return pwd_context.verify(password, hash)

def create_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(hours=1)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm="HS256")
```

#### Rate limiting
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.get("/api/resource")
@limiter.limit("100/minute")
async def get_resource(request: Request):
    return {"data": "resource"}
```

## MCP Integration

### Поиск security библиотек
```
mcp__context7__resolve-library-id
  libraryName: "bandit"
  query: "Python security scanner"
```

## Выходные артефакты
- Security scan отчеты
- Список уязвимостей
- План исправления
- Security рекомендации
