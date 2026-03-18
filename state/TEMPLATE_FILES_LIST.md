# 📋 Список файлов для нового проекта (шаблон)

**Версия:** 1.0.0  
**Дата:** 2026-03-18

---

## 🎯 БЫСТРЫЙ СТАРТ (минимальный набор)

**Для копирования в новый проект:**

```
новый-проект/
├── .qwen/
│   ├── agents/
│   │   ├── orc_dev_task_coordinator.md
│   │   ├── orc_security_security_orchestrator.md
│   │   ├── orc_testing_quality_assurer.md
│   │   ├── work_dev_code_analyzer.md
│   │   ├── bug-fixer.md
│   │   ├── bug-hunter.md
│   │   └── code-quality-checker.md
│   ├── skills/
│   │   ├── validate-report-file/SKILL.md
│   │   ├── generate-report-header/SKILL.md
│   │   ├── task-analyzer/SKILL.md
│   │   ├── select-mcp-server/SKILL.md
│   │   ├── security-analyzer/SKILL.md
│   │   ├── dependency-auditor/SKILL.md
│   │   ├── security-scanner/SKILL.md
│   │   ├── bug-hunter/SKILL.md
│   │   ├── bug-fixer/SKILL.md
│   │   └── run-quality-gate/SKILL.md
│   ├── commands/
│   │   ├── run-quality-gate.md
│   │   ├── health-security.md
│   │   ├── orchestrate-project.md
│   │   └── template.md
│   ├── scripts/
│   │   └── orchestration-tools/
│   │       ├── analyze-project-state.sh
│   │       ├── check-security.sh
│   │       └── health-bugs.sh
│   ├── templates/
│   │   ├── orchestrator-template.md
│   │   ├── worker-template.md
│   │   ├── skill-template.md
│   │   └── report-template.md
│   ├── mcp.json
│   ├── settings.json
│   └── settings.local.json.example
├── .gitignore
├── CHANGELOG.md
├── GIT_WORKFLOW.md
├── INSTALLATION.md
├── package.json
├── QWEN.md
├── QUICKSTART.md
├── README.md
└── USAGE_INSTRUCTIONS.md
```

**Итого:** 42 файла (~500 KB)

---

## 📦 ПОЛНЫЙ ШАБЛОН (production-ready)

**Для копирования в новый проект:**

### **1. Корневые файлы (12)**

```
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
└── RELEASE_NOTES.md (опционально)
```

### **2. .qwen/ Конфигурация (3)**

```
.qwen/
├── mcp.json
├── settings.json
└── settings.local.json.example
```

### **3. .qwen/agents/ (25)**

**Оркестраторы (7):**
```
├── orc_backend_api_coordinator.md
├── orc_dev_task_coordinator.md
├── orc_frontend_ui_coordinator.md
├── orc_planning_task_analyzer.md
├── orc_research_data_analyzer.md
├── orc_security_security_orchestrator.md
└── orc_testing_quality_assurer.md
```

**Воркеры (18):**
```
├── work_backend_api_validator.md
├── work_dev_code_analyzer.md
├── work_dev_dependency_analyzer.md
├── work_dev_meta_agent.md
├── work_dev_qwen_code_cli_specialist.md
├── work_doc_tech_translator_ru.md
├── work_frontend_component_generator.md
├── work_health_bug_fixer.md
├── work_health_bug_hunter.md
├── work_health_dead_code_detector.md
├── work_meta_agent_creator.md
├── work_planning_agent_requirer.md
├── work_planning_executor_assigner.md
├── work_planning_task_classifier.md
├── work_research_trend_tracker.md
├── work_security_security_analyzer.md
├── work_testing_code_quality_checker.md
└── work_testing_test_generator.md
```

### **4. .qwen/skills/ (31)**

```
├── bug-fixer/SKILL.md
├── bug-hunter/SKILL.md
├── calculate-priority-score/SKILL.md
├── code-cleaner/SKILL.md
├── code-refactorer/SKILL.md
├── dependency-auditor/SKILL.md
├── documentation-generator/SKILL.md
├── extract-version/SKILL.md
├── format-markdown-table/SKILL.md
├── generate-changelog/SKILL.md
├── generate-report-header/SKILL.md
├── parse-error-logs/SKILL.md
├── parse-git-status/SKILL.md
├── resume-session/SKILL.md
├── run-quality-gate/SKILL.md
├── save-session-context/SKILL.md
├── security-analyzer/SKILL.md
├── security-scanner/SKILL.md
├── select-mcp-server/SKILL.md
├── skill-template/SKILL.md
├── specification-analyzer/SKILL.md
├── task-analyzer/SKILL.md
├── validate-plan-file/SKILL.md
├── validate-report-file/SKILL.md
├── webhook-sender/SKILL.md
├── yaml-header-validator/SKILL.md
├── agent-structure-checker/SKILL.md
├── check-agent-name-uniqueness/SKILL.md
├── code-quality-checker/SKILL.md
└── tech-translator-ru/SKILL.md
```

### **5. .qwen/commands/ (22)**

```
├── configure-webhooks.md
├── health-cleanup.md
├── health-deps.md
├── health-security.md
├── orchestrate-project.md
├── run-quality-gate.md
├── speckit.analyze.md
├── speckit.checklist.md
├── speckit.clarify.md
├── speckit.constitution.md
├── speckit.implement.md
├── speckit.plan.md
├── speckit.specify.md
├── speckit.taskstoissues.md
├── speckit.tasks.md
├── specification-validate.md
├── template.md
├── worktree-create.md
├── worktree-list.md
└── worktree-remove.md
```

### **6. .qwen/scripts/ (~20)**

**Quality Gates (6):**
```
├── quality-gates/
│   ├── check-bundle-size.sh
│   ├── check-changelog.sh
│   ├── check-coverage.sh
│   ├── check-linting.sh
│   ├── check-security.sh
│   └── check-typing.sh
```

**Orchestration tools (3):**
```
├── orchestration-tools/
│   ├── analyze-project-state.sh
│   ├── phase0-analyzer.sh
│   └── switch-mcp.sh
```

**Health tools (4):**
```
│   ├── health-bugs.sh
│   ├── health-cleanup.sh
│   ├── health-deps.sh
│   └── health-security.sh
```

**Specification tools (2):**
```
├── specification-tools/
│   ├── assign-agents-to-tasks.sh
│   └── generate-tests-from-spec.sh
```

**Release tools (2):**
```
├── release-tools/
│   ├── create-release-artifacts.sh
│   └── initialize-project.sh
```

**Другие:**
```
├── monitoring/
│   ├── check-standards-compliance.sh
│   └── update-project-index.sh
├── agent-creation/
│   ├── agent-search.sh
│   └── validate-agent-names.sh
└── template-switcher.sh
```

### **7. .qwen/templates/ (5)**

```
├── orchestrator-template.md
├── README.ru.md
├── report-template.md
├── skill-template.md
└── worker-template.md
```

### **8. .qwen/docs/ (40)**

**Архитектура (23):**
```
├── docs/architecture/
│   ├── GIT_WORKFLOW.md
│   ├── adaptative-orchestration.md
│   ├── agent-creation-process.md
│   ├── agent-naming-convention.md
│   ├── agent-orchestration.md
│   ├── code-maintenance.md
│   ├── dependency-management.md
│   ├── mcp-configurations.md
│   ├── mcp-integration.md
│   ├── notification-system.md
│   ├── overview.md
│   ├── planning-phase.md
│   ├── quality-gates.md
│   ├── quality-standards.md
│   ├── report-format-standard.md
│   ├── security-guidelines.md
│   ├── skills-agents-integration.md
│   ├── skills-system.md
│   ├── specification-driven-development.md
│   ├── standards.md
│   ├── worktree-guidelines.md
│   ├── project-index.md
│   └── agents-index.md
```

**Справка (17):**
```
└── docs/help/
    ├── qwen_orchestrator_kit/
    │   ├── 00-overview.md
    │   ├── 01-quickstart.md
    │   ├── 02-architecture.md
    │   ├── 03-agents.md
    │   ├── 04-skills.md
    │   ├── 05-commands.md
    │   ├── 06-mcp-servers.md
    │   ├── 07-quality-gates.md
    │   ├── 08-git-workflow.md
    │   ├── 09-specification-driven.md
    │   ├── 10-adaptive-orchestration.md
    │   ├── 11-health-workflow.md
    │   ├── 12-template-switcher.md
    │   ├── 13-troubleshooting.md
    │   ├── 14-best-practices.md
    │   └── 15-glossary.md
    └── README.md
```

### **9. .qwen/config/ (3)**

```
├── config/
│   ├── monitoring-config.json
│   ├── release-config.toml
│   └── qwen-code-cli-specialist-config.json
```

### **10. .qwen/prompts/ (2)**

```
├── prompts/
│   ├── release_specification_prompt.txt
│   └── specification_prompt.md
```

### **11. .qwen/tests/ (4 поддиректории)**

```
└── tests/
    ├── integration/
    ├── agents/
    ├── skills/
    └── commands/
```

---

## 📊 ИТОГОВАЯ СТАТИСТИКА

| Категория | Файлов | Размер |
|-----------|--------|--------|
| **Корневые файлы** | 12 | ~150 KB |
| **.qwen/ конфигурация** | 3 | ~50 KB |
| **Агенты** | 25 | ~500 KB |
| **Навыки** | 31 | ~400 KB |
| **Команды** | 22 | ~300 KB |
| **Скрипты** | ~20 | ~200 KB |
| **Шаблоны** | 5 | ~20 KB |
| **Документация** | 40 | ~600 KB |
| **Конфигурации** | 3 | ~30 KB |
| **Промпты** | 2 | ~30 KB |
| **Тесты** | ~10 | ~100 KB |
| **ИТОГО** | **~173** | **~2.3 MB** |

---

## 🚀 СКОПИРОВАТЬ В НОВЫЙ ПРОЕКТ

### **Команда для копирования (Linux/Mac):**

```bash
# Создать новый проект
mkdir my-new-project && cd my-new-project

# Скопировать полный шаблон
cp -r /path/to/qwen_orc_kit_ru/.qwen ./
cp /path/to/qwen_orc_kit_ru/.gitignore ./
cp /path/to/qwen_orc_kit_ru/.markdownlint.yml ./
cp /path/to/qwen_orc_kit_ru/CHANGELOG.md ./
cp /path/to/qwen_orc_kit_ru/GIT_WORKFLOW.md ./
cp /path/to/qwen_orc_kit_ru/INSTALLATION.md ./
cp /path/to/qwen_orc_kit_ru/package.json ./
cp /path/to/qwen_orc_kit_ru/QWEN.md ./
cp /path/to/qwen_orc_kit_ru/QUICKSTART.md ./
cp /path/to/qwen_orc_kit_ru/README.md ./
cp /path/to/qwen_orc_kit_ru/USAGE_INSTRUCTIONS.md ./

# Инициализировать git
git init
git add -A
git commit -m "Initial commit from Qwen Orchestrator Kit template

Co-authored-by: Qwen-Coder <qwen-coder@alibabacloud.com>"
```

### **Для быстрого старта (только базовые):**

```bash
# Создать новый проект
mkdir my-new-project && cd my-new-project

# Скопировать .qwen/
cp -r /path/to/qwen_orc_kit_ru/.qwen ./

# Оставить только базовые агенты (7)
rm .qwen/agents/orc_backend_*
rm .qwen/agents/orc_frontend_*
rm .qwen/agents/orc_planning_*
rm .qwen/agents/orc_research_*
rm .qwen/agents/work_backend_*
rm .qwen/agents/work_frontend_*
rm .qwen/agents/work_dev_dependency_analyzer.md
rm .qwen/agents/work_dev_meta_agent.md
rm .qwen/agents/work_dev_qwen_code_cli_specialist.md
# ... и так далее (оставить 7 базовых)

# Скопировать корневые файлы
cp /path/to/qwen_orc_kit_ru/.gitignore ./
cp /path/to/qwen_orc_kit_ru/QWEN.md ./
cp /path/to/qwen_orc_kit_ru/README.md ./
cp /path/to/qwen_orc_kit_ru/QUICKSTART.md ./
cp /path/to/qwen_orc_kit_ru/INSTALLATION.md ./
cp /path/to/qwen_orc_kit_ru/CHANGELOG.md ./
cp /path/to/qwen_orc_kit_ru/GIT_WORKFLOW.md ./
cp /path/to/qwen_orc_kit_ru/package.json ./

# Инициализировать git
git init
git add -A
git commit -m "Initial commit (quickstart template)"
```

---

## ✅ ПЕРВЫЕ ШАГИ ПОСЛЕ КОПИРОВАНИЯ

```bash
# 1. Проверить статус
qwen template-switcher status

# 2. Настроить MCP (если нужно)
qwen template-switcher full  # или quickstart

# 3. Начать разработку
qwen speckit.specify  # Создать спецификацию
qwen orchestrate-project  # Запустить оркестрацию
```

---

**Список готов к использованию!**
