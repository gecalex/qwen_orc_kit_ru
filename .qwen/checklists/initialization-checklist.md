# Initialization Checklist

Чек-лист инициализации проекта.

---

## Чек-лист (9 пунктов)

- [ ] **1.1** Git репозиторий инициализирован
- [ ] **1.2** .gitignore настроен
- [ ] **1.3** README.md создан
- [ ] **1.4** LICENSE выбран и добавлен
- [ ] **1.5** .qwen/ директория создана
- [ ] **1.6** .qwen/mcp.json настроен
- [ ] **1.7** .qwen/settings.json настроен
- [ ] **1.8** .version создан с версией 0.1.0
- [ ] **1.9** CHANGELOG.md создан

---

## Быстрая инициализация

```bash
# Инициализация Git
git init

# Создание структуры
mkdir -p .qwen/{agents,commands,config,docs,feedback,logs,prompts,reports,scripts,skills,specify,templates,tests}

# Создание базовых файлов
echo "0.1.0" > .version
echo "# Changelog" > CHANGELOG.md
echo "# Project Name" > README.md
```

---

## Конфигурация MCP

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    }
  }
}
```

---

## Использование

```bash
# Автоматическая проверка
.qwen/checklists/validate-checklist.sh --name "Initialization"
```

---

*Версия: 1.0.0 | Последнее обновление: 2026-03-21*
