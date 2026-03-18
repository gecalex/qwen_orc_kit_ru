# 📊 Отчет: Разделение release/main и develop

**Дата:** 2026-03-18  
**Версия:** 1.0.0  
**Цель:** Разделение файлов для релиза (main) и разработки (develop)

---

## 🎯 АРХИТЕКТУРА ВЕТОК

### **main (release)**
- ✅ Только файлы для пользователя (172 файла, ~2.2 MB)
- ✅ Чистая структура для клонирования
- ✅ Готов к немедленному использованию
- ✅ Теги версий: v0.2.0, v0.3.0, etc.

### **develop (development)**
- ✅ ВСЕ файлы проекта (включая артефакты разработки)
- ✅ state/, specs/, reports/, examples/
- ✅ Документация разработки
- ✅ Ветки feature/*, bugfix/*, release/*

---

## 📊 СРАВНЕНИЕ СОДЕРЖИМОГО

| Файл/Директория | main | develop | Примечание |
|-----------------|------|---------|------------|
| **Корневые файлы** | | | |
| .gitignore | ❌ | ✅ | Создается пользователем |
| .markdownlint.yml | ✅ | ✅ | |
| CHANGELOG.md | ✅ | ✅ | |
| CONTRIBUTING.md | ✅ | ✅ | |
| INSTALLATION.md | ✅ | ✅ | |
| package.json | ✅ | ✅ | |
| QWEN.md | ✅ | ✅ | |
| QUICKSTART.md | ✅ | ✅ | |
| README.md | ✅ | ✅ | |
| USAGE_INSTRUCTIONS.md | ✅ | ✅ | |
| GIT_WORKFLOW.md | ❌ | ✅ | В main: .qwen/docs/architecture/ |
| release_preparation_report.md | ❌ | ✅ | Только разработка |
| RELEASE_BUILD_INSTRUCTIONS.md | ❌ | ✅ | Только разработка |
| RELEASE_NOTES.md | ❌ | ✅ | Только разработка |
| | | | |
| **.qwen/** | | | |
| agents/ | ✅ | ✅ | 25 агентов |
| skills/ | ✅ | ✅ | 31 навык |
| commands/ | ✅ | ✅ | 22 команды |
| scripts/ | ✅ | ✅ | ~20 скриптов |
| templates/ | ✅ | ✅ | 5 шаблонов |
| docs/ | ✅ | ✅ | Документация |
| config/ | ✅ | ✅ | Конфигурации |
| prompts/ | ✅ | ✅ | Промпты |
| tests/ | ✅ | ✅ | Тесты |
| plans/ | ✅ | ✅ | Планы задач |
| mcp.json | ✅ | ✅ | |
| settings.json | ✅ | ✅ | |
| | | | |
| **Артефакты разработки** | | | |
| state/ | ❌ | ✅ | Только develop |
| specs/ | ❌ | ✅ | Только develop |
| reports/ | ❌ | ✅ | Только develop |
| examples/ | ❌ | ✅ | Только develop |
| logs/ | ❌ | ✅ | Игнорируется |
| .tmp/ | ❌ | ✅ | Игнорируется |
| | | | |
| **Ветки** | | | |
| main | ✅ | - | Только релизы |
| develop | - | ✅ | Основная разработка |
| feature/* | - | ✅ | Функциональность |
| bugfix/* | - | ✅ | Исправления |
| release/* | ⚠️ Временно | ✅ | Подготовка релиза |

---

## 🔄 ПРОЦЕСС РЕЛИЗА

### **Этап 1: Подготовка (develop)**

```bash
# 1. Создать release-ветку из develop
git checkout develop
git checkout -b release/v0.2.0

# 2. Обновить CHANGELOG.md
# 3. Обновить версию в package.json
# 4. Протестировать
```

### **Этап 2: Очистка для main**

```bash
# 4. Переключиться на main
git checkout main

# 5. Влить release
git merge --no-ff release/v0.2.0

# 6. Удалить лишние файлы
rm -rf state/ specs/ reports/ examples/ logs/
rm -f release_preparation_report.md 
rm -f RELEASE_BUILD_INSTRUCTIONS.md RELEASE_NOTES.md
rm -f .gitignore

# 7. Переместить GIT_WORKFLOW.md
mv GIT_WORKFLOW.md .qwen/docs/architecture/

# 8. Закоммитить
git add -A
git commit -m "release: v0.2.0 - очистка для публикации"
```

### **Этап 3: Публикация**

```bash
# 9. Создать тег
git tag -a v0.2.0 -m "Release v0.2.0"

# 10. Отправить
git push origin main v0.2.0
```

### **Этап 4: Завершение (develop)**

```bash
# 11. Влить release в develop
git checkout develop
git merge --no-ff release/v0.2.0

# 12. Удалить release-ветку
git branch -d release/v0.2.0

# 13. Отправить
git push origin develop
```

---

## 🛠️ АВТОМАТИЗАЦИЯ

### **Скрипт: .qwen/scripts/release/prepare-for-main.sh**

```bash
#!/bin/bash
# prepare-for-main.sh - Очистка для релиза в main

set -e

echo "🚀 Подготовка к релизу в main..."

# Проверка ветки
if [ "$(git branch --show-current)" != "main" ]; then
    echo "❌ Ошибка: переключитесь на main"
    exit 1
fi

# Удаление файлов разработки
echo "🗑️  Удаление файлов разработки..."
rm -rf state/ specs/ reports/ examples/ logs/
rm -f release_preparation_report.md
rm -f RELEASE_BUILD_INSTRUCTIONS.md RELEASE_NOTES.md
rm -f .gitignore

# Перемещение GIT_WORKFLOW.md
echo "📁 Перемещение GIT_WORKFLOW.md..."
if [ -f "GIT_WORKFLOW.md" ]; then
    mkdir -p .qwen/docs/architecture/
    mv GIT_WORKFLOW.md .qwen/docs/architecture/
    echo "✅ GIT_WORKFLOW.md перемещен в .qwen/docs/architecture/"
fi

# Обновление ссылок в QWEN.md
echo "📝 Обновление ссылок..."
sed -i 's|GIT_WORKFLOW.md|.qwen/docs/architecture/GIT_WORKFLOW.md|g' QWEN.md 2>/dev/null || true

# Статистика
echo ""
echo "📊 Статистика:"
echo "  Файлов в корне: $(ls -1 | wc -l)"
echo "  Агентов: $(ls -1 .qwen/agents/ 2>/dev/null | wc -l)"
echo "  Навыков: $(ls -1 .qwen/skills/ 2>/dev/null | wc -l)"
echo ""
echo "✅ Готово к коммиту!"
echo ""
echo "Следующие шаги:"
echo "1. git add -A"
echo "2. git commit -m 'release: v0.2.0'"
echo "3. git tag -a v0.2.0 -m 'Release v0.2.0'"
echo "4. git push origin main v0.2.0"
```

### **Скрипт: .qwen/scripts/release/after-release.sh**

```bash
#!/bin/bash
# after-release.sh - Завершение релиза в develop

set -e

echo "🔄 Завершение релиза..."

# Влить release в develop
git checkout develop
git merge --no-ff release/v0.2.0 -m "Merge release/v0.2.0 into develop"

# Удалить release-ветку
git branch -d release/v0.2.0

# Отправить
git push origin develop

echo "✅ Релиз завершен!"
```

---

## 📊 РАЗЛИЧИЯ МЕЖДУ ВЕТКАМИ

### **main (172 файла, ~2.2 MB)**

```
✅ Только необходимые файлы
✅ Чистая структура
✅ Готов к клонированию
✅ Никаких артефактов разработки
✅ GIT_WORKFLOW.md в .qwen/docs/architecture/
✅ Нет .gitignore
```

### **develop (200+ файлов, ~3.5 MB)**

```
✅ ВСЕ файлы проекта
✅ state/ - артефакты выполнения
✅ specs/ - спецификации
✅ reports/ - отчеты
✅ examples/ - примеры
✅ GIT_WORKFLOW.md в корне
✅ .gitignore в корне
✅ Ветки feature/*, bugfix/*, release/*
```

---

## 🎯 СЦЕНАРИИ ИСПОЛЬЗОВАНИЯ

### **Сценарий 1: Регулярный релиз**

```bash
# 1. Разработка в develop
git checkout develop
git checkout -b feature/new-skill
# ... работа ...
git commit -m "feat: добавить новый навык"
git checkout develop
git merge feature/new-skill

# 2. Подготовка релиза
git checkout -b release/v0.3.0
# ... тестирование, исправления ...

# 3. Релиз в main
git checkout main
git merge --no-ff release/v0.3.0
# ... очистка скриптом ...
git commit -m "release: v0.3.0"
git tag -a v0.3.0
git push origin main v0.3.0

# 4. Завершение
git checkout develop
git merge --no-ff release/v0.3.0
git branch -d release/v0.3.0
git push origin develop
```

### **Сценарий 2: Экстренный хотфикс**

```bash
# 1. Создать хотфикс из main
git checkout main
git checkout -b hotfix/critical-bug

# 2. Исправить
# ... работа ...
git commit -m "fix: критическое исправление"

# 3. Влить в main
git checkout main
git merge --no-ff hotfix/critical-bug
git tag -a v0.2.1 -m "Hotfix v0.2.1"
git push origin main v0.2.1

# 4. Влить в develop
git checkout develop
git merge --no-ff hotfix/critical-bug
git branch -d hotfix/critical-bug
git push origin develop
```

---

## ⚠️ КРИТИЧЕСКИЕ ТОЧКИ

### **Перед релизом в main:**

1. ✅ Проверить, что все тесты проходят
2. ✅ Обновить CHANGELOG.md
3. ✅ Обновить версию в package.json
4. ✅ Протестировать на чистом проекте
5. ✅ Запустить скрипт очистки

### **После релиза:**

1. ✅ Влить изменения в develop
2. ✅ Удалить release-ветку
3. ✅ Отправить develop на remote
4. ✅ Проверить, что develop содержит все файлы

---

## 📋 ЧЕК-ЛИСТ РЕЛИЗА

### **Подготовка (develop)**
- [ ] Все feature-ветки влиты
- [ ] Тесты проходят
- [ ] CHANGELOG.md обновлен
- [ ] Версия в package.json обновлена
- [ ] release-ветка создана

### **Релиз (main)**
- [ ] release влит в main
- [ ] Файлы разработки удалены
- [ ] GIT_WORKFLOW.md перемещен
- [ ] Ссылки обновлены
- [ ] Коммит сделан
- [ ] Тег создан
- [ ] Push выполнен

### **Завершение (develop)**
- [ ] release влит в develop
- [ ] release-ветка удалена
- [ ] Push выполнен
- [ ] Релиз анонсирован

---

## 🔄 ВИЗУАЛИЗАЦИЯ ПРОЦЕССА

```
develop ─┬──────────────┬─────────────────────┬────────>
         │              │                     │
         ├─feature/xxx──┤                     │
         │              │                     │
         ├─feature/yyy──┤                     │
         │              │                     │
         └──────────────┴─release/v0.2.0──────┘
                                    │
                                    ↓
main ───────────────────────────────●───────> (v0.2.0)
                                    │
                                    └─ тег v0.2.0
```

---

## 📖 СВЯЗАННАЯ ДОКУМЕНТАЦИЯ

- `RELEASE_TEMPLATE_FILES.md` — Список файлов для релиза
- `GIT_WORKFLOW.md` — Рабочий процесс Git
- `quality-gates.md` — Контрольные точки качества

---

**Отчет готов к использованию!**
