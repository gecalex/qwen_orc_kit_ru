# 📋 Анализ: Файлы для шаблона нового проекта

**Дата:** 2026-03-18  
**Ветка:** `analysis/template-files-analysis`  
**Цель:** Определить список файлов и директорий, необходимых для создания нового проекта на основе Qwen Orchestrator Kit

---

## 🎯 КРИТЕРИИ ОТБОРА

### ✅ Должны входить в шаблон:
1. **Конфигурация оркестратора** — файлы, определяющие поведение ИИ-агентов
2. **Системные компоненты** — агенты, навыки, команды, шаблоны
3. **Документация для пользователя** — README, INSTALLATION, QUICKSTART
4. **Инфраструктура** — .gitignore, package.json, MCP конфигурации
5. **Скрипты автоматизации** — Quality Gates, health-workflow, orchestration

### ❌ Не должны входить в шаблон:
1. **История разработки** — отчеты, логи, черновики
2. **Спецификации проекта** — уникальны для каждого проекта
3. **Состояние (state)** — артефакты выполнения задач
4. **Временные файлы** — .tmp, .backup, .log
5. **Локальные конфигурации** — .env, settings.local.json

---

## 📁 СТРУКТУРА ШАБЛОНА

### **1. КОРНЕВЫЕ ФАЙЛЫ (Обязательно)**

| Файл | Размер | Назначение | Статус |
|------|--------|------------|--------|
| `QWEN.md` | 73 KB | ⭐ Конфигурация поведения оркестратора | ✅ Включить |
| `README.md` | 17 KB | Основная документация | ✅ Включить |
| `INSTALLATION.md` | 7 KB | Установка и настройка | ✅ Включить |
| `QUICKSTART.md` | 7 KB | Быстрый старт | ✅ Включить |
| `USAGE_INSTRUCTIONS.md` | 7 KB | Инструкции по использованию | ✅ Включить |
| `CONTRIBUTING.md` | 12 KB | Гайдлайн для контрибьюторов | ✅ Включить |
| `CHANGELOG.md` | 7 KB | История изменений (начать с [Unreleased]) | ✅ Включить |
| `GIT_WORKFLOW.md` | 18 KB | Рабочий процесс Git | ✅ Включить |
| `RELEASE_NOTES.md` | 4 KB | Заметки о релизе (опционально) | ⚠️ Опционально |
| `RELEASE_BUILD_INSTRUCTIONS.md` | 8 KB | Инструкции по сборке | ⚠️ Опционально |
| `package.json` | 2 KB | ⭐ Метаданные npm-пакета | ✅ Включить |
| `.gitignore` | 298 KB | ⭐ Игнорирование файлов | ✅ Включить |
| `.markdownlint.yml` | 500 B | Линтер markdown | ✅ Включить |

**Итого:** 12 обязательных файлов + 2 опциональных

---

### **2. ДИРЕКТОРИЯ `.qwen/` (Ядро системы)**

#### **2.1 Конфигурация**

| Файл | Назначение | Статус |
|------|------------|--------|
| `.qwen/settings.json` | ⭐ Основные настройки Qwen Code | ✅ Включить |
| `.qwen/mcp.json` | ⭐ Конфигурация MCP серверов | ✅ Включить |
| `.qwen/settings.local.json.example` | Пример локальных настроек | ✅ Включить |

#### **2.2 Агенты (`.qwen/agents/`)**

**Оркестраторы (7 файлов):**
- `orc_backend_api_coordinator.md` — координация API
- `orc_dev_task_coordinator.md` — координация разработки
- `orc_frontend_ui_coordinator.md` — координация UI/UX
- `orc_planning_task_analyzer.md` — анализ задач планирования
- `orc_research_data_analyzer.md` — анализ данных исследований
- `orc_security_security_orchestrator.md` — координация безопасности
- `orc_testing_quality_assurer.md` — обеспечение качества тестирования

**Воркеры (18 файлов):**
- `work_backend_api_validator.md` — валидация API
- `work_dev_code_analyzer.md` — анализ кода
- `work_dev_meta_agent.md` — создание новых агентов
- `work_dev_qwen_code_cli_specialist.md` — специалист по Qwen Code CLI
- `work_dev_test-agent.md` — тестирование
- `work_frontend_component_generator.md` — генерация компонентов
- `work_planning_agent_requirer.md` — определение типов агентов
- `work_planning_executor_assigner.md` — назначение исполнителей
- `work_planning_task_classifier.md` — классификация задач
- `work_research_trend_tracker.md` — отслеживание тенденций
- `work_testing_test_generator.md` — генерация тестов
- `work_health_bug_fixer.md` — исправление ошибок
- `work_health_bug_hunter.md` — поиск ошибок
- `work_health_dead_code_detector.md` — обнаружение мертвого кода
- `security-analyzer.md` — анализ безопасности
- `code-quality-checker.md` — проверка качества кода
- `dependency-analyzer.md` — анализ зависимостей
- `tech-translator-ru.md` — перевод документации

**Итого:** 25 агентов ✅ Включить все

#### **2.3 Навыки (`.qwen/skills/`)**

**31 навык по категориям:**

**Обработка данных:**
- `parse-error-logs/SKILL.md`
- `parse-git-status/SKILL.md`
- `format-markdown-table/SKILL.md`

**Валидация:**
- `run-quality-gate/SKILL.md`
- `validate-plan-file/SKILL.md`
- `validate-report-file/SKILL.md`
- `yaml-header-validator/SKILL.md`
- `specification-analyzer/SKILL.md`

**Форматирование:**
- `generate-report-header/SKILL.md`
- `extract-version/SKILL.md`
- `calculate-priority-score/SKILL.md`

**Анализ:**
- `task-analyzer/SKILL.md`
- `select-mcp-server/SKILL.md`
- `security-analyzer/SKILL.md`
- `dependency-auditor/SKILL.md`

**Безопасность:**
- `security-scanner/SKILL.md`
- `bug-hunter/SKILL.md`
- `bug-fixer/SKILL.md`

**Утилиты:**
- `generate-changelog/SKILL.md`
- `code-cleaner/SKILL.md`
- `code-refactorer/SKILL.md`
- `documentation-generator/SKILL.md`
- `webhook-sender/SKILL.md`
- `resume-session/SKILL.md`
- `save-session-context/SKILL.md`
- `skill-template/SKILL.md`

**Итого:** 31 навык ✅ Включить все

#### **2.4 Команды (`.qwen/commands/`)**

**22 команды:**

**Speckit (9 команд):**
- `speckit.specify.md`
- `speckit.clarify.md`
- `speckit.plan.md`
- `speckit.tasks.md`
- `speckit.implement.md`
- `speckit.constitution.md`
- `speckit.analyze.md`
- `speckit.checklist.md`
- `speckit.taskstoissues.md`

**Health-workflow (3 команды):**
- `health-security.md`
- `health-deps.md`
- `health-cleanup.md`

**Git worktree (3 команды):**
- `worktree-create.md`
- `worktree-list.md`
- `worktree-remove.md`

**Другие (7 команд):**
- `orchestrate-project.md`
- `run-quality-gate.md`
- `specification-validate.md`
- `configure-webhooks.md`
- `template.md`

**Итого:** 22 команды ✅ Включить все

#### **2.5 Шаблоны (`.qwen/templates/`)**

**5 шаблонов:**
- `orchestrator-template.md` — создание оркестраторов
- `worker-template.md` — создание воркеров
- `skill-template.md` — создание навыков
- `report-template.md` — стандартизация отчетов
- `README.ru.md` — документация на русском

**Итого:** 5 шаблонов ✅ Включить все

#### **2.6 Скрипты (`.qwen/scripts/`)**

**18 директорий скриптов:**

**Quality Gates (5 скриптов):**
- `check-security.sh`
- `check-coverage.sh`
- `check-bundle-size.sh`
- `check-typing.sh`
- `check-linting.sh`
- `check-changelog.sh` ⭐ НОВЫЙ

**Specification tools (2 скрипта):**
- `generate-tests-from-spec.sh`
- `assign-agents-to-tasks.sh`

**Release tools (2 скрипта):**
- `create-release-artifacts.sh`
- `initialize-project.sh`

**Orchestration tools (3 скрипта):**
- `analyze-project-state.sh`
- `switch-mcp.sh`
- `phase0-analyzer.sh`

**Monitoring (2 скрипта):**
- `update-project-index.sh`
- `check-standards-compliance.sh`

**Agent tools (2 скрипта):**
- `agent-search.sh`
- `validate-agent-names.sh`

**Health tools (4 скрипта):**
- `health-bugs.sh`
- `health-security.sh`
- `health-cleanup.sh`
- `health-deps.sh`

**Итого:** ~20 скриптов ✅ Включить все

#### **2.7 Конфигурации (`.qwen/config/`)**

**3 файла:**
- `monitoring-config.json`
- `release-config.toml`
- `qwen-code-cli-specialist-config.json`

**Итого:** 3 конфигурации ✅ Включить все

#### **2.8 Промпты (`.qwen/prompts/`)**

**2 файла:**
- `release_specification_prompt.txt`
- `specification_prompt.md`

**Итого:** 2 промпта ✅ Включить все

#### **2.9 Тесты (`.qwen/tests/`)**

**4 поддиректории:**
- `integration/`
- `agents/`
- `skills/`
- `commands/`

**Итого:** Система тестов ✅ Включить все

---

### **3. ДИРЕКТОРИЯ `docs/` (Внутри .qwen/)**

#### **3.1 Архитектура (`.qwen/docs/architecture/`)**

**22 файла документации:**
- `GIT_WORKFLOW.md`
- `adaptative-orchestration.md`
- `agent-creation-process.md`
- `agent-naming-convention.md`
- `agent-orchestration.md`
- `code-maintenance.md`
- `dependency-management.md`
- `mcp-configurations.md`
- `mcp-integration.md`
- `notification-system.md`
- `overview.md`
- `planning-phase.md`
- `quality-gates.md`
- `quality-standards.md`
- `report-format-standard.md`
- `security-guidelines.md`
- `skills-agents-integration.md`
- `skills-system.md`
- `specification-driven-development.md`
- `standards.md`
- `worktree-guidelines.md`
- `project-index.md`
- `agents-index.md`

**Итого:** 23 файла ✅ Включить все

#### **3.2 Справка (`.qwen/docs/help/`)**

**17 файлов по Qwen Orchestrator Kit**

**Итого:** 17 файлов ✅ Включить все

---

### **4. ИСКЛЮЧИТЬ ИЗ ШАБЛОНА**

#### **4.1 Директории для исключения:**

| Директория | Причина | Файлов |
|------------|---------|--------|
| `specs/` | Уникальные спецификации проекта | ~10 |
| `state/` | Артефакты выполнения задач | ~8 |
| `reports/` | Отчеты разработки | ~15 |
| `examples/` | Примеры использования | ~2 |
| `logs/` | Логи (игнорируются .gitignore) | ~7 |
| `backups/` | Резервные копии (игнорируются) | 0 |
| `FEATURE_DIR/` | Временная директория | 0 |
| `releases/` | Устаревшие релизные копии | 0 |

#### **4.2 Файлы для исключения:**

| Файл | Причина |
|------|---------|
| `QWEN.md.backup` | Резервная копия |
| `weather_app.log` | Лог файл |
| `release_preparation_report.md` | Отчет конкретного проекта |

---

## 📊 ФИНАЛЬНЫЙ СПИСОК ДЛЯ ШАБЛОНА

### **Структура шаблона:**

```
новый-проект/
├── .qwen/
│   ├── agents/              # 25 файлов
│   ├── commands/            # 22 файла
│   ├── config/              # 3 файла
│   ├── docs/
│   │   ├── architecture/    # 23 файла
│   │   └── help/            # 17 файлов
│   ├── plans/               # Пустая (для планов задач)
│   ├── prompts/             # 2 файла
│   ├── scripts/             # ~20 скриптов
│   ├── skills/              # 31 навык
│   ├── templates/           # 5 шаблонов
│   ├── tests/               # 4 поддиректории
│   ├── mcp.json
│   ├── settings.json
│   └── settings.local.json.example
├── .gitignore
├── .markdownlint.yml
├── CHANGELOG.md
├── CONTRIBUTING.md
├── GIT_WORKFLOW.md
├── INSTALLATION.md
├── package.json
├── QWEN.md
├── QUICKSTART.md
├── README.md
├── USAGE_INSTRUCTIONS.md
├── RELEASE_NOTES.md         # Опционально
└── RELEASE_BUILD_INSTRUCTIONS.md  # Опционально
```

### **Статистика:**

| Категория | Файлов | Размер (примерно) |
|-----------|--------|-------------------|
| **Корневые файлы** | 12 | ~150 KB |
| **Агенты** | 25 | ~500 KB |
| **Навыки** | 31 | ~400 KB |
| **Команды** | 22 | ~300 KB |
| **Шаблоны** | 5 | ~20 KB |
| **Скрипты** | ~20 | ~200 KB |
| **Конфигурации** | 6 | ~50 KB |
| **Документация** | 40 | ~600 KB |
| **Промпты** | 2 | ~30 KB |
| **Тесты** | ~10 | ~100 KB |
| **ИТОГО** | **~173** | **~2.3 MB** |

---

## 🎯 РЕКОМЕНДАЦИИ

### **Минимальный шаблон (быстрый старт):**
1. `QWEN.md` — конфигурация оркестратора
2. `.qwen/settings.json` — настройки
3. `.qwen/mcp.json` — MCP серверы
4. `.qwen/agents/` — базовые агенты (5-7 файлов)
5. `.qwen/skills/` — базовые навыки (10 файлов)
6. `README.md` — документация
7. `.gitignore` — игнорирование

**Итого:** ~20 файлов, ~500 KB

### **Полный шаблон (production-ready):**
Все 173 файла из списка выше

---

## 📝 СЛЕДУЮЩИЕ ШАГИ

1. ✅ Создать скрипт для копирования шаблона
2. ✅ Создать документацию по использованию шаблона
3. ✅ Протестировать на новом проекте
4. ✅ Обновить package.json для npm-публикации

---

**Отчет готов к использованию!**
