# Руководство по TDD в Qwen Code Orchestrator Kit

**Версия:** 1.0.0  
**Дата:** 2026-03-25  
**Статус:** RELEASE

---

## 🎯 Цель документа

Это руководство описывает как применять TDD (Test-Driven Development) в проекте Qwen Code Orchestrator Kit.

---

## 📊 Что такое TDD?

**TDD (Test-Driven Development)** — это методология разработки, при которой тесты пишутся ПЕРЕД кодом.

**Классический TDD цикл:**

```
1. ✅ Написать тест (RED)
2. ✅ Написать код (GREEN)
3. ✅ Рефакторинг
```

---

## 📋 TDD в Qwen Code Orchestrator Kit

### **Автоматизированный TDD Workflow:**

```
1. ✅ work_planning_test_assigner создаёт TEST/CODE задачи
2. ✅ work_testing_tdd_specialist пишет тесты → RED
3. ✅ work_backend_api_validator пишет код → GREEN
4. ✅ orc_testing_quality_assurer проверяет Quality Gate
```

**Почему это работает:**

```
✅ backend_dev НИКОГДА не напишет тесты перед кодом
✅ Тесты без явного указания будут пропущены
✅ Разделение задач (test → code) улучшает качество кода
✅ Взаимодействие между агентами критически важно
```

---

## 🛠️ Как использовать TDD

### **Шаг 1: Создание задач**

```bash
task '{
  "subagent_type": "speckit-tasks-agent",
  "prompt": "Создай задачи для проекта"
}'
```

**Результат:**
```markdown
# tasks.md

## T-004-001: Project Scaffolding
- TDD: true ← ОБЯЗАТЕЛЬНО!
- Acceptance criteria: ...
```

---

### **Шаг 2: Разделение TEST/CODE**

```bash
task '{
  "subagent_type": "work_planning_test_assigner",
  "prompt": "Создай TEST/CODE разделение"
}'
```

**Результат:**
```json
{
  "test_task": {
    "id": "T-004-001-T",
    "agent": "work_testing_tdd_specialist",
    "type": "TEST"
  },
  "code_task": {
    "id": "T-004-001-C",
    "agent": "work_backend_api_validator",
    "type": "CODE",
    "depends_on": ["T-004-001-T"]
  }
}
```

---

### **Шаг 3: Написание тестов**

```bash
task '{
  "subagent_type": "work_testing_tdd_specialist",
  "prompt": "Создай тесты для T-004-001-T"
}'
```

**Процесс:**
1. ✅ Прочитать acceptance criteria
2. ✅ Создать тесты (tests/test_004_001.py)
3. ✅ Запустить тесты → RED (падение)
4. ✅ Закоммитить тесты

**Результат:**
```python
# tests/test_004_001_scaffolding.py

def test_health_check(client):
    """Health check endpoint должен возвращать 200"""
    response = client.get("/health")
    assert response.status_code == 200
```

```bash
pytest tests/test_004_001_scaffolding.py -v

# FAILED tests/test_004_001_scaffolding.py::test_health_check
# 1 failed, 0 passed ← RED (ожидаем код)
```

---

### **Шаг 4: Написание кода**

```bash
task '{
  "subagent_type": "work_backend_api_validator",
  "prompt": "Реализуй T-004-001-C (тесты уже существуют)"
}'
```

**Процесс:**
1. ✅ Прочитать тесты
2. ✅ Написать код под тесты (backend/app/main.py)
3. ✅ Запустить тесты → GREEN (прохождение)
4. ✅ Закоммитить код

**Результат:**
```python
# backend/app/main.py

from fastapi import FastAPI

app = FastAPI(title="{Project} API", version="0.1.0")

@app.get("/health")
def health_check():
    return {"status": "healthy"}
```

```bash
pytest tests/test_004_001_scaffolding.py -v

# PASSED tests/test_004_001_scaffolding.py::test_health_check
# 1 passed, 0 failed ← GREEN (код работает!)
```

---

### **Шаг 5: Quality Gate**

```bash
# Pre-commit validation
.qwen/scripts/quality-gates/pre-commit-validation.sh

# Full Quality Gate
.qwen/scripts/quality-gates/check-commit.sh

# Проверка покрытия
pytest --cov=backend --cov-report=html --cov-fail-under=80
```

**Результат:**
```
✅ Pre-commit validation: PASSED
✅ Quality Gate: PASSED
✅ Покрытие: 85% (≥ 80%)
✅ Все тесты прошли: GREEN
```

---

## 📋 Типы тестов

### **Unit тесты**

**Назначение:** Тестирование отдельных функций/классов

**Пример:**
```python
def test_calculate_total():
    """Тест расчёта общей суммы"""
    items = [10, 20, 30]
    total = calculate_total(items)
    assert total == 60
```

**Когда использовать:**
- ✅ Тестирование бизнес-логики
- ✅ Тестирование утилитарных функций
- ✅ Тестирование классов

---

### **Integration тесты**

**Назначение:** Тестирование взаимодействия между компонентами

**Пример:**
```python
def test_create_note_integration(client, test_db):
    """Интеграционный тест создания заметки"""
    response = client.post("/api/v1/notes", json={"title": "Test"})
    assert response.status_code == 201
```

**Когда использовать:**
- ✅ Тестирование API endpoints
- ✅ Тестирование баз данных
- ✅ Тестирование внешних сервисов

---

### **E2E тесты**

**Назначение:** Тестирование полных пользовательских сценариев

**Пример:**
```python
def test_full_note_workflow(page):
    """E2E тест полного workflow"""
    page.goto("http://localhost:3000")
    page.click("text=Новая заметка")
    # ...
```

**Когда использовать:**
- ✅ Тестирование пользовательских сценариев
- ✅ Тестирование UI/UX
- ✅ Кросс-браузерное тестирование

---

### **Security тесты**

**Назначение:** Поиск уязвимостей безопасности

**Пример:**
```python
def test_sql_injection_login(client):
    """Проверка на SQL инъекцию"""
    response = client.post("/api/v1/login", json={
        "email": "' OR '1'='1' --",
        "password": "anything"
    })
    assert response.status_code == 401
```

**Когда использовать:**
- ✅ Проверка на OWASP Top 10
- ✅ Vulnerability scan
- ✅ Security audit

---

## 📋 Best Practices

### **1. Пиши тесты ПЕРЕД кодом**

```
✅ ПРАВИЛЬНО:
1. Написать тест → RED
2. Написать код → GREEN
3. Рефакторинг

❌ НЕПРАВИЛЬНО:
1. Написать код
2. Написать тесты (если осталось время)
```

---

### **2. Один тест — одно утверждение**

```
✅ ПРАВИЛЬНО:
def test_health_check_returns_200():
    response = client.get("/health")
    assert response.status_code == 200

def test_health_check_returns_status():
    response = client.get("/health")
    assert "status" in response.json()

❌ НЕПРАВИЛЬНО:
def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert "status" in response.json()
    assert response.json()["status"] == "healthy"
    # ... 10 больше утверждений
```

---

### **3. Используй Mock fixtures**

```
✅ ПРАВИЛЬНО:
@pytest.fixture
def mock_database():
    db = Mock()
    db.query.return_value = []
    return db

def test_user_service_create(mock_database):
    service = UserService(mock_database)
    # ...

❌ НЕПРАВИЛЬНО:
def test_user_service_create():
    # Подключение к реальной базе данных
    db = Database()
    db.connect()
    # ...
```

---

### **4. Называй тесты понятно**

```
✅ ПРАВИЛЬНО:
def test_health_check_returns_200()
def test_create_note_with_valid_data()
def test_login_fails_with_invalid_password()

❌ НЕПРАВИЛЬНО:
def test1()
def test_stuff()
def test_my_function()
```

---

### **5. Проверяй покрытие**

```
✅ ПРАВИЛЬНО:
pytest --cov=backend --cov-report=html --cov-fail-under=80

# Отчёт:
Name                      Stmts   Miss  Cover
---------------------------------------------
backend/app/main.py          50      5    90%
backend/app/core/security    30      3    90%
---------------------------------------------
TOTAL                        80      8    90%

❌ НЕПРАВИЛЬНО:
pytest

# Покрытие: 0%
```

---

## 📋 Чек-лист TDD

### **Перед началом задачи:**

- [ ] Acceptance criteria прочитаны
- [ ] Тесты написаны ПЕРЕД кодом
- [ ] Тесты запущены → RED

### **После написания кода:**

- [ ] Тесты запущены → GREEN
- [ ] Покрытие ≥ 80%
- [ ] Quality Gate пройден
- [ ] Код закоммичен с тестами

---

## 📋 Troubleshooting

### **Проблема: Тесты не пишутся**

**Причина:** backend_dev пытается написать тесты

**Решение:**
```
✅ work_testing_tdd_specialist пишет тесты
✅ backend_dev пишет код под тесты
```

---

### **Проблема: Тесты не проходят (всё ещё RED)**

**Причина:** Код не реализован или реализован неправильно

**Решение:**
```
1. Проверить что код написан
2. Проверить что код соответствует тестам
3. Исправить код
4. Запустить тесты → GREEN
```

---

### **Проблема: Покрытие < 80%**

**Причина:** Не все функции покрыты тестами

**Решение:**
```
1. Запустить pytest --cov=backend --cov-report=html
2. Открыть отчёт (htmlcov/index.html)
3. Найти функции без тестов
4. Написать тесты
5. Проверить покрытие ≥ 80%
```

---

## 📋 Ссылки

- **tdd-architecture.md** — Архитектура TDD
- **testing-workflow.md** — Workflow тестирования
- **constitution.md** — Принцип 6: TDD
- **coding-standards.md** — TDD методология

---

**Это руководство является обязательным для всех разработчиков и агентов!**
