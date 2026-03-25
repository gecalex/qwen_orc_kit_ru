# Автоматизация Git Workflow

**Версия:** 1.0.0
**Последнее обновление:** 2026-03-21
**Статус:** ✅ Готов к использованию

---

## 📋 Оглавление

1. [Обзор](#обзор)
2. [Установка и настройка](#установка-и-настройка)
3. [Скрипт create-feature-branch.sh](#create-feature-branchsh)
4. [Скрипт pre-commit-review.sh](#pre-commit-reviewsh)
5. [Скрипт auto-tag-release.sh](#auto-tag-releasesh)
6. [Скрипт check-workflow.sh](#check-workflowsh)
7. [Интеграция в рабочий процесс](#интеграция-в-рабочий-процесс)
8. [Примеры использования](#примеры-использования)
9. [Устранение неполадок](#устранение-неполадок)
10. [FAQ](#faq)

---

## Обзор

Система автоматизации Git Workflow предоставляет набор скриптов для стандартизации и упрощения работы с Git в проекте Qwen Code Orchestrator Kit.

### Преимущества

- ✅ **Стандартизация** — единый подход к созданию веток и коммитов
- ✅ **Автоматизация** — минимизация рутинных операций
- ✅ **Контроль качества** — валидация сообщений коммитов и имен веток
- ✅ **Безопасность** — проверка перед коммитом и push
- ✅ **Документирование** — автоматическое обновление CHANGELOG

### Скрипты

| Скрипт | Назначение | Время выполнения |
|--------|-------------|------------------|
| `create-feature-branch.sh` | Создание feature-ветки | ~5 секунд |
| `pre-commit-review.sh` | Pre-commit ревью | ~10 секунд |
| `auto-tag-release.sh` | Создание тега релиза | ~15 секунд |
| `check-workflow.sh` | Проверка workflow | ~3 секунды |

---

## Установка и настройка

### Требования

- Git 2.20+
- Bash 4.0+
- Доступ к удалённому репозиторию (опционально)

### Настройка

1. **Убедитесь, что скрипты исполняемые:**

```bash
chmod +x .qwen/scripts/git/*.sh
```

2. **Проверьте доступность скриптов:**

```bash
.qwen/scripts/git/check-workflow.sh --help
```

3. **Настройте Git (если не настроен):**

```bash
git config --global user.name "Ваше Имя"
git config --global user.email "your.email@example.com"
```

---

## create-feature-branch.sh

### Назначение

Автоматическое создание feature-ветки от develop с валидацией имени и push на удалённый репозиторий.

### Использование

```bash
.qwen/scripts/git/create-feature-branch.sh "<task-name>"
```

### Параметры

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `task-name` | string | Да | Название задачи для имени ветки |

### Примеры

```bash
# Создание ветки для новой функции
.qwen/scripts/git/create-feature-branch.sh "user-authentication"

# Создание ветки для исправления
.qwen/scripts/git/create-feature-branch.sh "login-bug-fix"

# Создание ветки с подчеркиваниями
.qwen/scripts/git/create-feature-branch.sh "api_v2_integration"
```

### Валидация имени ветки

**Допустимые символы:**
- ✅ Строчные буквы (a-z)
- ✅ Цифры (0-9)
- ✅ Дефисы (-)
- ✅ Подчеркивания (_)

**Недопустимые паттерны:**
- ❌ Заглавные буквы
- ❌ Пробелы
- ❌ Специальные символы
- ❌ Двойные дефисы (--)
- ❌ Двойные подчеркивания (__)
- ❌ Начальные/конечные дефисы/подчеркивания

**Максимальная длина:** 50 символов

### Выходные данные

**Успех:**
```
ℹ️  ИНФО: Текущая ветка: develop
ℹ️  ИНФО: Базовая ветка: develop
ℹ️  ИНФО: Создаваемая ветка: feature/user-authentication
ℹ️  ИНФО: Создание ветки feature/user-authentication от develop...
ℹ️  ИНФО: Попытка push ветки на удалённый репозиторий...
✅ УСПЕХ: Ветка 'feature/user-authentication' создана и отправлена на удалённый репозиторий
feature/user-authentication
```

**Ошибка:**
```
❌ ОШИБКА: Ветка 'feature/user-authentication' уже существует
```

### Коды возврата

| Код | Описание |
|-----|----------|
| 0 | Успешное создание ветки |
| 1 | Ошибка валидации или создания |

---

## pre-commit-review.sh

### Назначение

Интерактивное ревью изменений перед коммитом с валидацией сообщения (Conventional Commits).

### Использование

```bash
# Интерактивный режим (по умолчанию)
.qwen/scripts/git/pre-commit-review.sh "<commit-message>"

# Неинтерактивный режим (для CI/CD)
.qwen/scripts/git/pre-commit-review.sh "<commit-message>" --no-interactive

# С полным diff
.qwen/scripts/git/pre-commit-review.sh "<commit-message>" --full-diff
```

### Параметры

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `commit-message` | string | Да | Сообщение коммита |
| `--no-interactive` | flag | Нет | Отключить интерактивные запросы |
| `--full-diff` | flag | Нет | Показать полный diff |
| `--help` | flag | Нет | Показать справку |

### Conventional Commits

**Формат:**
```
type(scope): description
```

**Типы коммитов:**

| Тип | Описание | Пример |
|-----|----------|--------|
| `feat` | Новая функция | `feat: добавлена аутентификация` |
| `fix` | Исправление ошибки | `fix(api): исправлен таймаут` |
| `docs` | Изменения в документации | `docs: обновлена инструкция` |
| `style` | Форматирование, отступы | `style: исправлены отступы` |
| `refactor` | Рефакторинг | `refactor: вынесена конфигурация` |
| `test` | Тесты | `test: добавлены тесты API` |
| `chore` | Служебные изменения | `chore: обновлены зависимости` |
| `perf` | Производительность | `perf: ускорена загрузка` |
| `ci` | CI/CD | `ci: добавлен workflow` |
| `build` | Система сборки | `build: обновлен webpack` |

### Примеры

```bash
# Простой коммит
.qwen/scripts/git/pre-commit-review.sh "feat: добавлена тема Catppuccin"

# Коммит с scope
.qwen/scripts/git/pre-commit-review.sh "fix(api): исправлен таймаут соединения"

# Неинтерактивный режим для CI/CD
.qwen/scripts/git/pre-commit-review.sh "chore: обновлены зависимости" --no-interactive
```

### Рабочий процесс

1. **Показ статуса:**
   ```
   ═══════════════════════════════════════════════════════
     Git Status
   ═══════════════════════════════════════════════════════
   
   M src/config.py
   A src/new_feature.py
   ?? .env.local
   
   ℹ️  ИНФО: Изменено файлов: 3
   ```

2. **Показ статистики изменений:**
   ```
   ═══════════════════════════════════════════════════════
     Изменения (diff --stat)
   ═══════════════════════════════════════════════════════
   
   src/config.py       | 15 +++++++++++++++
   src/new_feature.py  | 50 ++++++++++++++++++++++++++++++++++++++++++++++++++
   2 files changed, 65 insertions(+)
   
   ℹ️  ИНФО: Вставлено строк: 65
   ℹ️  ИНФО: Удалено строк: 0
   ```

3. **Запрос подтверждения:**
   ```
   ═══════════════════════════════════════════════════════
     Подтверждение коммита
   ═══════════════════════════════════════════════════════
   
   Сообщение коммита:
     feat: добавлена тема Catppuccin
   
   ℹ️  ИНФО: Тип коммита: FEAT (новая функция)
   
   Файлы для коммита:
   M src/config.py
   A src/new_feature.py
   
   ⚠️  ПРЕДУПРЕЖДЕНИЕ: После коммита изменения нельзя будет легко отменить!
   
   Создать коммит? (y/n):
   ```

### Коды возврата

| Код | Описание |
|-----|----------|
| 0 | Успешный коммит |
| 1 | Ошибка валидации или отмена |

---

## auto-tag-release.sh

### Назначение

Автоматическое создание аннотированных тегов версий с обновлением CHANGELOG.

### Использование

```bash
.qwen/scripts/git/auto-tag-release.sh "<version>" "<description>"
```

### Параметры

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `version` | string | Да | Версия в формате semver |
| `description` | string | Да | Описание релиза |

### Формат версии (SemVer)

```
v<major>.<minor>.<patch>(-<prerelease>)(+<build>)
```

**Примеры:**
- `v1.0.0` — стабильный релиз
- `v1.0.0-beta.1` — бета-версия
- `v1.0.0-rc.2` — релиз-кандидат
- `v1.0.0+build.123` — с метаданными сборки

### Примеры

```bash
# Стабильный релиз
.qwen/scripts/git/auto-tag-release.sh "v0.6.0" "Release v0.6.0: Feedback System"

# Бета-версия
.qwen/scripts/git/auto-tag-release.sh "v1.0.0-beta.1" "Beta release for testing"

# Релиз-кандидат
.qwen/scripts/git/auto-tag-release.sh "v1.0.0-rc.1" "Release candidate 1"
```

### Рабочий процесс

1. **Валидация версии:**
   ```
   ℹ️  ИНФО: Валидация версии...
   ✅ УСПЕХ: Версия v0.6.0 корректна
   ```

2. **Анализ фаз:**
   ```
   ℹ️  ИНФО: Анализ завершенных фаз...
   ℹ️  ИНФО: Статистика: phases=5,specs=12
   ```

3. **Создание тега:**
   ```
   ℹ️  ИНФО: Создание аннотированного тега...
   ✅ УСПЕХ: Тег 'v0.6.0' создан
   ```

4. **Обновление CHANGELOG:**
   ```
   ℹ️  ИНФО: Обновление CHANGELOG...
   ✅ УСПЕХ: CHANGELOG.md обновлен
   ```

5. **Push тега:**
   ```
   Отправить тег на удалённый репозиторий? (y/n): y
   ℹ️  ИНФО: Отправка тега 'v0.6.0' на удалённый репозиторий...
   ✅ УСПЕХ: Тег 'v0.6.0' отправлен на удалённый репозиторий
   ```

### Формат CHANGELOG

```markdown
## [v0.6.0] - 2026-03-21

### Изменения
- Release v0.6.0: Feedback System

### Технические детали
- phases=5, specs=12
- Commits:
  abc1234 feat: Add feedback system
  def5678 fix: Resolve memory leak
  ...
```

### Коды возврата

| Код | Описание |
|-----|----------|
| 0 | Успешное создание тега |
| 1 | Ошибка валидации или создания |

---

## check-workflow.sh

### Назначение

Комплексная проверка соблюдения Git workflow с рекомендациями.

### Использование

```bash
.qwen/scripts/git/check-workflow.sh
```

### Проверки

#### 1. Git репозиторий
- ✅ Инициализирован ли Git
- ✅ Наличие .git директории

#### 2. Текущая ветка
- ✅ Проверка на main (предупреждение)
- ✅ Проверка на develop/dev (OK)
- ✅ Проверка на feature/bugfix/hotfix (OK)

#### 3. Незакоммиченные изменения
- ✅ Staged изменения
- ✅ Unstaged изменения
- ✅ Неотслеживаемые файлы
- ⚠️ Проверка на чувствительные файлы (.env, .key, .pem)

#### 4. Синхронизация с remote
- ✅ Наличие remote 'origin'
- ✅ Доступность remote
- ✅ Отставание от remote
- ✅ Опережение remote

#### 5. Теги
- ✅ Наличие тегов
- ✅ Последний semver тег
- ✅ Коммиты с последнего тега

#### 6. Структура веток
- ✅ Наличие main/master
- ✅ Наличие develop/dev
- ✅ Подсчет feature/bugfix/hotfix веток

#### 7. .gitignore
- ✅ Наличие файла
- ✅ Типичные паттерны (node_modules, .env, *.log)

### Вывод

**Успешная проверка:**
```
╔═══════════════════════════════════════════════════════╗
║         Git Workflow Checker - Qwen Orchestrator      ║
╚═══════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════
  Проверка Git репозитория
═══════════════════════════════════════════════════════

✅ УСПЕХ: Git репозиторий инициализирован

...

═══════════════════════════════════════════════════════
  Итоги проверки
═══════════════════════════════════════════════════════

✅ УСПЕХ: Все проверки пройдены успешно!

Ваш git workflow в отличном состоянии 🎉

═══════════════════════════════════════════════════════
  Статистика
═══════════════════════════════════════════════════════
  Ошибки:       0
  Предупреждения: 0
  Инфо:         15
═══════════════════════════════════════════════════════
```

**Проверка с предупреждениями:**
```
⚠️  ПРЕДУПРЕЖДЕНИЕ: Обнаружено предупреждений: 3

Workflow работает, но есть рекомендации к улучшению

═══════════════════════════════════════════════════════
  Статистика
═══════════════════════════════════════════════════════
  Ошибки:       0
  Предупреждения: 3
  Инфо:         12
═══════════════════════════════════════════════════════

═══════════════════════════════════════════════════════
  Рекомендации
═══════════════════════════════════════════════════════

Рекомендуемые действия:
  1. Создайте feature-ветку для новой задачи
  2. Закоммитьте незавершенные изменения
  3. Синхронизируйтесь с remote

Полезные команды:
  .qwen/scripts/git/create-feature-branch.sh "<task>"  - создать ветку
  .qwen/scripts/git/pre-commit-review.sh "<msg>"       - коммит
  .qwen/scripts/git/auto-tag-release.sh "vX.Y.Z" "..." - тег
```

### Коды возврата

| Код | Описание |
|-----|----------|
| 0 | Все проверки пройдены |
| 1 | Предупреждения (workflow работает) |
| 2 | Ошибки (требуется внимание) |

---

## Интеграция в рабочий процесс

### Pre-Task Workflow

**Перед началом задачи:**

```bash
# 1. Проверка текущего состояния
.qwen/scripts/git/check-workflow.sh

# 2. Создание feature-ветки
.qwen/scripts/git/create-feature-branch.sh "task-name"

# 3. Начало работы
```

### Pre-Commit Workflow

**Перед каждым коммитом:**

```bash
# 1. Pre-commit ревью
.qwen/scripts/git/pre-commit-review.sh "type: description"

# 2. Push (если предлагается)
# или вручную:
git push -u origin feature/task-name
```

### Post-Phase Workflow

**После завершения фазы:**

```bash
# 1. Проверка workflow
.qwen/scripts/git/check-workflow.sh

# 2. Создание тега
.qwen/scripts/git/auto-tag-release.sh "vX.Y.Z" "Release description"

# 3. Мерж в develop (если в feature-ветке)
git checkout develop
git merge --no-ff feature/task-name
git push origin develop
```

### CI/CD Интеграция

**GitHub Actions пример:**

```yaml
name: Git Workflow Check

on: [push, pull_request]

jobs:
  check-workflow:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Check Git Workflow
        run: |
          chmod +x .qwen/scripts/git/check-workflow.sh
          .qwen/scripts/git/check-workflow.sh || true
      
      - name: Validate Commit Messages
        run: |
          git log --format=%s | grep -E '^(feat|fix|docs|style|refactor|test|chore|perf|ci|build):' || exit 1
```

---

## Примеры использования

### Сценарий 1: Новая функция

```bash
# 1. Проверка состояния
.qwen/scripts/git/check-workflow.sh

# 2. Создание ветки
.qwen/scripts/git/create-feature-branch.sh "user-dashboard"

# 3. Работа над функцией...
# Изменения в коде

# 4. Коммит
.qwen/scripts/git/pre-commit-review.sh "feat: добавлена панель пользователя"

# 5. Push
git push -u origin feature/user-dashboard

# 6. После завершения - создание тега
.qwen/scripts/git/auto-tag-release.sh "v0.7.0" "Release v0.7.0: User Dashboard"
```

### Сценарий 2: Исправление ошибки

```bash
# 1. Создание bugfix-ветки
.qwen/scripts/git/create-feature-branch.sh "login-timeout-fix"

# 2. Переименование в bugfix
git branch -m bugfix/login-timeout-fix

# 3. Исправление...

# 4. Коммит
.qwen/scripts/git/pre-commit-review.sh "fix(auth): исправлен таймаут входа"

# 5. Push и PR
git push -u origin bugfix/login-timeout-fix
```

### Сценарий 3: Экстренный hotfix

```bash
# 1. Переключение на main
git checkout main
git pull origin main

# 2. Создание hotfix-ветки
git checkout -b hotfix/security-patch

# 3. Исправление...

# 4. Коммит
.qwen/scripts/git/pre-commit-review.sh "fix(security): патч уязвимости XSS"

# 5. Мерж в main и develop
git checkout main
git merge --no-ff hotfix/security-patch
git tag -a v0.6.1 -m "Security patch"
git push origin main --tags

git checkout develop
git merge --no-ff hotfix/security-patch
git push origin develop
```

---

## Устранение неполадок

### Проблема: "Ветка уже существует"

**Решение:**
```bash
# Проверка существующих веток
git branch -a | grep feature/

# Удаление старой ветки (если не нужна)
git branch -D feature/old-branch
git push origin --delete feature/old-branch

# Или использование другого имени
.qwen/scripts/git/create-feature-branch.sh "task-name-v2"
```

### Проблема: "Неверный формат версии"

**Решение:**
```bash
# Используйте правильный формат semver
.qwen/scripts/git/auto-tag-release.sh "v1.0.0" "Description"  # ✅
.qwen/scripts/git/auto-tag-release.sh "1.0.0" "Description"   # ✅
.qwen/scripts/git/auto-tag-release.sh "v1.0" "Description"    # ❌
.qwen/scripts/git/auto-tag-release.sh "1.0" "Description"     # ❌
```

### Проблема: "Сообщение не соответствует Conventional Commits"

**Решение:**
```bash
# Неправильно
.qwen/scripts/git/pre-commit-review.sh "Fixed bug"

# Правильно
.qwen/scripts/git/pre-commit-review.sh "fix: исправлена ошибка"
.qwen/scripts/git/pre-commit-review.sh "fix(api): исправлена ошибка таймаута"
```

### Проблема: "Не удалось отправить ветку на remote"

**Решение:**
```bash
# Проверка remote
git remote -v

# Добавление remote (если нет)
git remote add origin https://github.com/user/repo.git

# Ручная отправка
git push -u origin feature/branch-name
```

### Проблема: "Чувствительные файлы в репозитории"

**Решение:**
```bash
# Добавление в .gitignore
echo ".env" >> .gitignore
echo "*.key" >> .gitignore
echo "*.pem" >> .gitignore

# Удаление из git (если уже добавлены)
git rm --cached .env
git rm --cached *.key
git commit -m "chore: удаление чувствительных файлов из git"
```

---

## FAQ

### Q: Можно ли использовать скрипты в других проектах?

**A:** Да, скрипты универсальны и могут быть скопированы в любой Git проект.

### Q: Как отключить интерактивные запросы?

**A:** Используйте флаг `--no-interactive`:
```bash
.qwen/scripts/git/pre-commit-review.sh "msg" --no-interactive
```

### Q: Можно ли изменить формат сообщений коммитов?

**A:** Да, отредактируйте функцию `validate_commit_message` в `pre-commit-review.sh`.

### Q: Как создать тег без обновления CHANGELOG?

**A:** Скрипт всегда обновляет CHANGELOG. Для пропуска закомментируйте вызов `update_changelog`.

### Q: Что делать если check-workflow.sh показывает ошибки?

**A:** Следуйте рекомендациям в выводе скрипта. Ошибки требуют немедленного внимания.

### Q: Можно ли использовать с другими Git хостингами?

**A:** Да, скрипты работают с любым Git remote (GitHub, GitLab, Bitbucket).

---

## Связанные документы

- [Git Workflow](./architecture/GIT_WORKFLOW.md) - Полное руководство по Git workflow
- [Quality Gates](./architecture/quality-gates.md) - Контрольные точки качества
- [QWEN.md](../../QWEN.md) - Основная документация проекта

---

**Документ утверждён:** 2026-03-21
**Версия:** 1.0.0
**Поддержка:** Qwen Orchestrator Team
