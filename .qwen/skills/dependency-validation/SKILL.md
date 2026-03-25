---
name: dependency-validation
description: Валидация зависимостей перед добавлением в проект. Проверка наличия, совместимости версий, уязвимостей и рекомендаций по обновлению.
---

# Dependency Validation

## Назначение

Навык валидации зависимостей для проверки проекта на наличие проблем с зависимостями перед их добавлением или обновлением.

## Когда использовать

- **Перед добавлением новой зависимости** - проверка необходимости и совместимости
- **При обновлении зависимостей** - проверка обратной совместимости
- **Перед релизом** - финальная проверка всех зависимостей
- **При возникновении конфликтов** - анализ и разрешение конфликтов версий
- **Для регулярного аудита** - плановая проверка состояния зависимостей

## Функционал

### 1. Проверка наличия в файлах зависимостей

**Для npm/package.json:**
```bash
# Проверка package.json
jq '.dependencies' package.json
jq '.devDependencies' package.json
```

**Для Python/requirements.txt:**
```bash
# Проверка requirements.txt
cat requirements.txt
cat requirements-dev.txt
```

### 2. Проверка совместимости версий

**Алгоритм проверки:**
1. Извлечь текущие версии зависимостей
2. Проверить требования новой зависимости
3. Выявить конфликты версий
4. Предложить совместимые версии

**Пример проверки:**
```bash
# Для npm
npm ls <package-name>
npm outdated

# Для Python
pip check
pip list --outdated
```

### 3. Проверка на уязвимости

**Для npm:**
```bash
npm audit
npm audit --audit-level=high
```

**Для Python:**
```bash
pip-audit
safety check
```

**Для общих проектов:**
```bash
# Snyk CLI
snyk test

# OSV-Scanner
osv-scanner
```

### 4. Рекомендации по обновлению

**Критерии рекомендаций:**
- 🔴 **Критическое** - уязвимости безопасности
- 🟡 **Рекомендуемое** - устаревшие версии (>1 года)
- 🟢 **Опциональное** - минорные обновления

## Процесс выполнения

### Шаг 1: Анализ текущих зависимостей

```bash
# Сбор информации о зависимостях
echo "=== Анализ package.json ==="
cat package.json | jq '.dependencies, .devDependencies'

echo "=== Анализ requirements.txt ==="
cat requirements*.txt
```

### Шаг 2: Проверка на уязвимости

```bash
# Запуск аудита безопасности
echo "=== Проверка уязвимостей npm ==="
npm audit --json > /tmp/npm-audit.json 2>&1 || true

echo "=== Проверка уязвимостей Python ==="
pip-audit --format json > /tmp/pip-audit.json 2>&1 || true
```

### Шаг 3: Проверка совместимости

```bash
# Проверка дерева зависимостей
echo "=== Дерево зависимостей ==="
npm ls --depth=0

# Проверка на конфликты
npm ls 2>&1 | grep -i "conflict\|peer dep" || echo "Конфликтов не найдено"
```

### Шаг 4: Формирование отчета

**Структура отчета:**

```markdown
# Отчет валидации зависимостей

## Статус: ✅ PASS / ⚠️ WARNING / ❌ FAIL

### Критические проблемы
- [ ] Уязвимости безопасности: 0
- [ ] Конфликты версий: 0

### Предупреждения
- [ ] Устаревшие зависимости: X
- [ ] Необязательные зависимости: Y

### Рекомендации
1. Обновить: package@version → version
2. Удалить: unused-package
3. Добавить: missing-package@version
```

## Примеры использования

### Пример 1: Валидация перед добавлением зависимости

```bash
# Проверка перед установкой
.qwen/scripts/validation/validate-dependency.sh <package-name>

# Вывод:
# ✅ Совместимость: OK
# ⚠️ Уязвимости: 1 (medium)
# 📦 Размер: 1.2 MB
# 📅 Последнее обновление: 2026-03-15
```

### Пример 2: Полный аудит проекта

```bash
# Запуск полного аудита
.qwen/scripts/validation/full-audit.sh

# Вывод:
# Всего зависимостей: 156
# Уязвимости: 2 (low), 1 (medium)
# Устаревшие: 12
# Конфликты: 0
```

### Пример 3: Проверка конкретной зависимости

```bash
# Проверка совместимости версии
.qwen/scripts/validation/check-compatibility.sh eslint "^9.0.0"

# Вывод:
# Требуется: Node.js >= 18
# Совместимо с: eslint-plugin-markdown@^4.0.0
# Конфликтует с: eslint@^8.0.0
```

## Интеграция с другими навыками

- **dependency-auditor** - регулярный аудит зависимостей
- **security-analyzer** - проверка безопасности кода
- **code-quality-checker** - проверка качества кода
- **generate-report-header** - генерация заголовка отчета

## Скрипты

### validate-dependency.sh

**Расположение:** `.qwen/scripts/validation/validate-dependency.sh`

**Назначение:** Валидация зависимости перед добавлением

**Использование:**
```bash
.qwen/scripts/validation/validate-dependency.sh <package-name> [version]
```

### full-audit.sh

**Расположение:** `.qwen/scripts/validation/full-audit.sh`

**Назначение:** Полный аудит всех зависимостей проекта

**Использование:**
```bash
.qwen/scripts/validation/full-audit.sh [--json]
```

### check-compatibility.sh

**Расположение:** `.qwen/scripts/validation/check-compatibility.sh`

**Назначение:** Проверка совместимости версий

**Использование:**
```bash
.qwen/scripts/validation/check-compatibility.sh <package>@<version>
```

## Чек-лист валидации

### Перед добавлением зависимости

- [ ] Проверена необходимость зависимости
- [ ] Найдены альтернативы (минимум 2)
- [ ] Проверена лицензия
- [ ] Проверена активность поддержки
- [ ] Проверены уязвимости (npm audit / pip-audit)
- [ ] Проверена совместимость версий
- [ ] Проверен размер пакета
- [ ] Проверена документация

### Перед обновлением зависимости

- [ ] Проверен changelog
- [ ] Проверены breaking changes
- [ ] Протестирована совместимость
- [ ] Создана резервная копия
- [ ] Обновлены связанные зависимости

### Перед релизом

- [ ] Все уязвимости устранены
- [ ] Конфликты версий разрешены
- [ ] Зависимости зафиксированы (lock file)
- [ ] Проверена воспроизводимость сборки

## Метрики

| Метрика | Значение | Порог |
|---------|----------|-------|
| Уязвимости (critical) | 0 | 0 |
| Уязвимости (high) | 0 | 0 |
| Уязвимости (medium) | < 5 | 10 |
| Устаревшие зависимости | < 20% | 50% |
| Конфликты версий | 0 | 0 |
| Размер node_modules | < 500 MB | 1 GB |

## Troubleshooting

### Проблема: Конфликт peer dependencies

**Решение:**
```bash
# Для npm
npm install <package> --legacy-peer-deps

# Или обновить конфликтующие пакеты
npm update <conflicting-package>
```

### Проблема: Уязвимость в зависимости

**Решение:**
```bash
# Автоматическое исправление
npm audit fix
npm audit fix --force

# Или обновить вручную
npm install <vulnerable-package>@latest
```

### Проблема: Устаревшая зависимость

**Решение:**
```bash
# Проверка доступных версий
npm view <package> versions

# Обновление до последней
npm install <package>@latest
```

## Ссылки

- [npm audit documentation](https://docs.npmjs.com/auditing-package-dependencies-for-security-vulnerabilities)
- [pip-audit documentation](https://pypi.org/project/pip-audit/)
- [Snyk vulnerability database](https://snyk.io/vuln/)
- [OSV vulnerability database](https://osv.dev/)
