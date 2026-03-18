# Категории агентов Qwen Orchestrator Kit

> **Назначение**: Этот файл группирует агентов по функциональности для улучшения навигации.
> **Обновлено**: 31 января 2026 г.

## Структура

- [Агенты разработки](#агенты-разработки)
- [Агенты тестирования](#агенты-тестирования)
- [Агенты безопасности](#агенты-безопасности)
- [Агенты исследований](#агенты-исследований)
- [Агенты мониторинга и качества](#агенты-мониторинга-и-качества)
- [Агенты планирования](#агенты-планирования)

## Агенты разработки

Агенты, занимающиеся основной разработкой, созданием кода и архитектурными задачами.

- [work_dev_meta_agent](../../.qwen/agents/work_dev_meta_agent.md) - Мета-агент для автоматического создания новых агентов
- [orc_dev_task_coordinator](../../.qwen/agents/orc_dev_task_coordinator.md) - Координатор задач разработки
- [work_dev_code_analyzer](../../.qwen/agents/work_dev_code_analyzer.md) - Анализатор кода

## Агенты тестирования

Агенты, отвечающие за тестирование, проверку качества и валидацию.

- [orc_testing_quality_assurer](../../.qwen/agents/orc_testing_quality_assurer.md) - Оркестратор обеспечения качества
- [work_testing_test_generator](../../.qwen/agents/work_testing_test_generator.md) - Генератор тестов
- [work_testing_code_quality_checker](../../.qwen/agents/work_testing_code_quality_checker.md) - Проверка качества кода

## Агенты безопасности

Агенты, занимающиеся безопасностью, анализом уязвимостей и защитой системы.

- [orc_security_security_orchestrator](../../.qwen/agents/orc_security_security_orchestrator.md) - Оркестратор безопасности
- [work_security_security_analyzer](../../.qwen/agents/work_security_security_analyzer.md) - Анализатор безопасности
- [work_health_bug_hunter](../../.qwen/agents/work_health_bug_hunter.md) - Охотник за багами

## Агенты исследований

Агенты, занимающиеся анализом, исследованием и изучением новых возможностей.

- [orc_research_data_analyzer](../../.qwen/agents/orc_research_data_analyzer.md) - Оркестратор анализа данных
- [work_research_trend_tracker](../../.qwen/agents/work_research_trend_tracker.md) - Отслеживатель тенденций

## Агенты мониторинга и качества

Агенты, отвечающие за мониторинг состояния системы и контроль качества.

- [work_planning_task_classifier](../../.qwen/agents/work_planning_task_classifier.md) - Классификатор задач планирования
- [work_planning_agent_requirer](../../.qwen/agents/work_planning_agent_requirer.md) - Определитель типов агентов
- [work_planning_executor_assigner](../../.qwen/agents/work_planning_executor_assigner.md) - Назначитель исполнителей

## Агенты планирования

Агенты, участвующие в фазе планирования и анализе задач.

- [orc_planning_task_analyzer](../../.qwen/agents/orc_planning_task_analyzer.md) - Оркестратор анализа задач планирования
- [work_dev_qwen_code_cli_specialist](../../.qwen/agents/work_dev_qwen_code_cli_specialist.md) - Специалист по Qwen Code CLI

## Домены агентов

### dev (Разработка)
Агенты, занимающиеся общей разработкой, созданием инструментов и архитектурными задачами.

### frontend (Фронтенд)
Агенты, специализирующиеся на задачах фронтенд-разработки.

### backend (Бэкенд)
Агенты, специализирующиеся на задачах бэкенд-разработки.

### testing (Тестирование)
Агенты, отвечающие за тестирование и проверку качества.

### research (Исследования)
Агенты, занимающиеся анализом и исследованием новых возможностей.

### security (Безопасность)
Агенты, специализирующиеся на задачах безопасности и анализе уязвимостей.

### planning (Планирование)
Агенты, участвующие в фазе планирования и анализе задач.

## Стандарты именования

- **Оркестраторы**: `orc_{домен}_{имя}` (например, `orc_dev_task_coordinator`)
- **Воркеры**: `work_{домен}_{имя}` (например, `work_dev_code_analyzer`)

## Критерии категоризации

Агенты категоризируются по:
1. Основной функциональности
2. Домену применения
3. Типу решаемых задач
4. Используемым технологиям