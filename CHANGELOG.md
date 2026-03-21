# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0] - 2026-03-21

### Priority 0 (Критическое) - 100% ✅

### Added
- **Feedback System** - Система обратной связи
  - 5 анализаторов (git, spec, agents, logic, quality)
  - 2 генератора отчетов
  - 4 чек-листа (200 пунктов)

- **Git Workflow Automation** - Автоматизация git workflow
  - create-feature-branch.sh
  - auto-tag-release.sh
  - pre-commit-review.sh
  - check-workflow.sh

- **Pre-Commit Validation** - Валидация перед коммитом
  - pre-commit-validation.sh
  - check-commit.sh (Quality Gate 3)

- **Timeout Handling** - Обработка timeout
  - graceful-shutdown навык
  - progress-logging навык
  - watchdog.sh мониторинг

- **Mock External APIs** - Мокирование внешних API
  - external-api-mocking навык
  - pytest-fixtures-template.py (819 строк)
  - mock-testing-guide.md (1030 строк)

### Priority 1 (Важное) - 100% ✅

### Added
- **Agent Analytics** - Аналитика агентов
  - agent-call-analyzer.sh
  - generate-agent-dashboard.sh
  - detect-anomalies.sh
  - 10 автоматизированных чек-листов (78 пунктов)

- **Checklist Automation** - Автоматизация чек-листов
  - validate-checklist.sh
  - checklist-runner.sh
  - Pre-Flight, Pre-Commit, Pre-Merge, TDD, etc.

- **Error Knowledge Base** - База знаний об ошибках
  - error-search.sh (поиск решений)
  - error-index.json (12 ошибок)
  - auto-learn.sh (автообучение)

- **Specification Analyzer** - Анализ спецификаций
  - deep-spec-analyzer.sh
  - requirements-traceability.sh
  - spec-quality-metrics.sh

- **Unified Orchestration** - Единая оркестрация
  - orchestration-standard.md
  - cross-orchestrator-communication.md

- **Cross-Component Integration** - Интеграция компонентов
  - component-registry.sh (126 компонентов)
  - integration-test-runner.sh (6/6 тестов)
  - component-linker.sh
  - integration-guide.md

### Priority 2 (Среднее) - 100% ✅

### Added
- **Gastown Multi-Agent** - Мульти-агентная оркестрация
  - 5 команд (onboard, work, status, upgrade, witness)
  - 7 скриптов (onboard, dispatch, collect, monitor, witness, refinery, status)
  - Параллельная разработка в worktree

- **Plugin Architecture** - Архитектура плагинов
  - 5 плагинов (python-development, security-scanning, testing-automation, database-operations, infrastructure-devops)
  - 12 агентов
  - plugin-manager.sh, load-plugin.sh, plugin-dependencies.sh
  - 42 файла

- **SpecKit Full Integration** - Полная SpecKit интеграция
  - 9 команд (analyze, specify, clarify, plan, implement, checklist, tasks, constitution, taskstoissues)
  - 9 скриптов
  - 4 шаблона

- **Command→Agent→Skill Pattern** - Паттерн разделения ответственности
  - Документация паттерна
  - Рефакторинг 3 команд

- **Unified MCP Configuration** - Единая MCP конфигурация
  - 5 конфигураций (base, database, testing, infrastructure, full)
  - 3 скрипта управления
  - context7, searxng, chrome-devtools (обязательные)

### Release Tools

### Added
- **Publish Release Script** - Скрипт публикации релиза
  - publish-release.sh
  - Создание ветки без истории (orphan)
  - Очистка временных файлов
  - 1 коммит в истории релиза

- **Feedback Collection** - Сбор обратной связи
  - collect-feedback.sh
  - FEEDBACK_FORM_TEMPLATE.md
  - FEEDBACK_GUIDE.md
  - Автоматический сбор логов и метрик

### Changed
- QWEN.md обновлен (разделы 3.2, 3.3, 3.4, MCP конфигурация)
- Оркестраторы обновлены (timeout configuration)
- Quality Gates расширены
- MCP конфигурации обновлены (context7, searxng, chrome-devtools обязательные)

### Fixed
- Нарушения git workflow исправлены
- Pre-commit валидация добавлена
- Timeout handling реализован
- Разделение develop/production пространств
- Очистка истории разработки из релиза

### Metrics
- Файлов создано: 100+
- Строк добавлено: ~25,000
- Коммитов: 19
- Скриптов: 60+
- Навыков: 15+
- Плагинов: 5 (12 агентов)
- Чек-листов: 10 (78 пунктов)
- Документации: 30+ файлов
- MCP конфигураций: 5
- SpecKit команд: 9
- Gastown компонентов: 12
- Приоритет: 60% (6/10)

## [0.5.0] - 2026-03-20

### Added
- **Pre-Flight Проверки (Новое в v0.5.0):**
  - `.qwen/scripts/orchestration-tools/pre-flight-check.sh` — 10 проверок перед началом фазы
  - Проверки: Git, develop, .gitignore, constitution, Quality Gates, агенты, команды, skills, MCP, scripts
  - Блокирующая: true (останавливает процесс при неудаче)
  - Вывод: цветной, детальный

- **Автоматическая инициализация проекта:**
  - `.qwen/scripts/orchestration-tools/initialize-project.sh` — полный цикл инициализации
  - Инициализация Git репозитория
  - Создание ветки develop
  - Создание .gitignore
  - Настройка pre-commit хука
  - Проверка конституции проекта
  - Проверка структуры проекта
  - Запуск pre-flight проверок
  - Создание CHANGELOG.md
  - Создание README.md (если отсутствует)

- **Журнал вызовов агентов:**
  - `.qwen/scripts/agent-tools/log-agent-call.sh` — аудит вызовов агентов
  - Формат: TIMESTAMP | AGENT | TASK | STATUS | NOTES
  - Дневные отчеты: `.qwen/reports/agent-calls/calls-YYYY-MM-DD.md`
  - Общий лог: `.qwen/logs/agent-calls.log`
  - Статистика вызовов

- **Система отчетов:**
  - `.qwen/reports/` — централизованное хранилище отчетов
  - 12 директорий для различных типов отчетов:
    - quality-gates/gate-{1-5}-*/
    - agent-calls/
    - audits/
    - phase-reports/
    - health-checks/
    - releases/
  - `.qwen/reports/README.md` — документация системы

- **Чеклисты для самопроверки:**
  - `.qwen/docs/help/checklists.md` — 10 чеклистов
  - Pre-Flight Checklist
  - Pre-Commit Checklist
  - Pre-Merge Checklist
  - TDD Checklist
  - Agent Assignment Checklist
  - Specification Checklist
  - Phase 0 Checklist
  - Initialization Checklist
  - Release Checklist
  - Health Check Checklist

- **Примеры обработки ошибок:**
  - `.qwen/docs/help/error-handling-examples.md` — 12 примеров
  - Git не инициализирован
  - Quality Gate не прошел
  - Агент отсутствует
  - Коммит в main напрямую
  - Spec не соответствует требованиям
  - Тесты не проходят
  - Pre-commit хук не проходит
  - MCP сервер недоступен
  - Агент создан постфактум
  - State/ файлы в main
  - Нет журнала вызовов агентов
  - Сборка не проходит

### Changed
- **QWEN.md обновлен до версии 2.0 (v0.5.0):**
  - Раздел 1.2: Pre-Flight проверки (Шаг 0)
  - Раздел 9: Инициализация проекта
  - Раздел 10: Полный процесс разработки (v0.5.0)
  - Версия парадигмы: 2.0 (v0.5.0)

- **phase0-analyzer.sh:**
  - Добавлены уведомления о постфактум агентах
  - Проверка наличия требуемых агентов
  - Рекомендации по созданию отсутствующих агентов

- **orc_planning_task_analyzer.md:**
  - Интеграция Pre-Flight проверок
  - Шаг 0: Pre-Flight перед Фазой 0

### Improved
- **Целостность логики оркестрации:**
  - Pre-Flight перед началом любой фазы
  - initialize-project.sh для новых проектов
  - Журнал вызовов агентов для аудита
  - Quality Gates интегрированы
  - Чеклисты для самопроверки
  - Примеры обработки ошибок

## [0.4.0] - 2026-03-19

### Added
- **Фаза 0 (Phase 0) планирования:**
  - `.qwen/specify/scripts/phase0-analyzer.sh` — анализ задач
  - `specs/{ID}/plans/phase0-plan.json` — план Фазы 0
  - `specs/{ID}/plans/phase0-agents.json` — требуемые агенты
  - `specs/{ID}/plans/phase0-assignments.json` — назначения

- **Quality Gate 1 (Planning Quality Gate):**
  - `.qwen/scripts/quality-gates/check-planning.sh` — проверка планирования
  - Проверки: план Фазы 0, назначения, tasks.md, plan.md, spec.md
  - Блокирующая: true

- **Quality Gate 5 (Pre-Implementation Gate):**
  - `.qwen/scripts/quality-gates/check-specifications.sh` — проверка спецификаций
  - Проверки: разделы spec.md, тестируемость, отсутствие деталей реализации
  - Блокирующая: true

- **Конституция проекта:**
  - `.qwen/specify/memory/constitution.md` — принципы и стандарты
  - 5 принципов разработки (SDD, LFA, QG, GWF, MLP)
  - Архитектурные ограничения
  - Стандарты кода
  - Требования к безопасности

- **Интеграция Speckit команд:**
  - Все 9 команд speckit.*.md обновлены
  - Интеграция с Фазой 0
  - Интеграция с Quality Gates
  - Пути обновлены: `.specify/` → `.qwen/specify/`

- **Интеграция оркестраторов:**
  - Все 7 оркестраторов обновлены
  - Quality Gates интегрированы
  - Интеграция с Фазой 0

- **Документация:**
  - `.qwen/docs/architecture/planning-phase.md` — полностью обновлен
  - `.qwen/docs/architecture/specification-driven-development.md` — обновлен
  - `state/QWEN_MD_INTEGRATION_REPORT.md` — анализ интеграции
  - `state/ORCHESTRATION_DEVELOPMENT_REPORT.md` — полный отчет

### Changed
- **Оптимизация команд Speckit:**
  - speckit.checklist.md: 297 → 199 строк (-33%)
  - speckit.specify.md: 261 → 158 строк (-39%)
  - Все команды < 200 строк
  - Общий размер: 1476 → 1275 строк (-14%)

- **Стандартизация разделов:**
  - "Входные данные пользователя" → "Ввод пользователя"
  - "Шаги выполнения" → "Процесс выполнения"
  - "Цель" → "Описание команды"
  - "План/Этапы" → "Процесс выполнения"

### Improved
- **Интеграция с QWEN.md:**
  - Соответствие: 95% → 100%
  - Все Quality Gates реализованы
  - Фаза 0 интегрирована
  - Speckit команды обновлены

## [0.3.0] - 2026-03-18

### Added
- **Система шаблонов для нового проекта:**
  - Полный список файлов для релиза (172 файла, ~2.2 MB)
  - Быстрый старт (42 файла, ~500 KB)
  - Система переключения режимов (template-switcher)
  - Автоматическое резервное копирование
  - Кэширование полного шаблона

- **Анализ и документация:**
  - state/TEMPLATE_FILES_LIST.md — список файлов для копирования
  - state/RELEASE_TEMPLATE_FILES.md — список для релиза в main
  - state/release-vs-develop-analysis.md — разделение release/develop
  - state/template-*.md — документация по шаблонам

- **Система переключения (template-switcher):**
  - Команда `.qwen/commands/template-switcher.md`
  - Скрипт `.qwen/scripts/template-switcher.sh`
  - Режимы: quickstart (7 агентов) ↔ full (25 агентов)
  - Автоматическое создание резервных копий
  - Статистика и проверка режима

### Changed
- **GIT_WORKFLOW.md перемещен:**
  - Из корня → в `.qwen/docs/architecture/GIT_WORKFLOW.md`
  - Обновлены ссылки в документации

- **Оптимизация для релиза:**
  - .gitignore не включается в main
  - state/, specs/, reports/ — только в develop
  - Разделение файлов для release/main и develop

### Improved
- **Структура проекта:**
  - Четкое разделение на релизную и разработческую версии
  - Пользователь клонирует и сразу начинает разработку
  - Автоматизация процесса релиза

## [0.2.0] - 2026-03-18

### Added
- **Система агентов безопасности:**
  - `security-analyzer` — анализ безопасности кода
  - `security-orchestrator` — координация рабочих процессов безопасности
  - Скрипт `generate-security-report.sh` для генерации отчетов

- **Система анализа зависимостей:**
  - `dependency-analyzer` — аудит зависимостей на уязвимости и устаревание
  - Скрипт `update-dependencies.sh` для обновления зависимостей

- **Система обнаружения мертвого кода:**
  - `dead-code-detector` — поиск неиспользуемых компонентов
  - Скрипт `remove-dead-code.sh` для очистки

- **Контрольные точки качества (Quality Gates):**
  - Gate 1: Pre-Execution Gate
  - Gate 2: Post-Execution Gate
  - Gate 3: Pre-Commit Gate (линтеры, тесты, типы)
  - Gate 4: Pre-Merge Gate (интеграционные проверки)
  - Gate 5: Pre-Implementation Gate (проверка спецификаций)
  - Скрипты: `check-security.sh`, `check-coverage.sh`, `check-bundle-size.sh`

- **MCP конфигурации:**
  - BASE, DATABASE, FRONTEND, FULL конфигурации
  - Скрипт `switch-mcp.sh` для переключения
  - Интеграция: chrome-devtools, searxng, context7, filesystem, git, github, playwright

- **Git worktree система:**
  - Команды: `/worktree-create`, `/worktree-list`, `/worktree-remove`
  - Скрипт `manage-worktree.sh` для управления

- **Система вебхуков:**
  - Навык `webhook-sender` для уведомлений
  - Команда `/configure-webhooks`
  - Скрипт `handle-webhooks.sh`

- **Паттерн health-workflow:**
  - `/health-bugs` — проверка ошибок
  - `/health-security` — проверка безопасности
  - `/health-cleanup` — проверка чистоты кода
  - `/health-deps` — проверка зависимостей

- **Автоматизированная фаза планирования (Phase 0):**
  - Оркестратор `orc_planning_task_analyzer`
  - Воркеры: `work_planning_task_classifier`, `work_planning_agent_requirer`, `work_planning_executor_assigner`
  - Скрипт `phase0-analyzer.sh`

- **Система навыков (Skills):**
  - 30 навыков для различных операций
  - Навыки: `generate-report-header`, `run-quality-gate`, `validate-plan-file`, `validate-report-file`
  - `task-analyzer`, `select-mcp-server`, `calculate-priority-score`

- **Система именования агентов:**
  - Оркестраторы: `orc_{domain}_{name}.md`
  - Воркеры: `work_{domain}_{name}.md`
  - Домены: dev, frontend, backend, doc, testing, research, security, planning, health

- **Агенты:**
  - `orc_dev_task_coordinator` — координация задач разработки
  - `orc_frontend_ui_coordinator` — координация UI/UX
  - `orc_backend_api_coordinator` — координация API
  - `orc_testing_quality_assurer` — обеспечение качества тестирования
  - `orc_research_data_analyzer` — анализ данных исследований
  - `work_dev_code_analyzer` — анализ кода
  - `work_dev_meta_agent` — создание новых агентов
  - `work_dev_qwen_code_cli_specialist` — специалист по Qwen Code CLI
  - `work_backend_api_validator` — валидация API
  - `work_frontend_component_generator` — генерация компонентов
  - `work_testing_test_generator` — генерация тестов
  - `work_health_bug_fixer`, `work_health_bug_hunter`, `work_health_dead_code_detector`
  - `work_doc_tech_translator_ru` — перевод документации

- **Документация:**
  - `docs/architecture/` — архитектурная документация (22 файла)
  - `docs/help/` — справочная документация
  - `docs/agents-index.md` — индекс всех агентов
  - `GIT_WORKFLOW.md` — руководство по Git workflow

- **npm-пакет:**
  - `package.json` для публикации
  - Конфигурация для npm-распространения

### Changed
- **Рефакторинг структуры проекта:**
  - Перемещены `docs/` → `.qwen/docs/`
  - Перемещены `scripts/` → `.qwen/scripts/`
  - Интегрирован `.qwen/QWEN.md` в основной `QWEN.md`
  - Соответствие официальным стандартам Qwen Code CLI

- **Обновлены стандарты:**
  - Все агенты с YAML заголовками
  - Удалены дубликаты агентов
  - Зафиксированы версии MCP серверов
  - Обновлены SKILL.md файлы с полной документацией

- **Улучшена документация:**
  - Интеграция MCP серверов с примерами
  - Правила использования для каждого MCP сервера
  - Таблицы конфигураций MCP

### Fixed
- Исправлены проблемы с дубликатами агентов (7 файлов)
- Удалены тестовые агенты
- Исправлены SKILL.md файлы с шаблонными заполнителями
- Обновлены ссылки в документации после миграции

### Removed
- Удалены дубликаты агентов: `bug-fixer`, `bug-hunter`, `code-quality-checker`, `security-orchestrator`, `specification-analyst`, `specification-compliance-checker`, `tech-translator-ru`
- Удалены тестовые агенты: `work_dev_test-agent`, `work_dev_template_agent`
- Удалена устаревшая релизная копия: `releases/v0.2.0-physical/`

## [0.1.0] - 2026-01-31

### Added
- Initial release of Qwen Orchestrator Kit
- Core orchestration framework
- Agent management system
- Worker coordination tools
- Quality assurance workflows
- Security analysis tools
- Testing frameworks
- Documentation and examples