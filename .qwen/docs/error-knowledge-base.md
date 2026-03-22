# Error Knowledge Base

**Версия:** 1.0.0
**Дата:** 21 марта 2026
**Назначение:** Руководство по базе знаний об ошибках

---

## Обзор

Error Knowledge Base - это централизованная система для хранения, поиска и анализа ошибок, возникающих в процессе разработки с использованием Qwen Orchestrator Kit.

### Компоненты

| Компонент | Файл | Назначение |
|-----------|------|------------|
| Поиск ошибок | `error-search.sh` | Поиск решений по ключевым словам, коду, категории |
| Индекс ошибок | `error-index.json` | Структурированная база данных ошибок |
| Автообучение | `auto-learn.sh` | Автоматическое добавление новых ошибок |

---

## Установка

База знаний расположена в `.qwen/knowledge-base/` и не требует дополнительной установки.

### Требования

- Bash 4.0+
- jq (для работы с JSON)

```bash
# Проверка зависимостей
command -v jq && echo "jq установлен" || echo "Требуется установка jq"
```

---

## Использование

### Поиск по ошибке

```bash
# Поиск по тексту ошибки
.qwen/knowledge-base/error-search.sh "Git не инициализирован"

# Поиск по ключевым словам
.qwen/knowledge-base/error-search.sh "quality gate"
```

**Пример вывода:**
```
Поиск по ключевым словам: quality gate
==========================================

ID: ERR-QG-001
Категория: Quality Gates
Название: Quality Gate не прошел
Паттерн: Gate не пройден, проверки не пройдены
Причина: Отсутствуют необходимые файлы, спецификация не заполнена
Решение: Запустить проверку с деталями, исправить ошибки
Профилактика: Следовать чеклистам, запускать Pre-Flight проверки
Ключевые слова: quality, gate, проверка, спецификация

Найдено ошибок: 2
```

### Поиск по коду ошибки

```bash
# Поиск по конкретному коду
.qwen/knowledge-base/error-search.sh --code "ERR-GIT-001"
```

**Пример вывода:**
```
Поиск по коду: ERR-GIT-001
==========================================

ID: ERR-GIT-001
Категория: Git
Название: Git не инициализирован
Паттерн: Git репозиторий не инициализирован
Причина: Разработка началась без инициализации Git
Решение: git init + создать ветку develop + cp .qwen/templates/gitignore .gitignore
Профилактика: Запускать initialize-project.sh перед началом разработки
Источник: error-handling-examples.md (раздел 1)
Ключевые слова: git, инициализация, репозиторий, init
```

### Поиск по категории

```bash
# Поиск по категории
.qwen/knowledge-base/error-search.sh --context "Git"
.qwen/knowledge-base/error-search.sh --context "Quality Gates"
.qwen/knowledge-base/error-search.sh --context "Агенты"
.qwen/knowledge-base/error-search.sh --context "TDD"
.qwen/knowledge-base/error-search.sh --context "MCP"
.qwen/knowledge-base/error-search.sh --context "Сборка"
```

### Список всех ошибок

```bash
# Показать все ошибки
.qwen/knowledge-base/error-search.sh --list
```

**Пример вывода:**
```
Все ошибки в базе знаний:
==========================================
ERR-GIT-001   Git         Git не инициализирован
ERR-QG-001    Quality Gates  Quality Gate не прошел
ERR-AGENT-001 Агенты      Агент отсутствует
...

Всего ошибок: 12
```

### Статистика базы знаний

```bash
# Показать статистику
.qwen/knowledge-base/error-search.sh --stats
```

---

## Автообучение

### Пересоздание индекса

```bash
# Пересоздать индекс из источника
.qwen/knowledge-base/auto-learn.sh --rebuild
```

### Добавление ошибок из логов

```bash
# Добавить ошибки из файла лога
.qwen/knowledge-base/auto-learn.sh --add .qwen/logs/error.log
```

### Сканирование директории

```bash
# Сканировать директорию на ошибки
.qwen/knowledge-base/auto-learn.sh --scan .qwen/logs
```

### Валидация индекса

```bash
# Проверить целостность индекса
.qwen/knowledge-base/auto-learn.sh --validate
```

### Статистика обучения

```bash
# Показать статистику
.qwen/knowledge-base/auto-learn.sh --stats
```

---

## Структура индекса

```json
{
  "metadata": {
    "version": "1.0.0",
    "created": "2026-03-21",
    "source": "error-handling-examples.md",
    "total_errors": 12
  },
  "categories": ["Git", "Quality Gates", "Агенты", "TDD", "MCP", "Сборка"],
  "errors": [
    {
      "id": "ERR-GIT-001",
      "category": "Git",
      "title": "Git не инициализирован",
      "pattern": "Git репозиторий не инициализирован",
      "cause": "Разработка началась без инициализации Git",
      "solution": "git init + создать ветку develop...",
      "prevention": "Запускать initialize-project.sh...",
      "file": "error-handling-examples.md",
      "section": 1,
      "keywords": ["git", "инициализация", "репозиторий", "init"]
    }
  ]
}
```

---

## Категории ошибок

### Git
Ошибки системы контроля версий:
- Инициализация репозитория
- Git workflow нарушения
- Проблемы с ветками
- .gitignore конфигурация

### Quality Gates
Ошибки проверок качества:
- Не пройденные проверки
- Отсутствующие файлы
- Неполная спецификация

### Агенты
Ошибки связанные с агентами:
- Отсутствующие агенты
- Постфактум создание
- Журнал вызовов

### TDD
Ошибки тестирования:
- Не проходящие тесты
- Проблемы с покрытием

### MCP
Ошибки MCP серверов:
- Недоступность серверов
- Проблемы конфигурации

### Сборка
Ошибки компиляции и сборки:
- Синтаксические ошибки
- Зависимости
- Конфликты версий

---

## Интеграция

### В Feedback System

Error Knowledge Base автоматически интегрируется в Feedback System:

```bash
# Запуск всех проверок включая Error KB
.qwen/feedback/generate-all.sh
```

### В рабочих процессах

```bash
# При возникновении ошибки - поиск решения
error_msg="Git репозиторий не инициализирован"
.qwen/knowledge-base/error-search.sh "$error_msg"
```

---

## Расширение базы знаний

### Добавление новой ошибки вручную

1. Откройте `error-index.json`
2. Добавьте новую запись в массив `errors`:

```json
{
  "id": "ERR-NEW-001",
  "category": "Категория",
  "title": "Название ошибки",
  "pattern": "Паттерн для поиска",
  "cause": "Причина возникновения",
  "solution": "Решение проблемы",
  "prevention": "Меры профилактики",
  "file": "source-file.md",
  "section": 1,
  "keywords": ["ключевое", "слово", "для", "поиска"]
}
```

3. Обновите `total_errors` в `metadata`

### Обновление из источника

```bash
# Обновить индекс из error-handling-examples.md
.qwen/knowledge-base/auto-learn.sh --rebuild
```

---

## Примеры использования

### Сценарий 1: Быстрый поиск решения

```bash
# Разработчик видит ошибку "Quality Gate не прошел"
# Поиск решения:
.qwen/knowledge-base/error-search.sh "Quality Gate"

# Получает решение и профилактику
```

### Сценарий 2: Анализ повторяющихся ошибок

```bash
# Просмотр всех ошибок категории
.qwen/knowledge-base/error-search.sh --context "Git"

# Анализ паттернов для улучшения профилактики
```

### Сценарий 3: Обучение на новых ошибках

```bash
# После завершения сессии - сканирование логов
.qwen/knowledge-base/auto-learn.sh --scan .qwen/logs

# Добавление новых паттернов в базу
```

---

## Поддержание

### Регулярные задачи

| Задача | Частота | Команда |
|--------|---------|---------|
| Обновление индекса | Еженедельно | `auto-learn.sh --rebuild` |
| Валидация | Ежедневно | `auto-learn.sh --validate` |
| Сканирование логов | После сессии | `auto-learn.sh --scan .qwen/logs` |

### Источник истины

Основной источник ошибок: `.qwen/docs/help/error-handling-examples.md`

При обнаружении новой ошибки:
1. Добавьте пример в `error-handling-examples.md`
2. Запустите `auto-learn.sh --rebuild`
3. Проверьте `error-search.sh --list`

---

## См. также

- [Specification Analysis](specification-analysis.md) - Руководство по анализу спецификаций
- [Error Handling Examples](../docs/help/error-handling-examples.md) - Примеры обработки ошибок
- [Feedback System](../feedback/README.md) - Система обратной связи
