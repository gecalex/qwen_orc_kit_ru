# Gastown Multi-Agent Orchestration Guide

**Версия:** 0.6.0

**Проект:** Qwen Code Orchestrator Kit

**Статус:** Production Ready

---

## Содержание

1. [Архитектура Gastown](#архитектура-gastown)
2. [Быстрый старт](#быстрый-старт)
3. [Управление worktree](#управление-worktree)
4. [Мониторинг и health check](#мониторинг-и-health-check)
5. [Merge и разрешение конфликтов](#merge-и-разрешение-конфликтов)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Архитектура Gastown

### Обзор

Gastown (Git Agent Sandbox Town) — система параллельной разработки, использующая git worktree для создания изолированных сред выполнения для агентов.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Основной репозиторий                          │
│                         (develop)                                │
└─────────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Worktree 1    │ │   Worktree 2    │ │   Worktree 3    │
│ agent-dev-spec  │ │ agent-bug-hunt  │ │ agent-sec-anal  │
│ task-001        │ │ task-002        │ │ task-003        │
│ [RUNNING]       │ │ [IDLE]          │ │ [COMPLETED]     │
└─────────────────┘ └─────────────────┘ └─────────────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              ▼
                    ┌─────────────────┐
                    │   Refinery      │
                    │   (Merge)       │
                    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Основная ветка │
                    │    (develop)    │
                    └─────────────────┘
```

### Компоненты

| Компонент | Описание | Скрипт |
|-----------|----------|--------|
| **Onboard** | Инициализация worktree | `onboard.sh` |
| **Dispatch** | Отправка задач | `dispatch.sh` |
| **Collect** | Сбор результатов | `collect.sh` |
| **Monitor** | Мониторинг задач | `monitor.sh` |
| **Witness** | Health check агентов | `witness.sh` |
| **Refinery** | Merge результатов | `refinery.sh` |

### Структура директорий

```
.qwen/gastown/
├── config.json           # Конфигурация системы
├── registry.json         # Реестр worktree и задач
├── worktrees/            # Изолированные worktree агентов
│   ├── agent-dev-specialist-task-001/
│   ├── agent-bug-hunter-002/
│   └── ...
├── collections/          # Собранные результаты
│   └── collect-YYYYMMDD-HHMMSS-PID/
├── archives/             # Архив завершенных задач
│   ├── backup-YYYYMMDD-HHMMSS/
│   └── collect-YYYYMMDD-HHMMSS-PID/
├── logs/                 # Логи системы
│   ├── onboard.log
│   ├── dispatch.log
│   ├── collect.log
│   ├── monitor.log
│   ├── witness.log
│   └── refinery.log
└── metrics/              # Метрики производительности
```

### Жизненный цикл задачи

```
1. Onboard → Создание worktree
       │
       ▼
2. Dispatch → Отправка задачи
       │
       ▼
3. Running → Выполнение задачи
       │
       ▼
4. Collect → Сбор результатов
       │
       ▼
5. Refinery → Merge в основную ветку
       │
       ▼
6. Cleanup → Очистка worktree
```

---

## Быстрый старт

### Предварительные требования

- Git 2.5+ (с поддержкой worktree)
- Bash 4.0+
- jq (рекомендуется)

### Шаг 1: Инициализация Gastown

```bash
# Создание первого worktree для агента
.qwen/scripts/gastown/onboard.sh "dev-specialist" "task-001" "develop"
```

**Ожидаемый вывод:**
```
✅ УСПЕХ: Gastown worktree успешно инициализирован!

  Агент:       dev-specialist
  Задача:      task-001
  Worktree:    agent-dev-specialist-task-001
  Путь:        .qwen/gastown/worktrees/agent-dev-specialist-task-001
```

### Шаг 2: Отправка задачи

```bash
# Отправка задачи агенту
.qwen/scripts/gastown/dispatch.sh \
  "agent-dev-specialist-task-001" \
  "specs/task-001"
```

### Шаг 3: Мониторинг выполнения

```bash
# Проверка статуса
.qwen/scripts/gastown/monitor.sh

# Live мониторинг
.qwen/scripts/gastown/monitor.sh --watch --interval 30
```

### Шаг 4: Сбор результатов

```bash
# После завершения задачи
.qwen/scripts/gastown/collect.sh "agent-dev-specialist-task-001"
```

### Шаг 5: Merge результатов

```bash
# Получение collection-id из вывода collect.sh
.qwen/scripts/gastown/refinery.sh "collect-20260321-120000-12345"
```

### Полный пример

```bash
#!/bin/bash
# Полный рабочий процесс Gastown

# 1. Инициализация
.qwen/scripts/gastown/onboard.sh "dev-specialist" "feature-auth" "develop"

# 2. Отправка задачи
.qwen/scripts/gastown/dispatch.sh \
  "agent-dev-specialist-feature-auth" \
  "specs/feature-authentication"

# 3. Ожидание завершения (в реальном сценарии — мониторинг)
sleep 300

# 4. Сбор результатов
COLLECTION=$(.qwen/scripts/gastown/collect.sh "agent-dev-specialist-feature-auth")

# 5. Merge
.qwen/scripts/gastown/refinery.sh "$COLLECTION"

# 6. Создание тега
.qwen/scripts/git/auto-tag-release.sh "v0.6.1" "Feature: Authentication"
```

---

## Управление worktree

### Создание worktree

```bash
# Базовое создание
.qwen/scripts/gastown/onboard.sh <agent-id> [task-id] [branch]

# Примеры
.qwen/scripts/gastown/onboard.sh "dev-specialist" "task-001"
.qwen/scripts/gastown/onboard.sh "bug-hunter" "bugfix-002" "bugfix/existing"
.qwen/scripts/gastown/onboard.sh "security-analyzer"  # без задачи
```

### Список worktree

```bash
# Через git
git worktree list

# Через Gastown
.qwen/scripts/gastown/monitor.sh
```

### Удаление worktree

```bash
# Через git
git worktree remove .qwen/gastown/worktrees/agent-name

# Через Gastown (после merge)
.qwen/scripts/gastown/refinery.sh "collection-id"
# worktree удаляется автоматически
```

### Конфигурация worktree

```json
// .qwen/gastown/config.json
{
  "worktree": {
    "basePath": ".qwen/gastown/worktrees",
    "namingPattern": "agent-{agent-id}-{task-id}",
    "maxWorktrees": 10,
    "autoPrune": true,
    "pruneAfterDays": 7,
    "isolatedEnv": true,
    "sharedObjects": false
  }
}
```

---

## Мониторинг и health check

### Базовый мониторинг

```bash
# Статус всех worktree
.qwen/scripts/gastown/monitor.sh

# Статус конкретного worktree
.qwen/scripts/gastown/monitor.sh "agent-dev-specialist-task-001"
```

### Live мониторинг

```bash
# Непрерывный мониторинг
.qwen/scripts/gastown/monitor.sh --watch --interval 30

# С интервалом 10 секунд
.qwen/scripts/gastown/monitor.sh --watch --interval 10
```

### Health Check агентов

```bash
# Разовая проверка здоровья
.qwen/scripts/gastown/witness.sh

# С авто-перезапуском
.qwen/scripts/gastown/witness.sh --auto-restart

# Непрерывный health check
.qwen/scripts/gastown/witness.sh --watch --interval 60 --auto-restart
```

### Статусы агентов

| Статус | Описание | Действие |
|--------|----------|----------|
| 🟢 HEALTHY | Агент работает нормально | Нет действий |
| 🟡 WARNING | Предупреждение (heartbeat) | Мониторить |
| 🔴 CRITICAL | Критическая проблема | Проверить задачу |
| ⚫ DEAD | Агент не отвечает | Перезапустить |

### Настройка порогов

```json
{
  "witness": {
    "thresholds": {
      "heartbeatWarning": 120,
      "heartbeatCritical": 300,
      "heartbeatDead": 600,
      "cpuWarning": 80,
      "cpuCritical": 95,
      "memoryWarning": 75,
      "memoryCritical": 90
    }
  }
}
```

---

## Merge и разрешение конфликтов

### Базовый merge

```bash
# После сбора результатов
.qwen/scripts/gastown/refinery.sh "collect-20260321-120000-12345"
```

### Опции merge

```bash
# Пропуск Quality Gate
.qwen/scripts/gastown/refinery.sh "collection-id" --skip-qg

# Принудительный merge
.qwen/scripts/gastown/refinery.sh "collection-id" --force

# Пробный запуск
.qwen/scripts/gastown/refinery.sh "collection-id" --dry-run
```

### Разрешение конфликтов

#### Автоматическое

```json
{
  "merge": {
    "autoResolve": true,
    "conflictStrategy": "ours"
  }
}
```

#### Ручное

```bash
# 1. Обнаружение конфликтов
git status

# 2. Просмотр конфликтов
git diff --name-only --diff-filter=U

# 3. Разрешение через mergetool
git mergetool

# 4. Завершение
git add .
git commit -m "resolve: manual conflict resolution"
```

### Конфигурация merge

```json
{
  "merge": {
    "strategy": "squash",
    "autoResolve": false,
    "conflictStrategy": "manual",
    "requireTests": true,
    "requireQualityGate": true,
    "backupBeforeMerge": true,
    "preserveHistory": true,
    "commitTemplate": "merge(gastown): {task-id} - {description}",
    "allowedBranches": ["develop", "main"],
    "blockedPatterns": ["**/config.json", "**/secrets/**"]
  }
}
```

---

## Best Practices

### 1. Именование worktree

```bash
# Хорошие имена
agent-dev-specialist-feature-auth
agent-bug-hunter-login-error
agent-security-audit-q2-2026

# Избегайте
agent1
test
temp
```

### 2. Ограничение количества worktree

```json
{
  "worktree": {
    "maxWorktrees": 10
  }
}
```

### 3. Регулярная очистка

```bash
# Настройка авто-очистки
{
  "cleanup": {
    "autoRemoveWorktrees": true,
    "removeAfterMerge": true,
    "pruneAfterDays": 7
  }
}
```

### 4. Мониторинг ресурсов

```bash
# Регулярная проверка
.qwen/scripts/gastown/monitor.sh | grep "Использование ресурсов"

# Настройка лимитов
{
  "resources": {
    "maxCpuPercent": 80,
    "maxMemoryMB": 4096,
    "maxDiskUsageMB": 10240
  }
}
```

### 5. Резервное копирование

```json
{
  "merge": {
    "backupBeforeMerge": true
  },
  "cleanup": {
    "archiveCompleted": true,
    "archivePath": ".qwen/gastown/archives"
  }
}
```

### 6. Логирование

```bash
# Централизованное логирование
tail -f .qwen/gastown/logs/*.log

# Поиск ошибок
grep -r "ERROR" .qwen/gastown/logs/
```

### 7. CI/CD интеграция

```yaml
# .github/workflows/gastown.yml
name: Gastown Merge

on:
  workflow_dispatch:
    inputs:
      collection_id:
        description: 'Collection ID'
        required: true

jobs:
  merge:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Setup Git
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
      
      - name: Merge Results
        run: |
          .qwen/scripts/gastown/refinery.sh "${{ github.event.inputs.collection_id }}"
      
      - name: Push Changes
        run: |
          git push origin develop
```

---

## Troubleshooting

### Worktree не создается

```bash
# Проверка поддержки git worktree
git worktree --help

# Проверка версии Git
git --version

# Минимальная версия: 2.5
```

### Агент не отвечает

```bash
# Проверка статуса
.qwen/scripts/gastown/witness.sh --agent "agent-name"

# Ручной перезапуск
git worktree remove .qwen/gastown/worktrees/agent-name
.qwen/scripts/gastown/onboard.sh "agent-id" "task-id"

# Авто-перезапуск
.qwen/scripts/gastown/witness.sh --auto-restart
```

### Конфликты при merge

```bash
# Просмотр конфликтующих файлов
git diff --name-only --diff-filter=U

# Разрешение
git mergetool

# Или принудительный merge
.qwen/scripts/gastown/refinery.sh "collection-id" --force
```

### Timeout задачи

```bash
# Проверка длительности
.qwen/scripts/gastown/monitor.sh | grep "TIMEOUT"

# Увеличение timeout
{
  "timeout": {
    "task": {
      "default": 7200
    }
  }
}

# Перезапуск задачи
.qwen/scripts/gastown/dispatch.sh "agent-name" "specs/task"
```

### Проблемы с реестром

```bash
# Проверка реестра
cat .qwen/gastown/registry.json | jq '.health'

# Восстановление
.qwen/scripts/gastown/repair-registry.sh  # если доступен

# Или ручное редактирование
cat > .qwen/gastown/registry.json << 'EOF'
{
  "version": "0.6.0",
  "lastUpdated": "$(date -Iseconds)",
  "worktrees": [],
  "tasks": {"active": [], "completed": [], "failed": []},
  "history": {"merges": [], "conflicts": [], "resolutions": []},
  "statistics": {
    "totalWorktreesCreated": 0,
    "totalTasksDispatched": 0
  },
  "health": {"status": "healthy", "lastCheck": "$(date -Iseconds)"}
}
EOF
```

### Недостаточно места на диске

```bash
# Проверка места
df -h

# Очистка старых worktree
rm -rf .qwen/gastown/worktrees/agent-old-*

# Очистка архивов
find .qwen/gastown/archives -type d -mtime +30 -exec rm -rf {} \;

# Очистка логов
find .qwen/gastown/logs -type f -mtime +7 -delete
```

---

## Приложения

### A. Команды Gastown

| Команда | Скрипт | Описание |
|---------|--------|----------|
| `onboard` | `onboard.sh` | Инициализация worktree |
| `work` | `dispatch.sh` | Отправка задачи |
| `status` | `monitor.sh` | Статус системы |
| `witness` | `witness.sh` | Health check |
| `upgrade` | `refinery.sh` | Merge результатов |

### B. Конфигурация

Полный пример `config.json`:

```json
{
  "version": "0.6.0",
  "worktree": {
    "basePath": ".qwen/gastown/worktrees",
    "namingPattern": "agent-{agent-id}-{task-id}",
    "maxWorktrees": 10,
    "autoPrune": true,
    "pruneAfterDays": 7
  },
  "timeout": {
    "task": {
      "default": 3600,
      "short": 300,
      "medium": 1800,
      "long": 7200
    },
    "heartbeat": {
      "interval": 60,
      "maxMissed": 5,
      "gracePeriod": 120
    }
  },
  "merge": {
    "strategy": "squash",
    "autoResolve": false,
    "conflictStrategy": "manual",
    "requireTests": true,
    "requireQualityGate": true,
    "backupBeforeMerge": true
  },
  "cleanup": {
    "autoRemoveWorktrees": true,
    "removeAfterMerge": true,
    "keepLogsDays": 30,
    "archiveCompleted": true
  }
}
```

### C. Ссылки

- [Onboard Command](./commands/gastown/onboard.md)
- [Work Command](./commands/gastown/work.md)
- [Status Command](./commands/gastown/status.md)
- [Upgrade Command](./commands/gastown/upgrade.md)
- [Witness Command](./commands/gastown/witness.md)
- [Git Workflow](./docs/git-workflow-automation.md)

---

**Документация Gastown Multi-Agent Orchestration v0.6.0**

*Qwen Code Orchestrator Kit*
