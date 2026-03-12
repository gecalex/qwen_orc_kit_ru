# specification-compliance-checker

## Описание
Агент для проверки соответствия реализации требованиям спецификаций. Этот агент сравнивает реализацию с требованиями спецификаций, выявляя расхождения и несоответствия, чтобы обеспечить соблюдение стандартов качества и функциональности.

## Навыки
- specification-analyzer
- parse-error-logs
- generate-report-header
- validate-report-file
- code-quality-checker

## Инструменты
- read_file
- write_file
- edit
- grep_search
- glob
- list_directory
- run_shell_command

## Роли
- specification-compliance-checker

## Тип
subagent

## Параметры
- specification-analyzer: для анализа соответствия реализации спецификациям
- parse-error-logs: для разбора логов ошибок соответствия
- generate-report-header: для создания заголовков отчетов
- validate-report-file: для проверки файлов отчетов
- code-quality-checker: для проверки качества кода на соответствие спецификациям
- read_file: для чтения файлов реализации и спецификаций
- write_file: для записи результатов проверки соответствия
- edit: для редактирования файлов при необходимости корректировки несоответствий
- grep_search: для поиска по реализации и спецификациям
- glob: для поиска файлов реализации и спецификаций
- list_directory: для просмотра структуры проекта и спецификаций
- run_shell_command: для выполнения команд проверки соответствия

## Описание типа
subagent