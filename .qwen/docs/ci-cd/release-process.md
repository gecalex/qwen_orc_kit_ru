# Процесс релиза расширения

**Версия:** 1.0  
**Дата:** 29 марта 2026  
**Статус:** ✅ Готово

---

## Обзор

Данный документ описывает пошаговый процесс создания релизов Qwen Orchestrator Kit Extension с использованием CI/CD.

---

## Предварительные требования

### Требования к окружению

| Компонент | Версия | Проверка |
|-----------|--------|----------|
| Git | ≥ 2.30 | `git --version` |
| Bash | ≥ 4.0 | `bash --version` |
| jq | ≥ 1.6 | `jq --version` |
| Node.js | ≥ 20 | `node --version` |

### Требования к репозиторию

- ✅ Инициализированный Git репозиторий
- ✅ Ветка `main` существует
- ✅ Манифест `.qwen/qwen-extension.json` существует
- ✅ Файл `QWEN.md` существует
- ✅ Файл `.version` существует

### Установка зависимостей

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y git jq nodejs npm

# macOS
brew install git jq node

# Проверка установки
git --version
jq --version
node --version
```

---

## Пошаговый процесс релиза

### Шаг 1: Подготовка к релизу

**Цель:** Обновить версию во всех файлах и сгенерировать changelog.

**Команда:**

```bash
./.qwen/scripts/release/prepare-release.sh 0.8.0
```

**Что делает скрипт:**

1. ✅ Проверяет окружение (Git, jq, манифест)
2. ✅ Обновляет версию в `.qwen/qwen-extension.json`
3. ✅ Обновляет версию в `package.json`
4. ✅ Обновляет версию в `.version`
5. ✅ Генерирует changelog из Git commits
6. ✅ Добавляет файлы в staging area

**Пример вывода:**

```
========================================
🚀 Подготовка к релизу v0.8.0
========================================

[INFO] Версия для релиза: 0.8.0
[STEP] Проверка окружения...
[OK] Git установлен
[OK] jq установлен
[OK] Манифест найден
[OK] QWEN.md найден
[OK] Корень проекта определён верно

[STEP] Обновление версии в манифесте...
[INFO] Старая версия: 0.7.0
[OK] Версия обновлена: 0.7.0 → 0.8.0

[STEP] Обновление версии в package.json...
[OK] Версия обновлена: 0.7.0 → 0.8.0

[STEP] Обновление файла .version...
[OK] Файл .version обновлён: 0.8.0

[STEP] Генерация changelog...
[OK] CHANGELOG.md обновлён

[STEP] Проверка изменений...
📊 Изменения:
 .qwen/qwen-extension.json | 2 +-
 package.json              | 2 +-
 .version                  | 2 +-
 CHANGELOG.md              | 10 ++++++++++

[OK] Обнаружены изменения

[STEP] Создание черновика коммита...
 M .qwen/qwen-extension.json
 M package.json
 M .version
 M CHANGELOG.md

[INFO] Файлы добавлены в staging area
[WARN] Коммит НЕ создан автоматически!

Следующие шаги:
  1. Проверьте изменения: git diff --cached
  2. Создайте коммит: git commit -m "chore: prepare release v0.8.0"
  3. Запустите create-release.sh: ./.qwen/scripts/release/create-release.sh 0.8.0

========================================
[OK] Подготовка к релизу v0.8.0 завершена!
========================================
```

**Проверка после шага:**

```bash
# Проверить изменения
git diff --cached

# Проверить версию в манифесте
jq -r '.version' .qwen/qwen-extension.json
# Должно вывести: 0.8.0

# Проверить версию в .version
cat .version
# Должно вывести: 0.8.0
```

---

### Шаг 2: Коммит изменений

**Цель:** Закоммитить изменения версии и отправить в репозиторий.

**Команды:**

```bash
# Проверить изменения
git diff --cached

# Создать коммит
git commit -m "chore: prepare release v0.8.0"

# Отправить в репозиторий
git push origin main
```

**Формат сообщения коммита:**

```
chore: prepare release v<версия>
```

**Пример:**

```bash
git commit -m "chore: prepare release v0.8.0"
```

**Проверка после шага:**

```bash
# Проверить историю коммитов
git log --oneline -3

# Убедиться, что изменения отправлены
git status
```

---

### Шаг 3: Создание релиза

**Цель:** Создать Git тег, который запустит CI/CD workflow.

**Команда:**

```bash
./.qwen/scripts/release/create-release.sh 0.8.0
```

**Что делает скрипт:**

1. ✅ Проверяет окружение и версию в манифесте
2. ✅ Проверяет отсутствие незакоммиченных изменений
3. ✅ Проверяет отсутствие существующего тега
4. ✅ Создаёт аннотированный Git тег
5. ✅ Отправляет тег на GitHub
6. ✅ Запускает GitHub Actions workflow

**Пример вывода:**

```
========================================
🚀 Создание релиза v0.8.0
========================================

[INFO] Версия для релиза: 0.8.0
[STEP] Проверка окружения...
[OK] Git установлен
[OK] Манифест найден
[OK] Версия в манифесте совпадает: 0.8.0
[OK] Версия в .version совпадает: 0.8.0
[OK] Текущая ветка: main
[OK] Нет незакоммиченных изменений

[STEP] Проверка существующих тегов...
[OK] Тег v0.8.0 не существует, можно создавать

[STEP] Создание Git тега...
[OK] Тег v0.8.0 создан

[STEP] Push тега на GitHub...
[INFO] Remote: https://github.com/username/qwen_orc_kit_ru.git
[INFO] Отправка тега v0.8.0...
Enumerating objects: 15, done.
Counting objects: 100% (15/15), done.
Delta compression using up to 8 threads
Compressing objects: 100% (8/8), done.
Writing objects: 100% (9/9), 1.23 KiB | 1.23 MiB/s, done.
Total 9 (delta 6), reused 0 (delta 0), pack-reused 0
To https://github.com/username/qwen_orc_kit_ru.git
 * [new tag]         v0.8.0 -> v0.8.0
[OK] Тег отправлен на GitHub

[STEP] Проверка статуса CI/CD...
[INFO] GitHub Actions должен автоматически запустить workflow 'Release Extension'

🔗 Ссылки:
   Actions: https://github.com/username/qwen_orc_kit_ru/actions
   Release: https://github.com/username/qwen_orc_kit_ru/releases/tag/v0.8.0

[WARN] Проверьте статус workflow в течение 1-2 минут

========================================
🎉 Релиз v0.8.0 создан!
========================================

✅ Выполненные шаги:
   1. Проверка окружения
   2. Проверка версии в манифесте
   3. Создание Git тега v0.8.0
   4. Push тега на GitHub

🔄 Следующие шаги:
   1. Проверьте GitHub Actions: workflow 'Release Extension'
   2. Дождитесь создания GitHub Release
   3. Проверьте опубликованный релиз

📦 Пользователи смогут обновиться:
   qwen extensions update qwen-orchestrator-kit

🔗 GitHub Release:
   https://github.com/username/qwen_orc_kit_ru/releases/tag/v0.8.0
```

**Проверка после шага:**

```bash
# Проверить созданный тег
git tag -l | grep v0.8.0

# Показать информацию о теге
git show v0.8.0

# Проверить отправку тега
git push --dry-run origin --tags
```

---

### Шаг 4: Мониторинг CI/CD

**Цель:** Убедиться, что workflow успешно выполнен и релиз создан.

**Действия:**

1. **Перейти на GitHub**
   - Открыть репозиторий
   - Перейти на вкладку **Actions**

2. **Найти запуск workflow**
   - Найти workflow **Release Extension**
   - Кликнуть на последний запуск (должен быть вверху)

3. **Проверить статус**
   - ✅ (зелёная галочка) — успешно
   - ❌ (красный крест) — ошибка
   - 🟡 (жёлтый круг) — выполняется

4. **Просмотр логов**
   - Кликнуть на задачу **Validate**
   - Кликнуть на задачу **Release**
   - Развернуть шаги для просмотра деталей

**Время выполнения:**

| Задача | Время |
|--------|-------|
| Validate | ~30 сек |
| Release | ~1-2 мин |
| **Итого** | **~2-3 мин** |

**Пример успешного выполнения:**

```
✅ Release Extension #42
   ✓ validate (32s)
   ✓ release (1m 45s)
```

---

### Шаг 5: Проверка релиза

**Цель:** Убедиться, что GitHub Release создан корректно.

**Действия:**

1. **Перейти на страницу релиза**
   - URL: `https://github.com/<username>/qwen_orc_kit_ru/releases/tag/v0.8.0`

2. **Проверить содержимое**
   - ✅ Название: `Release v0.8.0`
   - ✅ Changelog (список изменений)
   - ✅ Дата публикации
   - ✅ Статус: `Latest` (если это последний релиз)

3. **Проверить установку**
   ```bash
   # Установка конкретной версии
   qwen extensions install https://github.com/<username>/qwen_orc_kit_ru --ref v0.8.0

   # Проверка версии
   qwen extensions list
   ```

---

## Чек-лист релиза

### Перед релизом

- [ ] Все изменения влиты в `main`
- [ ] Тесты проходят успешно
- [ ] Документация обновлена
- [ ] CHANGELOG.md актуален
- [ ] Версия в `.qwen/qwen-extension.json` обновлена
- [ ] Нет незакоммиченных изменений
- [ ] Текущая ветка: `main`

### Во время релиза

- [ ] Запущен `prepare-release.sh`
- [ ] Изменения проверены (`git diff --cached`)
- [ ] Коммит создан с правильным сообщением
- [ ] Изменения отправлены (`git push`)
- [ ] Запущен `create-release.sh`
- [ ] Тег создан и отправлен

### После релиза

- [ ] Workflow выполнен успешно (зелёная галочка)
- [ ] GitHub Release создан
- [ ] Changelog корректен
- [ ] Версия в манифесте совпадает с тегом
- [ ] Пользователи могут обновиться

---

## Troubleshooting

### Ошибка: "Manifest not found"

**Симптомы:**

```
[ERROR] Манифест не найден: /path/to/.qwen/qwen-extension.json
```

**Причина:** Отсутствует файл манифеста.

**Решение:**

```bash
# Проверить наличие файла
ls -la .qwen/qwen-extension.json

# Если отсутствует, создать
# См. документацию по созданию манифеста
```

---

### Ошибка: "Version mismatch"

**Симптомы:**

```
[ERROR] Версия в манифесте (0.7.0) не совпадает с указанной (0.8.0)!
```

**Причина:** Версия в файлах не обновлена.

**Решение:**

```bash
# Запустить prepare-release.sh с правильной версией
./.qwen/scripts/release/prepare-release.sh 0.8.0

# Проверить версию
jq -r '.version' .qwen/qwen-extension.json
```

---

### Ошибка: "Tag already exists"

**Симптомы:**

```
[ERROR] Тег v0.8.0 уже существует!
```

**Причина:** Тег с такой версией уже создан.

**Решение 1: Использовать другую версию**

```bash
# Создать релиз с новой версией
./.qwen/scripts/release/create-release.sh 0.8.1
```

**Решение 2: Удалить существующий тег**

```bash
# Удалить локальный тег
git tag -d v0.8.0

# Удалить удалённый тег
git push origin :refs/tags/v0.8.0

# Создать заново
./.qwen/scripts/release/create-release.sh 0.8.0
```

---

### Ошибка: "Uncommitted changes"

**Симптомы:**

```
[ERROR] Есть незакоммиченные изменения!
```

**Причина:** В репозитории есть незакоммиченные изменения.

**Решение:**

```bash
# Показать изменения
git status

# Закоммитьте или отмените изменения
git add -A
git commit -m "chore: commit before release"
git push

# Или отмените изменения
git stash
```

---

### Ошибка: "Not on main branch"

**Симптомы:**

```
[WARN] Текущая ветка: feature/my-feature (рекомендуется main)
```

**Причина:** Релиз создаётся не из ветки `main`.

**Решение:**

```bash
# Переключиться на main
git checkout main

# Обновить main
git pull origin main

# Запустить create-release.sh заново
./.qwen/scripts/release/create-release.sh 0.8.0
```

---

### Workflow не запускается

**Симптомы:**

- Тег создан и отправлен
- Workflow не появляется в Actions

**Причины:**

1. GitHub Actions отключены в настройках репозитория
2. Нет прав на запуск workflow

**Решение:**

```bash
# Проверить настройки репозитория
# Settings → Actions → Allow all actions

# Проверить наличие workflow файла
ls -la .github/workflows/release.yml

# Проверить синтаксис YAML
yamllint .github/workflows/release.yml
```

---

### Workflow завершился ошибкой

**Симптомы:**

- Workflow показывает ❌ (красный крест)

**Действия:**

1. **Открыть логи**
   - Перейти на вкладку **Actions**
   - Кликнуть на неудачный запуск
   - Кликнуть на задачу с ошибкой

2. **Найти ошибку**
   - Развернуть шаги
   - Найти сообщение об ошибке

3. **Исправить и перезапустить**
   - Исправить причину ошибки
   - Нажать **Re-run jobs**

**Типичные ошибки workflow:**

| Ошибка | Решение |
|--------|---------|
| `jq: command not found` | Установить jq в workflow |
| `Permission denied` | Проверить `GITHUB_TOKEN` |
| `Invalid JSON` | Исправить синтаксис манифеста |

---

## Автоматизация

### Полный скрипт релиза

```bash
#!/bin/bash

# release-all.sh - Полный процесс релиза

VERSION="$1"

if [ -z "$VERSION" ]; then
    echo "Использование: $0 <версия>"
    exit 1
fi

echo "🚀 Начало релиза v$VERSION"

# Шаг 1: Подготовка
echo "📝 Шаг 1: Подготовка..."
./.qwen/scripts/release/prepare-release.sh "$VERSION"

# Шаг 2: Коммит
echo "💾 Шаг 2: Коммит..."
git commit -m "chore: prepare release v$VERSION"
git push origin main

# Шаг 3: Создание релиза
echo "🏷️ Шаг 3: Создание релиза..."
./.qwen/scripts/release/create-release.sh "$VERSION"

echo "✅ Релиз v$VERSION завершён!"
echo "🔗 Проверьте: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]/' | sed 's/\.git$//')/actions"
```

**Использование:**

```bash
chmod +x release-all.sh
./release-all.sh 0.8.0
```

---

## Дополнительные команды

### Полезные Git команды

```bash
# Показать все теги
git tag -l

# Показать информацию о теге
git show v0.8.0

# Удалить тег (локально)
git tag -d v0.8.0

# Удалить тег (удалённо)
git push origin :refs/tags/v0.8.0

# Показать историю тегов
git log --tags --simplify-by-decoration --pretty="format:%ci %d"

# Сравнить версии
git diff v0.7.0..v0.8.0
```

### Полезные GitHub CLI команды

```bash
# Установить GitHub CLI
sudo apt-get install gh

# Авторизация
gh auth login

# Показать релизы
gh release list

# Создать релиз вручную
gh release create v0.8.0 --title "Release v0.8.0" --notes "Changelog..."

# Показать статус workflow
gh run list
gh run view <run-id>
```

---

## Ссылки

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Creating Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Последнее обновление:** 29 марта 2026
