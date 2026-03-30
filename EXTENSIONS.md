# Руководство по расширениям Qwen Code Orchestrator Kit

**Версия:** 1.0  
**Дата:** 29 марта 2026  
**Статус:** ✅ Готово

---

## 📖 Оглавление

1. [Что такое расширения](#что-такое-расширения)
2. [Установка](#установка)
3. [Обновление](#обновление)
4. [Управление](#управление)
5. [Link-разработка](#link-разработка)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Что такое расширения

**Расширения Qwen Code** — это официальный способ добавления пользовательских агентов, навыков, команд и MCP-серверов в Qwen Code CLI.

**Qwen Code Orchestrator Kit** распространяется как расширение и предоставляет:

- **36 агентов** — оркестраторы и воркеры для различных задач
- **40 навыков** — переиспользуемые функции для агентов
- **24 команды** — слэш-команды для быстрого доступа
- **7 MCP серверов** — интеграция с внешними сервисами
- **94 скрипта** — автоматизация рутинных задач

### Преимущества модели расширений

| Характеристика | Старый подход | Extensions |
|----------------|---------------|------------|
| **Установка** | Копирование файлов | `qwen extensions install` ✅ |
| **Обновления** | Вручную | Автоматически ✅ |
| **Управление** | Сложное | Простое (enable/disable) ✅ |
| **Изоляция** | В проекте | Глобально ✅ |
| **Чистота** | Файлы в проекте | Проект чистый ✅ |

---

## 🚀 Установка

### Способ 1: Из GitHub (рекомендуется)

```bash
# Установить расширение
qwen extensions install https://github.com/gecalex/qwen_orc_kit_ru

# Проверить установку
qwen extensions list
qwen extensions detail qwen-orchestrator-kit
```

**Что происходит:**
1. Qwen Code клонирует репозиторий
2. Создаёт директорию `~/.qwen/extensions/qwen-orchestrator-kit`
3. Загружает манифест `qwen-extension.json`
4. Регистрирует агентов, навыки, команды
5. Настраивает MCP серверы

### Способ 2: Link для разработки

```bash
# Создать символическую ссылку
qwen extensions link /path/to/qwen_orc_kit_ru/.qwen

# Проверить
qwen extensions list
```

**Преимущества link:**
- ✅ Все изменения видны сразу
- ✅ Не нужно `qwen extensions update`
- ✅ Обычный Git workflow
- ✅ Проект остаётся чистым

**Как это работает:**
```
Проект: /path/to/qwen_orc_kit_ru/.qwen/
                  ↓ (symlink)
Расширение: ~/.qwen/extensions/qwen-orchestrator-kit/
```

### Способ 3: Из локального пути

```bash
# Установить из локальной директории
qwen extensions install /path/to/qwen_orc_kit_ru/.qwen
```

**Используется для:**
- Тестирования локальных изменений
- Офлайн-разработки
- Кастомных сборок

---

## 🔄 Обновление

### Автоматическое обновление

```bash
# Обновить конкретное расширение
qwen extensions update qwen-orchestrator-kit

# Обновить все расширения
qwen extensions update --all
```

**Как работает:**
1. Qwen Code проверяет Git репозиторий
2. Сравнивает локальный HEAD с remote
3. Если есть новые коммиты → загружает
4. Версия берётся из `qwen-extension.json`

### Обновление с тегами

```bash
# Установка конкретной версии
qwen extensions install https://github.com/gecalex/qwen_orc_kit_ru --ref v0.8.0

# Обновление до последней версии
qwen extensions update qwen-orchestrator-kit
```

**Git стратегия:**
- `main` — стабильная ветка (теги v*)
- `develop` — разработка
- `feature/*` — новые функции

### Авто-обновление

```bash
# Установка с авто-обновлением
qwen extensions install https://github.com/gecalex/qwen_orc_kit_ru --auto-update
```

**Поведение:**
- Qwen Code периодически проверяет remote
- При обнаружении новых коммитов → уведомляет
- Пользователь подтверждает обновление

---

## ⚙️ Управление

### Список расширений

```bash
# Все установленные расширения
qwen extensions list
```

**Вывод:**
```
✓ qwen-orchestrator-kit (0.8.0)
  Path: /home/alex/.qwen/extensions/qwen-orchestrator-kit
  Enabled (User): true
  Enabled (Workspace): true
```

### Детали расширения

```bash
# Подробная информация
qwen extensions detail qwen-orchestrator-kit
```

**Вывод включает:**
- Версию
- Путь установки
- Статус (enabled/disabled)
- Список команд
- Список навыков
- Список агентов
- MCP серверы

### Включить/выключить

```bash
# Включить для пользователя
qwen extensions enable qwen-orchestrator-kit

# Выключить для пользователя
qwen extensions disable qwen-orchestrator-kit

# Включить для workspace
qwen extensions enable qwen-orchestrator-kit --scope workspace

# Выключить для workspace
qwen extensions disable qwen-orchestrator-kit --scope workspace
```

**Область действия:**
- `--scope user` — глобально для всех проектов
- `--scope workspace` — только для текущего проекта

### Удаление

```bash
# Удалить расширение
qwen extensions uninstall qwen-orchestrator-kit

# Проверить
qwen extensions list
```

**Что происходит:**
- Удаляется директория расширения
- Удаляются зарегистрированные команды
- Удаляются навыки и агенты
- Отключаются MCP серверы

---

## 💻 Link-разработка

### Настройка

**Шаг 1: Проверка текущей установки**

```bash
qwen extensions list
```

**Шаг 2: Удаление старой установки**

```bash
qwen extensions uninstall qwen-orchestrator-kit
```

**Шаг 3: Создание ссылки**

```bash
qwen extensions link /path/to/qwen_orc_kit_ru/.qwen
```

**Шаг 4: Проверка**

```bash
qwen extensions list
```

**Ожидаемый вывод:**
```
✓ qwen-orchestrator-kit (0.8.0)
  Path: /path/to/qwen_orc_kit_ru/.qwen (linked)
```

### Процесс разработки

**1. Внести изменения**

```bash
cd /path/to/qwen_orc_kit_ru

# Редактировать агента
vim .qwen/agents/orc_dev_task_coordinator.md

# Создать навык
mkdir -p .qwen/skills/my-skill
vim .qwen/skills/my-skill/SKILL.md
```

**2. Протестировать**

```bash
# Запустить Qwen Code
qwen

# Использовать изменённый компонент
skill: my-skill
```

**3. Закоммитить**

```bash
git add .qwen/...
git commit -m "feat: добавить my-skill"
git push origin feature/...
```

### Тестирование

**Создание тестового проекта:**

```bash
mkdir -p /tmp/test-extension-project
cd /tmp/test-extension-project

# Инициализировать Git
git init

# Запустить Qwen Code
qwen

# Проверить команды
/speckit.plan
skill: template-feedback
```

**Проверка symlink:**

```bash
# Проверить ссылку
ls -la ~/.qwen/extensions/qwen-orchestrator-kit

# Должна указывать на .qwen/ проекта
```

---

## 🔧 Troubleshooting

### Расширение не загружается

**Симптомы:**
```
qwen extensions list
# qwen-orchestrator-kit отсутствует
```

**Причины:**
- Symlink не создан или повреждён
- Манифест `qwen-extension.json` отсутствует
- Неправильный путь

**Решение:**

```bash
# Проверить symlink
ls -la ~/.qwen/extensions/qwen-orchestrator-kit

# Если нет — пересоздать
rm -rf ~/.qwen/extensions/qwen-orchestrator-kit
qwen extensions link /path/to/qwen_orc_kit_ru/.qwen

# Проверить манифест
cat /path/to/qwen_orc_kit_ru/.qwen/qwen-extension.json
```

### Изменения не видны

**Симптомы:**
```
# Внёс изменения в .qwen/
# Но в Qwen Code старые версии
```

**Причина:** Qwen Code кэширует расширения.

**Решение:**

```bash
# Выйти из Qwen Code
exit

# Перезапустить
qwen
```

### Конфликт с Git-установкой

**Симптомы:**
```
qwen extensions link ...
# Ошибка: Extension already installed
```

**Причина:** Расширение уже установлено из Git.

**Решение:**

```bash
# Удалить Git-установку
qwen extensions uninstall qwen-orchestrator-kit

# Создать ссылку
qwen extensions link /path/to/qwen_orc_kit_ru/.qwen
```

### Команды не работают

**Симптомы:**
```
/speckit.plan
# Command not found
```

**Причины:**
- Расширение не включено
- Конфликт имён
- Ошибка в манифесте

**Решение:**

```bash
# Проверить статус
qwen extensions list

# Если disabled — включить
qwen extensions enable qwen-orchestrator-kit

# Проверить манифест
jq '.commands' /path/to/qwen_orc_kit_ru/.qwen/qwen-extension.json
```

### MCP серверы не подключаются

**Симптомы:**
```
MCP server context7 failed to connect
```

**Причины:**
- Не установлен npx/uvx
- Нет доступа к интернету
- Неправильная конфигурация

**Решение:**

```bash
# Проверить npx
npx --version

# Проверить конфигурацию
jq '.mcpServers' /path/to/qwen_orc_kit_ru/.qwen/qwen-extension.json

# Перезапустить Qwen Code
exit
qwen
```

---

## 📚 Дополнительные ресурсы

### Официальная документация

- [Extension Management](https://qwenlm.github.io/qwen-code-docs/en/users/extension/introduction)
- [Developing Extensions](https://qwenlm.github.io/qwen-code-docs/en/developers/extensions/getting-started-extensions)
- [Extension Format](https://qwenlm.github.io/qwen-code-docs/en/developers/extensions/extension)

### Документы проекта

- [Link Development Guide](.qwen/docs/development/link-development.md)
- [CI/CD Workflows](.qwen/docs/ci-cd/github-actions-workflows.md)
- [Release Process](.qwen/docs/ci-cd/release-process.md)

### GitHub

- [Репозиторий](https://github.com/gecalex/qwen_orc_kit_ru)
- [Issues](https://github.com/gecalex/qwen_orc_kit_ru/issues)
- [Releases](https://github.com/gecalex/qwen_orc_kit_ru/releases)

---

## 📊 Метрики расширения

| Метрика | Значение |
|---------|----------|
| **Версия** | 0.8.0 |
| **Агентов** | 36 |
| **Навыков** | 40 |
| **Команд** | 24 |
| **Скриптов** | 94 |
| **MCP серверов** | 7 |
| **Документации** | 50+ файлов |

---

**Последнее обновление:** 29 марта 2026  
**Версия документа:** 1.0
