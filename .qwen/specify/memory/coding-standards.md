# Стандарты написания кода Qwen Code Orchestrator Kit

**Версия:** 1.0.0  
**Дата:** 2026-03-25

---

## 1. TDD (Test-Driven Development) — ОБЯЗАТЕЛЬНО!

### 1.1. Методология

**Все новые функции начинаются с тестов!**

```
1. ✅ Прочитать acceptance criteria из tasks.md
2. ✅ Написать тесты для КАЖДОГО criteria
3. ✅ Запустить тесты → убедиться что падают (RED)
4. ✅ Написать код → тесты должны пройти (GREEN)
5. ✅ Рефакторинг → тесты должны пройти
6. ✅ Закоммитить с тестами
```

### 1.2. Требования к тестам

**Python (pytest):**
```python
# tests/test_feature.py
def test_feature_acceptance_criteria():
    """Тест должен покрывать acceptance criteria из tasks.md"""
    # Arrange
    # Act
    # Assert
```

**JavaScript/TypeScript (Jest):**
```javascript
// tests/feature.test.js
describe('Feature', () => {
  it('должен соответствовать acceptance criteria', () => {
    // Arrange
    // Act
    // Assert
  });
});
```

### 1.3. Покрытие кода

**Минимальное покрытие:**
- ✅ Backend (Python): ≥ 80%
- ✅ Frontend (TypeScript): ≥ 80%
- ✅ Критические модули: ≥ 90%

**Проверка:**
```bash
# Python
pytest --cov=backend --cov-report=html --cov-fail-under=80

# JavaScript/TypeScript
jest --coverage --coverageThreshold='{"global": {"branches": 80, "functions": 80, "lines": 80, "statements": 80}}'
```

### 1.4. Запуск тестов ПЕРЕД коммитом

**ОБЯЗАТЕЛЬНО:**
```bash
# Запустить все тесты
pytest  # или jest

# Убедиться что все тесты прошли
# Только после этого коммитить
```

---

## 2. Quality Gate (ОБЯЗАТЕЛЬНО!)

### 2.1. Pre-commit Validation

**ПЕРЕД КАЖДЫМ коммитом:**
```bash
.qwen/scripts/quality-gates/pre-commit-validation.sh
```

**Проверки:**
- ✅ Синтаксис Python (`python -m py_compile`)
- ✅ Синтаксис Bash (`bash -n`)
- ✅ Линтинг Markdown (`markdownlint`)
- ✅ Валидация JSON (`jq`)
- ✅ Валидация YAML (`python + PyYAML`)

### 2.2. Full Quality Gate

**ПЕРЕД КАЖДЫМ коммитом:**
```bash
.qwen/scripts/quality-gates/check-commit.sh
```

**Дополнительные проверки:**
- ✅ Git workflow соблюдён
- ✅ Сообщение коммита (Conventional Commits)
- ✅ .gitignore настроен
- ✅ Нет секретов в коде

---

## 3. Conventional Commits

**Формат:**
```
type(scope): описание

[optional body]

[optional footer]
```

**Типы:**
- `feat:` — новая функция
- `fix:` — исправление бага
- `docs:` — документация
- `style:` — форматирование
- `refactor:` — рефакторинг
- `test:` — тесты
- `chore:` — обслуживание

**Примеры:**
```bash
feat(backend): добавить JWT аутентификацию
fix(frontend): исправить утечку памяти в useEffect
test(api): добавить тесты для /api/v1/users
docs(readme): обновить примеры использования
```

---

## 4. Git Workflow

### 4.1. Ветки

```
main — production (только релизы)
develop — development (основная ветка)
feature/* — новые функции
bugfix/* — исправления багов
hotfix/* — критические исправления
```

### 4.2. Процесс

```bash
# 1. Создать feature-ветку
git checkout develop
git checkout -b feature/my-feature

# 2. Работа над задачей
# TDD: тесты → код → тесты → рефакторинг

# 3. Pre-commit проверки
.qwen/scripts/quality-gates/pre-commit-validation.sh
.qwen/scripts/quality-gates/check-commit.sh

# 4. Коммит
git add -A
git commit -m "feat: моя функция"

# 5. Push и PR
git push -u origin feature/my-feature
# → Pull Request в develop

# 6. Merge после проверок
git checkout develop
git merge --no-ff feature/my-feature
git branch -d feature/my-feature
```

---

## 5. Стандарты кода

### 5.1. Python

**Стиль:** PEP 8
**Линтер:** `flake8` или `pylint`

```bash
# Проверка
flake8 backend/
pylint backend/
```

### 5.2. TypeScript/JavaScript

**Стиль:** Airbnb или Standard
**Линтер:** `eslint`

```bash
# Проверка
eslint frontend/
```

### 5.3. Markdown

**Линтер:** `markdownlint`

```bash
# Проверка
markdownlint *.md
```

---

## 6. Документирование

### 6.1. Docstrings

**Python:**
```python
def my_function(param1: str, param2: int) -> bool:
    """
    Краткое описание функции.
    
    Args:
        param1: Описание параметра 1
        param2: Описание параметра 2
    
    Returns:
        bool: Описание возвращаемого значения
    
    Raises:
        ValueError: Описание исключения
    """
```

### 6.2. JSDoc

**TypeScript:**
```typescript
/**
 * Краткое описание функции.
 * @param param1 - Описание параметра 1
 * @param param2 - Описание параметра 2
 * @returns Описание возвращаемого значения
 * @throws Error Описание исключения
 */
function myFunction(param1: string, param2: number): boolean {
  // ...
}
```

---

## 7. Безопасность

### 7.1. Запрещено

- ❌ Хардкод секретов (API keys, passwords)
- ❌ Логирование чувствительных данных
- ❌ SQL без параметризации
- ❌ eval() и аналоги

### 7.2. Проверка на секреты

**ПЕРЕД коммитом:**
```bash
# Проверка на секреты
grep -r "API_KEY\|PASSWORD\|SECRET" --include="*.py" --include="*.js" --include="*.ts"
```

---

## 8. Code Review

### 8.1. Чек-лист ревью

- [ ] TDD соблюдён (тесты перед кодом)
- [ ] Все тесты проходят
- [ ] Покрытие ≥ 80%
- [ ] Pre-commit validation пройден
- [ ] Conventional Commits соблюдён
- [ ] Git workflow соблюдён
- [ ] Документация обновлена
- [ ] Нет секретов в коде

---

**Этот документ является обязательным для всех разработчиков и агентов!**
