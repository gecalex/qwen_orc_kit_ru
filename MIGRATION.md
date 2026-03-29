# Руководство по миграции на Extensions System

**Версия:** 1.0  
**Дата:** 29 марта 2026  
**Статус:** ✅ Готово

---

## 📖 Оглавление

1. [Обзор миграции](#обзор-миграции)
2. [Подготовка](#подготовка)
3. [Шаги миграции](#шаги-миграции)
4. [Пост-миграция](#пост-миграция)
5. [Troubleshooting](#troubleshooting)
6. [Чек-лист](#чек-лист)

---

## 🎯 Обзор миграции

### Что меняется

**До миграции (старый подход):**

```
Проект/
├── .qwen/              ← Все файлы в проекте
│   ├── agents/
│   ├── skills/
│   ├── commands/
│   └── scripts/
└── src/
```

**После миграции (Extensions):**

```
Проект/                 ← Чистый проект
├── src/
└── ...

~/.qwen/extensions/qwen-orchestrator-kit/  ← Глобальное расширение
├── agents/
├── skills/
├── commands/
└── scripts/
```

### Преимущества миграции

| Аспект | До | После |
|--------|-----|-------|
| **Чистота проекта** | ❌ Файлы в проекте | ✅ Проект чистый |
| **Обновления** | ❌ Вручную | ✅ Автоматически |
| **Управление** | ❌ Сложное | ✅ Простое |
| **Изоляция** | ❌ В проекте | ✅ Глобально |
| **Тестирование** | ❌ Копирование | ✅ Link (symlink) |

### Типы миграции

**1. Миграция существующего проекта:**
- Удаление `.qwen/` из проекта
- Установка расширения
- Настройка конфигурации

**2. Миграция разработчика:**
- Переход на link-разработку
- Настройка symlink
- Тестирование

---

## 📋 Подготовка

### Шаг 1: Проверка текущей версии

```bash
# Проверить версию Qwen Code
qwen --version

# Должна быть >= 0.13.0 (с поддержкой extensions)
```

**Если старая:**

```bash
# Обновить Qwen Code
npm install -g @qwen-code/cli@latest
```

### Шаг 2: Резервное копирование

```bash
# Скопировать .qwen/ для резерва
cp -r /path/to/project/.qwen /path/to/backup/.qwen.backup

# Или создать Git тег
git tag -a pre-migration-backup -m "Резерв перед миграцией"
git push origin pre-migration-backup
```

### Шаг 3: Проверка установленных расширений

```bash
# Проверить текущие расширения
qwen extensions list
```

**Ожидаемый вывод:**
```
No extensions installed.
```

**Если есть другие расширения:**
- Запомнить их
- Проверить совместимость

---

## 🚀 Шаги миграции

### Шаг 1: Удаление .qwen/ из проекта

**ВНИМАНИЕ:** Сначала убедитесь, что все изменения закоммичены!

```bash
cd /path/to/project

# Проверить статус
git status

# Если есть изменения — закоммитить
git add -A
git commit -m "chore: pre-migration commit"

# Удалить .qwen/ (опционально, можно оставить для истории)
git rm -r .qwen/
git commit -m "chore: удалить .qwen/ (миграция на extensions)"
```

**Или оставить для истории:**

```bash
# Переместить в архив
mv .qwen/ .qwen.archive/

# Добавить в .gitignore
echo ".qwen.archive/" >> .gitignore
```

### Шаг 2: Установка расширения

```bash
# Установить расширение из GitHub
qwen extensions install https://github.com/gecalex/qwen_orc_kit_ru

# Проверить установку
qwen extensions list
qwen extensions detail qwen-orchestrator-kit
```

**Что происходит:**
1. Qwen Code создаёт `~/.qwen/extensions/qwen-orchestrator-kit`
2. Загружает манифест `qwen-extension.json`
3. Регистрирует агентов, навыки, команды
4. Настраивает MCP серверы

### Шаг 3: Настройка MCP серверов

```bash
# Проверить настройки MCP
cat ~/.qwen/settings.json

# Если нужно — добавить переменные окружения
export GITHUB_TOKEN="your_token"
export SEARXNG_URL="http://localhost:8080"
```

**Опционально:** Создать `~/.qwen/settings.local.json`

```json
{
  "mcpServers": {
    "github": {
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your_token"
      }
    }
  }
}
```

### Шаг 4: Проверка работоспособности

```bash
# Запустить Qwen Code
qwen

# Проверить команды
/speckit.plan
/speckit.specify

# Проверить навыки
skill: template-feedback

# Проверить агентов
task '{
  "subagent_type": "bug-hunter",
  "prompt": "Найти ошибки в коде"
}'
```

---

## 🔧 Пост-миграция

### Шаг 5: Обновление документации проекта

**Обновить README.md:**

```markdown
## Требования

- [Qwen Code CLI](https://github.com/QwenLM/qwen-code) >= 0.13.0
- [Qwen Code Orchestrator Kit](https://github.com/gecalex/qwen_orc_kit_ru) (extension)

## Установка

```bash
# Установить Qwen Code
npm install -g @qwen-code/cli

# Установить расширение
qwen extensions install https://github.com/gecalex/qwen_orc_kit_ru
```
```

**Обновить .gitignore:**

```gitignore
# Qwen Code
.qwen/
!qwen-extension.json

# Исключения для расширения
!.qwen/qwen-extension.json
```

### Шаг 6: Настройка для разработчиков

**Создать DEVELOPMENT.md:**

```markdown
## Разработка

### Установка расширения

```bash
# Установить расширение
qwen extensions install https://github.com/gecalex/qwen_orc_kit_ru

# Или для разработки (link)
qwen extensions link /path/to/qwen_orc_kit_ru/.qwen
```

### Тестирование

```bash
# Запустить Qwen Code
qwen

# Проверить команды
/speckit.plan
```
```

### Шаг 7: Настройка CI/CD (опционально)

**Для проекта:**

```yaml
# .github/workflows/qwen.yml
name: Qwen Code Checks

on: [push, pull_request]

jobs:
  qwen-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Qwen Code
        run: npm install -g @qwen-code/cli

      - name: Install Extension
        run: qwen extensions install https://github.com/gecalex/qwen_orc_kit_ru

      - name: Run Quality Gates
        run: qwen /run-quality-gate
```

---

## 🔧 Troubleshooting

### Проблема 1: Команды не работают

**Симптомы:**
```
/speckit.plan
# Command not found
```

**Причины:**
- Расширение не установлено
- Расширение отключено
- Неправильная версия Qwen Code

**Решение:**

```bash
# Проверить расширение
qwen extensions list

# Если не установлено — установить
qwen extensions install https://github.com/gecalex/qwen_orc_kit_ru

# Если отключено — включить
qwen extensions enable qwen-orchestrator-kit

# Проверить версию Qwen Code
qwen --version  # >= 0.13.0
```

### Проблема 2: Агенты не загружаются

**Симптомы:**
```
task '{
  "subagent_type": "bug-hunter",
  ...
}'
# Agent not found
```

**Причины:**
- Манифест повреждён
- Файлы агентов отсутствуют

**Решение:**

```bash
# Переустановить расширение
qwen extensions uninstall qwen-orchestrator-kit
qwen extensions install https://github.com/gecalex/qwen_orc_kit_ru

# Проверить манифест
cat ~/.qwen/extensions/qwen-orchestrator-kit/qwen-extension.json
```

### Проблема 3: MCP серверы не подключаются

**Симптомы:**
```
MCP server context7 failed to connect
```

**Причины:**
- Не установлен npx
- Нет интернета
- Неправильная конфигурация

**Решение:**

```bash
# Проверить npx
npx --version

# Проверить конфигурацию
jq '.mcpServers' ~/.qwen/extensions/qwen-orchestrator-kit/qwen-extension.json

# Перезапустить Qwen Code
exit
qwen
```

### Проблема 4: Конфликт с локальной .qwen/

**Симптомы:**
```
# Команды работают, но используют старую версию
```

**Причины:**
- В проекте осталась `.qwen/`
- Qwen Code использует локальную конфигурацию

**Решение:**

```bash
# Проверить наличие .qwen/ в проекте
ls -la .qwen/

# Если есть — удалить или переименовать
mv .qwen/ .qwen.archive/

# Перезапустить Qwen Code
exit
qwen
```

---

## ✅ Чек-лист

### До миграции

- [ ] Проверена версия Qwen Code (>= 0.13.0)
- [ ] Создано резервное копирование
- [ ] Все изменения закоммичены
- [ ] Проверены установленные расширения

### Миграция

- [ ] Удалена `.qwen/` из проекта (или перемещена в архив)
- [ ] Установлено расширение
- [ ] Настроены MCP серверы
- [ ] Проверена работоспособность команд

### После миграции

- [ ] Обновлён README.md
- [ ] Обновлён .gitignore
- [ ] Создан DEVELOPMENT.md (для разработчиков)
- [ ] Настроен CI/CD (опционально)
- [ ] Протестировано в боевом режиме

### Для разработчиков

- [ ] Настроен link для разработки
- [ ] Протестировано мгновенное обновление
- [ ] Настроен Git workflow
- [ ] Протестирован CI/CD

---

## 📚 Дополнительные ресурсы

### Документация

- [Extension Management](https://qwenlm.github.io/qwen-code-docs/en/users/extension/introduction)
- [Developing Extensions](https://qwenlm.github.io/qwen-code-docs/en/developers/extensions/getting-started-extensions)
- [Extensions Guide](EXTENSIONS.md) — полное руководство
- [Link Development](.qwen/docs/development/link-development.md) — разработка через link

### Поддержка

- [GitHub Issues](https://github.com/gecalex/qwen_orc_kit_ru/issues)
- [Discussions](https://github.com/gecalex/qwen_orc_kit_ru/discussions)

---

**Последнее обновление:** 29 марта 2026  
**Версия документа:** 1.0
