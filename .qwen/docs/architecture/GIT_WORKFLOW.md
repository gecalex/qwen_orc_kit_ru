## СТРАТЕГИЯ GIT WORKFLOW

Дисциплинированная работа с Git — основа качества кода. Весь процесс управляется через **shell-команды с префиксом `!`**.

### 1.1. Общие принципы
-   **Атомарность коммитов**: Каждый коммит — одно логическое, завершённое изменение.
-   **Читаемая история**: Сообщения коммитов следуют Conventional Commits, ветки именуются по шаблону.
-   **Изоляция функциональности**: Любая новая фича, багфикс или эксперимент ведутся в отдельной ветке.
-   **Качество через процесс**: Вливание кода в основную ветку (`develop`) происходит только через Pull/Merge Request (PR/MR) после проверки.

### 1.2. Структура ветвления (Git Flow)
```
main          # Стабильная, продакшен-ветка. Обновляется только через релизы и хотфиксы.
develop       # Основная ветка интеграции. Сюда мержатся все завершённые фичи.
```
**Ветки-функции (feature/)**:
```bash
# Создание ветки для новой фичи от актуальной develop
!git checkout develop && git pull origin develop
!git checkout -b feature/short-description
# Пример: feature/add-jwt-auth, feature/refactor-plan-validator
```

**Ветки-исправления (bugfix/)**:
```bash
# Создание ветки для исправления бага, найденного в develop
!git checkout develop && git pull origin develop
!git checkout -b bugfix/describe-issue
# Пример: bugfix/fix-nullptr-in-agent, bugfix/correct-schema-validation
```

**Ветки-хотфиксы (hotfix/)**:
```bash
# СРОЧНОЕ исправление для main (продакшена)
!git checkout main && git pull origin main
!git checkout -b hotfix/critical-issue-name
!git push origin hotfix/critical-issue-name
# После исправления мержится и в main, и в develop.
```

### 1.3. Соглашения о коммитах (Conventional Commits)
**Структура сообщения**:
```
<type>(<scope>): <subject> # Обязательно
<BLANK LINE>
<body>                      # Опционально, но рекомендуется для нетривиальных изменений
<BLANK LINE>
<footer>                    # Опционально (ссылки на задачи, breaking changes)
```

**Основные типы (type)**:
-   `feat`: Новая функциональность.
-   `fix`: Исправление бага.
-   `docs`: Изменения в документации.
-   `style`: Изменения, не влияющие на логику (форматирование, пробелы).
-   `refactor`: Рефакторинг кода без изменения поведения.
-   `test`: Добавление или исправление тестов.
-   `chore`: Обновление зависимостей, настроек сборки и т.п.

**Примеры отличных коммитов**:
```
feat(orchestrator): добавить базовую команду `task` для делегирования

- Реализован парсинг JSON-конфига для команды `task`
- Добавлена валидация полей `subagent_type` и `prompt`
- Интегрирован вызов под-агентов через единый интерфейс

Closes #15
```
```
fix(auth): исправить утечку памяти в валидаторе JWT

Использование глобального кэша без TTL приводило к линейному росту
потребления памяти. Заменён на LRU-кэш с лимитом в 1000 записей.

Fixes #42
```

**Процесс создания правильного коммита в Qwen CLI**:
```bash
# 1. Проверить статус
!git status
# 2. Добавить изменения (избегайте слепого `git add .`)
!git add path/to/changed_file.py
# 3. Создать коммит с соблюдением конвенции
!git commit -m "feat(agent): добавить обработку таймаутов в task runner"
# 4. Отправить ветку в удалённый репозиторий
!git push origin feature/your-branch-name
```

### 1.4. Процесс код-ревью и влития (Pull Request)
1.  **Запрос на влитие (PR)**: Создаётся после завершения работы в ветке.
2.  **Описание PR**: Должно содержать:
    -   **Что сделано и зачем** (связь с задачей).
    -   **Как тестировать** (конкретные шаги, команды).
    -   **Контрольный список** (чеклист) перед мержем.
3.  **Контрольный список для каждого PR**:
    ```
    - [ ] Код соответствует стилю проекта (линтеры пройдены).
    - [ ] Добавлены или обновлены тесты, если это необходимо.
    - [ ] Документация (комментарии, README, etc.) обновлена.
    - [ ] Все CI-проверки (тесты, сборка) проходят успешно.
    - [ ] Получено как минимум одно одобрение (`approve`) от коллеги.
    ```
4.  **Мерж PR**: После прохождения ревью и CI выполняется слияние. **Предпочтительнее `Squash and Merge`** для поддержания чистоты истории.

### 1.5. Стандарты стиля кода и инструменты качества

**Для Python (современный стек: Ruff, mypy, uv)**:
-   **Отступ**: 4 пробела.
-   **Длина строки**: 88 символов (стандарт Ruff/Black).
-   **Именование**:
    -   `snake_case` для функций, переменных, методов, модулей.
    -   `PascalCase` для классов, исключений.
    -   `UPPER_SNAKE_CASE` для констант.
-   **Импорты**: Группировка и сортировка автоматически через `ruff format --check` и `ruff check --fix`. Стандартный порядок: будущие импорты, стандартная библиотека, сторонние пакеты, локальные модули.
-   **Типизация**: **Обязательно** использовать аннотации типов. Строгая проверка через `mypy`.

**Инструментарий и команды для Python**:
-   **`uv`**: Используется для создания виртуального окружения, установки зависимостей и управления скрипстами.
    ```bash
    # Инициализация проекта (если еще нет pyproject.toml)
    !uv init --python 3.11

    # Активация виртуального окружения (автоматическая в uv)
    # Установка зависимостей для разработки
    !uv add --dev ruff mypy pytest
    !uv add fastapi pydantic  # пример prod-зависимостей
    ```

-   **`ruff`**: Универсальный инструмент для линтинга (заменяет flake8, pycodestyle) и форматирования (заменяет black, isort).
    ```bash
    # Запустить форматирование и исправить все исправимые нарушения
    !ruff check workspace/src/ --fix
    !ruff format workspace/src/

    # Проверить без исправлений (для CI)
    !ruff check workspace/src/ --output-format=github  # или simple
    !ruff format workspace/src/ --check
    ```

-   **`mypy`**: Статическая проверка типов. Конфигурация в `pyproject.toml` или `mypy.ini`.
    ```bash
    # Строгая проверка типов
    !mypy workspace/src/

    # Пример менее строгой конфигурации для легаси-кода
    !mypy workspace/src/ --ignore-missing-imports
    ```

**Пример `pyproject.toml` с конфигурацией для Python**:
```toml
[project]
name = "qwen-orchestrator"
version = "0.1.0"
dependencies = [
    "pydantic>=2.0",
    "fastapi>=0.104.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
# Конфигурация uv (если используется как пакетный менеджер)

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = [
    "E",  # pycodestyle errors
    "W",  # pycodestyle warnings
    "F",  # pyflakes
    "I",  # isort
    "UP", # pyupgrade
]
ignore = ["E501"]  # Игнорировать длину строки, если она проверяется форматером

[tool.ruff.format]
quote-style = "double"
line-ending = "auto"

[tool.mypy]
python_version = "3.11"
strict = true
ignore_missing_imports = true  # Отключить для продакшена
warn_return_any = true
warn_unused_configs = true
```

**Полный пайплайн перед коммитом для Python-проекта**:
```bash
# 1. Активируем окружение и убеждаемся, что инструменты установлены
!uv sync --dev

# 2. Запускаем форматирование и линтинг
!ruff check workspace/src/ --fix --exit-non-zero-on-fix
!ruff format workspace/src/

# 3. Проверяем типы
!mypy workspace/src/

# 4. Запускаем тесты (если есть)
!uv run pytest workspace/tests/ -v

# 5. Если все проверки пройдены, можно коммитить
!git add .
!git commit -m "feat(api): добавить эндпоинт healthz с проверкой типов"
```

**Для TypeScript/JavaScript**:
-   **Отступ**: 2 пробела.
-   **Длина строки**: 80-100 символов (настраивается в Prettier).
-   **Именование**:
    -   `camelCase` для переменных, функций, методов.
    -   `PascalCase` для классов, интерфейсов, типов, компонентов React.
    -   `UPPER_SNAKE_CASE` для констант.
-   **Фигурные скобки**: K&R стиль (открывающая на той же строке).
-   **Кавычки**: Одинарные (`'`) для JS/TS, если нет необходимости в интерполяции.
-   **Типизация**: **Обязательно** использовать TypeScript с strict режимом.

**Инструментарий и команды для TypeScript/JavaScript**:
-   **`pnpm`**: Предпочтительный пакетный менеджер (или `npm`).
    ```bash
    # Инициализация проекта
    !pnpm init

    # Установка зависимостей для разработки
    !pnpm add -D typescript prettier eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser
    !pnpm add express  # пример prod-зависимости
    ```

-   **`prettier`**: Форматирование кода.
    ```bash
    # Форматирование всех файлов
    !pnpm prettier --write "workspace/src/**/*.{ts,tsx,js,jsx}"

    # Проверка форматирования (для CI)
    !pnpm prettier --check "workspace/src/**/*.{ts,tsx,js,jsx}"
    ```

-   **`eslint`**: Линтинг кода с поддержкой TypeScript.
    ```bash
    # Запустить линтинг с автоматическим исправлением
    !pnpm eslint "workspace/src/**/*.{ts,tsx}" --fix

    # Проверка без исправлений (для CI)
    !pnpm eslint "workspace/src/**/*.{ts,tsx}" --max-warnings=0
    ```

-   **`tsc`**: Проверка типов TypeScript.
    ```bash
    # Проверка типов без генерации файлов
    !pnpm tsc --noEmit --project workspace/

    # Сборка проекта (если нужно)
    !pnpm tsc --project workspace/
    ```

**Пример `tsconfig.json` для TypeScript**:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts", "**/*.spec.ts"]
}
```

**Полный пайплайн перед коммитом для TypeScript-проекта**:
```bash
# 1. Убедиться, что зависимости установлены
!pnpm install

# 2. Проверить форматирование и применить автоматические исправления
!pnpm prettier --write "workspace/src/**/*.{ts,tsx,js,jsx}"
!pnpm eslint "workspace/src/**/*.{ts,tsx}" --fix

# 3. Проверить типы
!pnpm tsc --noEmit --project workspace/

# 4. Запустить тесты
!pnpm test

# 5. Если все проверки пройдены, можно коммитить
!git add .
!git commit -m "feat(ui): добавить компонент Table с виртуализацией"
```

### 1.6. Безопасность и секреты
-   **НИКОГДА** не коммитьте:
    -   Пароли, API-ключи, токены доступа.
    -   Приватные SSH-ключи или сертификаты.
    -   Файлы `.env` с продакшен-переменными.
-   **Обязательно**: Добавьте шаблоны в `.gitignore`:
    ```
    # Секреты и конфиги
    .env
    .env.local
    *.pem
    *.key
    # Системные файлы
    __pycache__/
    node_modules/
    .DS_Store
    # Артефакты сборки и логи
    dist/
    build/
    *.log
    # Инструменты Python
    .venv/
    .mypy_cache/
    .ruff_cache/
    .pytest_cache/
    # Инструменты TypeScript
    *.tsbuildinfo
    ```
-   **Проверка истории**: Перед публикацией репозитория проверьте историю на случайно закоммиченные секреты с помощью инструментов вроде `git-secrets` или `truffleHog`.

### 1.7. Начало работы с новым проектом (первая задача оркестратора)
Когда оркестратор начинает работу с чистым или существующим репозиторием, **первой задачей** должно быть настройка этого workflow.
1.  **Делегируйте агенту `backend_dev` или `code-quality-checker`**:
    ```bash
    task '{
      "subagent_type": "code-quality-checker",
      "description": "Инициализировать Git workflow и конфигурацию качества кода",
      "prompt": "В корне проекта `workspace/`: 1. Инициализируй git репозиторий, если его нет. 2. Создай файлы `.gitignore` (для Python/TS), `.prettierrc`, `.eslintrc.js` (если TS), `pyproject.toml` с настройками ruff и mypy (если Python), `tsconfig.json` (если TS). 3. Создай базовую структуру веток (`main`, `develop`). 4. Создай `CONTRIBUTING.md` с кратким описанием этого workflow. Все изменения должны быть закоммичены в ветку `develop` с соответствующими сообщениями (feat, chore)."
    }'
    ```
