# Разработка расширения через qwen extensions link

**Дата:** 29 марта 2026  
**Статус:** ✅ Готово  
**Версия:** 1.0

---

## 📖 Оглавление

1. [Что такое link](#что-такое-link)
2. [Установка](#установка)
3. [Процесс разработки](#процесс-разработки)
4. [Тестирование](#тестирование)
5. [Решение проблем](#решение-проблем)
6. [Чек-лист](#чек-лист)

---

## 🎯 Что такое link

**`qwen extensions link`** — команда для создания символической ссылки между директорией разработки и директорией расширений Qwen Code.

### Преимущества

| Действие | Без link | С link |
|----------|----------|--------|
| **Внесение изменений** | Редактировать в `~/.qwen/extensions/` | Редактировать в проекте ✅ |
| **Тестирование** | `qwen extensions update` после каждого изменения | Мгновенно ✅ |
| **Git** | Сложно, нет истории | Обычный git workflow ✅ |
| **Бэкап** | Нет | Git репозиторий ✅ |
| **CI/CD** | Нет | GitHub Actions ✅ |

### Как это работает

```
Проект: /home/alex/MyProjects/qwen_orc_kit_ru/.qwen/
                    ↓ (symlink)
Расширение: ~/.qwen/extensions/qwen-orchestrator-kit/
```

**Qwen Code при запуске:**
1. Сканирует `~/.qwen/extensions/`
2. Находит symlink на `.qwen/` проекта
3. Загружает расширение из проекта
4. Все изменения видны сразу!

---

## 🚀 Установка

### Шаг 1: Проверить текущие расширения

```bash
# Список установленных расширений
qwen extensions list
```

**Ожидаемый вывод:**
```
Installed Extensions:
- qwen-orchestrator-kit (v0.7.0) [enabled]
  Source: Git (https://github.com/gecalex/qwen_orc_kit_ru)
```

### Шаг 2: Удалить старую установку (если есть)

```bash
# Удалить расширение
qwen extensions uninstall qwen-orchestrator-kit

# Проверить
qwen extensions list
```

### Шаг 3: Создать ссылку

```bash
# Создать symlink
qwen extensions link /home/alex/MyProjects/qwen_orc_kit_ru/.qwen

# Проверить
qwen extensions list
```

**Ожидаемый вывод:**
```
Installed Extensions:
- qwen-orchestrator-kit (v0.7.0) [enabled]
  Source: Linked (/home/alex/MyProjects/qwen_orc_kit_ru/.qwen)
```

### Шаг 4: Проверить работоспособность

```bash
# Запустить Qwen Code
qwen

# Проверить команду расширения
/speckit.plan
```

---

## 💻 Процесс разработки

### 1. Внести изменения

```bash
# Перейти в проект
cd /home/alex/MyProjects/qwen_orc_kit_ru

# Внести изменения в .qwen/
# Например, обновить агента
vim .qwen/agents/orc_dev_task_coordinator.md

# Или создать новый навык
mkdir -p .qwen/skills/my-new-skill
vim .qwen/skills/my-new-skill/SKILL.md
```

### 2. Протестировать

```bash
# Запустить Qwen Code в тестовом проекте
cd /tmp/test-extension-project
qwen

# Использовать изменённый агент/навык/команду
```

**Изменения видны сразу!** Не нужно выполнять `qwen extensions update`.

### 3. Закоммитить

```bash
# Вернуться в проект
cd /home/alex/MyProjects/qwen_orc_kit_ru

# Проверить изменения
git status

# Добавить файлы
git add .qwen/...

# Закоммитить
git commit -m "feat: добавить my-new-skill"

# Push
git push origin feature/...
```

### 4. Создать PR (опционально)

```bash
# Если работа в feature-ветке
# Создать Pull Request на GitHub
```

---

## 🧪 Тестирование

### Тестовый проект

**Создание:**
```bash
# Создать тестовую директорию
mkdir -p /tmp/test-extension-project
cd /tmp/test-extension-project

# Инициализировать Git (опционально)
git init

# Запустить Qwen Code
qwen
```

**Тестирование команд:**
```bash
# Проверить команды расширения
/speckit.plan
/speckit.specify
/speckit.tasks

# Проверить навыки
skill: template-feedback
skill: calculate-bug-priority

# Проверить агентов
task '{
  "subagent_type": "bug-hunter",
  "prompt": "Найти ошибки в коде"
}'
```

### Автоматическое тестирование

**Скрипт для быстрого теста:**

```bash
#!/bin/bash
# .qwen/scripts/dev/quick-test.sh

echo "=== Quick Test Extension ==="
echo ""

# Проверка symlink
echo "1. Проверка symlink..."
ls -la ~/.qwen/extensions/qwen-orchestrator-kit
echo ""

# Проверка манифеста
echo "2. Проверка манифеста..."
cat .qwen/qwen-extension.json | jq .name, .version
echo ""

# Проверка агентов
echo "3. Проверка агентов..."
ls -la .qwen/agents/ | wc -l
echo ""

# Проверка навыков
echo "4. Проверка навыков..."
ls -la .qwen/skills/ | wc -l
echo ""

echo "✅ Quick Test Complete"
```

**Использование:**
```bash
./.qwen/scripts/dev/quick-test.sh
```

---

## 🔧 Решение проблем

### Проблема 1: Расширение не загружается

**Симптомы:**
```
qwen extensions list
# qwen-orchestrator-kit отсутствует
```

**Причина:** Symlink не создан или повреждён.

**Решение:**
```bash
# Удалить старую ссылку
rm -rf ~/.qwen/extensions/qwen-orchestrator-kit

# Создать новую
qwen extensions link /home/alex/MyProjects/qwen_orc_kit_ru/.qwen

# Проверить
qwen extensions list
```

### Проблема 2: Изменения не видны

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

### Проблема 3: Конфликт с Git-установкой

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
qwen extensions link /home/alex/MyProjects/qwen_orc_kit_ru/.qwen
```

### Проблема 4: Неправильный путь

**Симптомы:**
```
# Symlink создан, но Qwen Code не видит файлы
```

**Причина:** Неверный путь при создании ссылки.

**Решение:**
```bash
# Проверить symlink
ls -la ~/.qwen/extensions/qwen-orchestrator-kit

# Должно указывать на .qwen/ проекта
# Если нет — пересоздать

rm -rf ~/.qwen/extensions/qwen-orchestrator-kit
qwen extensions link /home/alex/MyProjects/qwen_orc_kit_ru/.qwen
```

### Проблема 5: Конфликт версий

**Симптомы:**
```
# Версия в qwen-extension.json не совпадает с ожидаемой
```

**Причина:** Изменения в манифесте не закоммичены.

**Решение:**
```bash
# Проверить версию
cat .qwen/qwen-extension.json | jq .version

# Обновить версию
vim .qwen/qwen-extension.json

# Закоммитить
git add .qwen/qwen-extension.json
git commit -m "chore: bump version to 0.8.0"
```

---

## ✅ Чек-лист

### Первоначальная настройка

- [ ] Проверить `qwen extensions list`
- [ ] Удалить старую установку (если есть)
- [ ] Создать symlink: `qwen extensions link ...`
- [ ] Проверить `qwen extensions list`
- [ ] Протестировать команду расширения

### Ежедневная разработка

- [ ] Внести изменения в `.qwen/`
- [ ] Протестировать в тестовом проекте
- [ ] Закоммитить изменения
- [ ] Push на GitHub

### Перед релизом

- [ ] Обновить версию в `qwen-extension.json`
- [ ] Обновить `CHANGELOG.md`
- [ ] Создать Git тег
- [ ] Push тега
- [ ] Протестировать установку из Git

---

## 📚 Дополнительные ресурсы

### Команды Qwen Code

```bash
# Управление расширениями
qwen extensions list
qwen extensions detail qwen-orchestrator-kit
qwen extensions enable qwen-orchestrator-kit
qwen extensions disable qwen-orchestrator-kit
qwen extensions uninstall qwen-orchestrator-kit

# Link
qwen extensions link path/to/.qwen
```

### Файлы расширения

| Файл | Назначение |
|------|------------|
| `.qwen/qwen-extension.json` | Манифест расширения |
| `.qwen/QWEN.md` | Контекст расширения |
| `.qwen/agents/` | Агенты |
| `.qwen/skills/` | Навыки |
| `.qwen/commands/` | Команды |
| `.qwen/scripts/` | Скрипты |

### Ссылки

- [Официальная документация](https://qwenlm.github.io/qwen-code-docs/)
- [GitHub Actions](.qwen/docs/ci-cd/github-actions-workflows.md)
- [Процесс релиза](.qwen/docs/ci-cd/release-process.md)

---

**Последнее обновление:** 29 марта 2026  
**Версия:** 1.0
