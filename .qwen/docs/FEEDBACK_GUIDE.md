# Сбор обратной связи от разработчиков

**Версия:** 1.0.0  
**Дата:** 2026-03-21

---

## 🎯 Назначение

Механизм сбора обратной связи предназначен для автоматического сбора данных об использовании шаблона Qwen Orchestrator Kit в реальных проектах разработчиков.

---

## 📦 Компоненты

### 1. Скрипт сбора обратной связи

**Файл:** `.qwen/scripts/feedback/collect-feedback.sh`

**Назначение:** Автоматический сбор и упаковка данных для отправки разработчикам шаблона.

**Использование:**

```bash
# В проекте разработчика
cd my-project
.qwen/scripts/feedback/collect-feedback.sh ./feedback-export

# Будет создано:
# - feedback-export/ (директория с данными)
# - feedback-YYYYMMDD-HHMMSS.tar.gz (архив)
```

**Собираемые данные:**

- `.qwen/logs/agent-calls.log` - логи вызовов агентов
- `.qwen/feedback/` - отчеты Feedback System
- `.qwen/logs/errors.log` - ошибки
- Метрики использования
- Информация о проекте

---

### 2. Форма обратной связи

**Файл:** `.qwen/docs/FEEDBACK_FORM_TEMPLATE.md`

**Назначение:** Стандартизированная форма для сбора структурированной обратной связи.

**Разделы формы:**

1. Общая информация
2. Оценка функциональности (1-5)
3. Детальная обратная связь
4. Обнаруженные ошибки
5. Предложения по улучшению
6. Использование компонентов
7. Технические детали
8. Дополнительные комментарии

---

### 3. Инструкция для разработчиков

**Файл:** `.qwen/docs/FEEDBACK_GUIDE.md`

Содержит:

- Как собрать обратную связь
- Как заполнить форму
- Как отправить данные
- Гарантии конфиденциальности

---

## 🔄 Процесс сбора обратной связи

### Для разработчика (пользователя шаблона):

```bash
# 1. Запустить сбор данных
.qwen/scripts/feedback/collect-feedback.sh ./feedback-export

# 2. Заполнить форму
# Открыть .qwen/docs/FEEDBACK_FORM_TEMPLATE.md
# Заполнить все разделы

# 3. Отправить
# - GitHub Issue
# - Email
# - Telegram
```

### Для разработчика шаблона (получение данных):

```bash
# 1. Получить архив от пользователя
# feedback-YYYYMMDD-HHMMSS.tar.gz

# 2. Распаковать
tar -xzf feedback-YYYYMMDD-HHMMSS.tar.gz

# 3. Проанализировать
cd feedback-export/
cat info/project-info.txt
cat info/usage-report.txt
cat logs/agent-calls.log
cat feedback/reports/

# 4. Обработать форму обратной связи
# Создать issue с анализом
```

---

## 📊 Анализ полученных данных

### 1. Статистика использования

```bash
# Подсчет вызовов агентов
grep -c "orc_" feedback-export/logs/agent-calls.log
grep -c "work_" feedback-export/logs/agent-calls.log

# Топ используемых агентов
awk -F'|' '{print $2}' feedback-export/logs/agent-calls.log | sort | uniq -c | sort -rn
```

### 2. Анализ ошибок

```bash
# Просмотр ошибок
cat feedback-export/errors/errors.log

# Подсчет по типам
grep -c "ERROR" feedback-export/logs/agent-calls.log
grep -c "WARNING" feedback-export/logs/agent-calls.log
```

### 3. Метрики производительности

```bash
# Время выполнения задач
grep "duration" feedback-export/logs/agent-calls.log | awk '{sum+=$NF} END {print "Average:", sum/NR}'
```

---

## 🔒 Конфиденциальность

### Что НЕ должно попадать в отчет:

- ❌ API ключи
- ❌ Пароли
- ❌ Персональные данные
- ❌ Коммерческая тайна
- ❌ Внутренние URL компании

### Автоматическая фильтрация:

Скрипт `collect-feedback.sh` автоматически исключает:

```bash
# Исключенные файлы
- .env
- .env.*
- *.key
- *.pem
- *.secret
- package-lock.json (может содержать токены)
```

---

## 📤 Каналы получения обратной связи

### 1. GitHub Issues

**Шаблон issue:**

```markdown
## Тип обратной связи
☐ Ошибка
☐ Предложение
☐ Вопрос
☐ Другое

## Краткое описание

## Версия шаблона

## Прикрепленные файлы
- [ ] feedback-*.tar.gz
- [ ] FEEDBACK_FORM_TEMPLATE.md (заполненная)
```

### 2. Email

**Адрес:** feedback@qwen-orchestrator.dev

**Тема:** `Feedback v0.6.0 - [Краткое описание]`

### 3. Telegram

**Канал:** @qwen_orchestrator_feedback

---

## 📈 Интеграция в процесс разработки

### Еженедельный анализ

1. **Понедельник:** Сбор всех полученных отчетов за неделю
2. **Вторник:** Анализ ошибок и проблем
3. **Среда:** Приоритизация предложений
4. **Четверг:** Создание задач в backlog
5. **Пятница:** Обновление документации

### Метрики для отслеживания:

| Метрика | Частота | Цель |
|---------|---------|------|
| Количество отчетов | Еженедельно | 10+ |
| Критических ошибок | Еженедельно | 0 |
| Предложений реализовано | Ежемесячно | 5+ |
| Удовлетворенность (средняя) | Ежемесячно | 4.0+ |

---

## 🎯 Интеграция с publish-release.sh

При публикации релиза добавить инструкцию:

```bash
# В конце publish-release.sh добавить:

log_info "═══════════════════════════════════════════════════"
log_info "  ОБРАТНАЯ СВЯЗЬ"
log_info "═══════════════════════════════════════════════════"
log_info ""
log_info "Для сбора обратной связи от разработчиков:"
log_info "  .qwen/scripts/feedback/collect-feedback.sh ./feedback-export"
log_info ""
log_info "Форма: .qwen/docs/FEEDBACK_FORM_TEMPLATE.md"
log_info ""
```

---

## 📚 Документы

- `FEEDBACK_FORM_TEMPLATE.md` - Форма обратной связи
- `FEEDBACK_GUIDE.md` - Руководство для разработчиков
- `collect-feedback.sh` - Скрипт сбора

---

## 🚀 Быстрый старт

### Для разработчика шаблона:

1. Скопируйте `.qwen/scripts/feedback/` в шаблон
2. Скопируйте `.qwen/docs/FEEDBACK_*` в шаблон
3. Добавьте инструкцию в README

### Для пользователя шаблона:

1. Запустите `.qwen/scripts/feedback/collect-feedback.sh`
2. Заполните форму
3. Отправьте разработчикам

---

**Спасибо за улучшение Qwen Orchestrator Kit!** 🎉
