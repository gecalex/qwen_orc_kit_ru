# Pre-Commit Валидация

## Обзор

Система pre-commit валидации обеспечивает автоматическую проверку синтаксиса и формата файлов перед коммитом. Это предотвращает попадание в репозиторий кода с ошибками синтаксиса и нарушениями формата.

## Назначение

- **Автоматическая проверка** синтаксиса перед каждым коммитом
- **Предотвращение ошибок** в репозитории
- **Стандартизация** формата файлов
- **Интеграция** с Quality Gate 3 (Pre-Commit Gate)

## Скрипты

### 1. pre-commit-validation.sh

**Путь:** `.qwen/scripts/quality-gates/pre-commit-validation.sh`

**Назначение:** Автоматическая валидация синтаксиса файлов

**Использование:**
```bash
# Базовая проверка
.qwen/scripts/quality-gates/pre-commit-validation.sh

# Подробный вывод
.qwen/scripts/quality-gates/pre-commit-validation.sh --verbose

# Справка
.qwen/scripts/quality-gates/pre-commit-validation.sh --help
```

**Проверки:**

| Тип файла | Инструмент | Описание |
|-----------|------------|----------|
| Python (`.py`) | `python -m py_compile` | Проверка синтаксиса Python |
| Bash (`.sh`, `.bash`) | `bash -n` | Проверка синтаксиса Bash |
| Markdown (`.md`, `.markdown`) | `markdownlint` | Линтинг Markdown |
| JSON (`.json`) | `jq` или `python -m json.tool` | Валидация JSON |
| YAML (`.yaml`, `.yml`) | `python + PyYAML` | Валидация YAML |

**Выходные коды:**
- `0` - Все проверки пройдены
- `1` - Валидация не пройдена (обнаружены ошибки)

**Пример вывода (успех):**
```
========================================
  Pre-Commit Валидация
========================================

ℹ Анализ файлов...

✓ Python: 5 файлов проверено
✓ Bash: 3 файла проверено
✓ Markdown: 2 файла проверено
✓ JSON: 1 файл проверено

========================================
  Итоги валидации
========================================

✅ Все проверки пройдены
```

**Пример вывода (ошибки):**
```
========================================
  Pre-Commit Валидация
========================================

ℹ Анализ файлов...

✗ Python: Ошибка в script.py
  File "script.py", line 10
    def broken(
               ^
SyntaxError: unexpected EOF while parsing

✗ Bash: Ошибка в deploy.sh
  deploy.sh: line 5: syntax error near unexpected token `fi'

========================================
  Итоги валидации
========================================

❌ Валидация не пройдена
Всего ошибок: 2
```

### 2. check-commit.sh

**Путь:** `.qwen/scripts/quality-gates/check-commit.sh`

**Назначение:** Полная проверка Quality Gate 3 перед коммитом

**Использование:**
```bash
# Запуск проверки
.qwen/scripts/quality-gates/check-commit.sh

# Справка
.qwen/scripts/quality-gates/check-commit.sh --help
```

**Проверки:**

1. **Валидация синтаксиса файлов**
   - Запускает `pre-commit-validation.sh`
   - Проверяет Python, Bash, Markdown, JSON, YAML

2. **Проверка Git workflow**
   - Запускает `check-workflow.sh`
   - Проверяет текущую ветку
   - Проверяет наличие незакоммиченных изменений
   - Проверяет синхронизацию с remote

3. **Валидация сообщения коммита**
   - Проверяет формат Conventional Commits
   - Паттерн: `type(scope): description`
   - Типы: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert

4. **Наличие и настройка .gitignore**
   - Проверяет существование файла
   - Проверяет наличие стандартных записей (node_modules, .env, __pycache__)

5. **Базовая проверка на наличие секретов**
   - Ищет паттерны API ключей
   - Ищет паттерны токенов
   - Предупреждает о потенциальных секретах

**Выходные коды:**
- `0` - Все проверки пройдены
- `1` - Проверка не пройдена (блокирующая ошибка)

## Интеграция в рабочий процесс

### Перед коммитом

```bash
# 1. Запустите pre-commit валидацию
.qwen/scripts/quality-gates/pre-commit-validation.sh --verbose

# 2. Если успешно, запустите полную проверку
.qwen/scripts/quality-gates/check-commit.sh

# 3. Если все проверки пройдены, выполните коммит
.qwen/scripts/git/pre-commit-review.sh "feat: Add new feature"
```

### В CI/CD

Добавьте в ваш CI/CD пайплайн:

```yaml
# Пример для GitHub Actions
jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.x'
      
      - name: Install dependencies
        run: |
          pip install pyyaml
          npm install -g markdownlint-cli
      
      - name: Pre-commit validation
        run: .qwen/scripts/quality-gates/pre-commit-validation.sh --verbose
      
      - name: Quality Gate 3
        run: .qwen/scripts/quality-gates/check-commit.sh
```

### Git hook (опционально)

Для автоматического запуска перед каждым коммитом создайте git hook:

```bash
# .git/hooks/pre-commit
#!/bin/bash
.qwen/scripts/quality-gates/pre-commit-validation.sh
exit $?
```

```bash
# Сделайте hook исполняемым
chmod +x .git/hooks/pre-commit
```

## Требования

### Обязательные

- **Git** - система контроля версий
- **Bash** - оболочка для выполнения скриптов

### Рекомендуемые

- **Python 3.x** - для проверки Python и YAML файлов
- **PyYAML** - для валидации YAML (`pip install pyyaml`)
- **markdownlint** - для линтинга Markdown (`npm install -g markdownlint-cli`)
- **jq** - для валидации JSON (`apt install jq` или `brew install jq`)

### Установка зависимостей

```bash
# Python и PyYAML
pip install pyyaml

# markdownlint
npm install -g markdownlint-cli

# jq (Ubuntu/Debian)
apt install jq

# jq (macOS)
brew install jq
```

## Устранение неполадок

### Ошибка: "Python не найден"

**Проблема:** Python не установлен или не в PATH

**Решение:**
```bash
# Проверка наличия Python
python --version
python3 --version

# Установка (Ubuntu/Debian)
apt install python3 python3-pip

# Установка (macOS)
brew install python
```

### Ошибка: "markdownlint: command not found"

**Проблема:** markdownlint не установлен

**Решение:**
```bash
npm install -g markdownlint-cli
```

### Ошибка: "jq: command not found"

**Проблема:** jq не установлен

**Решение:**
```bash
# Ubuntu/Debian
apt install jq

# macOS
brew install jq

# CentOS/RHEL
yum install jq
```

### Ошибка: "ModuleNotFoundError: No module named 'yaml'"

**Проблема:** PyYAML не установлен

**Решение:**
```bash
pip install pyyaml
# или
pip3 install pyyaml
```

### Проверка не проходит из-за предупреждений Markdown

**Проблема:** markdownlint находит предупреждения

**Решение:**
- Исправьте предупреждения согласно выводу markdownlint
- Или создайте файл `.markdownlint.json` с настройками:

```json
{
  "default": true,
  "MD013": false,
  "MD033": false
}
```

## Best Practices

1. **Запускайте перед каждым коммитом**
   - Не пропускайте проверки
   - Исправляйте ошибки немедленно

2. **Используйте --verbose для отладки**
   - Подробный вывод помогает найти причину ошибок

3. **Интегрируйте в CI/CD**
   - Автоматизируйте проверки в пайплайне

4. **Настройте git hooks**
   - Автоматический запуск перед коммитом

5. **Обновляйте зависимости**
   - Следите за актуальностью инструментов

## Примеры использования

### Пример 1: Базовая проверка

```bash
$ .qwen/scripts/quality-gates/pre-commit-validation.sh

========================================
  Pre-Commit Валидация
========================================

ℹ Анализ файлов...

✓ Python: 3 файлов проверено
✓ Bash: 1 файлов проверено

========================================
  Итоги валидации
========================================

✅ Все проверки пройдены
```

### Пример 2: Проверка с ошибками

```bash
$ .qwen/scripts/quality-gates/pre-commit-validation.sh --verbose

========================================
  Pre-Commit Валидация
========================================

ℹ Анализ файлов...

  Проверка Python: src/main.py
✗ Python: Ошибка в src/main.py
  File "src/main.py", line 15
    print("Hello"
                 ^
SyntaxError: unexpected EOF while parsing

========================================
  Итоги валидации
========================================

❌ Валидация не пройдена
Всего ошибок: 1
```

### Пример 3: Полная проверка Quality Gate 3

```bash
$ .qwen/scripts/quality-gates/check-commit.sh

========================================
  Quality Gate 3: Pre-Commit
========================================


=== Проверка синтаксиса файлов ===
✓ Валидация синтаксиса

=== Проверка Git workflow ===
✓ Git workflow

=== Проверка формата сообщения коммита ===
✓ Формат сообщения (Conventional Commits)
  Сообщение: feat(auth): Add JWT authentication

=== Проверка .gitignore ===
✓ Файл .gitignore существует
✓ .gitignore: node_modules
✓ .gitignore: .env файлы
✓ .gitignore: __pycache__

=== Проверка на наличие секретов ===
✓ Проверка секретов

========================================
  Итоги Quality Gate 3
========================================

Всего проверок: 9
Пройдено: 9
Не пройдено: 0

✅ Quality Gate 3 пройден

Можно выполнять коммит:
  git commit -m "type(scope): description"
```

## Связанная документация

- [Quality Gates](architecture/quality-gates.md) - Система контрольных точек качества
- [Git Workflow](git-workflow-automation.md) - Автоматизация Git workflow
- [QWEN.md](../../QWEN.md) - Раздел 3.2: Контрольные точки качества

## История изменений

| Версия | Дата | Изменения |
|--------|------|-----------|
| 0.6.0 | 2026-03-21 | Первоначальная реализация |
