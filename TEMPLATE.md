# 🚀 Шаблон для нового проекта

**Версия:** 1.0.0  
**Дата:** 2026-03-18

---

## 🎯 БЫСТРЫЙ СТАРТ

### **1. Клонировать шаблон**

```bash
git clone https://github.com/your-org/qwen-orchestrator-kit.git my-project
cd my-project
```

### **2. Инициализировать git**

```bash
git init
```

### **3. Создать .gitignore**

```bash
cat > .gitignore << EOF
node_modules/
*.log
.tmp/
.env
*.backup
EOF
```

### **4. Начать разработку!**

```bash
qwen  # Запустить Qwen Code
qwen speckit.specify  # Создать спецификацию
qwen orchestrate-project  # Запустить оркестрацию
```

**ВСЁ!** Можно работать! 🎉

---

## 📦 ЧТО ВЫ ПОЛУЧАЕТЕ

### **Структура проекта:**

```
my-project/
├── .qwen/                          # Конфигурация Qwen Code
│   ├── agents/                     # 25 ИИ-агентов
│   ├── commands/                   # 22 команды
│   ├── config/                     # 3 конфигурации
│   ├── docs/architecture/          # 23 файла документации
│   ├── prompts/                    # 2 промпта
│   ├── scripts/                    # ~20 скриптов
│   ├── skills/                     # 31 навык
│   ├── templates/                  # 5 шаблонов
│   ├── tests/                      # 4 поддиректории
│   ├── mcp.json                    # MCP серверы
│   ├── settings.json               # Настройки
│   └── settings.local.json.example # Пример локальных настроек
├── .markdownlint.yml               # Линтер markdown
├── CHANGELOG.md                    # История изменений
├── CONTRIBUTING.md                 # Гайдлайн контрибьютора
├── INSTALLATION.md                 # Установка
├── package.json                    # npm-пакет
├── QWEN.md                         # Конфигурация оркестратора
├── QUICKSTART.md                   # Быстрый старт
├── README.md                       # Документация
└── USAGE_INSTRUCTIONS.md           # Инструкции
```

**ИТОГО:** 172 файла, ~2.2 MB

---

## 🔧 ПЕРВЫЕ ШАГИ

### **1. Проверить статус**

```bash
qwen template-switcher status
```

**Вывод:**
```
ℹ️  📊 СТАТИСТИКА ПРОЕКТА
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Агенты:    25
  Навыки:    31
  Команды:   22
  Скрипты:   53
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Режим: ПОЛНЫЙ ШАБЛОН
```

---

### **2. Настроить MCP серверы**

**Файл:** `.qwen/mcp.json`

**Пример:**
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@2.1.4"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem@2026.1.14"]
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git@0.0.3"]
    }
  }
}
```

---

### **3. Создать первую спецификацию**

```bash
qwen speckit.specify
```

**Вопросы:**
- Что нужно реализовать?
- Кто будет использовать?
- Какие требования?

**Результат:**
```
specs/001-my-feature/
├── spec.md         # Спецификация
├── plan.md         # План реализации
├── tasks.md        # Задачи
└── checklists/     # Чек-листы
```

---

### **4. Запустить реализацию**

```bash
qwen speckit.implement
```

**Процесс:**
1. Анализ спецификации
2. Генерация задач
3. Назначение агентов
4. Выполнение задач
5. Проверка качества

---

## 🎯 РЕЖИМЫ РАБОТЫ

### **Полный шаблон (по умолчанию)**

**172 файла, все возможности:**
- ✅ 25 агентов
- ✅ 31 навык
- ✅ 22 команды
- ✅ ~20 скриптов
- ✅ Полная документация

**Для:** production-проектов, сложных систем

---

### **Быстрый старт**

**42 файла, базовые возможности:**
- ✅ 7 агентов
- ✅ 10 навыков
- ✅ 4 команды
- ✅ 3 скрипта

**Переключение:**
```bash
qwen template-switcher quickstart
```

**Для:** прототипов, малых проектов

---

### **Переключение режимов**

```bash
# Быстрый старт
qwen template-switcher quickstart

# Полный шаблон
qwen template-switcher full

# Статус
qwen template-switcher status
```

---

## 📚 ДОКУМЕНТАЦИЯ

### **Основная:**

| Файл | Описание |
|------|----------|
| `QWEN.md` | Конфигурация оркестратора |
| `QUICKSTART.md` | Быстрый старт |
| `README.md` | Основная документация |
| `USAGE_INSTRUCTIONS.md` | Инструкции |
| `INSTALLATION.md` | Установка |

### **Архитектура (.qwen/docs/architecture/):**

| Файл | Описание |
|------|----------|
| `GIT_WORKFLOW.md` | Рабочий процесс Git |
| `release-workflow.md` | Процесс релиза |
| `agent-orchestration.md` | Оркестрация агентов |
| `quality-gates.md` | Контрольные точки |
| `specification-driven.md` | Разработка по спецификациям |

---

## 🔍 КОМАНДЫ

### **Speckit (разработка по спецификациям):**

```bash
qwen speckit.specify        # Создать спецификацию
qwen speckit.clarify        # Уточнить спецификацию
qwen speckit.plan           # Создать план
qwen speckit.tasks          # Генерировать задачи
qwen speckit.implement      # Реализовать
qwen speckit.constitution   # Конституция проекта
```

### **Health-workflow (диагностика):**

```bash
qwen health-bugs            # Проверка ошибок
qwen health-security        # Проверка безопасности
qwen health-cleanup         # Проверка чистоты кода
qwen health-deps            # Проверка зависимостей
```

### **Quality Gates:**

```bash
qwen run-quality-gate 1     # Pre-Execution
qwen run-quality-gate 2     # Post-Execution
qwen run-quality-gate 3     # Pre-Commit
```

### **Git worktree:**

```bash
qwen worktree-create feature/my-feature
qwen worktree-list
qwen worktree-remove feature/my-feature
```

---

## 📊 СТАТИСТИКА

### **Агенты (25):**

**Оркестраторы (7):**
- `orc_dev_task_coordinator` — координация разработки
- `orc_security_security_orchestrator` — безопасность
- `orc_testing_quality_assurer` — качество тестирования
- и другие

**Воркеры (18):**
- `work_dev_code_analyzer` — анализ кода
- `bug-fixer` — исправление ошибок
- `bug-hunter` — поиск ошибок
- и другие

---

### **Навыки (31):**

**Категории:**
- Обработка данных (3)
- Валидация (5)
- Форматирование (3)
- Анализ (4)
- Безопасность (3)
- Утилиты (13)

---

### **Команды (22):**

**Категории:**
- Speckit (9)
- Health-workflow (3)
- Git worktree (3)
- Другие (7)

---

## ⚠️ ВАЖНО

### **НЕ включать в релиз (main):**

| Файл/Директория | Причина |
|-----------------|---------|
| `state/` | Артефакты разработки |
| `specs/` | Спецификации проекта |
| `reports/` | Отчеты разработки |
| `examples/` | Примеры |
| `backups/` | Резервные копии |
| `.tmp/` | Временные файлы |

**Эти файлы есть только в develop!**

---

## 🚀 СЛЕДУЮЩИЕ ШАГИ

1. ✅ Изучить `QWEN.md` — конфигурация оркестратора
2. ✅ Запустить `qwen speckit.specify` — создать спецификацию
3. ✅ Изучить `.qwen/agents/` — доступные агенты
4. ✅ Изучить `.qwen/skills/` — доступные навыки
5. ✅ Начать разработку!

---

## 📖 ПОМОЩЬ

**Документация:**
- `.qwen/docs/help/` — справочная документация
- `.qwen/docs/architecture/` — архитектурная документация

**Команды:**
```bash
qwen --help              # Общая справка
qwen template-switcher help  # Справка по переключению
```

---

**Готовы начать разработку!** 🎉
