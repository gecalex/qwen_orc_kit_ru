# Release Workflow

**Версия:** 1.0.0  
**Дата:** 2026-03-18

---

## 🎯 ОБЗОР

Процесс релиза разделен на две ветки:
- **main** — только файлы для пользователя (172 файла, ~2.2 MB)
- **develop** — все файлы проекта (200+ файлов, ~3.5 MB)

---

## 🌿 СТРУКТУРА ВЕТОК

```
main (production)
  ↑
release/vX.X.X
  ↑
dev (development) ← основная ветка для разработки
  ↑
feature/xxx  bugfix/xxx  hotfix/xxx
```

### Ветка `main`
- ✅ Только стабильные релизные версии
- ✅ 172 файла для немедленного начала работы
- ✅ Нет файлов разработки (state/, specs/, reports/)
- ✅ Теги версий: v0.2.0, v0.3.0, etc.

### Ветка `develop`
- ✅ Основная ветка для разработки
- ✅ Все файлы проекта (state/, specs/, reports/, examples/)
- ✅ Сюда мержатся все feature/bugfix ветки

---

## 📦 СОДЕРЖИМОЕ ВЕТОК

### **main (для пользователя)**

**Корневые файлы (9):**
```
.markdownlint.yml
CHANGELOG.md
CONTRIBUTING.md
INSTALLATION.md
package.json
QWEN.md
QUICKSTART.md
README.md
USAGE_INSTRUCTIONS.md
```

**.qwen/ (вся конфигурация):**
```
.qwen/
├── agents/           # 25 агентов
├── commands/         # 22 команды
├── config/           # 3 конфигурации
├── docs/
│   └── architecture/ # 23 файла документации
├── prompts/          # 2 промпта
├── scripts/          # ~20 скриптов
├── skills/           # 31 навык
├── templates/        # 5 шаблонов
└── tests/            # 4 поддиректории
```

**ИТОГО:** 172 файла, ~2.2 MB

---

### **develop (для разработки)**

**Дополнительно к main:**
```
backups/              # Резервные копии
examples/             # Примеры использования
logs/                 # Логи
specs/                # Спецификации проекта
state/                # Артефакты выполнения
reports/              # Отчеты разработки
FEATURE_DIR/          # Тестовые файлы
.tmp/                 # Временные файлы
GIT_WORKFLOW.md       # В корне (для разработки)
RELEASE_*.md          # Документация релиза
release_preparation_report.md
```

**ИТОГО:** 200+ файлов, ~3.5 MB

---

## 🔄 ПРОЦЕСС РЕЛИЗА

### **Этап 1: Подготовка (develop)**

```bash
# 1. Убедиться, что все изменения в develop
git checkout develop
git pull origin develop

# 2. Создать release-ветку
git checkout -b release/v0.3.0

# 3. Обновить CHANGELOG.md
# 4. Обновить версию в package.json
# 5. Протестировать
```

---

### **Этап 2: Слияние в main**

```bash
# 1. Переключиться на main
git checkout main

# 2. Влить release-ветку
git merge --no-ff release/v0.3.0 -m "Release v0.3.0"
```

---

### **Этап 3: Очистка main**

**Удалить файлы разработки:**

```bash
# Директории
rm -rf state/ specs/ reports/ examples/ logs/
rm -rf backups/ FEATURE_DIR/ .tmp/

# Файлы
rm -f release_preparation_report.md
rm -f RELEASE_BUILD_INSTRUCTIONS.md
rm -f RELEASE_NOTES.md
rm -f .gitignore

# Переместить GIT_WORKFLOW.md
mkdir -p .qwen/docs/architecture/
if [ -f "GIT_WORKFLOW.md" ]; then
    mv GIT_WORKFLOW.md .qwen/docs/architecture/
fi
```

**Закоммитить:**

```bash
git add -A
git commit -m "release: v0.3.0 - очистка для публикации"
```

---

### **Этап 4: Создание тега**

```bash
# Создать аннотированный тег
git tag -a v0.3.0 -m "Release v0.3.0: описание изменений"

# Отправить на GitHub
git push origin main v0.3.0
```

---

### **Этап 5: Завершение (develop)**

```bash
# 1. Переключиться на develop
git checkout develop

# 2. Влить release-ветку
git merge --no-ff release/v0.3.0

# 3. Удалить release-ветку
git branch -d release/v0.3.0

# 4. Отправить develop
git push origin develop
```

---

## 📋 ЧЕК-ЛИСТ РЕЛИЗА

### **Подготовка**
- [ ] Все feature-ветки влиты в develop
- [ ] Тесты проходят
- [ ] CHANGELOG.md обновлен
- [ ] Версия в package.json обновлена
- [ ] release-ветка создана

### **Очистка main**
- [ ] state/, specs/, reports/ удалены
- [ ] examples/, logs/, backups/ удалены
- [ ] FEATURE_DIR/, .tmp/ удалены
- [ ] release_preparation_report.md удален
- [ ] RELEASE_*.md удалены
- [ ] .gitignore удален
- [ ] GIT_WORKFLOW.md перемещен в .qwen/docs/architecture/

### **Публикация**
- [ ] Коммит сделан
- [ ] Тег создан
- [ ] main отправлен на GitHub
- [ ] develop отправлен на GitHub

---

## ⚠️ ВАЖНО

### **НЕ включать в main:**

| Файл/Директория | Причина |
|-----------------|---------|
| `state/` | Артефакты разработки |
| `specs/` | Спецификации проекта |
| `reports/` | Отчеты разработки |
| `examples/` | Примеры (только для develop) |
| `backups/` | Резервные копии |
| `FEATURE_DIR/` | Тестовые файлы |
| `.tmp/` | Временные файлы |
| `.gitignore` | Создается пользователем |
| `RELEASE_*.md` | Для команды разработки |

---

## 🚀 ИСПОЛЬЗОВАНИЕ ПОЛЬЗОВАТЕЛЕМ

### **Клонирование и начало работы:**

```bash
# 1. Клонировать main
git clone https://github.com/your-org/qwen-orchestrator-kit.git my-project
cd my-project

# 2. Инициализировать git
git init

# 3. Создать .gitignore (опционально)
cat > .gitignore << EOF
node_modules/
*.log
.tmp/
.env
EOF

# 4. Начать разработку!
qwen  # Запустить Qwen Code
qwen speckit.specify  # Создать спецификацию
qwen orchestrate-project  # Запустить оркестрацию
```

**ВСЁ!** Никаких установок, настроек, зависимостей!

---

## 📊 СТАТИСТИКА

| Параметр | main | develop |
|----------|------|---------|
| **Файлов** | 172 | 200+ |
| **Размер** | ~2.2 MB | ~3.5 MB |
| **Корневые файлы** | 9 | 11+ |
| **Агенты** | 25 | 25 |
| **Навыки** | 31 | 31 |
| **Команды** | 22 | 22 |
| **Скрипты** | ~20 | ~20 |
| **Документация** | 23 файла | 60+ файлов |

---

## 🔧 АВТОМАТИЗАЦИЯ

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
rm -rf backups/ FEATURE_DIR/ .tmp/
rm -f release_preparation_report.md
rm -f RELEASE_BUILD_INSTRUCTIONS.md RELEASE_NOTES.md
rm -f .gitignore

# Перемещение GIT_WORKFLOW.md
echo "📁 Перемещение GIT_WORKFLOW.md..."
mkdir -p .qwen/docs/architecture/
if [ -f "GIT_WORKFLOW.md" ]; then
    mv GIT_WORKFLOW.md .qwen/docs/architecture/
fi

echo "✅ Релиз готов!"
```

---

## 📖 СВЯЗАННАЯ ДОКУМЕНТАЦИЯ

- `GIT_WORKFLOW.md` — Рабочий процесс Git
- `RELEASE_TEMPLATE_FILES.md` — Список файлов для релиза
- `release-vs-develop-analysis.md` — Сравнение release/main и develop

---

**Документ готов к использованию!**
