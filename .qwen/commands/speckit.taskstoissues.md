# SpecKit Command: TasksToIssues

**Назначение:** Конвертация задач в GitHub Issues

**Версия:** 1.0.0

---

## Описание

Команда `speckit.taskstoissues` конвертирует задачи из tasks.md в GitHub Issues, создавая их через GitHub API и устанавливая связи с задачами.

## Использование

```bash
/qwen speckit.taskstoissues
```

## Функционал

### 1. Конвертация tasks.md в GitHub issues
- Парсинг документа tasks.md
- Извлечение метаданных задач
- Форматирование описания issue
- Подготовка к созданию

### 2. Создание issues через API
- Аутентификация в GitHub API
- Создание issue для каждой задачи
- Установка меток и приоритетов
- Назначение исполнителей

### 3. Связывание с задачами
- Добавление ID задачи в описание issue
- Создание обратной ссылки в tasks.md
- Поддержание синхронизации
- Обновление статуса

### 4. Управление проектом
- Добавление issues в GitHub Project
- Установка вех (milestones)
- Настройка зависимостей между issues
- Создание досок Kanban

## Выходные артефакты

- `.qwen/specify/.qwen/specify/specs/{ID}/issues-log.md` - Лог создания issues
- `.qwen/specify/.qwen/specify/specs/{ID}/github-links.md` - Ссылки на issues
- `.qwen/specify/.qwen/specify/specs/{ID}/project-board.md` - Конфигурация проекта
- `.qwen/specify/.qwen/specify/specs/{ID}/tasks.md` - Обновленный с ссылками

## Интеграция

**Предыдущая команда:** `speckit.constitution`

**Следующая команда:** Завершение SpecKit workflow

**Зависимости:** `.qwen/specify/.qwen/specify/specs/{ID}/tasks.md`, GitHub API credentials

## Требования к API

```bash
# Переменные окружения
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
GITHUB_OWNER=username
GITHUB_REPO=repository
```

## Пример создания issue

```markdown
# Issue: T-001 Реализация аутентификации

**Задача:** T-001
**Приоритет:** P0
**Оценка:** 4 часа
**Агент:** work_dev_specialist

## Описание
Реализовать JWT аутентификацию пользователей

## Требования
- FR-001: Пользователь может аутентифицироваться
- NFR-001: Время отклика < 200ms

## Acceptance Criteria
- [ ] Вход с корректными учетными данными работает
- [ ] Токен обновляется корректно
- [ ] Истечение токена обрабатывается

## Зависимости
- Нет

## Ссылки
- Spec: .qwen/specify/specs/PROJ-001/spec.md#FR-001
- Plan: .qwen/specify/specs/PROJ-001/plan.md#task-001
```

## Пример лога

```markdown
# Issues Creation Log

**Дата:** 2026-03-21
**Статус:** ✅ Успешно

| Задача | Issue # | Статус | Ссылка |
|--------|---------|--------|--------|
| T-001 | #101 | ✅ Создано | https://github.com/.../issues/101 |
| T-002 | #102 | ✅ Создано | https://github.com/.../issues/102 |
| T-003 | #103 | ✅ Создано | https://github.com/.../issues/103 |
| T-004 | #104 | ⚠️ Warning | https://github.com/.../issues/104 |

## Предупреждения
- T-004: Метка P2 не найдена, создана автоматически

## Итого
- Создано: 4 issues
- Обновлено: 0 issues
- Ошибок: 0
```
