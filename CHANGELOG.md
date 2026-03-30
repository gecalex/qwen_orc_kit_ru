# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.0] - 2026-03-30

### Bugfixes v0.8.0 Polish

#### Fixed
- **Оркестраторы пишут код** — Исправлена критическая проблема делегирования (Sprint 1-3)
  - Удалены write_file/edit из инструментов 8 оркестраторов
  - Добавлены явные запреты на написание кода
  - Создан механизм контроля делегирования
  - Интегрировано в Quality Gate 3
  - Все тесты пройдены (7/7)

- **Нумерация фаз** — Исправлена путаница с нумерацией
  - Изменена на сквозную 1-12
  - Обновлена документация (QWEN.md, README, CHANGELOG)
  - Устранены конфликты нумерации

- **Дубликат агента** — Удалён work_meta_agent_creator
  - work_dev_meta_agent оставлен (используется в QWEN.md)
  - work_meta_agent_creator удалён (дубликат)

- **Неиспользуемые скрипты** — Обработаны по отчёту Dead Code Detector
  - 5 скриптов удалено (дубликаты, пустые, заменённые)
  - 3 скрипта архивировано (миграционные)

#### Changed
- **Skills** — Исследованы 7 "неиспользуемых" навыков
  - Все оказались используемыми (34 упоминания найдено)
  - Решено не удалять

- **Документация** — Обновлена по итогам аудита
  - phases-numbering-audit.md — отчёт о нумерации фаз
  - orchestration-delegation-audit.md — отчёт о проблеме оркестрации

### Extensions System

#### Added
- **qwen-extension.json** — Манифест расширения для Qwen Code CLI
- **QWEN.md** — Парадигма оркестратора v2.0 (1801 строка)
- **CI/CD** — GitHub Actions workflow для автоматических релизов
- **Документация** — EXTENSIONS.md, MIGRATION.md

#### Changed
- **README.md** — Обновлён для Extensions System
- **CHANGELOG.md** — Добавлена запись v0.8.0

## [0.7.0] - 2026-03-28

### Priority 0 (Критическое) - 100% ✅

### Added
- **Система обратной связи (Template Feedback System)**
  - `orc_bug_auto_fixer.md` — оркестратор авто-исправления багов
  - `template-feedback/SKILL.md` — сбор обратной связи о ШАБЛОНЕ
  - `calculate-bug-priority/SKILL.md` — расчёт приоритета багов
  - `run-template-feedback.sh` — запуск сбора обратной связи
  - `template-feedback-report.sh` — создание отчёта об ошибках
  - `send-template-feedback.sh` — отправка в ШАБЛОН
  - `receive-template-feedback.sh` — приём в ШАБЛОНЕ
  - `.qwen/config.sh` — универсальная конфигурация (БЕЗ HARDCODE)
  - `deploy-to-test.sh` — автоматическое копирование в тестовый проект

- **TDD Система (Test-Driven Development)**
  - `work_planning_test_assigner.md` — назначение тестов
  - `work_testing_tdd_specialist.md` — TDD специалист
  - `work_testing_unit_test_writer.md` — unit тесты
  - `work_testing_integration_test_writer.md` — integration тесты
  - `work_testing_e2e_test_writer.md` — e2e тесты
  - `work_testing_security_tester.md` — security тесты
  - `check-tests.sh` — Quality Gate проверка тестов
  - `tdd-architecture.md` — архитектура TDD
  - `testing-workflow.md` — workflow тестирования
  - `tdd-guide.md` — руководство по TDD
  - TDD принцип в конституции
  - `coding-standards.md` — стандарты кода с TDD принципами

### Changed
- **README.md** — полная перепись с актуальной информацией v0.7.0
- **MCP Integration** — добавлен MCP Context7 во ВСЕ агенты
- **MCP Chrome-DevTools** — добавлен для frontend разработки

### Fixed
- **HARDCODE** — удалён весь хардкод PKB из шаблона (КРИТИЧЕСКОЕ)
- **Warnings** — исправлен рост warnings
- **Task Divergence** — универсальное решение расхождения задач
- **orc_planning_task_analyzer** — автоматический вызов Фазы 0.5
