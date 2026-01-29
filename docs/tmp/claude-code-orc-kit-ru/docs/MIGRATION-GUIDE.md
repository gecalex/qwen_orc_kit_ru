# 🔄 Руководство по миграции

## Добавление Orchestrator Kit в существующие проекты

### Быстрый старт

```bash
# 1. Создать резервную копию существующего каталога .claude (если существует)
mv .claude .claude.backup

# 2. Скопировать Orchestrator Kit
cp -r /path/to/claude-code-orchestrator-kit/.claude ./

# 3. Если у вас были пользовательские агенты, объединить их
cp .claude.backup/agents/my-custom-agent.md .claude/agents/

# 4. Настроить окружение
cp .env.example .env.local
# Отредактировать .env.local с вашими учетными данными

# 5. Выбрать конфигурацию MCP
./switch-mcp.sh

# 6. Перезапустить Claude Code
```

---

## Пошаговая миграция

### Шаг 1: Оценка

**Перед тем как что-либо копировать, оцените текущую настройку:**

```bash
# Проверить существующих агентов
ls -la .claude/agents/

# Проверить пользовательские команды
ls -la .claude/commands/

# Проверить скрипты
ls -la .claude/scripts/

# Проверить, существует ли CLAUDE.md
cat CLAUDE.md
```

**Документировать, что у вас есть:**
- Пользовательские агенты, которые вы хотите сохранить
- Пользовательские команды
- Пользовательские скрипты
- Существующие конфигурации MCP

---

### Шаг 2: Резервное копирование

**Создать резервную копию существующей настройки:**

```bash
# Полная резервная копия
tar -czf claude-backup-$(date +%Y%m%d).tar.gz .claude/ CLAUDE.md .mcp.json

# Или простое копирование
cp -r .claude .claude.backup
cp CLAUDE.md CLAUDE.md.backup
cp .mcp.json .mcp.json.backup
```

---

### Шаг 3: Установить Orchestrator Kit

```bash
# Клонировать или скачать комплект
git clone https://github.com/maslennikov-ig/claude-code-orchestrator-kit.git
# Или: скачать и извлечь ZIP

# Скопировать каталог .claude
cp -r claude-code-orchestrator-kit/.claude ./

# Скопировать CLAUDE.md (Поведенческая ОС)
cp claude-code-orchestrator-kit/CLAUDE.md ./

# Скопировать конфигурации MCP
cp -r claude-code-orchestrator-kit/mcp ./

# Скопировать скрипт переключения
cp claude-code-orchestrator-kit/switch-mcp.sh ./
chmod +x switch-mcp.sh

# Скопировать шаблон окружения
cp claude-code-orchestrator-kit/.env.example ./.env.local
```

---

### Шаг 4: Объединить пользовательских агентов

**Если у вас были пользовательские агенты в `.claude.backup/agents/`:**

```bash
# Список ваших пользовательских агентов
ls .claude.backup/agents/

# Скопировать пользовательских агентов в соответствующую категорию
cp .claude.backup/agents/my-custom-worker.md .claude/agents/development/workers/
cp .claude.backup/agents/my-orchestrator.md .claude/agents/custom/orchestrators/

# Проверить отсутствие конфликтов
diff .claude.backup/agents/my-agent.md .claude/agents/development/workers/my-agent.md
```

**Обновить пользовательских агентов, чтобы следовать новым шаблонам:**
```markdown
# Обновить YAML frontmatter при необходимости
---
name: my-agent
description: Use proactively for {task}...
model: sonnet
color: cyan
---

# Проверить ссылки на ARCHITECTURE.md, CLAUDE.md
# Обновить местоположения файлов плана на .tmp/current/plans/
# Обновить местоположения отчетов на .tmp/current/reports/
```

---

### Шаг 5: Настроить окружение

**Отредактировать `.env.local`:**

```bash
# Требуется для Supabase MCP
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_ACCESS_TOKEN=your-token
SUPABASE_DB_PASSWORD=your-password

# Требуется для Sequential Thinking
SEQUENTIAL_THINKING_KEY=your-smithery-key
SEQUENTIAL_THINKING_PROFILE=your-profile

# Необязательно для n8n
N8N_API_URL=https://your-n8n.com
N8N_API_KEY=your-api-key
```

**Проверка безопасности:**
```bash
# Проверить, что .env.local в git-игноре
cat .gitignore | grep ".env.local"

# Если нет, добавить
echo ".env.local" >> .gitignore
```

---

### Шаг 6: Выбрать конфигурацию MCP

```bash
# Запустить интерактивный переключатель
./switch-mcp.sh

# Выбрать подходящую конфигурацию:
# 1. BASE - Минимальная (начните здесь)
# 2. SUPABASE - Работа с базой данных
# 3. SUPABASE-FULL - Много проектов
# 4. N8N - Автоматизация рабочих процессов
# 5. FRONTEND - Работа с UI/UX
# 6. FULL - Все

# Для первой настройки рекомендуется: BASE
```

---

### Шаг 7: Проверить установку

```bash
# Проверить, что агенты загружены
# (В Claude Code)
"List available agents"

# Протестировать простую команду
/health-metrics

# Протестировать вызов агента
"Use bug-hunter to scan src/"

# Проверить, что серверы MCP работают
"Check Context7 availability"
```

---

## Сценарии миграции

### Сценарий 1: Нет существующего каталога .claude

**Это самый простой сценарий:**

```bash
# Просто скопировать все
cp -r claude-code-orchestrator-kit/.claude ./
cp claude-code-orchestrator-kit/CLAUDE.md ./
cp -r claude-code-orchestrator-kit/mcp ./
cp claude-code-orchestrator-kit/switch-mcp.sh ./
cp claude-code-orchestrator-kit/.env.example ./.env.local

# Настроить и запустить
./switch-mcp.sh
```

---

### Сценарий 2: Существующий .claude с пользовательскими агентами

**Подход объединения:**

```bash
# 1. Создать резервную копию существующего
mv .claude .claude.backup

# 2. Установить комплект
cp -r claude-code-orchestrator-kit/.claude ./

# 3. Создать пользовательскую категорию
mkdir -p .claude/agents/custom/workers/
mkdir -p .claude/agents/custom/orchestrators/

# 4. Скопировать пользовательских агентов
cp .claude.backup/agents/*.md .claude/agents/custom/workers/

# 5. Обновить пользовательских агентов (при необходимости)
# - Обновить YAML frontmatter
# - Обновить ссылки на ARCHITECTURE.md
# - Обновить пути к файлам (.tmp/current/...)
```

---

### Сценарий 3: Существующая конфигурация MCP

**Объединить конфигурации MCP:**

```bash
# 1. Создать резервную копию существующей MCP
cp .mcp.json .mcp.json.backup

# 2. Скопировать конфигурации MCP комплекта
cp -r claude-code-orchestrator-kit/mcp ./

# 3. Объединить пользовательские серверы MCP в базовую конфигурацию
# Отредактировать mcp/.mcp.base.json:
{
  "mcpServers": {
    "context7": { ... },
    "server-sequential-thinking": { ... },
    "my-custom-mcp": {
      "command": "...",
      "args": [...],
      "env": { ... }
    }
  }
}

# 4. Переключиться на объединенную конфигурацию
./switch-mcp.sh
# Выбрать BASE (теперь включает ваш пользовательский MCP)
```

---

### Сценарий 4: Существующий CLAUDE.md

**Сравнить и объединить:**

```bash
# 1. Создать резервную копию существующего
cp CLAUDE.md CLAUDE.md.backup

# 2. Сравнить
diff CLAUDE.md.backup claude-code-orchestrator-kit/CLAUDE.md

# 3. Варианты:
# A. Использовать CLAUDE.md комплекта (рекомендуется):
cp claude-code-orchestrator-kit/CLAUDE.md ./

# B. Объединить вручную (продвинутый):
# - Сохранить проектные правила
# - Добавить основные директивы комплекта (PD-1 до PD-7)
# - Добавить поведенческие контракты комплекта
```

---

## Контрольный список после миграции

### Проверка

- [ ] Каталог `.claude/` существует с агентами, командами, навыками
- [ ] `CLAUDE.md` существует (Поведенческая ОС)
- [ ] Каталог `mcp/` имеет файлы конфигурации
- [ ] `.mcp.json` активная конфигурация (не в git-игноре)
- [ ] `.env.local` настроен с учетными данными (в git-игноре)
- [ ] `switch-mcp.sh` исполняемый (`chmod +x`)
- [ ] Пользовательские агенты скопированы в соответствующие категории
- [ ] Git игнорирует конфиденциальные файлы (.env.local, .tmp/)

### Функциональное тестирование

```bash
# Тест 1: Агенты загружены
# (Спросить Claude Code): "List health agents"
# Должно показать: bug-orchestrator, security-orchestrator и т.д.

# Тест 2: Команды работают
/health-metrics
# Должно сгенерировать отчет о метриках

# Тест 3: Серверы MCP активны
# (Спросить Claude Code): "Use Context7 to get React docs"
# Должно вернуть документацию React

# Тест 4: Пользовательские агенты работают
# (Если у вас были пользовательские агенты): "Use my-custom-agent for..."
# Должно вызвать вашего пользовательского агента
```

### Проверка производительности

```bash
# Проверить конфигурацию
./switch-mcp.sh
# Выбрать 0, чтобы увидеть текущую конфигурацию

# Проверить использование токенов
# Текущая конфигурация должна быть BASE (наименьший объем использования)
```

---

## Устранение неполадок

### Проблема: Агенты не найдены

**Симптом**: Claude Code не распознает команды проверки здоровья.

**Решение**:
```bash
# 1. Проверить структуру .claude/
ls -la .claude/agents/health/orchestrators/
# Должно быть: bug-orchestrator.md, security-orchestrator.md и т.д.

# 2. Полностью перезапустить Claude Code
# (Не просто перезагрузить, полный перезапуск)

# 3. Проверить YAML frontmatter в файлах агентов
head -10 .claude/agents/health/orchestrators/bug-orchestrator.md
# Должен иметь действительный YAML:
# ---
# name: bug-orchestrator
# description: ...
# model: sonnet
# color: blue
# ---
```

---

### Проблема: Серверы MCP не работают

**Симптом**: Context7, Supabase MCP показывают "недоступно".

**Решение**:
```bash
# 1. Проверить, что .mcp.json скопирован
cat .mcp.json | jq .mcpServers

# 2. Проверить, что переменные окружения загружены
cat .env.local
# Переменные должны присутствовать (без кавычек)

# 3. Перезапустить Claude Code
# Переменные окружения загружаются при запуске

# 4. Протестировать конкретный MCP
# (Спросить Claude Code): "Test Context7 MCP server"
```

---

### Проблема: Пользовательские агенты сломаны

**Симптом**: Пользовательские агенты не запускаются или дают ошибки.

**Решение**:
```bash
# 1. Проверить местоположение агента
# Пользовательские агенты должны быть в:
# .claude/agents/custom/workers/ или
# .claude/agents/{appropriate-category}/workers/

# 2. Обновить ссылки агента
# Старые: docs/ARCHITECTURE.md
# Новые: docs/Agents Ecosystem/ARCHITECTURE.md

# Старые: .bug-plan.json
# Новые: .tmp/current/plans/.bug-plan.json

# 3. Проверить YAML frontmatter
# Должен содержать: name, description, model, color

# 4. Протестировать агента
# (Спросить Claude Code): "Use {agent-name} for test"
```

---

### Проблема: Git показывает файлы комплекта как непроиндексированные

**Симптом**: `git status` показывает `.claude/`, `docs/` и т.д.

**Решение**:
```bash
# Вариант A: Зафиксировать файлы комплекта (рекомендуется)
git add .claude/ docs/ CLAUDE.md mcp/ switch-mcp.sh
git commit -m "feat: Add Claude Code Orchestrator Kit"

# Вариант B: Добавить в .gitignore (не рекомендуется)
# Файлы комплекта должны быть зафиксированы, чтобы у команды был доступ
```

---

### Проблема: Конфликты с существующими агентами

**Симптом**: Агент комплекта имеет то же имя, что и пользовательский агент.

**Решение**:
```bash
# 1. Переименовать пользовательского агента
mv .claude/agents/custom/bug-hunter.md .claude/agents/custom/my-bug-hunter.md

# 2. Обновить YAML frontmatter
# Изменить: name: bug-hunter
# На: name: my-bug-hunter

# 3. Использовать переименованного агента
# (Спросить Claude Code): "Use my-bug-hunter for..."
```

---

## Интеграция CI/CD

### GitHub Actions

```yaml
# .github/workflows/health-check.yml
name: Health Check

on:
  pull_request:
  schedule:
    - cron: '0 0 * * 1'  # Еженедельно

jobs:
  health:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Claude Code
        uses: claude-code/setup@v1
        with:
          mcp-config: base  # Использовать BASE для CI

      - name: Run health checks
        run: |
          cp mcp/.mcp.base.json .mcp.json
          claude-code /health-bugs

      - name: Upload reports
        uses: actions/upload-artifact@v3
        with:
          name: health-reports
          path: .tmp/current/reports/
```

---

## Процедура отката

**Если миграция вызывает проблемы:**

```bash
# 1. Остановить Claude Code

# 2. Восстановить резервную копию
rm -rf .claude/
mv .claude.backup .claude/

rm CLAUDE.md
mv CLAUDE.md.backup CLAUDE.md

rm .mcp.json
mv .mcp.json.backup .mcp.json

# 3. Перезапустить Claude Code

# 4. Проверить восстановление системы
# (Спросить Claude Code): "List agents"
# Должно показать ваши оригинальные агенты
```

---

## Следующие шаги

После успешной миграции:

1. **Запустить базовую проверку состояния**: `/health-bugs`, `/health-security`, `/health-deps`
2. **Просмотреть отчеты**: Понять текущее состояние кода
3. **Создать план действий**: Приоритизировать исправления на основе отчетов
4. **Обучить команду**: Поделиться документацией, провести демонстрационную сессию
5. **Интегрировать с рабочим процессом**: Добавить к проверке кода, CI/CD

См.:
- [TUTORIAL-CUSTOM-AGENTS.md](./TUTORIAL-CUSTOM-AGENTS.md) для создания агентов
- [USE-CASES.md](./USE-CASES.md) для примеров из реальной жизни
- [PERFORMANCE-OPTIMIZATION.md](./PERFORMANCE-OPTIMIZATION.md) для экономии средств

---

**Версия документа**: 1.0
**Последнее обновление**: 2025-01-11
**Поддерживается**: [Игорь Маслennикov](https://github.com/maslennikov-ig)
