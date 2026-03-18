# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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