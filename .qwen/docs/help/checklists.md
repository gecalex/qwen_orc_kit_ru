# Чеклисты Qwen Code Orchestrator Kit

**Версия:** 1.0.0 (v0.5.0)  
**Дата:** 20 марта 2026  
**Назначение:** Самопроверка перед ключевыми этапами разработки

---

## 📋 Pre-Flight Checklist (Перед началом фазы)

**Использование:** Перед началом любой фазы разработки

```bash
.qwen/scripts/orchestration-tools/pre-flight-check.sh "<Название фазы>"
```

### Чеклист:

- [ ] Git репозиторий инициализирован
- [ ] Ветка develop существует
- [ ] .gitignore существует
- [ ] constitution.md существует
- [ ] Quality Gates скрипты существуют
- [ ] Агенты существуют (>= 7)
- [ ] Speckit команды существуют (9)
- [ ] Skills существуют (>= 10)
- [ ] MCP конфигурация существует
- [ ] Скрипты существуют (>= 5)

**При неудаче:**
- ❌ ОСТАНОВКА процесса
- ❌ Вывод списка ошибок
- ❌ Запрос на устранение

---

## 📋 Pre-Commit Checklist (Перед коммитом)

**Использование:** Перед каждым коммитом

### Чеклист:

- [ ] Код отформатирован (`cargo fmt --check` / `npm run lint`)
- [ ] Линтеры пройдены (`cargo clippy` / `npm run lint`)
- [ ] Тесты пройдены (`cargo test` / `npm test`)
- [ ] Сборка успешна (`cargo build` / `npm run build`)
- [ ] Изменения показаны пользователю (`git diff --staged`)
- [ ] Получено явное подтверждение пользователя
- [ ] Сообщение коммита по Conventional Commits
- [ ] CHANGELOG.md обновлен (если нужно)

**Пример:**
```bash
# Показать изменения
git diff --staged

# Запросить подтверждение
echo "Создать коммит? (да/нет)"

# Только после подтверждения
git commit -m "feat: добавить новую функцию"
```

---

## 📋 Pre-Merge Checklist (Перед мержем)

**Использование:** Перед вливанием в main/develop

### Чеклист:

- [ ] Feature-ветка завершена
- [ ] Все тесты пройдены
- [ ] Integration тесты пройдены
- [ ] Нет конфликтов слияния
- [ ] Code review выполнен
- [ ] Документация обновлена
- [ ] Quality Gates пройдены
- [ ] CHANGELOG.md обновлен
- [ ] Версия увеличена (semver)

**Процесс:**
```bash
# Переключиться на target ветку
git checkout develop

# Мерж с сохранением истории
git merge --no-ff feature/my-feature

# Удалить feature-ветку
git branch -d feature/my-feature

# Отправить на GitHub
git push origin develop
```

---

## 📋 TDD Checklist (Test-Driven Development)

**Использование:** При разработке новой функциональности

### Чеклист:

- [ ] Тесты написаны ДО кода
- [ ] Тесты failing при первом запуске
- [ ] Код написан для прохождения тестов
- [ ] Рефакторинг выполнен
- [ ] Все тесты проходят
- [ ] Покрытие тестами >= требуемого

**Процесс:**
```
1. Красный: Написать failing тест
2. Зеленый: Написать код для прохождения
3. Рефакторинг: Улучшить код
4. Повторить
```

---

## 📋 Agent Assignment Checklist (Назначение агентов)

**Использование:** Перед делегированием задачи агенту

### Чеклист:

- [ ] Тип задачи определен
- [ ] Специализированный агент выбран
- [ ] Агент существует в `.qwen/agents/`
- [ ] Агент не используется в другой задаче
- [ ] Задача делегирована через `task` команду
- [ ] Вызов агента залогирован

**Пример:**
```bash
# Логирование вызова
.qwen/scripts/agent-tools/log-agent-call.sh orc_dev_task_coordinator P1-T01 started

# Делегирование
task '{
  "subagent_type": "orc_dev_task_coordinator",
  "description": "Разработка функции",
  "prompt": "Детальное ТЗ..."
}'
```

---

## 📋 Specification Checklist (Проверка спецификации)

**Использование:** Перед началом реализации (Gate 5)

### Чеклист:

- [ ] Все разделы spec.md заполнены
- [ ] Требования тестируемые и однозначные
- [ ] Критерии успеха измеримы
- [ ] Нет деталей реализации (что, не как)
- [ ] Пользовательские сценарии определены
- [ ] Риски идентифицированы
- [ ] plan.md существует
- [ ] tasks.md существует
- [ ] Фаза 0 завершена

**Проверка:**
```bash
.qwen/scripts/quality-gates/check-specifications.sh specs/{ID}
```

---

## 📋 Phase 0 Checklist (Планирование)

**Использование:** Перед генерацией задач

### Чеклист:

- [ ] spec.md существует и заполнен
- [ ] phase0-analyzer.sh запущен
- [ ] phase0-plan.json создан
- [ ] phase0-agents.json создан
- [ ] phase0-assignments.json создан
- [ ] Quality Gate 1 пройден

**Процесс:**
```bash
# Запуск Фазы 0
.qwen/specify/scripts/phase0-analyzer.sh specs/{ID}

# Проверка результатов
cat specs/{ID}/plans/phase0-plan.json
```

---

## 📋 Initialization Checklist (Инициализация проекта)

**Использование:** Для нового проекта

### Чеклист:

- [ ] Git репозиторий инициализирован
- [ ] Ветка develop создана
- [ ] .gitignore создан
- [ ] Pre-commit хук настроен
- [ ] constitution.md существует
- [ ] Структура проекта проверена
- [ ] Pre-Flight проверки пройдены
- [ ] CHANGELOG.md создан
- [ ] README.md создан

**Автоматизация:**
```bash
.qwen/scripts/orchestration-tools/initialize-project.sh
```

---

## 📋 Release Checklist (Подготовка релиза)

**Использование:** Перед выпуском релиза

### Чеклист:

- [ ] Все feature-ветки влиты в develop
- [ ] Все тесты пройдены
- [ ] Integration тесты пройдены
- [ ] Documentation обновлена
- [ ] CHANGELOG.md заполнен
- [ ] Версия увеличена (semver)
- [ ] Release-ветка создана
- [ ] Тестирование release завершено
- [ ] Мерж в main выполнен
- [ ] Тег создан
- [ ] Мерж в develop выполнен
- [ ] Release-ветка удалена
- [ ] Отправлено на GitHub

**Процесс:**
```bash
# Создание release-ветки
git checkout -b release/v1.0.0 develop

# Тестирование
npm test && npm run build

# Мерж в main
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0"

# Мерж в develop
git checkout develop
git merge --no-ff release/v1.0.0

# Удаление release-ветки
git branch -d release/v1.0.0

# Отправка на GitHub
git push origin main develop v1.0.0
```

---

## 📋 Health Check Checklist (Диагностика)

**Использование:** Ежедневная проверка состояния

### Чеклист:

- [ ] `/health-bugs` — проверка ошибок
- [ ] `/health-security` — проверка безопасности
- [ ] `/health-cleanup` — проверка чистоты кода
- [ ] `/health-deps` — проверка зависимостей

**Команды:**
```bash
/health-bugs
/health-security
/health-cleanup
/health-deps
```

---

**Все чеклисты готовы к использованию!**

**Версия:** 1.0.0 (v0.5.0)  
**Поддержание:** Обновлять при добавлении новых процессов
