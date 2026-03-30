# GitHub Actions Workflows

**Версия:** 1.0  
**Дата:** 29 марта 2026  
**Статус:** ✅ Готово

---

## Обзор

Данный документ описывает GitHub Actions workflow, настроенные для автоматизации релизов и синхронизации веток Qwen Orchestrator Kit Extension.

---

## Workflow 1: Release Extension

**Файл:** `.github/workflows/release.yml`

### Назначение

Автоматическое создание релизов расширения при создании Git тега.

### Триггеры

```yaml
on:
  push:
    tags:
      - 'v*'  # Теги версий: v0.8.0, v1.0.0, etc.
  workflow_dispatch:
    inputs:
      version:
        description: 'Версия для релиза (например, v0.8.0)'
        required: true
        type: string
```

**Типы триггеров:**

| Тип | Описание | Пример |
|-----|----------|--------|
| `push.tags` | Автоматически при пуше тега | `git push origin v0.8.0` |
| `workflow_dispatch` | Вручную через GitHub UI | Кнопка "Run workflow" |

### Задачи (Jobs)

#### Job 1: Validate

**Назначение:** Валидация манифеста расширения перед релизом.

**Шаги:**

1. **Checkout code** — загрузка кода из репозитория
2. **Setup Node.js** — установка Node.js 20
3. **Validate qwen-extension.json** — проверка манифеста:
   - Наличие файла
   - Валидность JSON
   - Наличие обязательных полей (`name`, `version`, `description`, `contextFileName`)
4. **Validate QWEN.md** — проверка наличия файла контекста

**Пример вывода:**

```
✅ Манифест валиден
{
  "name": "qwen-orchestrator-kit",
  "version": "0.8.0",
  ...
}
✅ QWEN.md найден
```

#### Job 2: Release

**Назначение:** Создание GitHub Release.

**Шаги:**

1. **Checkout code** — загрузка кода с полной историей
2. **Setup Node.js** — установка Node.js 20
3. **Get version from tag** — извлечение версии из тега
4. **Update version in manifests** — обновление версии в файлах:
   - `.qwen/qwen-extension.json`
   - `package.json`
   - `.version`
5. **Commit version updates** — коммит и push изменений версии
6. **Generate changelog** — генерация changelog из Git commits
7. **Create GitHub Release** — создание релиза с помощью `softprops/action-gh-release`
8. **Notify success** — вывод итоговой информации

**Пример вывода:**

```
🏷️ Release version: v0.8.0 (без v: 0.8.0)
📝 Обновление версии в манифестах...
✅ .qwen/qwen-extension.json обновлён
✅ package.json обновлён
✅ .version обновлён
📋 Changelog:
* Add CI/CD workflows (abc1234)
* Update documentation (def5678)
✅ Release v0.8.0 создан успешно!
```

### Переменные окружения

| Переменная | Описание | Требуется |
|------------|----------|-----------|
| `GITHUB_TOKEN` | Токен для создания релиза | ✅ Автоматически |

### Артефакты

| Артефакт | Описание | Расположение |
|----------|----------|--------------|
| GitHub Release | Релиз с changelog | `/releases/tag/v*` |
| Обновлённые файлы | Версия в манифестах | В репозитории |

### Примеры использования

**Автоматический релиз:**

```bash
# 1. Подготовить релиз
./.qwen/scripts/release/prepare-release.sh 0.8.0

# 2. Закоммитить изменения
git add -A
git commit -m "chore: prepare release v0.8.0"
git push origin main

# 3. Создать тег (запустит workflow)
git tag -a v0.8.0 -m "Release v0.8.0"
git push origin v0.8.0
```

**Ручной запуск:**

1. Перейти на вкладку **Actions**
2. Выбрать workflow **Release Extension**
3. Нажать **Run workflow**
4. Ввести версию (например, `v0.8.0`)
5. Нажать **Run workflow**

---

## Workflow 2: Sync Stable Branch

**Файл:** `.github/workflows/stable-sync.yml`

### Назначение

Автоматическая синхронизация стабильной ветки (`stable`) из основной ветки (`main`).

### Триггеры

```yaml
on:
  push:
    branches:
      - main  # При пуше в main
```

**Тип триггера:**

| Тип | Описание | Пример |
|-----|----------|--------|
| `push.branches` | Автоматически при пуше в main | `git push origin main` |

### Задачи (Jobs)

#### Job 1: Sync Stable

**Назначение:** Синхронизация ветки `stable` с `main`.

**Шаги:**

1. **Checkout code** — загрузка кода с полной историей
2. **Configure Git** — настройка Git пользователя
3. **Check if stable branch exists** — проверка существования ветки
4. **Create or update stable branch** — создание или обновление:
   - Если `stable` существует → merge из `main`
   - Если не существует → создание из `main`
5. **Verify sync** — проверка успешности синхронизации
6. **Notify success** — вывод итоговой информации

**Пример вывода:**

```
✅ Stable ветка существует
🔄 Обновление stable ветки...
✅ Проверка синхронизации...
📊 Последние коммиты в stable:
abc1234 chore: sync stable with main (2026-03-29)
def5678 Add CI/CD workflows
...
✅ Stable ветка синхронизирована с main
```

### Переменные окружения

| Переменная | Описание | Требуется |
|------------|----------|-----------|
| `GITHUB_TOKEN` | Токен для push в репозиторий | ✅ Автоматически |

### Артефакты

| Артефакт | Описание | Расположение |
|----------|----------|--------------|
| Ветка `stable` | Стабильная ветка релизов | `/tree/stable` |

### Примеры использования

**Автоматическая синхронизация:**

```bash
# 1. Влить изменения в main
git checkout main
git merge feature/my-feature --no-ff
git push origin main

# 2. Workflow автоматически синхронизирует stable
# Через 1-2 минуты stable будет обновлена
```

**Проверка статуса:**

```bash
# Проверить последнюю синхронизацию
git log --oneline -5 stable

# Проверить разницу между main и stable
git diff main stable
```

---

## Git стратегия

### Ветки

```
main (stable)         ← стабильные релизы (теги v*)
  ↑
release/v*            ← подготовка релиза
  ↑
develop               ← разработка
  ↑
feature/*             ← новые функции
```

### Теги

**Семантическое версионирование:**

```
MAJOR.MINOR.PATCH
  ↓     ↓     ↓
  1     2     3

MAJOR (1): Несовместимые изменения API
MINOR (2): Новая функциональность (обратно совместимая)
PATCH (3): Исправления ошибок (обратно совместимые)
```

**Примеры:**

```
v0.7.0 → v0.7.1  # Исправление ошибок (PATCH)
v0.7.0 → v0.8.0  # Новая функциональность (MINOR)
v0.7.0 → v1.0.0  # Стабильный релиз (MAJOR)
```

---

## Мониторинг и отладка

### Проверка статуса workflow

1. Перейти на вкладку **Actions**
2. Выбрать нужный workflow
3. Проверить статус последнего запуска

### Просмотр логов

1. Кликнуть на запуск workflow
2. Кликнуть на задачу (job)
3. Развернуть шаги для просмотра логов

### Типичные ошибки

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `Manifest not found` | Отсутствует `.qwen/qwen-extension.json` | Создать манифест |
| `Invalid JSON` | Ошибка в JSON манифесте | Исправить синтаксис |
| `Tag already exists` | Тег уже существует | Удалить или использовать другую версию |
| `Permission denied` | Нет прав на push | Проверить `GITHUB_TOKEN` |

### Перезапуск workflow

1. Перейти на вкладку **Actions**
2. Выбрать неудачный запуск
3. Нажать **Re-run jobs**

---

## Интеграция со скриптами

### Скрипты релиза

| Скрипт | Назначение | Вызов |
|--------|-------------|-------|
| `prepare-release.sh` | Подготовка к релизу | `./.qwen/scripts/release/prepare-release.sh 0.8.0` |
| `create-release.sh` | Создание тега и push | `./.qwen/scripts/release/create-release.sh 0.8.0` |

### Полный процесс релиза

```bash
# 1. Подготовка (обновление версии, changelog)
./.qwen/scripts/release/prepare-release.sh 0.8.0

# 2. Проверка изменений
git diff --cached

# 3. Коммит
git commit -m "chore: prepare release v0.8.0"
git push origin main

# 4. Создание релиза (запускает workflow)
./.qwen/scripts/release/create-release.sh 0.8.0

# 5. Проверка статуса
# Перейти на GitHub → Actions → Release Extension
```

---

## Безопасность

### Токены

| Токен | Назначение | Где настроить |
|-------|------------|---------------|
| `GITHUB_TOKEN` | Автоматический токен GitHub | Не требуется настройка |

### Разрешения

Workflow требуют следующих разрешений:

- `contents: write` — для создания релизов и push
- `actions: read` — для чтения статуса workflow

---

## Дополнительные ресурсы

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Creating Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
- [Semantic Versioning](https://semver.org/)

---

**Последнее обновление:** 29 марта 2026
