#!/bin/bash
# SpecKit: Constitution Script
# Назначение: Создание конституции проекта
# Версия: 2.0.0 (Исправление: нет зависимости от SPEC_ID)

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECIFY_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SPECIFY_DIR")")"
TEMPLATES_DIR="$SPECIFY_DIR/templates"
LOGS_DIR="$PROJECT_ROOT/logs"

# constitution.md - ПЕРВАЯ команда!
# SPEC_ID генерируется автоматически (000-constitution)
SPEC_ID="${1:-000-constitution}"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Логирование
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."

    # constitution.md - ПЕРВАЯ команда, нет зависимостей!
    # Speckit стандарт: конституция создаётся до spec.md и tasks.md

    log_success "Зависимости проверены (нет зависимостей - первая команда)"
}

# Создание constitution.md
create_constitution() {
    local constitution_file="$PROJECT_ROOT/.qwen/specify/memory/constitution.md"

    log_info "Создание constitution.md..."

    cat > "$constitution_file" << EOF
# Project Constitution: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Версия:** 1.0.0
**Дата:** $(date +%Y-%m-%d)
**Статус:** Active

---

## 1. Принципы разработки

### 1.1 Основные ценности

1. **Простота** - Предпочитать простые решения сложным
2. **Читаемость** - Код читается чаще, чем пишется
3. **Тестируемость** - Нетестированный код не принимается
4. **Документированность** - Документация так же важна, как код
5. **Безопасность** - Security first подход

### 1.2 Принципы чистого кода

- **DRY** (Don't Repeat Yourself) - Избегать дублирования
- **KISS** (Keep It Simple, Stupid) - Сохранять простоту
- **YAGNI** (You Ain't Gonna Need It) - Не добавлять лишнее
- **SOLID** принципы:
  - Single Responsibility Principle
  - Open/Closed Principle
  - Liskov Substitution Principle
  - Interface Segregation Principle
  - Dependency Inversion Principle

### 1.3 Подходы к проектированию

- **Domain-Driven Design** - Моделирование на основе предметной области
- **Test-Driven Development** - Тесты перед кодом
- **Continuous Integration** - Частые интеграции
- **Incremental Development** - Постепенная разработка

---

## 2. Стандарты кода

### 2.1 Стиль кодирования

| Аспект | Стандарт |
|--------|----------|
| Язык | TypeScript/JavaScript |
| Форматирование | Prettier |
| Линтер | ESLint |
| Отступы | 2 пробела |
| Кавычки | Одинарные |
| Точка с запятой | Обязательно |
| Макс. длина строки | 100 символов |

### 2.2 Соглашения об именовании

| Элемент | Стиль | Пример |
|---------|-------|--------|
| Переменные | camelCase | \`userName\` |
| Функции | camelCase | \`getUserData()\` |
| Классы | PascalCase | \`UserService\` |
| Константы | UPPER_SNAKE_CASE | \`MAX_RETRY_COUNT\` |
| Файлы | kebab-case.ts | \`user-service.ts\` |
| Интерфейсы | PascalCase с I | \`IUser\` |
| Типы | PascalCase | \`UserType\` |
| Приватные члены | _prefix | \`_internalValue\` |

### 2.3 Требования к документации

1. **JSDoc для публичных API**
   \`\`\`typescript
   /**
    * Получает пользователя по ID
    * @param id - Уникальный идентификатор пользователя
    * @returns Promise с данными пользователя
    * @throws {UserNotFoundError} Если пользователь не найден
    */
   async getUser(id: string): Promise<User>
   \`\`\`

2. **README для каждого модуля**
   - Описание назначения
   - Примеры использования
   - Зависимости

3. **Комментарии для сложной логики**
   - Объяснение "почему", а не "что"
   - Ссылки на спецификации

### 2.4 Структура проекта

\`\`\`
project/
├── src/
│   ├── core/           # Ядро приложения
│   ├── features/       # Фичи
│   ├── shared/         # Общие утилиты
│   └── index.ts        # Точка входа
├── tests/
│   ├── unit/           # Unit тесты
│   ├── integration/    # Integration тесты
│   └── e2e/            # E2E тесты
├── docs/               # Документация
└── config/             # Конфигурация
\`\`\`

---

## 3. Архитектурные ограничения

### 3.1 Обязательные паттерны

| Паттерн | Применение | Описание |
|---------|------------|----------|
| Dependency Injection | Внедрение зависимостей | Через конструктор или IoC контейнер |
| Repository | Доступ к данным | Абстракция над хранилищем |
| Service | Бизнес-логика | Оркестрация репозиториев |
| Factory | Создание объектов | Инкапсуляция логики создания |
| Observer | Реактивность | Event-driven архитектура |

### 3.2 Запрещенные паттерны

| Паттерн | Причина запрета | Альтернатива |
|---------|-----------------|--------------|
| Глобальные переменные | Нарушение инкапсуляции | Dependency Injection |
| Singleton для бизнес-логики | Сложность тестирования | Factory + DI |
| Прямые импорты из node_modules | Coupling | Barrel exports |
| God Objects | Нарушение SRP | Разделение на компоненты |
| Circular dependencies | Проблемы сборки | Рефакторинг архитектуры |

### 3.3 Ограничения зависимостей

1. **Максимум зависимостей:** 50 пакетов
2. **Только активные пакеты:** Последнее обновление < 1 года
3. **Обязательная проверка:**
   - Security audit: \`npm audit\`
   - License check: допустимые лицензии
   - Size check: bundle size анализ

### 3.4 Модульность

- **Максимальный размер модуля:** 500 строк
- **Максимальная глубина вложенности:** 4 уровня
- **Максимальное количество импортов:** 15
- **Минимальное покрытие тестами:** 80%

---

## 4. Практики код-ревью

### 4.1 Требования к Pull Request

Чек-лист перед созданием PR:

- [ ] Все тесты проходят
- [ ] Coverage не уменьшился
- [ ] Документация обновлена
- [ ] Нет предупреждений линтера
- [ ] Нет ошибок типизации
- [ ] Изменения атомарны
- [ ] Сообщение коммита по Conventional Commits

### 4.2 Критерии приемки кода

| Критерий | Требование |
|----------|------------|
| Функциональность | Код выполняет задачу |
| Тесты | Покрытие ≥ 80% |
| Производительность | Нет очевидных проблем |
| Безопасность | Нет уязвимостей |
| Читаемость | Код понятен |
| Документация | JSDoc присутствует |

### 4.3 Процесс ревью

1. **Автор создает PR** с описанием изменений
2. **Автоматические проверки** (CI pipeline)
3. **Ревью от минимум 1 разработчика**
4. **Исправление замечаний**
5. **Аппрув и мерж**

### 4.4 Временные рамки

- **Время первого ревью:** ≤ 24 часов
- **Время мержа после аппрува:** ≤ 4 часов
- **Время жизни PR:** ≤ 3 дней

---

## 5. Безопасность

### 5.1 Обязательные практики

1. **Валидация входных данных** - Все input валидируется
2. **Экранирование output** - Защита от XSS
3. **Параметризованные запросы** - Защита от SQL injection
4. **HTTPS только** - Все соединения зашифрованы
5. **Без секретов в коде** - Secrets через environment variables

### 5.2 Запрещенные практики

- Хардкод credentials
- Логирование чувствительных данных
- Отключение security проверок
- Использование eval()

---

## 6. Непрерывная интеграция

### 6.1 CI Pipeline

\`\`\`yaml
stages:
  - lint      # Проверка стиля
  - typecheck # Проверка типов
  - test      # Запуск тестов
  - build     # Сборка
  - deploy    # Деплой
\`\`\`

### 6.2 Требования к pipeline

- Все стадии должны проходить
- Время выполнения ≤ 10 минут
- Артефакты сохраняются

---

## 7. Версионирование

### 7.1 Semantic Versioning

Формат: \`MAJOR.MINOR.PATCH\`

- **MAJOR:** Несовместимые изменения
- **MINOR:** Новая функциональность
- **PATCH:** Исправления ошибок

### 7.2 Conventional Commits

Формат: \`type(scope): description\`

Типы:
- \`feat\` - Новая функция
- \`fix\` - Исправление
- \`docs\` - Документация
- \`style\` - Форматирование
- \`refactor\` - Рефакторинг
- \`test\` - Тесты
- \`chore\` - Вспомогательные изменения

---

## 8. История изменений конституции

| Версия | Дата | Автор | Изменения |
|--------|------|-------|-----------|
| 1.0.0 | $(date +%Y-%m-%d) | | Initial version |
EOF
    
    log_success "constitution.md создан: $constitution_file"
}

# Создание coding-standards.md
create_coding_standards() {
    local standards_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/coding-standards.md"
    
    log_info "Создание coding-standards.md..."
    
    cat > "$standards_file" << EOF
# Coding Standards: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

---

## 1. TypeScript/JavaScript Standards

### 1.1 Базовые правила

\`\`\`typescript
// ✅ Хорошо
const userName = 'John';
function getUserData(id: string): Promise<User> { }
class UserService { }

// ❌ Плохо
const username = 'John';  // должно быть userName
function get_user_data(id) { }  // должно быть camelCase с типами
class userService { }  // должно быть PascalCase
\`\`\`

### 1.2 Типизация

\`\`\`typescript
// ✅ Хорошо - явные типы
interface User {
  id: string;
  name: string;
  email: string;
}

// ❌ Плохо - any
const data: any = getData();
\`\`\`

### 1.3 Обработка ошибок

\`\`\`typescript
// ✅ Хорошо
try {
  await userService.getUser(id);
} catch (error) {
  if (error instanceof UserNotFoundError) {
    logger.warn('User not found', { id });
    throw error;
  }
  logger.error('Unexpected error', { error });
  throw new InternalServerError();
}

// ❌ Плохо
try {
  await userService.getUser(id);
} catch (e) {
  console.log(e);
}
\`\`\`

---

## 2. Тестирование

### 2.1 Структура теста

\`\`\`typescript
describe('UserService', () => {
  describe('getUser', () => {
    it('должен вернуть пользователя по ID', async () => {
      // Arrange
      const userId = '123';
      const expectedUser = { id: userId, name: 'John' };
      
      // Act
      const result = await userService.getUser(userId);
      
      // Assert
      expect(result).toEqual(expectedUser);
    });
  });
});
\`\`\`

### 2.2 Покрытие

- Unit тесты: ≥ 80%
- Integration тесты: критические пути
- E2E тесты: основные сценарии

---

## 3. Документирование

### 3.1 JSDoc

\`\`\`typescript
/**
 * Сервис для управления пользователями
 */
export class UserService {
  /**
   * Получает пользователя по ID
   * @param id - Уникальный идентификатор
   * @returns Promise с данными пользователя
   * @throws {UserNotFoundError} Если пользователь не найден
   * @throws {ValidationError} Если ID некорректен
   */
  async getUser(id: string): Promise<User> { }
}
\`\`\`

---

## 4. Конфигурация

### 4.1 ESLint

\`\`\`json
{
  "extends": ["@typescript-eslint/recommended"],
  "rules": {
    "@typescript-eslint/explicit-function-return-type": "error",
    "@typescript-eslint/no-explicit-any": "error"
  }
}
\`\`\`

### 4.2 Prettier

\`\`\`json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5"
}
\`\`\`
EOF
    
    log_success "coding-standards.md создан: $standards_file"
}

# Создание architecture-rules.md
create_architecture_rules() {
    local rules_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/architecture-rules.md"
    
    log_info "Создание architecture-rules.md..."
    
    cat > "$rules_file" << EOF
# Architecture Rules: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

---

## 1. Слои архитектуры

\`\`\`
┌─────────────────────────────────────┐
│         Presentation Layer          │
│         (Controllers, Views)        │
├─────────────────────────────────────┤
│          Business Layer             │
│         (Services, Domain)          │
├─────────────────────────────────────┤
│          Data Access Layer          │
│       (Repositories, Models)        │
├─────────────────────────────────────┤
│         Infrastructure Layer        │
│      (Database, External APIs)      │
└─────────────────────────────────────┘
\`\`\`

### Правила зависимостей

- Presentation → Business → Data Access → Infrastructure
- Обратные зависимости только через интерфейсы
- Нет cross-layer импортов

---

## 2. Компоненты

### 2.1 Core компоненты

| Компонент | Ответственность | Зависимости |
|-----------|-----------------|-------------|
| UserService | Бизнес-логика пользователей | UserRepository |
| AuthController | HTTP endpoints аутентификации | AuthService |
| UserRepository | Доступ к данным пользователей | Database |

### 2.2 Shared компоненты

| Компонент | Ответственность |
|-----------|-----------------|
| Logger | Логирование |
| Config | Конфигурация |
| Utils | Утилиты |

---

## 3. Диаграмма компонентов

\`\`\`
┌──────────────┐     ┌──────────────┐
│   Controller │────▶│   Service    │
└──────────────┘     └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  Repository  │
                     └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │   Database   │
                     └──────────────┘
\`\`\`

---

## 4. Правила

1. **Одна ответственность** - Каждый класс имеет одну причину для изменения
2. **Инкапсуляция** - Внутренняя реализация скрыта
3. **Абстракция** - Зависимость от абстракций, не от реализаций
4. **Композиция** - Предпочитать композицию наследованию
EOF
    
    log_success "architecture-rules.md создан: $rules_file"
}

# Создание review-checklist.md
create_review_checklist() {
    local checklist_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/review-checklist.md"
    
    log_info "Создание review-checklist.md..."
    
    cat > "$checklist_file" << EOF
# Code Review Checklist: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

---

## Pre-PR Checklist (Автор)

### Код
- [ ] Код следует стандартам проекта
- [ ] Нет дублирования (DRY)
- [ ] Функции маленькие и фокусированные
- [ ] Нет мертвого кода
- [ ] Нет закомментированного кода

### Тесты
- [ ] Unit тесты написаны
- [ ] Все тесты проходят
- [ ] Coverage не уменьшился
- [ ] Тесты покрывают edge cases

### Документация
- [ ] JSDoc добавлен
- [ ] README обновлен
- [ ] Изменения документированы

### Безопасность
- [ ] Нет hardcoded secrets
- [ ] Input валидируется
- [ ] Нет уязвимостей

---

## Review Checklist (Ревьюер)

### Функциональность
- [ ] Код выполняет задачу
- [ ] Логика корректна
- [ ] Edge cases обработаны
- [ ] Ошибки обрабатываются

### Качество кода
- [ ] Код читаем
- [ ] Имена понятные
- [ ] Структура логична
- [ ] Нет излишней сложности

### Производительность
- [ ] Нет очевидных проблем
- [ ] Алгоритмы эффективны
- [ ] Нет утечек памяти

### Тесты
- [ ] Тесты покрывают функциональность
- [ ] Тесты читаемы
- [ ] Assert сообщения понятны

---

## Review Response Template

\`\`\`
## Review Summary
**Status:** ✅ Approved / 🔁 Changes Requested

## Comments
### 🎯 Critical
- 

### ⚠️ Important
- 

### 💡 Suggestions
- 

## Next Steps
- 
\`\`\`
EOF
    
    log_success "review-checklist.md создан: $checklist_file"
}

# Обновление состояния
update_state() {
    local state_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/state.json"
    
    log_info "Обновление состояния..."
    
    if command -v jq &> /dev/null && [ -f "$state_file" ]; then
        jq '.phase = "constitution_complete" | .commands.constitution = "completed"' \
            "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
    fi
    
    log_success "Состояние обновлено"
}

# Основная функция
main() {
    # constitution.md - ПЕРВАЯ команда!
    # SPEC_ID уже установлен в начале скрипта (000-constitution по умолчанию)
    # PROJECT_NAME уже установлен в начале скрипта

    echo "========================================"
    echo "  SpecKit: Constitution"
    echo "  Версия: 2.0.0"
    echo "  Spec ID: $SPEC_ID"
    echo "  Project: $PROJECT_NAME"
    echo "========================================"
    echo ""

    check_dependencies
    echo ""

    create_constitution
    echo ""

    create_coding_standards
    echo ""

    create_architecture_rules
    echo ""
    
    create_review_checklist
    echo ""
    
    update_state
    echo ""
    
    log_success "========================================"
    log_success "  Конституция создана!"
    log_success "  Файлы:"
    log_success "  - constitution.md"
    log_success "  - coding-standards.md"
    log_success "  - architecture-rules.md"
    log_success "  - review-checklist.md"
    log_success "  Следующий шаг: speckit.taskstoissues"
    log_success "========================================"
}

# Запуск
main "$@"
