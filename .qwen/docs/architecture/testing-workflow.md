# Workflow тестирования в Qwen Code Orchestrator Kit

**Версия:** 1.0.0  
**Дата:** 2026-03-25  
**Статус:** RELEASE

---

## 🎯 Цель документа

Этот документ описывает workflow тестирования в проекте Qwen Code Orchestrator Kit.

---

## 📊 Overview

```
TDD Workflow:
1. ✅ work_planning_test_assigner создаёт TEST/CODE задачи
2. ✅ work_testing_tdd_specialist пишет тесты → RED
3. ✅ work_backend_api_validator пишет код → GREEN
4. ✅ orc_testing_quality_assurer проверяет Quality Gate
5. ✅ Коммит в develop
```

---

## 📋 Этапы workflow

### **Этап 1: Создание задач (speckit-tasks-agent)**

**Вход:** plan.md, data-model.md, spec.md (4 модуля)  
**Выход:** tasks.md (N задач)

**Процесс:**
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
- Модуль: {module-api}
- Часы: 4
- TDD: true ← ОБЯЗАТЕЛЬНО!
- Acceptance criteria: ...
```

---

### **Этап 2: Разделение TEST/CODE (work_planning_test_assigner)**

**Вход:** tasks.md (N задач)  
**Выход:** tasks-with-test-assignments.json (2N задач)

**Процесс:**
```bash
task '{
  "subagent_type": "work_planning_test_assigner",
  "prompt": "Создай TEST/CODE разделение"
}'
```

**Результат:**
```json
{
  "tasks": [
    {
      "original_id": "T-004-001",
      "test_task": {
        "id": "T-004-001-T",
        "agent": "work_testing_tdd_specialist",
        "type": "TEST",
        "hours": 2
      },
      "code_task": {
        "id": "T-004-001-C",
        "agent": "work_backend_api_validator",
        "type": "CODE",
        "hours": 4,
        "depends_on": ["T-004-001-T"]
      }
    }
  ]
}
```

---

### **Этап 3: Назначение исполнителей (orc_planning_task_analyzer)**

**Вход:** tasks-with-test-assignments.json  
**Выход:** phase0-assignments.json

**Процесс:**
```bash
task '{
  "subagent_type": "orc_planning_task_analyzer",
  "prompt": "Назначь исполнителей"
}'
```

**Результат:**
```json
{
  "assignments": [
    {
      "task_id": "T-004-001-T",
      "agent": "work_testing_tdd_specialist",
      "status": "assigned"
    },
    {
      "task_id": "T-004-001-C",
      "agent": "work_backend_api_validator",
      "status": "pending",
      "depends_on": ["T-004-001-T"]
    }
  ]
}
```

---

### **Этап 4: Написание тестов (work_testing_tdd_specialist)**

**Вход:** T-004-001-T, acceptance criteria  
**Выход:** tests/test_004_001.py (RED)

**Процесс:**
```bash
task '{
  "subagent_type": "work_testing_tdd_specialist",
  "prompt": "Создай тесты для T-004-001-T"
}'
```

**Результат:**
```python
# tests/test_004_001_scaffolding.py
"""
Тесты для T-004-001: Project Scaffolding
"""

def test_health_check(client):
    """Health check endpoint должен возвращать 200"""
    response = client.get("/health")
    assert response.status_code == 200

def test_api_version(client):
    """API version endpoint должен возвращать версию"""
    response = client.get("/api/v1/status")
    assert response.status_code == 200
```

**Запуск тестов:**
```bash
pytest tests/test_004_001_scaffolding.py -v

# Результат:
# FAILED tests/test_004_001_scaffolding.py::test_health_check
# FAILED tests/test_004_001_scaffolding.py::test_api_version
# 2 failed, 0 passed ← RED (ожидаем код)
```

**Коммит:**
```bash
git add -A
git commit -m "test: добавить тесты для T-004-001 Project Scaffolding (RED)"
```

---

### **Этап 5: Написание кода (work_backend_api_validator)**

**Вход:** T-004-001-C, tests/test_004_001.py  
**Выход:** backend/app/main.py (GREEN)

**Процесс:**
```bash
task '{
  "subagent_type": "work_backend_api_validator",
  "prompt": "Реализуй T-004-001-C (тесты уже существуют)"
}'
```

**Результат:**
```python
# backend/app/main.py
from fastapi import FastAPI

app = FastAPI(title="{Project} API", version="0.1.0")

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/api/v1/status")
def api_status():
    return {"version": "0.1.0"}
```

**Запуск тестов:**
```bash
pytest tests/test_004_001_scaffolding.py -v

# Результат:
# PASSED tests/test_004_001_scaffolding.py::test_health_check
# PASSED tests/test_004_001_scaffolding.py::test_api_version
# 2 passed, 0 failed ← GREEN (код работает!)
```

**Коммит:**
```bash
git add -A
git commit -m "feat: реализовать T-004-001 Project Scaffolding (GREEN)"
```

---

### **Этап 6: Quality Gate (orc_testing_quality_assurer)**

**Вход:** Код, тесты  
**Выход:** Quality Gate passed

**Процесс:**
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

### **Этап 7: Merge в develop**

**Вход:** Feature-ветка с кодом  
**Выход:** develop обновлён

**Процесс:**
```bash
git checkout develop
git merge --no-ff feature/T-004-001-C -m "Merge branch 'feature/T-004-001-C'"
git push -u origin develop
```

---

## 📊 Диаграмма workflow

```
┌─────────────────────────────────────────────────────────┐
│  1. speckit-tasks-agent                                 │
│     tasks.md (N задач, TDD: true)                     │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│  2. work_planning_test_assigner                         │
│     tasks-with-test-assignments.json (2N задач)        │
│     - T-004-001-T (TEST)                                │
│     - T-004-001-C (CODE, depends_on: TEST)              │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│  3. orc_planning_task_analyzer                          │
│     phase0-assignments.json                             │
│     - Назначение исполнителей                           │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│  4. work_testing_tdd_specialist                         │
│     tests/test_004_001.py (RED)                         │
│     - Тесты написаны                                    │
│     - Тесты падают (RED)                                │
│     - Коммит                                            │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│  5. work_backend_api_validator                          │
│     backend/app/main.py (GREEN)                         │
│     - Код написан под тесты                             │
│     - Тесты прошли (GREEN)                              │
│     - Коммит                                            │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│  6. orc_testing_quality_assurer                         │
│     Quality Gate                                        │
│     - Pre-commit validation: PASSED                     │
│     - Покрытие: 85%                                     │
│     - Все тесты: GREEN                                  │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│  7. Git Merge                                           │
│     develop обновлён                                    │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Типы тестов

### **Unit тесты (work_testing_unit_test_writer)**

```python
# tests/test_module.py
def test_my_function():
    """Unit тест функции"""
    result = my_function("input")
    assert result == "expected_output"
```

**Требования:**
- ✅ Покрытие ≥ 80%
- ✅ Mock fixtures для внешних зависимостей
- ✅ Параметризованные тесты

---

### **Integration тесты (work_testing_integration_test_writer)**

```python
# tests/integration/test_api.py
def test_create_note_integration(client, test_db):
    """Integration тест создания заметки"""
    response = client.post("/api/v1/notes", json={"title": "Test"})
    assert response.status_code == 201
```

**Требования:**
- ✅ Тесты API endpoints
- ✅ Тесты баз данных
- ✅ Тесты внешних сервисов

---

### **E2E тесты (work_testing_e2e_test_writer)**

```python
# tests/e2e/test_user_workflow.py
def test_full_note_workflow(page):
    """E2E тест полного workflow"""
    page.goto("http://localhost:3000")
    page.click("text=Новая заметка")
    # ...
```

**Требования:**
- ✅ Пользовательские сценарии
- ✅ Кросс-браузерность
- ✅ Скриншоты при ошибках

---

### **Security тесты (work_testing_security_tester)**

```python
# tests/security/test_injections.py
def test_sql_injection_login(client):
    """Проверка на SQL инъекцию"""
    response = client.post("/api/v1/login", json={
        "email": "' OR '1'='1' --",
        "password": "anything"
    })
    assert response.status_code == 401
```

**Требования:**
- ✅ OWASP Top 10 проверка
- ✅ Vulnerability scan
- ✅ Security audit

---

## 📋 Метрики

| Метрика | Значение |
|---------|----------|
| **Время на задачу** | +2 часа (тесты) |
| **Покрытие** | ≥ 80% |
| **Качество кода** | Высокое |
| **Количество багов** | Низкое |
| **Время на исправление** | Низкое |

---

## 📋 Best Practices

### **1. TDD First**

```
✅ ВСЕГДА пиши тесты ПЕРЕД кодом
✅ Запускай тесты → RED (перед кодом)
✅ Пиши код → GREEN (после кода)
```

### **2. Разделение ответственности**

```
✅ test_engineer пишет тесты
✅ backend_dev пишет код
✅ НЕ смешивай ответственность
```

### **3. Quality Gate**

```
✅ ВСЕГДА проходи Quality Gate
✅ Проверяй покрытие (≥ 80%)
✅ Проверяй что ВСЕ тесты прошли
```

---

## 📋 Ссылки

- **tdd-architecture.md** — Архитектура TDD
- **tdd-guide.md** — Руководство по TDD
- **constitution.md** — Принцип 6: TDD

---

**Этот документ является обязательным для всех разработчиков и агентов!**
