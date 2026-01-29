---
name: setup-knip
description: Установка и настройка Knip для обнаружения мертвого кода. Используется перед запуском dead-code-hunter или dependency-auditor для обеспечения доступности Knip. Обрабатывает установку, создание конфигурации и проверку.
allowed-tools: Bash, Read, Write, Glob
---

# Настройка Knip

Установка и настройка Knip - инструмента для поиска неиспользуемых файлов, зависимостей и экспортов в проектах JavaScript/TypeScript.

## Когда использовать

- Перед запуском агента dead-code-hunter
- Перед запуском агента dependency-auditor
- Когда в проекте не настроен Knip
- При обновлении конфигурации Knip
- При предварительной проверке рабочих процессов проверки

## Инструкции

### Шаг 1: Проверка установки Knip

Проверить package.json на наличие knip в devDependencies.

**Используемые инструменты**: Read

```bash
# Прочитать package.json и проверить на наличие knip
```

**Логика проверки**:
- Если `devDependencies.knip` существует → Knip установлен
- Если не найден → Нужно установить

### Шаг 2: Установка Knip при отсутствии

Если Knip не установлен, добавить его как devDependency.

**Используемые инструменты**: Bash

```bash
# Определить менеджер пакетов
if [ -f "pnpm-lock.yaml" ]; then
  pnpm add -D knip
elif [ -f "yarn.lock" ]; then
  yarn add -D knip
elif [ -f "bun.lockb" ]; then
  bun add -D knip
else
  npm install -D knip
fi
```

**Ожидаемый вывод**:
```
+ knip@5.x.x
```

### Шаг 3: Проверка наличия конфигурации Knip

Поиск существующих файлов конфигурации Knip.

**Используемые инструменты**: Glob

**Файлы конфигурации** (в порядке приоритета):
1. `knip.json`
2. `knip.jsonc`
3. `knip.ts`
4. `knip.config.ts`
5. `knip.config.js`
6. `package.json` (поле knip)

### Шаг 4: Создание конфигурации по умолчанию при отсутствии

Если конфигурация не найдена, создать `knip.json` с разумными настройками по умолчанию.

**Используемые инструменты**: Write

**Конфигурация по умолчанию для стандартного проекта**:
```json
{
  "$schema": "https://unpkg.com/knip@5/schema.json",
  "entry": ["src/index.{ts,tsx,js,jsx}", "src/main.{ts,tsx,js,jsx}"],
  "project": ["src/**/*.{ts,tsx,js,jsx}"],
  "ignore": [
    "**/*.d.ts",
    "**/*.test.{ts,tsx}",
    "**/*.spec.{ts,tsx}",
    "**/test/**",
    "**/tests/**",
    "**/__tests__/**",
    "**/node_modules/**"
  ],
  "ignoreDependencies": [
    "@types/*"
  ]
}
```

**Конфигурация по умолчанию для проекта Next.js** (определяется по next в зависимостях):
```json
{
  "$schema": "https://unpkg.com/knip@5/schema.json",
  "entry": [
    "src/app/**/*.{ts,tsx}",
    "src/pages/**/*.{ts,tsx}",
    "app/**/*.{ts,tsx}",
    "pages/**/*.{ts,tsx}"
  ],
  "project": ["src/**/*.{ts,tsx}", "app/**/*.{ts,tsx}", "pages/**/*.{ts,tsx}"],
  "ignore": [
    "**/*.d.ts",
    "**/*.test.{ts,tsx}",
    "**/*.spec.{ts,tsx}",
    "**/node_modules/**"
  ],
  "next": {
    "entry": [
      "next.config.{js,ts,mjs}",
      "middleware.{js,ts}"
    ]
  }
}
```

**Конфигурация по умолчанию для монорепозитория** (определяется по workspaces в package.json):
```json
{
  "$schema": "https://unpkg.com/knip@5/schema.json",
  "workspaces": {
    "packages/*": {
      "entry": ["src/index.{ts,tsx,js,jsx}"],
      "project": ["src/**/*.{ts,tsx,js,jsx}"]
    },
    "apps/*": {
      "entry": ["src/index.{ts,tsx,js,jsx}", "src/main.{ts,tsx,js,jsx}"],
      "project": ["src/**/*.{ts,tsx,js,jsx}"]
    }
  },
  "ignore": [
    "**/*.d.ts",
    "**/*.test.{ts,tsx}",
    "**/*.spec.{ts,tsx}",
    "**/node_modules/**"
  ]
}
```

### Шаг 5: Добавление npm-скриптов при отсутствии

Проверить, есть ли в package.json скрипты knip, добавить при отсутствии.

**Используемые инструменты**: Read, Bash

**Добавляемые скрипты**:
```json
{
  "scripts": {
    "knip": "knip",
    "knip:fix": "knip --fix",
    "knip:deps": "knip --dependencies",
    "knip:exports": "knip --exports",
    "knip:files": "knip --files"
  }
}
```

**Добавление через npm pkg**:
```bash
npm pkg set scripts.knip="knip"
npm pkg set scripts.knip:fix="knip --fix"
npm pkg set scripts.knip:deps="knip --dependencies"
npm pkg set scripts.knip:exports="knip --exports"
npm pkg set scripts.knip:files="knip --files"
```

### Шаг 6: Проверка установки

Запустить Knip для проверки работоспособности установки.

**Используемые инструменты**: Bash

```bash
npx knip --help
```

**Ожидаемый результат**: Вывод справки без ошибок

### Шаг 7: Возврат результата

Вернуть структурированный результат, указывающий статус настройки.

**Ожидаемый вывод**:
```json
{
  "installed": true,
  "version": "5.x.x",
  "config_file": "knip.json",
  "config_created": true,
  "scripts_added": ["knip", "knip:fix", "knip:deps", "knip:exports", "knip:files"],
  "project_type": "nextjs|monorepo|standard",
  "ready": true
}
```

## Обработка ошибок

- **Установка не удалась**: Вернуть ошибку с выводом менеджера пакетов
- **Неверная конфигурация**: Вернуть ошибку с деталями проверки
- **Доступ запрещен**: Вернуть ошибку с предложением использовать sudo или исправить права
- **Ошибка сети**: Вернуть ошибку с предложением установки в автономном режиме

## Примеры

### Пример 1: Новый проект (без Knip)

**Начальное состояние**:
- package.json существует
- Нет knip в devDependencies
- Нет knip.json

**Действия**:
1. Установить knip через определенный менеджер пакетов
2. Определить тип проекта (стандартный)
3. Создать knip.json со значениями по умолчанию
4. Добавить npm-скрипты
5. Проверить установку

**Вывод**:
```json
{
  "installed": true,
  "version": "5.73.3",
  "config_file": "knip.json",
  "config_created": true,
  "scripts_added": ["knip", "knip:fix", "knip:deps", "knip:exports", "knip:files"],
  "project_type": "standard",
  "ready": true
}
```

### Пример 2: Проект Next.js с существующим Knip

**Начальное состояние**:
- package.json с зависимостью next
- knip уже в devDependencies
- knip.json существует

**Действия**:
1. Обнаружить установленный knip (пропустить установку)
2. Обнаружить существующую конфигурацию (пропустить создание)
3. Проверить скрипты (добавить отсутствующие)
4. Проверить установку

**Вывод**:
```json
{
  "installed": true,
  "version": "5.73.3",
  "config_file": "knip.json",
  "config_created": false,
  "scripts_added": ["knip:deps"],
  "project_type": "nextjs",
  "ready": true
}
```

### Пример 3: Проект монорепозитория

**Начальное состояние**:
- package.json с полем workspaces
- Нет knip

**Действия**:
1. Обнаружить монорепозиторий (workspaces в package.json)
2. Установить knip
3. Создать специфичный для монорепозитория knip.json
4. Добавить npm-скрипты
5. Проверить установку

**Вывод**:
```json
{
  "installed": true,
  "version": "5.73.3",
  "config_file": "knip.json",
  "config_created": true,
  "scripts_added": ["knip", "knip:fix", "knip:deps", "knip:exports", "knip:files"],
  "project_type": "monorepo",
  "ready": true
}
```

## Справочник команд Knip

Для агентов, использующих Knip после настройки:

| Команда | Назначение | Сценарий использования |
|---------|------------|------------------------|
| `npx knip` | Полный анализ | Полное сканирование мертвого кода |
| `npx knip --dependencies` | Только зависимости | dependency-auditor |
| `npx knip --exports` | Только экспорт | Обнаружение неиспользуемого экспорта |
| `npx knip --files` | Только файлы | Обнаружение неиспользуемых файлов |
| `npx knip --fix --fix-type exports,types` | Автоисправление экспорта/типов | Безопасная автоматическая очистка |
| `npx knip --fix --fix-type dependencies` | Автоисправление зависимостей | Удаление из package.json |
| `npx knip --reporter json` | Вывод JSON | Машинная обработка |
| `npx knip --reporter compact` | Компактный вывод | Быстрый обзор |

## КРИТИЧЕСКОЕ ПРЕДУПРЕЖДЕНИЕ О БЕЗОПАСНОСТИ

### НИКОГДА не использовать `--allow-remove-files`

**`npx knip --fix --allow-remove-files` ЗАПРЕЩЕНО!**

У Knip есть критическое ограничение: **он не может обнаруживать динамические импорты**.

```typescript
// Knip НЕ ВИДИТ эти отношения:
const module = await import(`./plugins/${name}.ts`);
const Component = lazy(() => import('./components/Dashboard'));
require(`./locales/${lang}.json`);
```

Файлы, загружаемые через динамические импорты, будут казаться Knip "неиспользуемыми", но на самом деле они критичны!

### Безопасное использование Knip

**РАЗРЕШЕНО**:
- `npx knip --fix --fix-type exports` - Безопасно: удаляет неиспользуемый экспорт из файлов
- `npx knip --fix --fix-type types` - Безопасно: удаляет неиспользуемый экспорт типов
- `npx knip --fix --fix-type dependencies` - Безопасно: удаляет только из package.json

**ЗАПРЕЩЕНО**:
- `npx knip --fix --allow-remove-files` - ОПАСНО: может удалить файлы с динамическими импортами
- `npx knip --fix` (без --fix-type) - Может включать удаление файлов

### Требуется ручная проверка

Перед удалением ЛЮБОГО файла, помеченного Knip:
1. Искать динамические импорты: `import(`, `require(`, `lazy(`, `loadable(`
2. Проверить интерполяцию строк в импортах
3. Убедиться, что файл не упоминается в конфигурационных файлах
4. Запустить сборку и тесты после удаления

## Интеграция с агентами

### Предварительная проверка dead-code-hunter

```markdown
## Фаза 0: Предварительная проверка

1. Использовать навык setup-knip, чтобы убедиться, что Knip доступен
2. Если result.ready === false, остановить с инструкциями по настройке
3. Если result.ready === true, продолжить обнаружение
```

### Предварительная проверка dependency-auditor

```markdown
## Фаза 1: Анализ среды

1. Использовать навык setup-knip перед анализом зависимостей
2. Knip обнаружит неиспользуемые зависимости точнее, чем ручной grep
```

## Примечания

- Требуется версия Knip 5.x (существенные улучшения по сравнению с v4)
- Конфигурация автоматически определяется для 100+ фреймворков
- Поддержка монорепозиториев первого класса
- Используйте `--reporter json` для машинно-читаемого вывода
- Флаг `--fix` может автоматически удалять неиспользуемый экспорт и зависимости
