# Qwen Code Orchestrator Kit

[![Version](https://img.shields.io/badge/version-0.7.0-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[![Qwen Code](https://img.shields.io/badge/Qwen-Code-purple.svg)]()

**Интеллектуальная система оркестрации разработки с ИИ-агентами**

---

## 🚀 Quick Start

### Установка за 1 минуту

```bash
# 1. Клонировать репозиторий
git clone https://github.com/yourusername/qwen_orc_kit_ru.git
cd qwen_orc_kit_ru

# 2. Установить зависимости
npm install -g @qwen-code/cli

# 3. Инициализировать проект
.qwen/scripts/init/init-project.sh

# 4. Запустить Qwen Code
qwen
```

### Первое использование

```bash
# Введите ваше техническое задание
qwen
> Создай REST API для заметок с CRUD операциями
```

---

## ✨ Возможности

### 🔹 Система обратной связи (v0.7.0)

Автоматический сбор ошибок ШАБЛОНА:

```bash
# Запустить сбор обратной связи
skill: template-feedback

# Проверить отчёты
ls -la .qwen/state/bugs/
cat .qwen/state/bugs/P2-*.md
```

**Функционал:**
- ✅ Автоматическое обнаружение ошибок
- ✅ Фильтр ошибок ШАБЛОНА (.qwen/...)
- ✅ Отправка отчётов разработчикам
- ✅ Реестр багов
- ✅ Подтверждение приёма

### 🔹 TDD Система (v0.7.0)

Test-Driven Development интеграция:

```bash
# TDD специалист создаёт тесты ПЕРЕД кодом
skill: tdd-specialist

# Quality Gate проверка тестов
.qwen/scripts/quality-gates/check-tests.sh
```

**Агенты тестирования:**
- `work_planning_test_assigner` — назначение тестов
- `work_testing_tdd_specialist` — TDD специалист
- `work_testing_unit_test_writer` — Unit тесты
- `work_testing_integration_test_writer` — Integration тесты
- `work_testing_e2e_test_writer` — E2E тесты
- `work_testing_security_tester` — Security тесты

### 🔹 ИИ-Агенты

**Оркестраторы:**
- `orc_dev_task_coordinator` — координация задач
- `orc_backend_api_coordinator` — backend разработка
- `orc_frontend_ui_coordinator` — frontend разработка
- `orc_planning_task_analyzer` — анализ задач планирования
- `orc_testing_quality_assurer` — обеспечение качества
- `orc_research_data_analyzer` — анализ данных
- `orc_security_security_orchestrator` — безопасность

**Воркеры:**
- `bug-fixer` — исправление ошибок
- `bug-hunter` — поиск ошибок
- `bug-orchestrator` — оркестрация исправления багов
- `code-quality-checker` — проверка качества
- `security-analyzer` — анализ безопасности
- `security-orchestrator` — оркестрация безопасности
- `dead-code-detector` — обнаружение мёртвого кода
- `dependency-analyzer` — анализ зависимостей
- `tech-translator-ru` — перевод на русский

**Специализированные агенты:**
- `speckit-constitution-agent` — создание конституции
- `speckit-specify-agent` — создание спецификаций
- `speckit-plan-agent` — создание плана
- `speckit-tasks-agent` — создание задач
- `work_dev_meta_agent` — создание агентов
- `qwen-code-cli-specialist` — эксперт по Qwen Code CLI

### 🔹 Speckit Workflow

Разработка на основе спецификаций:

```bash
# Создать спецификацию
speckit.specify

# Создать план
speckit.plan

# Создать задачи
speckit.tasks

# Реализовать
speckit.implement

# Проверить
speckit.validate
```

### 🔹 Quality Gates

5 контрольных точек качества:

| Gate | Название | Описание | Блокирующая |
|------|----------|----------|-------------|
| Gate 1 | Pre-Execution | Проверка корректности задачи | ❌ |
| Gate 2 | Post-Execution | Верификация результата | ❌ |
| Gate 3 | Pre-Commit | Валидация перед коммитом | ✅ |
| Gate 4 | Pre-Merge | Интеграционные проверки | ✅ |
| Gate 5 | Pre-Implementation | Проверка спецификаций | ✅ |

**Скрипты проверок:**
```bash
# Pre-Commit валидация
.qwen/scripts/quality-gates/pre-commit-validation.sh

# Проверка тестов
.qwen/scripts/quality-gates/check-tests.sh

# Проверка безопасности
.qwen/scripts/quality-gates/check-security.sh

# Проверка покрытия
.qwen/scripts/quality-gates/check-coverage.sh
```

### 🔹 MCP Интеграция

**Доступные серверы:**
- `context7` — документация API (актуальная, версионная)
- `filesystem` — файловая система
- `git` — Git операции
- `github` — GitHub API
- `chrome-devtools` — браузерная автоматизация
- `searxng` — веб-поиск (70+ движков, бесплатно)
- `playwright` — кросс-браузерная автоматизация
- `supabase` — базы данных

**Конфигурации:**
```bash
# Переключение MCP конфигураций
.qwen/scripts/orchestration-tools/switch-mcp.sh

# Доступные конфигурации:
# - BASE (context7, filesystem, git)
# - DATABASE (+ supabase)
# - FRONTEND (+ playwright, shadcn)
# - FULL (все серверы)
```

### 🔹 Git Workflow Automation

**Скрипты:**
- `create-feature-branch.sh` — создание feature-веток
- `pre-commit-review.sh` — ревью перед коммитом
- `auto-tag-release.sh` — автоматическое создание тегов
- `check-workflow.sh` — проверка соблюдения workflow

**Использование:**
```bash
# Создать feature-ветку
.qwen/scripts/git/create-feature-branch.sh "my-feature"

# Pre-commit ревью
.qwen/scripts/git/pre-commit-review.sh "feat: Add feature"

# Auto-tag релиза
.qwen/scripts/git/auto-tag-release.sh "v0.7.0" "Release"
```

---

## 📦 Установка

### Требования

| Компонент | Версия | Примечание |
|-----------|--------|------------|
| **Node.js** | 18+ | Для Qwen Code CLI |
| **npm** | 9+ | Менеджер пакетов |
| **Git** | 2.30+ | Система контроля версий |
| **Python** | 3.9+ | Для тестов и скриптов |
| **Qwen Code CLI** | последняя | ИИ-агент |

### Шаг 1: Установка Qwen Code CLI

```bash
# Через npm
npm install -g @qwen-code/cli

# Проверка
qwen --version
```

### Шаг 2: Клонирование проекта

```bash
git clone https://github.com/yourusername/qwen_orc_kit_ru.git
cd qwen_orc_kit_ru
```

### Шаг 3: Инициализация

```bash
# Инициализировать проект
.qwen/scripts/init/init-project.sh

# Проверка состояния
.qwen/scripts/orchestration-tools/analyze-project-state.sh
```

### Шаг 4: Pre-Flight проверки

```bash
# Проверка перед началом работы
.qwen/scripts/orchestration-tools/pre-flight-check.sh "Разработка"

# Проверки:
# ✅ Git репозиторий
# ✅ Ветка develop
# ✅ .gitignore
# ✅ Конституция
# ✅ Quality Gates
# ✅ Агенты
# ✅ Speckit команды
# ✅ Skills
# ✅ MCP конфигурация
# ✅ Скрипты
```

### Шаг 5: Настройка MCP (опционально)

```bash
# Переключение MCP конфигураций
.qwen/scripts/orchestration-tools/switch-mcp.sh

# Настройка переменных окружения
export GITHUB_TOKEN="your_token"  # Для GitHub MCP
```

---

## 📖 Использование

### Базовый workflow

```bash
# 1. Запустить Qwen Code
qwen

# 2. Ввести техническое задание
> Создай REST API для заметок

# 3. Оркестратор проанализирует состояние проекта
# 4. Создаст спецификацию (speckit.specify)
# 5. Создаст план (speckit.plan)
# 6. Создаст задачи (speckit.tasks)
# 7. Назначит агентов (Фаза 0)
# 8. Реализует задачи (speckit.implement)
```

### Работа с агентами

```bash
# Запустить конкретного агента через task команду
task '{
  "subagent_type": "bug-hunter",
  "prompt": "Найти уязвимости в коде"
}'

# Использовать skill
skill: template-feedback

# Проверить доступных агентов
ls -la .qwen/agents/
```

### Speckit Workflow

```bash
# 1. Создание конституции
speckit.constitution

# 2. Создание спецификаций
speckit.specify

# 3. Создание плана
speckit.plan

# 4. Создание задач
speckit.tasks

# 5. Фаза 0: Назначение агентов
# (автоматически после tasks)

# 6. Реализация
speckit.implement

# 7. Проверка
speckit.validate
```

### Quality Gates

```bash
# Pre-Commit валидация (Gate 3)
.qwen/scripts/quality-gates/pre-commit-validation.sh

# Проверка тестов
.qwen/scripts/quality-gates/check-tests.sh

# Проверка безопасности (Gate 4)
.qwen/scripts/quality-gates/check-security.sh

# Полная проверка Quality Gate
.qwen/scripts/quality-gates/run-quality-gate.sh
```

### Git Workflow

```bash
# Создать feature-ветку
.qwen/scripts/git/create-feature-branch.sh "my-feature"

# Pre-commit ревью
.qwen/scripts/git/pre-commit-review.sh "feat: Add feature"

# Quality Gate перед коммитом
.qwen/scripts/quality-gates/check-commit.sh

# Commit (после успешных проверок)
git add -A
git commit -m "feat: Add feature"

# Push
git push -u origin feature/my-feature

# Auto-tag релиза
.qwen/scripts/git/auto-tag-release.sh "v0.7.0" "Release"
```

### Система обратной связи

```bash
# Запустить сбор обратной связи
skill: template-feedback

# ИЛИ через скрипт
.qwen/scripts/bug-tracking/run-template-feedback.sh

# Проверить отчёты
ls -la .qwen/state/bugs/
cat .qwen/state/bugs/P2-*.md

# Проверить реестр
cat .qwen/state/template-feedback-registry.json | jq .

# Отправить в ШАБЛОН
.qwen/scripts/bug-tracking/send-template-feedback.sh .qwen/state/bugs/P2-*.md
```

---

## 🏗️ Структура проекта

```
qwen_orc_kit_ru/
├── .qwen/                          # Конфигурация Qwen Code
│   ├── agents/                     # ИИ-агенты
│   │   ├── orc_*.md               # Оркестраторы (7 файлов)
│   │   └── work_*.md              # Воркеры (15+ файлов)
│   ├── skills/                     # Навыки (Skills)
│   │   ├── template-feedback/     # Сбор обратной связи
│   │   ├── calculate-bug-priority/ # Расчёт приоритета
│   │   └── ...
│   ├── scripts/                    # Скрипты
│   │   ├── bug-tracking/          # Система обратной связи
│   │   │   ├── run-template-feedback.sh
│   │   │   ├── template-feedback-report.sh
│   │   │   ├── send-template-feedback.sh
│   │   │   ├── receive-template-feedback.sh
│   │   │   └── receive-template-confirmation.sh
│   │   ├── git/                   # Git автоматизация
│   │   │   ├── create-feature-branch.sh
│   │   │   ├── pre-commit-review.sh
│   │   │   ├── auto-tag-release.sh
│   │   │   └── check-workflow.sh
│   │   ├── quality-gates/         # Quality Gates
│   │   │   ├── pre-commit-validation.sh
│   │   │   ├── check-commit.sh
│   │   │   ├── check-tests.sh
│   │   │   ├── check-security.sh
│   │   │   └── check-coverage.sh
│   │   ├── orchestration-tools/   # Оркестрация
│   │   │   ├── pre-flight-check.sh
│   │   │   ├── analyze-project-state.sh
│   │   │   └── initialize-project.sh
│   │   └── template/              # Шаблоны
│   ├── templates/                  # Шаблоны для создания
│   ├── docs/                       # Документация
│   │   ├── architecture/          # Архитектурная документация
│   │   ├── help/                  # Помощь
│   │   └── ...
│   ├── config.sh                   # Конфигурация
│   ├── settings.json               # Настройки Qwen
│   └── mcp.*.json                  # MCP конфигурации
├── specs/                          # Спецификации
│   └── ###-module-name/
│       ├── spec.md                # Спецификация
│       ├── plan.md                # План
│       ├── tasks.md               # Задачи
│       ├── requirements.md        # Требования
│       └── checklists/            # Чек-листы
├── tests/                          # Тесты
│   ├── test_*.py                  # Python тесты
│   └── ...
├── .version                        # Версия проекта
├── CHANGELOG.md                    # История изменений
├── CONTRIBUTING.md                 # Руководство для участников
├── INSTALLATION.md                 # Подробная установка
├── QUICKSTART.md                   # Быстрый старт
├── QWEN.md                         # Парадигма оркестратора
└── README.md                       # Этот файл
```

---

## 🧪 Тестирование

### Запуск тестов

```bash
# Все тесты
pytest tests/ -v

# С покрытием
pytest tests/ -v --cov=src --cov-report=html

# TDD режим (тесты ПЕРЕД кодом)
skill: tdd-specialist

# Quality Gate проверка тестов
.qwen/scripts/quality-gates/check-tests.sh
```

### Система обратной связи

```bash
# Запустить сбор обратной связи
skill: template-feedback

# Проверить отчёты
cat .qwen/state/bugs/*.md

# Проверить реестр
cat .qwen/state/template-feedback-registry.json | jq .

# Статистика
jq '.bugs | length' .qwen/state/template-feedback-registry.json
```

### Health Workflow

```bash
# Проверка ошибок
/health-bugs

# Проверка безопасности
/health-security

# Проверка чистоты кода
/health-cleanup

# Проверка зависимостей
/health-deps
```

---

## 📚 Документация

### Основная документация

| Файл | Описание |
|------|----------|
| **[README.md](README.md)** | Основная документация |
| **[QWEN.md](QWEN.md)** | Парадигма оркестратора |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Руководство для участников |
| **[CHANGELOG.md](CHANGELOG.md)** | История изменений |
| **[QUICKSTART.md](QUICKSTART.md)** | Быстрый старт |
| **[INSTALLATION.md](INSTALLATION.md)** | Подробная установка |

### Архитектурная документация

- `.qwen/docs/architecture/agent-orchestration.md` — Оркестрация агентов
- `.qwen/docs/architecture/quality-gates.md` — Контрольные точки качества
- `.qwen/docs/architecture/tdd-architecture.md` — TDD архитектура
- `.qwen/docs/architecture/git-workflow.md` — Git workflow
- `.qwen/docs/architecture/mcp-configurations.md` — MCP конфигурации
- `.qwen/docs/architecture/specification-driven-development.md` — Разработка по спецификациям
- `.qwen/docs/architecture/security-guidelines.md` — Руководство по безопасности
- `.qwen/docs/architecture/dependency-management.md` — Управление зависимостями

### Помощь

- `.qwen/docs/help/tdd-guide.md` — TDD руководство
- `.qwen/docs/help/feedback-system.md` — Система обратной связи
- `.qwen/docs/help/git-workflow-guide.md` — Git workflow руководство

### Скрипты

- `.qwen/scripts/README.md` — Документация скриптов
- `.qwen/scripts/bug-tracking/README.md` — Система обратной связи
- `.qwen/scripts/quality-gates/README.md` — Quality Gates

---

## 🤝 Вклад в проект

### Как внести свой вклад

1. **Fork** репозиторий
2. **Создать feature-ветку** (`git checkout -b feature/amazing-feature`)
3. **Закоммитить изменения** (`git commit -m 'feat: Add amazing feature'`)
4. **Push** в ветку (`git push origin feature/amazing-feature`)
5. **Открыть Pull Request**

### Требования к коду

- ✅ Conventional Commits
- ✅ Quality Gates проверки
- ✅ Тесты для нового функционала
- ✅ Документация
- ✅ Pre-commit ревью

### Типы коммитов

| Тип | Описание | Пример |
|-----|----------|--------|
| `feat:` | Новый функционал | `feat: Add TDD support` |
| `fix:` | Исправление ошибок | `fix: Correct regex pattern` |
| `docs:` | Документация | `docs: Update README.md` |
| `style:` | Форматирование | `style: Fix indentation` |
| `refactor:` | Рефакторинг | `refactor: Extract method` |
| `test:` | Тесты | `test: Add unit tests` |
| `chore:` | Вспомогательные | `chore: Update dependencies` |

### Pre-Commit проверки

```bash
# Pre-Commit валидация
.qwen/scripts/quality-gates/pre-commit-validation.sh

# Quality Gate 3
.qwen/scripts/quality-gates/check-commit.sh

# Git Workflow проверка
.qwen/scripts/git/check-workflow.sh
```

---

## 📄 Лицензия

MIT License — см. файл [LICENSE](LICENSE) для деталей.

---

## 🔗 Ссылки

### Официальные ресурсы

- **GitHub:** [github.com/yourusername/qwen_orc_kit_ru](https://github.com/yourusername/qwen_orc_kit_ru)
- **Qwen Code:** [github.com/QwenLM/qwen-code](https://github.com/QwenLM/qwen-code)
- **Документация Qwen Code:** [qwenlm.github.io/qwen-code-docs](https://qwenlm.github.io/qwen-code-docs/)
- **NPM Package:** [npmjs.com/package/@qwen-code/cli](https://www.npmjs.com/package/@qwen-code/cli)

### Сообщество

- **Discord:** [Пригласительная ссылка]
- **Telegram:** [Пригласительная ссылка]
- **Issues:** [github.com/issues](https://github.com/yourusername/qwen_orc_kit_ru/issues)

---

## 📊 Статистика

| Метрика | Значение |
|---------|----------|
| **Версия** | 0.7.0 |
| **Агентов** | 22 |
| **Skills** | 12 |
| **Скриптов** | 50+ |
| **Тестов** | 100+ |
| **Документации** | 30+ файлов |
| **Коммитов** | 400+ |

---

## 🎉 Благодарности

- **Qwen Team** за Qwen Code CLI и Qwen3-Coder модели
- **Google** за Gemini CLI (основа Qwen Code)
- **Сообществу** за вклад, обратную связь и баг-репорты
- **Всем контрибьюторам** за улучшение проекта

---

## 📝 Changelog

См. [CHANGELOG.md](CHANGELOG.md) для полной истории изменений.

### [0.7.0] — 2026-03-28

**Система обратной связи + TDD**

- ✅ Feedback System — автоматический сбор ошибок ШАБЛОНА
- ✅ TDD Integration — 6 агентов тестирования
- ✅ Quality Gate 5 — TDD проверки
- ✅ Universal Template — БЕЗ HARDCODE
- ✅ MCP Chrome-DevTools — браузерная автоматизация

### [0.6.0] — 2026-03-21

**Git Workflow Automation + Mock APIs**

- ✅ Git Workflow Automation
- ✅ Pre-Commit Validation
- ✅ Mock External APIs
- ✅ Timeout Handling
- ✅ Agent Analytics

### [0.5.0] — 2026-03-15

**Pre-Flight Automation**

- ✅ Pre-Flight Checks
- ✅ Project Initialization
- ✅ Adaptive Orchestration

---

**Made with ❤️ by Qwen Code Orchestrator Kit**

*Последнее обновление: 28 марта 2026*
