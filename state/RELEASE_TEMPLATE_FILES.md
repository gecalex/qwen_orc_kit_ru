# 📋 Список файлов для релиза в main

**Версия:** 1.0.0  
**Дата:** 2026-03-18  
**Цель:** Пользователь клонирует repo в корень проекта и сразу начинает разработку

---

## 🎯 СТРУКТУРА РЕЛИЗА (main ветка)

```
новый-проект/
├── .qwen/                          # Вся конфигурация Qwen Code
│   ├── agents/                     # 25 агентов
│   ├── commands/                   # 22 команды
│   ├── config/                     # 3 конфигурации
│   ├── docs/
│   │   └── architecture/
│   │       └── GIT_WORKFLOW.md     # ✅ Здесь!
│   ├── plans/                      # Пустая (для планов)
│   ├── prompts/                    # 2 промпта
│   ├── scripts/                    # ~20 скриптов
│   ├── skills/                     # 31 навык
│   ├── templates/                  # 5 шаблонов
│   ├── tests/                      # 4 поддиректории
│   ├── mcp.json                    # MCP конфигурация
│   ├── settings.json               # Настройки Qwen Code
│   └── settings.local.json.example # Пример локальных настроек
├── .markdownlint.yml               # Линтер markdown
├── CHANGELOG.md                    # История изменений
├── CONTRIBUTING.md                 # Гайдлайн контрибьютора
├── INSTALLATION.md                 # Установка
├── package.json                    # npm-пакет
├── QWEN.md                         # ⭐ Конфигурация оркестратора
├── QUICKSTART.md                   # Быстрый старт
├── README.md                       # Основная документация
└── USAGE_INSTRUCTIONS.md           # Инструкции
```

**ИТОГО:** 172 файла (~2.2 MB)

---

## ❌ ИСКЛЮЧИТЬ ИЗ РЕЛИЗА (main)

**Не попадают в main:**

| Файл/Директория | Причина | Где хранить |
|-----------------|---------|-------------|
| `.gitignore` | Создается при инициализации проекта | Отдельно в repo |
| `state/` | Артефакты разработки | Только в dev |
| `specs/` | Спецификации проекта | Только в dev |
| `reports/` | Отчеты разработки | Только в dev |
| `examples/` | Примеры | Только в dev |
| `logs/` | Логи | Игнорируются |
| `.tmp/` | Временные файлы | Игнорируются |
| `*.log` | Логи | Игнорируются |
| `*.backup` | Резервные копии | Игнорируются |
| `release_preparation_report.md` | Отчет разработки | Только в dev |
| `RELEASE_BUILD_INSTRUCTIONS.md` | Для команды разработки | Только в dev |
| `RELEASE_NOTES.md` | Для команды разработки | Только в dev |

---

## ✅ ПОЛНЫЙ СПИСОК ФАЙЛОВ ДЛЯ MAIN

### **1. Корневые файлы (9)**

```
.markdownlint.yml
CHANGELOG.md
CONTRIBUTING.md
INSTALLATION.md
package.json
QWEN.md
QUICKSTART.md
README.md
USAGE_INSTRUCTIONS.md
```

### **2. .qwen/agents/ (25)**

**Оркестраторы (7):**
```
orc_backend_api_coordinator.md
orc_dev_task_coordinator.md
orc_frontend_ui_coordinator.md
orc_planning_task_analyzer.md
orc_research_data_analyzer.md
orc_security_security_orchestrator.md
orc_testing_quality_assurer.md
```

**Воркеры (18):**
```
work_backend_api_validator.md
work_dev_code_analyzer.md
work_dev_dependency_analyzer.md
work_dev_meta_agent.md
work_dev_qwen_code_cli_specialist.md
work_doc_tech_translator_ru.md
work_frontend_component_generator.md
work_health_bug_fixer.md
work_health_bug_hunter.md
work_health_dead_code_detector.md
work_meta_agent_creator.md
work_planning_agent_requirer.md
work_planning_executor_assigner.md
work_planning_task_classifier.md
work_research_trend_tracker.md
work_security_security_analyzer.md
work_testing_code_quality_checker.md
work_testing_test_generator.md
```

### **3. .qwen/skills/ (31)**

```
bug-fixer/SKILL.md
bug-hunter/SKILL.md
calculate-priority-score/SKILL.md
code-cleaner/SKILL.md
code-refactorer/SKILL.md
dependency-auditor/SKILL.md
documentation-generator/SKILL.md
extract-version/SKILL.md
format-markdown-table/SKILL.md
generate-changelog/SKILL.md
generate-report-header/SKILL.md
parse-error-logs/SKILL.md
parse-git-status/SKILL.md
resume-session/SKILL.md
run-quality-gate/SKILL.md
save-session-context/SKILL.md
security-analyzer/SKILL.md
security-scanner/SKILL.md
select-mcp-server/SKILL.md
skill-template/SKILL.md
specification-analyzer/SKILL.md
task-analyzer/SKILL.md
validate-plan-file/SKILL.md
validate-report-file/SKILL.md
webhook-sender/SKILL.md
yaml-header-validator/SKILL.md
agent-structure-checker/SKILL.md
check-agent-name-uniqueness/SKILL.md
code-quality-checker/SKILL.md
tech-translator-ru/SKILL.md
template-agent/SKILL.md
```

### **4. .qwen/commands/ (22)**

```
configure-webhooks.md
health-cleanup.md
health-deps.md
health-security.md
orchestrate-project.md
run-quality-gate.md
speckit.analyze.md
speckit.checklist.md
speckit.clarify.md
speckit.constitution.md
speckit.implement.md
speckit.plan.md
speckit.specify.md
speckit.taskstoissues.md
speckit.tasks.md
specification-validate.md
template.md
worktree-create.md
worktree-list.md
worktree-remove.md
```

### **5. .qwen/scripts/ (~20)**

```
quality-gates/check-bundle-size.sh
quality-gates/check-changelog.sh
quality-gates/check-coverage.sh
quality-gates/check-linting.sh
quality-gates/check-security.sh
quality-gates/check-typing.sh
orchestration-tools/analyze-project-state.sh
orchestration-tools/phase0-analyzer.sh
orchestration-tools/switch-mcp.sh
health-tools/health-bugs.sh
health-tools/health-cleanup.sh
health-tools/health-deps.sh
health-tools/health-security.sh
specification-tools/assign-agents-to-tasks.sh
specification-tools/generate-tests-from-spec.sh
release-tools/create-release-artifacts.sh
release-tools/initialize-project.sh
monitoring/check-standards-compliance.sh
monitoring/update-project-index.sh
template-switcher.sh
```

### **6. .qwen/templates/ (5)**

```
orchestrator-template.md
README.ru.md
report-template.md
skill-template.md
worker-template.md
```

### **7. .qwen/docs/architecture/ (23)**

```
GIT_WORKFLOW.md              # ✅ Переместить из корня!
adaptative-orchestration.md
agent-creation-process.md
agent-naming-convention.md
agent-orchestration.md
code-maintenance.md
dependency-management.md
mcp-configurations.md
mcp-integration.md
notification-system.md
overview.md
planning-phase.md
quality-gates.md
quality-standards.md
report-format-standard.md
security-guidelines.md
skills-agents-integration.md
skills-system.md
specification-driven-development.md
standards.md
worktree-guidelines.md
project-index.md
agents-index.md
```

### **8. .qwen/docs/help/ (17)**

```
qwen_orchestrator_kit/00-overview.md
qwen_orchestrator_kit/01-quickstart.md
qwen_orchestrator_kit/02-architecture.md
qwen_orchestrator_kit/03-agents.md
qwen_orchestrator_kit/04-skills.md
qwen_orchestrator_kit/05-commands.md
qwen_orchestrator_kit/06-mcp-servers.md
qwen_orchestrator_kit/07-quality-gates.md
qwen_orchestrator_kit/08-git-workflow.md
qwen_orchestrator_kit/09-specification-driven.md
qwen_orchestrator_kit/10-adaptive-orchestration.md
qwen_orchestrator_kit/11-health-workflow.md
qwen_orchestrator_kit/12-template-switcher.md
qwen_orchestrator_kit/13-troubleshooting.md
qwen_orchestrator_kit/14-best-practices.md
qwen_orchestrator_kit/15-glossary.md
README.md
```

### **9. .qwen/config/ (3)**

```
monitoring-config.json
release-config.toml
qwen-code-cli-specialist-config.json
```

### **10. .qwen/prompts/ (2)**

```
release_specification_prompt.txt
specification_prompt.md
```

### **11. .qwen/ (3)**

```
mcp.json
settings.json
settings.local.json.example
```

### **12. .qwen/tests/ (4 поддиректории)**

```
integration/
agents/
skills/
commands/
```

---

## 📊 СТАТИСТИКА РЕЛИЗА

| Категория | Файлов | Размер |
|-----------|--------|--------|
| **Корневые файлы** | 9 | ~100 KB |
| **Агенты** | 25 | ~500 KB |
| **Навыки** | 31 | ~400 KB |
| **Команды** | 22 | ~300 KB |
| **Скрипты** | ~20 | ~200 KB |
| **Шаблоны** | 5 | ~20 KB |
| **Документация** | 40 | ~600 KB |
| **Конфигурации** | 6 | ~80 KB |
| **Промпты** | 2 | ~30 KB |
| **ИТОГО** | **~172** | **~2.2 MB** |

---

## 🚀 ИНСТРУКЦИЯ ДЛЯ ПОЛЬЗОВАТЕЛЯ

### **Клонирование и начало работы:**

```bash
# 1. Клонировать репозиторий
git clone https://github.com/your-org/qwen-orchestrator-kit.git my-project
cd my-project

# 2. Инициализировать git
git init

# 3. Создать .gitignore (опционально)
cat > .gitignore << EOF
node_modules/
*.log
.tmp/
.env
EOF

# 4. Начать разработку!
qwen  # Запустить Qwen Code
qwen speckit.specify  # Создать спецификацию
qwen orchestrate-project  # Запустить оркестрацию
```

**ВСЁ!** Никаких установок, зависимостей, настроек!

---

## ⚠️ ВАЖНО

**GIT_WORKFLOW.md:**
- ✅ Переместить из корня в `.qwen/docs/architecture/`
- ✅ Обновить ссылки в QWEN.md: `.qwen/docs/architecture/GIT_WORKFLOW.md`
- ✅ Алгоритм уже реализован в оркестраторе

**.gitignore:**
- ❌ НЕ включать в релиз
- ✅ Создается пользователем при инициализации
- ✅ Или добавляется отдельным файлом в repo

---

**Список готов для релиза в main!**
