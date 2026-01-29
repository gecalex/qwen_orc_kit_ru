# 🏗️ Обзор архитектуры

## Содержание

- [Системная архитектура](#системная-архитектура)
- [Отношения компонентов](#отношения-компонентов)
- [Паттерны рабочих процессов](#паттерны-рабочих-процессов)
- [Структура файлов](#структура-файлов)
- [Поток данных](#поток-данных)
- [Принципы проектирования](#принципы-проектирования)

---

## Системная архитектура

### Обзор высокого уровня

```mermaid
graph TB
    User[👤 Пользователь] -->|Команды с префиксом /| Claude[Claude Code]
    Claude -->|Вызывает| Orchestrator[🎼 Оркестратор]
    Claude -->|Вызывает| SimpleAgent[🤖 Простой агент]

    Orchestrator -->|Создаёт| Plan[📋 Файл плана]
    Plan -->|Руководит| Worker[⚙️ Агент-воркер]
    Worker -->|Использует| Skills[🎯 Навыки]
    Worker -->|Генерирует| Report[📄 Отчёт]

    Report -->|Валидирует| QualityGate[✅ Контрольная точка качества]
    QualityGate -->|Проход| NextPhase[Следующая фаза]
    QualityGate -->|Провал| Rollback[🔄 Откат]

    Skills -->|Валидирует| MCP[🔌 MCP-серверы]
    MCP -->|Context7| LibDocs[📚 Документация библиотек]
    MCP -->|Supabase| Database[🗄️ База данных]
    MCP -->|Другие| ExternalAPI[🌐 Внешние API]

    style Orchestrator fill:#4A90E2
    style Worker fill:#50C878
    style Skills fill:#FFB347
    style MCP fill:#9B59B6
```

---

## Отношения компонентов

### Экосистема агентов

```mermaid
graph LR
    subgraph "Типы агентов"
        O[Оркестратор<br/>Координирует рабочий процесс]
        W[Воркер<br/>Выполняет задачи]
        S[Простой агент<br/>Автономный инструмент]
    end

    subgraph "Утилиты"
        SK[Навыки<br/>Переиспользуемые функции]
        QG[Контрольные точки качества<br/>Валидация]
    end

    subgraph "Инфраструктура"
        MCP[MCP-серверы<br/>Внешние сервисы]
        FS[Файловая система<br/>Планы, отчёты, логи]
    end

    O -->|Создаёт план| FS
    FS -->|Читает план| W
    W -->|Генерирует отчёт| FS
    FS -->|Валидирует| QG

    W -->|Вызывает| SK
    O -->|Вызывает| SK
    S -->|Вызывает| SK

    W -->|Использует| MCP
    S -->|Использует| MCP

    style O fill:#4A90E2,color:#fff
    style W fill:#50C878,color:#fff
    style S fill:#9370DB,color:#fff
    style SK fill:#FFB347
    style QG fill:#E74C3C,color:#fff
    style MCP fill:#9B59B6,color:#fff
```

### Иерархия категорий

```mermaid
graph TD
    Root[.claude/agents/] --> Health[health/]
    Root --> Development[development/]
    Root --> Testing[testing/]
    Root --> Database[database/]
    Root --> Infrastructure[infrastructure/]
    Root --> Frontend[frontend/]
    Root --> Documentation[documentation/]
    Root --> Research[research/]
    Root --> Meta[meta/]

    Health --> HO[orchestrators/]
    Health --> HW[workers/]

    HO --> BO[bug-orchestrator]
    HO --> SO[security-orchestrator]
    HO --> DO[dependency-orchestrator]
    HO --> DCO[dead-code-orchestrator]

    HW --> BH[bug-hunter]
    HW --> BF[bug-fixer]
    HW --> SS[security-scanner]
    HW --> DA[dependency-auditor]

    style Health fill:#E74C3C,color:#fff
    style Development fill:#3498DB,color:#fff
    style Meta fill:#9B59B6,color:#fff
```

---

## Паттерны рабочих процессов

### 1. Паттерн возврата управления (PD-1)

**Основной паттерн**, предотвращающий вложенность контекста:

```mermaid
sequenceDiagram
    participant User
    participant Main as Основная сессия
    participant Orch as Оркестратор
    participant FS as Файловая система
    participant Worker

    User->>Main: /health-bugs
    Main->>Orch: Вызов оркестратора

    Note over Orch: Фаза 0: Предварительная проверка
    Orch->>FS: Настройка .tmp/current/

    Note over Orch: Фаза 1: Создание плана
    Orch->>FS: Запись .bug-plan.json
    Orch->>Main: "Готов к bug-hunter" + ВЫХОД

    Note over Main: Пользователь видит сигнал
    Main->>Worker: Вызов bug-hunter

    Note over Worker: Чтение плана, выполнение, валидация
    Worker->>FS: Запись bug-hunting-report.md
    Worker->>Main: Сводка отчёта + ВЫХОД

    Note over Main: Пользователь видит завершение
    Main->>Orch: Возобновление оркестратора

    Note over Orch: Контрольная точка 1
    Orch->>FS: Чтение bug-hunting-report.md
    Orch->>Orch: Валидация (type-check, сборка)

    alt Контрольная точка ПРОЙДЕНА
        Note over Orch: Фаза 2: Создание плана исправления
        Orch->>FS: Запись .bug-fix-plan.json
        Orch->>Main: "Готов к bug-fixer" + ВЫХОД
    else Контрольная точка ПРОВАЛЕНА
        Orch->>Main: ОСТАНОВКА + Отчёт об ошибке
    end
```

**Почему возврат управления?**
- ✅ Предотвращает вложенность контекста (контекст воркера остаётся изолированным)
- ✅ Обеспечивает возможность отката (чёткое разделение фаз)
- ✅ Предотвращает бесконечные циклы (основная сессия управляет вызовами)
- ✅ Видимость для пользователя (видит завершение каждой фазы)

---

### 2. Паттерн контрольной точки качества

```mermaid
graph LR
    Start[Воркер<br/>Завершает работу] --> Report[Генерация<br/>отчёта]
    Report --> QG{Контрольная точка качества}

    QG -->|Проверка типов| TC[npm run type-check]
    QG -->|Сборка| B[npm run build]
    QG -->|Тесты| T[npm run test]

    TC --> TCR{Проход?}
    B --> BR{Проход?}
    T --> TR{Проход?}

    TCR -->|Да| Check2[Следующая проверка]
    TCR -->|Нет<br/>Блокирующая| Fail[ОСТАНОВКА рабочего процесса]

    BR -->|Да| Check3[Следующая проверка]
    BR -->|Нет<br/>Блокирующая| Fail

    TR -->|Да| Success[✅ Продолжить]
    TR -->|Нет<br/>Опциональная| Warning[⚠️ Логировать предупреждение<br/>Продолжить]

    Fail --> Rollback[Откат изменений]
    Rollback --> UserPrompt[Спросить пользователя:<br/>Исправить или пропустить?]

    style QG fill:#E74C3C,color:#fff
    style Success fill:#50C878,color:#fff
    style Fail fill:#C0392B,color:#fff
    style Warning fill:#F39C12
```

**Конфигурация контрольной точки качества** в файлах плана:

```json
{
  "validation": {
    "required": ["проверка типов", "сборка"],
    "optional": ["тесты", "линт"]
  }
}
```

---

### 3. Паттерн итеративного рабочего процесса

```mermaid
stateDiagram-v2
    [*] --> PreFlight: Запуск оркестратора

    PreFlight --> IterationCheck: Настройка завершена

    IterationCheck --> Discovery: итерация < макс
    IterationCheck --> FinalSummary: итерация >= макс

    Discovery --> QualityGate1: Воркер завершает работу
    QualityGate1 --> Implementation: ПРОХОД
    QualityGate1 --> Rollback: ПРОВАЛ

    Implementation --> QualityGate2: Воркер завершает работу
    QualityGate2 --> PostIteration: ПРОХОД
    QualityGate2 --> Rollback: ПРОВАЛ

    PostIteration --> Archive: Вся работа завершена
    PostIteration --> IterationCheck: Работа осталась

    Rollback --> UserDecision: Изменения откачены
    UserDecision --> IterationCheck: Исправление применено
    UserDecision --> FinalSummary: Запрошено прерывание

    Archive --> FinalSummary
    FinalSummary --> [*]: Рабочий процесс завершён

    note right of IterationCheck
        Макс итераций: 3-10
        Предотвращает бесконечные циклы
    end note

    note right of QualityGate1
        Блокирующие: проверка типов, сборка
        Опциональные: тесты
    end note
```

**Пример**: bug-orchestrator запускает до 3 итераций:
1. Итерация 1: Найти баги → Исправить критические/высокие
2. Итерация 2: Проверка верификации → Исправить оставшиеся
3. Итерация 3: Финальная проверка → Отчёт

---

## Структура файлов

### Структура директорий

```mermaid
graph TB
    subgraph "Источник истины (Git)"
        Claude[.claude/]
        Agents[agents/]
        Commands[commands/]
        Skills[skills/]
        Scripts[scripts/]
        Schemas[schemas/]
    end

    subgraph "Во время выполнения (Git-игнорируемые)"
        Tmp[.tmp/]
        Current[current/]
        Plans[plans/]
        Reports[reports/]
        Changes[changes/]
        Backups[backups/]
        Archive[archive/]
    end

    subgraph "Конфигурация"
        MCP[.mcp.json]
        Env[.env.local]
        BehavioralOS[CLAUDE.md]
    end

    Claude --> Agents
    Claude --> Commands
    Claude --> Skills
    Claude --> Scripts
    Claude --> Schemas

    Tmp --> Current
    Tmp --> Archive
    Current --> Plans
    Current --> Reports
    Current --> Changes
    Current --> Backups

    style Claude fill:#4A90E2,color:#fff
    style Tmp fill:#E74C3C,color:#fff
    style MCP fill:#9B59B6,color:#fff
```

### Поток файлов во время рабочего процесса

```mermaid
sequenceDiagram
    participant O as Оркестратор
    participant P as .tmp/current/plans/
    participant W as Воркер
    participant C as .tmp/current/changes/
    participant B as .tmp/current/backups/
    participant R as .tmp/current/reports/
    participant A as .tmp/archive/

    Note over O: Фаза 1: Создание плана
    O->>P: Запись .workflow-plan.json

    Note over W: Фаза 2: Выполнение
    W->>P: Чтение .workflow-plan.json
    W->>B: Резервное копирование файлов перед редактированием
    W->>W: Изменение файлов
    W->>C: Логирование изменений
    W->>R: Запись report.md

    Note over O: Фаза 3: Валидация
    O->>R: Чтение report.md
    O->>O: Запуск контрольных точек качества

    alt Успех
        O->>A: Архивирование запуска (по времени)
        A->>A: Копирование планов, отчётов, изменений
    else Провал
        O->>C: Чтение лога изменений
        O->>B: Восстановление резервных копий
        O->>C: Очистка лога изменений
    end
```

---

## Поток данных

### Файл плана → Воркер → Отчёт

```mermaid
graph LR
    subgraph "Ввод: Файл плана"
        P1[фаза: 2]
        P2[конфиг:<br/>приоритет, область]
        P3[валидация:<br/>обязательные, опциональные]
        P4[mcpGuidance:<br/>рекомендуемые серверы]
        P5[nextAgent:<br/>имя-воркера]
    end

    subgraph "Обработка: Воркер"
        W1[Чтение плана]
        W2[Выполнение задач]
        W3[Логирование изменений]
        W4[Валидация работы]
        W5[Генерация отчёта]
    end

    subgraph "Вывод: Отчёт"
        R1[Заголовок:<br/>временная метка, статус]
        R2[Итоговое резюме]
        R3[Выполненная работа]
        R4[Сделанные изменения]
        R5[Результаты валидации]
        R6[Следующие шаги]
    end

    P1 & P2 & P3 & P4 & P5 --> W1
    W1 --> W2
    W2 --> W3
    W3 --> W4
    W4 --> W5
    W5 --> R1 & R2 & R3 & R4 & R5 & R6

    style P1 fill:#3498DB
    style W1 fill:#50C878
    style R1 fill:#9B59B6
```

### Интеграция MCP-сервера

```mermaid
graph TB
    Worker[Агент-воркер] -->|Нужна документация библиотек?| Context7Decision{Использовать Context7?}
    Worker -->|Нужна база данных?| SupabaseDecision{Использовать Supabase?}
    Worker -->|Нужны UI-компоненты?| ShadcnDecision{Использовать shadcn?}

    Context7Decision -->|Да| Context7[mcp__context7__*]
    Context7Decision -->|Нет| DirectCode[Использовать общие знания]

    SupabaseDecision -->|Да| Supabase[mcp__supabase__*]
    SupabaseDecision -->|Нет| DirectCode

    ShadcnDecision -->|Да| Shadcn[mcp__shadcn__*]
    ShadcnDecision -->|Нет| DirectCode

    Context7 -->|Запрос| Upstash[Upstash API]
    Supabase -->|Запрос| SupabaseAPI[Supabase Management API]
    Shadcn -->|Запрос| Registry[Реестр компонентов]

    Upstash -->|Возврат документов| Context7
    SupabaseAPI -->|Возврат схемы| Supabase
    Registry -->|Возврат компонентов| Shadcn

    Context7 & Supabase & Shadcn & DirectCode --> Implementation[Реализация решения]

    style Context7 fill:#3498DB,color:#fff
    style Supabase fill:#50C878,color:#fff
    style Shadcn fill:#9B59B6,color:#fff
```

---

## Принципы проектирования

### 1. Единственная ответственность

**Каждый компонент имеет одну ясную цель:**

```mermaid
graph LR
    O[Оркестратор:<br/>Координация рабочего процесса]
    W[Воркер:<br/>Выполнение задач]
    S[Навык:<br/>Утилитарная функция]
    Q[Контрольная точка качества:<br/>Валидация кода]

    O -.->|Создаёт| Plan[Файл плана]
    Plan -.->|Руководит| W
    W -.->|Использует| S
    W -.->|Генерирует| Report[Отчёт]
    Report -.->|Проверяется| Q

    style O fill:#4A90E2,color:#fff
    style W fill:#50C878,color:#fff
    style S fill:#FFB347
    style Q fill:#E74C3C,color:#fff
```

**Анти-паттерн**: Оркестратор выполняет реализационную работу (нарушает SRP)

---

### 2. Разделение ответственности

```mermaid
graph TB
    subgraph "Слой координации"
        Orchestrator[Оркестраторы<br/>Планирование и координация]
    end

    subgraph "Слой выполнения"
        Workers[Воркеры<br/>Выполнение и отчётность]
    end

    subgraph "Слой утилит"
        Skills[Навыки<br/>Переиспользуемая логика]
    end

    subgraph "Слой валидации"
        Gates[Контрольные точки качества<br/>Проверка качества]
    end

    subgraph "Слой инфраструктуры"
        MCP[MCP-серверы<br/>Внешние сервисы]
        FS[Файловая система<br/>Управление состоянием]
    end

    Orchestrator --> Workers
    Workers --> Skills
    Workers --> Gates
    Workers --> MCP
    Workers --> FS
    Skills --> FS

    style Orchestrator fill:#4A90E2,color:#fff
    style Workers fill:#50C878,color:#fff
    style Skills fill:#FFB347
    style Gates fill:#E74C3C,color:#fff
    style MCP fill:#9B59B6,color:#fff
```

---

### 3. Быстрый отказ с откатом

```mermaid
graph TD
    Start[Начало работы] --> Backup[Резервное копирование файлов]
    Backup --> Changes[Отслеживание изменений]
    Changes --> Work[Изменение файлов]
    Work --> Validate{Валидация}

    Validate -->|Проход| Commit[Фиксация изменений]
    Validate -->|Провал| Rollback[Откат]

    Rollback --> RestoreBackups[Восстановление резервных копий]
    RestoreBackups --> ClearLogs[Очистка логов изменений]
    ClearLogs --> Report[Отчёт о провале]

    Commit --> CleanupBackups[Очистка резервных копий]
    CleanupBackups --> Success[Успех]

    style Validate fill:#E74C3C,color:#fff
    style Rollback fill:#C0392B,color:#fff
    style Success fill:#50C878,color:#fff
```

**Реализация**:
- Все изменения логируются в `.tmp/current/changes/*.json`
- Оригинальные файлы резервируются в `.tmp/current/backups/`
- Навык `rollback-changes` откатывает все модификации

---

### 4. Наблюдаемые рабочие процессы

```mermaid
sequenceDiagram
    participant User
    participant Orch as Оркестратор
    participant TODO as TodoWrite
    participant Worker
    participant Report as Отчёты

    User->>Orch: Запуск рабочего процесса

    Orch->>TODO: Фаза 1: Обнаружение (в_процессе)
    Note over Orch: Пользователь видит: "Обнаружение багов в кодовой базе"

    Orch->>Worker: Вызов bug-hunter
    Worker->>Report: Генерация отчёта
    Worker-->>User: "Найдено 45 багов (12 критических, 18 высоких...)"

    Orch->>TODO: Фаза 1: Обнаружение (завершено)
    Orch->>TODO: Фаза 2: Исправление критических (в_процессе)
    Note over Orch: Пользователь видит: "Исправление багов критического приоритета"

    Orch->>Worker: Вызов bug-fixer
    Worker->>Report: Генерация отчёта об исправлениях
    Worker-->>User: "Исправлено 12 критических багов, 0 неудачных"

    Orch->>TODO: Фаза 2: Исправление критических (завершено)
```

**Функции наблюдаемости**:
- Обновления TodoWrite (прогресс в реальном времени)
- Выполнение по фазам (чёткие этапы)
- Подробные отчёты (аудит-трак)
- Запросы пользователю при критических решениях

---

### 5. Плавная деградация

```mermaid
graph TD
    Start[Воркер запускается] --> CheckMCP{MCP доступен?}

    CheckMCP -->|Context7 доступен| UseContext7[Использовать Context7 для валидации]
    CheckMCP -->|Context7 недоступен| Fallback[Использовать общие знания]

    UseContext7 --> HighConfidence[Результаты с высокой уверенностью]
    Fallback --> LowerConfidence[Ниже уверенность + Предупреждение]

    HighConfidence --> Report[Генерация отчёта]
    LowerConfidence --> Report

    Report --> Status{Общий статус}
    Status -->|Все MCP доступны| FullSuccess[✅ ПРОЙДЕНО]
    Status -->|Некоторые MCP недоступны| PartialSuccess[⚠️ ПРОЙДЕНО С ПРЕДУПРЕЖДЕНИЯМИ]
    Status -->|Критические MCP недоступны| Failure[❌ ПРОВАЛЕНО]

    style UseContext7 fill:#50C878,color:#fff
    style Fallback fill:#F39C12
    style FullSuccess fill:#27AE60,color:#fff
    style PartialSuccess fill:#F39C12
    style Failure fill:#E74C3C,color:#fff
```

**Стратегия отката**:
- Context7 недоступен → Использовать общие знания + уменьшить уверенность
- Провал контрольной точки качества → Запрос пользователю (исправить/пропустить/прервать)
- Макс итераций → Генерация сводки с частичными результатами
- Бюджет токенов исчерпан → Упрощённый режим → Аварийный выход

---

## Архитектура конфигурации MCP

### Уровни конфигурации

```mermaid
graph TB
    subgraph "BASE (~600 токенов)"
        B1[Context7<br/>Документация библиотек]
        B2[Sequential Thinking<br/>Улучшенные рассуждения]
    end

    subgraph "SUPABASE (~2500 токенов)"
        S1[Context7]
        S2[Sequential Thinking]
        S3[Supabase<br/>Доступ к базе данных]
    end

    subgraph "FULL (~5000 токенов)"
        F1[Context7]
        F2[Sequential Thinking]
        F3[Supabase основной]
        F4[Supabase устаревший]
        F5[n8n рабочие процессы]
        F6[n8n MCP]
        F7[Playwright<br/>Автоматизация браузера]
        F8[shadcn<br/>UI-компоненты]
    end

    BASE --> SUPABASE
    SUPABASE --> FULL

    style BASE fill:#27AE60,color:#fff
    style SUPABASE fill:#3498DB,color:#fff
    style FULL fill:#9B59B6,color:#fff
```

### Дерево принятия решений по выбору конфигурации

```mermaid
graph TD
    Start{Что вы создаёте?}

    Start -->|Общая разработка| CheckDB{Работа с базой данных?}
    Start -->|UI/UX| Frontend[FRONTEND конфигурация]
    Start -->|Автоматизация| N8N[N8N конфигурация]
    Start -->|Всё| Full[FULL конфигурация]

    CheckDB -->|Да| CheckMulti{Несколько проектов?}
    CheckDB -->|Нет| Base[BASE конфигурация]

    CheckMulti -->|Да| SupabaseFull[SUPABASE-FULL конфигурация]
    CheckMulti -->|Нет| Supabase[SUPABASE конфигурация]

    style Base fill:#27AE60,color:#fff
    style Supabase fill:#3498DB,color:#fff
    style SupabaseFull fill:#E67E22,color:#fff
    style Frontend fill:#E74C3C,color:#fff
    style N8N fill:#9B59B6,color:#fff
    style Full fill:#34495E,color:#fff
```

---

## Архитектура поведенческой ОС (CLAUDE.md)

### Обеспечение основных директив

```mermaid
graph TB
    AgentStart[Агент вызван] --> SelfDiag{Самодиагностика}

    SelfDiag --> CheckPD1{PD-1:<br/>Возврат управления?}
    SelfDiag --> CheckPD2{PD-2:<br/>Контрольные точки качества?}
    SelfDiag --> CheckPD3{PD-3:<br/>Логирование изменений?}
    SelfDiag --> CheckPD4{PD-4:<br/>Валидация Context7?}

    CheckPD1 -->|Соответствует| CheckPD2
    CheckPD1 -->|Нарушает| Halt1[ОСТАНОВКА: Нельзя вызывать воркеров через Task]

    CheckPD2 -->|Соответствует| CheckPD3
    CheckPD2 -->|Нарушает| Halt2[ОСТАНОВКА: Нельзя пропускать блокирующие контрольные точки]

    CheckPD3 -->|Соответствует| CheckPD4
    CheckPD3 -->|Нарушает| Halt3[ОСТАНОВКА: Должен логировать все изменения]

    CheckPD4 -->|Соответствует| Execute[✅ Выполнить работу]
    CheckPD4 -->|Нарушает| Halt4[ОСТАНОВКА: Должен валидировать с Context7]

    Halt1 & Halt2 & Halt3 & Halt4 --> Report[Сообщить о нарушении пользователю]

    style Execute fill:#50C878,color:#fff
    style Halt1 fill:#E74C3C,color:#fff
    style Halt2 fill:#E74C3C,color:#fff
    style Halt3 fill:#E74C3C,color:#fff
    style Halt4 fill:#E74C3C,color:#fff
```

---

## Summary

### Key Architectural Patterns

1. **Return Control Pattern** — Prevents context nesting, enables rollback
2. **Quality Gates** — Automated validation checkpoints
3. **Iterative Workflows** — Bounded loops with max iterations
4. **Plan → Execute → Report** — Standardized communication protocol
5. **Graceful Degradation** — Fallback strategies for failures
6. **Observability** — TodoWrite, reports, logs for transparency
7. **Fail-Fast with Rollback** — Detect errors early, restore state
8. **Behavioral OS (CLAUDE.md)** — Constitutional rules for all agents

### Component Summary

| Component | Purpose | Count | Examples |
|-----------|---------|-------|----------|
| **Orchestrators** | Coordinate multi-phase workflows | 4 | bug-orchestrator, security-orchestrator |
| **Workers** | Execute specific tasks from plans | 25+ | bug-hunter, bug-fixer, security-scanner |
| **Simple Agents** | Standalone utilities | 4+ | code-reviewer, technical-writer |
| **Skills** | Reusable utility functions | 15+ | run-quality-gate, validate-plan-file |
| **MCP Configs** | External service integrations | 6 | BASE, SUPABASE, FULL |
| **Quality Gates** | Validation scripts | 3+ | check-bundle-size, check-security |

---

## Related Documentation

- **Tutorial**: [TUTORIAL-CUSTOM-AGENTS.md](./TUTORIAL-CUSTOM-AGENTS.md) — Create custom agents
- **Use Cases**: [USE-CASES.md](./USE-CASES.md) — Real-world examples
- **Performance**: [PERFORMANCE-OPTIMIZATION.md](./PERFORMANCE-OPTIMIZATION.md) — Token optimization
- **FAQ**: [FAQ.md](./FAQ.md) — Common questions
- **Behavioral OS**: [../CLAUDE.md](../CLAUDE.md) — Prime Directives and contracts
- **Detailed Specs**: [Agents Ecosystem/](./Agents%20Ecosystem/) — Full specifications

---

**Architecture Version**: 3.0
**Last Updated**: 2025-01-11
**Maintained by**: [Igor Maslennikov](https://github.com/maslennikov-ig)
