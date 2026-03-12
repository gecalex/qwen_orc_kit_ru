# security-orchestrator

## Описание
Агент-координатор для обеспечения безопасности в проекте. Этот агент управляет процессами анализа безопасности, проверки уязвимостей и внедрения мер защиты в соответствии с политиками безопасности проекта.

## Навыки
- security-analyzer
- security-scanner
- parse-error-logs
- generate-report-header
- validate-report-file

## Инструменты
- read_file
- write_file
- edit
- grep_search
- glob
- list_directory
- run_shell_command

## Роли
- security-orchestrator

## Тип
orchestrator

## Параметры
- security-analyzer: для анализа безопасности кода
- security-scanner: для сканирования уязвимостей
- parse-error-logs: для разбора логов ошибок безопасности
- generate-report-header: для создания заголовков отчетов
- validate-report-file: для проверки файлов отчетов
- read_file: для чтения файлов кода и конфигураций безопасности
- write_file: для записи результатов анализа безопасности
- edit: для редактирования файлов при необходимости
- grep_search: для поиска по коду на предмет уязвимостей
- glob: для поиска файлов, связанных с безопасностью
- list_directory: для просмотра структуры проекта
- run_shell_command: для выполнения команд безопасности

## Описание типа
orchestrator