# 🔄 Переключение между режимами шаблона

**Дата:** 2026-03-18  
**Версия:** 1.0.0

---

## 📋 ОБЗОР

Система поддерживает **два режима работы**:

| Режим | Агентов | Навыков | Команд | Размер | Назначение |
|-------|---------|---------|--------|--------|------------|
| **Быстрый старт** | 7 | 10 | 5 | ~500 KB | Прототипы, малые проекты |
| **Полный шаблон** | 25 | 31 | 22 | ~2.3 MB | Production, сложные системы |

---

## 🚀 БЫСТРОЕ ПЕРЕКЛЮЧЕНИЕ

### **Через команду (рекомендуется):**

```bash
# Быстрый старт
qwen template-switcher quickstart

# Полный шаблон
qwen template-switcher full

# Проверка статуса
qwen template-switcher status
```

### **Через скрипт:**

```bash
# Быстрый старт
bash .qwen/scripts/template-switcher.sh quickstart

# Полный шаблон
bash .qwen/scripts/template-switcher.sh full

# Статус
bash .qwen/scripts/template-switcher.sh status
```

---

## 📖 ПОДРОБНОЕ ОПИСАНИЕ

### **Команда: `template-switcher`**

**Файл:** `.qwen/commands/template-switcher.md`

**Скрипт:** `.qwen/scripts/template-switcher.sh`

#### **Режимы работы:**

| Команда | Алиасы | Описание |
|---------|--------|----------|
| `quickstart` | `qs`, `q` | Переключиться на быстрый старт |
| `full` | `f` | Переключиться на полный шаблон |
| `status` | `s`, `stat` | Показать текущий режим |
| `help` | `h` | Показать справку |

---

## 🔧 КАК ЭТО РАБОТАЕТ

### **Алгоритм переключения в быстрый старт:**

```
1. Проверка текущего режима
   ↓
2. Создание резервной копии (.qwen/.backup-YYYYMMDD-HHMMSS/)
   ↓
3. Удаление специализированных агентов (остается 7)
   ↓
4. Удаление специализированных навыков (остается 10)
   ↓
5. Удаление специализированных команд (остается 5)
   ↓
6. Удаление специализированных скриптов (остается 3)
   ↓
7. Показ статистики
```

### **Алгоритм переключения в полный режим:**

```
1. Проверка текущего режима
   ↓
2. Проверка кэша шаблонов (.qwen/template-cache/)
   ↓
3. Если кэша нет → создание из текущих файлов
   ↓
4. Восстановление всех файлов из кэша
   ↓
5. Показ статистики
```

---

## 📊 ПРИМЕРЫ ВЫВОДА

### **Статус (быстрый старт):**

```
ℹ️  СТАТИСТИКА ПРОЕКТА
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Агенты:    7
  Навыки:    10
  Команды:   5
  Скрипты:   3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Режим: БЫСТРЫЙ СТАРТ
```

### **Статус (полный шаблон):**

```
ℹ️  СТАТИСТИКА ПРОЕКТА
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Агенты:    25
  Навыки:    31
  Команды:   22
  Скрипты:   20
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Режим: ПОЛНЫЙ ШАБЛОН
```

### **Переключение:**

```bash
$ qwen template-switcher quickstart

ℹ️  Переключение в режим БЫСТРОГО СТАРТА...
ℹ️  Создание резервной копии в .qwen/.backup-20260318-143022
✅ Резервная копия создана
ℹ️  Настройка агентов (7 базовых)...
ℹ️  Настройка навыков (10 базовых)...
ℹ️  Настройка команд (5 базовых)...
ℹ️  Настройка скриптов (3 базовых)...
✅ Режим БЫСТРОГО СТАРТА активирован
ℹ️  Резервная копия полных файлов: .qwen/.backup-20260318-143022
⚠️  Для возврата используйте: template-switcher full

ℹ️  СТАТИСТИКА ПРОЕКТА
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Агенты:    7
  Навыки:    10
  Команды:   5
  Скрипты:   3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Режим: БЫСТРЫЙ СТАРТ
```

---

## 🗂️ ЧТО ВКЛЮЧАЕТСЯ/ИСКЛЮЧАЕТСЯ

### **Быстрый старт (остается):**

**Агенты (7):**
- ✅ `orc_dev_task_coordinator` — координация разработки
- ✅ `orc_security_security_orchestrator` — безопасность
- ✅ `orc_testing_quality_assurer` — качество тестирования
- ✅ `work_dev_code_analyzer` — анализ кода
- ✅ `bug-fixer` — исправление ошибок
- ✅ `bug-hunter` — поиск ошибок
- ✅ `code-quality-checker` — проверка качества

**Навыки (10):**
- ✅ `validate-report-file` — валидация отчетов
- ✅ `generate-report-header` — заголовки отчетов
- ✅ `task-analyzer` — анализ задач
- ✅ `select-mcp-server` — выбор MCP
- ✅ `security-analyzer` — безопасность
- ✅ `dependency-auditor` — зависимости
- ✅ `security-scanner` — сканирование
- ✅ `bug-hunter` — поиск ошибок
- ✅ `bug-fixer` — исправление
- ✅ `run-quality-gate` — Quality Gates

**Команды (5):**
- ✅ `run-quality-gate`
- ✅ `health-security`
- ✅ `orchestrate-project`
- ✅ `template`
- ✅ `speckit.specify` (опционально)

**Скрипты (3):**
- ✅ `analyze-project-state.sh`
- ✅ `check-security.sh`
- ✅ `health-bugs.sh`

---

### **Полный шаблон (добавляется):**

**Агенты (+18):**
- `orc_backend_api_coordinator`
- `orc_frontend_ui_coordinator`
- `orc_planning_task_analyzer`
- `orc_research_data_analyzer`
- `work_backend_api_validator`
- `work_dev_dependency_analyzer`
- `work_dev_meta_agent`
- `work_dev_qwen_code_cli_specialist`
- `work_doc_tech_translator_ru`
- `work_frontend_component_generator`
- `work_planning_*` (3 файла)
- `work_research_trend_tracker`
- `work_health_dead_code_detector`
- `work_security_security_analyzer`
- `work_testing_test_generator`
- `work_meta_agent_creator`

**Навыки (+21):**
- Все навыки обработки данных
- Все навыки валидации
- Все навыки форматирования
- Специализированные утилиты

**Команды (+17):**
- Все команды Speckit (9 файлов)
- Health-workflow (3 файла)
- Git worktree (3 файла)
- Другие

**Скрипты (+17):**
- Quality Gates (6 файлов)
- Specification tools (2 файла)
- Release tools (2 файла)
- Orchestration tools (3 файла)
- Monitoring (2 файла)
- Health tools (4 файла)
- Agent tools (2 файла)

---

## 🗄️ РЕЗЕРВНОЕ КОПИРОВАНИЕ

### **Автоматическое создание:**

Перед переключением в быстрый старт:

```
.qwen/.backup-20260318-143022/
├── agents/      # Все 25 агентов
├── skills/      # Все 31 навык
└── commands/    # Все 22 команды
```

### **Ручное восстановление:**

```bash
# Восстановить агентов
cp -r .qwen/.backup-*/agents/* .qwen/agents/

# Восстановить навыки
cp -r .qwen/.backup-*/skills/* .qwen/skills/

# Восстановить команды
cp -r .qwen/.backup-*/commands/* .qwen/commands/
```

---

## 📦 КЭШ ШАБЛОНОВ

### **Расположение:**
```
.qwen/template-cache/
```

### **Содержимое:**
```
template-cache/
├── agents/      # Полный набор агентов
├── skills/      # Полный набор навыков
├── commands/    # Полный набор команд
├── scripts/     # Полный набор скриптов
└── docs/        # Полная документация
```

### **Создание:**

Кэш создается **автоматически** при первом переключении в полный режим.

**Или вручную:**
```bash
mkdir -p .qwen/template-cache
cp -r .qwen/agents/* .qwen/template-cache/agents/
cp -r .qwen/skills/* .qwen/template-cache/skills/
cp -r .qwen/commands/* .qwen/template-cache/commands/
cp -r .qwen/scripts/* .qwen/template-cache/scripts/
cp -r .qwen/docs/* .qwen/template-cache/docs/
```

---

## 🎯 СЦЕНАРИИ ИСПОЛЬЗОВАНИЯ

### **Сценарий 1: Новый проект**

```bash
# 1. Создаем проект
mkdir my-project && cd my-project
cp -r /path/to/qwen-orchestrator-kit/* .

# 2. Переключаемся на быстрый старт
qwen template-switcher quickstart

# 3. Начинаем разработку
qwen speckit.specify
```

### **Сценарий 2: Проект вырос**

```bash
# Проект стал сложным, нужны все возможности
qwen template-switcher full

# Проверяем
qwen template-switcher status

# Запускаем Quality Gates
qwen run-quality-gate 3
```

### **Сценарий 3: Тестирование**

```bash
# Тестируем быстрый старт
qwen template-switcher quickstart
qwen health-security

# Возвращаем полный
qwen template-switcher full
```

---

## ⚠️ ПРЕДУПРЕЖДЕНИЯ

### **Перед переключением:**

1. ✅ **Закоммитьте изменения**
   ```bash
   git add -A && git commit -m "..."
   ```

2. ✅ **Проверьте статус**
   ```bash
   qwen template-switcher status
   ```

3. ✅ **Закройте файлы в редакторе**
   - Иначе могут быть конфликты

### **После переключения:**

1. ✅ **Проверьте компоненты**
   ```bash
   qwen template-switcher status
   ```

2. ✅ **Протестируйте агентов**
   ```bash
   qwen orchestrate-project
   ```

---

## 🔧 НАСТРОЙКА

### **Изменение базового набора:**

Откройте `.qwen/scripts/template-switcher.sh` и измените:

```bash
# Базовые агенты
local keep_agents=(
    "orc_dev_task_coordinator.md"
    "orc_security_security_orchestrator.md"
    # Добавьте свои
)

# Базовые навыки
local keep_skills=(
    "validate-report-file"
    "generate-report-header"
    # Добавьте свои
)

# Базовые команды
local keep_commands=(
    "run-quality-gate.md"
    "health-security.md"
    # Добавьте свои
)
```

---

## 🆘 УСТРАНЕНИЕ ПРОБЛЕМ

### **Проблема 1: Скрипт не находит кэш**

**Ошибка:**
```
❌ Кэш шаблонов не найден
```

**Решение:**
```bash
# Создайте кэш вручную
mkdir -p .qwen/template-cache
cp -r .qwen/agents/* .qwen/template-cache/agents/
# ... и так далее для всех директорий
```

---

### **Проблема 2: Ошибка при переключении**

**Ошибка:**
```
❌ Не удалось удалить файл
```

**Решение:**
1. Проверьте права:
   ```bash
   ls -la .qwen/agents/
   ```

2. Закройте файлы в редакторе

3. Попробуйте снова:
   ```bash
   qwen template-switcher full
   ```

---

### **Проблема 3: Пропали нужные агенты**

**Решение:**
```bash
# Переключитесь на полный режим
qwen template-switcher full

# Или восстановите из резервной копии
cp -r .qwen/.backup-*/agents/* .qwen/agents/
```

---

## 📊 СТАТИСТИКА

### **Время переключения:**

| Операция | Время |
|----------|-------|
| Быстрый старт | ~5 секунд |
| Полный шаблон | ~3 секунды |
| Проверка статуса | ~1 секунда |

### **Размер файлов:**

| Компонент | Быстрый старт | Полный |
|-----------|---------------|--------|
| Агенты | ~140 KB | ~500 KB |
| Навыки | ~130 KB | ~400 KB |
| Команды | ~70 KB | ~300 KB |
| Скрипты | ~30 KB | ~200 KB |
| Документация | ~75 KB | ~600 KB |
| **ИТОГО** | **~445 KB** | **~2.0 MB** |

---

## 📖 СВЯЗАННАЯ ДОКУМЕНТАЦИЯ

- `template-comparison-report.md` — Сравнение шаблонов
- `template-files-analysis-report.md` — Анализ файлов шаблона
- `GIT_WORKFLOW.md` — Рабочий процесс Git
- `quality-gates.md` — Контрольные точки качества

---

**Документ готов к использованию!**
