---
description: Создание конституции проекта — ПЕРВАЯ команда, нет зависимостей
scripts.sh: scripts/bash/constitution.sh
scripts.ps: scripts/powershell/constitution.ps1
handoffs:
  - label: "Создать спецификацию"
    agent: speckit.specify
    prompt: "Создать спецификацию на основе конституции"
---

# Speckit Command: constitution

**Назначение:** Создание конституции проекта — фундаментальные принципы и стандарты

**Версия:** 2.0.0 (Speckit стандарт)

**Порядок:** ПЕРВАЯ команда (нет зависимостей)

---

## Описание

Команда `/speckit.constitution` создаёт конституцию проекта — документ с фундаментальными принципами, стандартами и архитектурными ограничениями.

**Speckit стандарт:**
- Конституция создаётся ПЕРВОЙ
- Нет зависимостей от spec.md или tasks.md
- Располагается в `.qwen/specify/memory/constitution.md`

---

## Использование

```bash
/speckit.constitution
```

Или через Qwen Code CLI:
```bash
qwen
# Введите: создай конституцию проекта для Personal Knowledge Base
```

---

## Что создаётся

**Файлы:**
- `.qwen/specify/memory/constitution.md` — конституция проекта
- `.qwen/specify/memory/coding-standards.md` — стандарты кода
- `.qwen/specify/memory/architecture-rules.md` — архитектурные правила
- `.qwen/specify/memory/review-checklist.md` — чек-лист ревью

---

## Структура конституции

```markdown
# Project Constitution: {Project Name}

## 1. Принципы разработки
### 1.1 Основные ценности
- Простота
- Читаемость
- Тестируемость
- Документированность
- Безопасность

### 1.2 Принципы чистого кода
- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple, Stupid)
- YAGNI (You Ain't Gonna Need It)
- SOLID принципы

## 2. Стандарты кода
### 2.1 Стиль кодирования
### 2.2 Соглашения об именовании
### 2.3 Требования к документации

## 3. Архитектурные ограничения
### 3.1 Обязательные паттерны
### 3.2 Запрещенные паттерны
### 3.3 Ограничения зависимостей
```

---

## Интеграция

**Предыдущая команда:** Нет (первая команда)

**Следующая команда:** `/speckit.specify`

**Зависимости:** Нет

---

## Пример использования

**Пользователь:**
```
Создай конституцию для Personal Knowledge Base (PKB)

Стек:
- Frontend: React + TypeScript + Bootstrap
- Backend: Python + FastAPI
- БД: PostgreSQL (Supabase)

Требования:
- TDD обязательно
- Документирование всех API
- Безопасность данных
```

**Оркестратор:**
1. Запускает `.qwen/specify/scripts/constitution.sh`
2. Скрипт создаёт `.qwen/specify/memory/constitution.md`
3. Возвращает путь к файлу
4. Предлагает перейти к `/speckit.specify`

---

## Выходные данные

```json
{
  "status": "success",
  "files": {
    "constitution": ".qwen/specify/memory/constitution.md",
    "coding_standards": ".qwen/specify/memory/coding-standards.md",
    "architecture_rules": ".qwen/specify/memory/architecture-rules.md",
    "review_checklist": ".qwen/specify/memory/review-checklist.md"
  },
  "next_command": "speckit.specify"
}
```

---

## Speckit Стандарт

**Согласно официальной документации Speckit:**
- https://github.com/github/spec-kit
- https://deepwiki.com/github/spec-kit/5.4-other-commands

**Путь конституции:** `.specify/memory/constitution.md` (или `.qwen/specify/memory/constitution.md` в Qwen Orchestrator Kit)

**Порядок команд:**
1. `/speckit.constitution` ← ПЕРВАЯ
2. `/speckit.specify`
3. `/speckit.clarify`
4. `/speckit.plan`
5. `/speckit.tasks`
6. `/speckit.analyze`
7. `/speckit.implement`
