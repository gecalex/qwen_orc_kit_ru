# Спецификация контрольных точек качества

**Дата создания**: 2025-10-16
**Фаза**: 2 - Задача 2.4
**Статус**: Завершено
**Контекст**: Рефакторинг основной экосистемы агентов

---

## Итоги

Этот документ определяет **Контрольные точки качества** для всех оркестрированных рабочих процессов в нашем проекте Claude Code. Контрольные точки качества - это точки проверки валидации, которые обеспечивают соответствие работы стандартам качества перед переходом к следующей фазе.

**Ключевой принцип**: Блокировать прогресс при критических сбоях, предупреждать о некритических проблемах.

**Источник**: Исследование vanzan01/claude-code-sub-agent-collective

---

## Содержание

1. [Что такое контрольные точки качества?](#что-такое-контрольные-точки-качества)
2. [Типы точек](#типы-точек)
3. [Специфичные для домена точки](#специфичные-для-домена-точки)
4. [Шаблон реализации](#шаблон-реализации)
5. [Пороги и метрики](#пороги-и-метрики)
6. [Обработка сбоев](#обработка-сбоев)
7. [Механизмы переопределения](#механизмы-переопределения)

---

## Что такое контрольные точки качества?

### Определение

**Контрольная точка качества** - это точка проверки валидации между фазами рабочего процесса, которая:
- Проверяет завершение фазы
- Проверяет метрики качества по порогам
- Блокирует прогресс, если критерии не пройдены
- Предупреждает, если некритические критерии не пройдены
- Обеспечивает четкий статус прошло/не прошло

### Назначение

Контрольные точки качества обеспечивают:
1. **Качество**: Работа соответствует минимальным стандартам перед прогрессом
2. **Безопасность**: Критические сбои выявляются на ранней стадии
3. **Видимость**: Пользователи явно видят результаты валидации
4. **Контроль**: Пользователи могут переопределить с явным подтверждением

### Структура точки

У каждой контрольной точки качества есть:

```yaml
gate_name:
  phase: N
  description: "Что проверяет эта точка"

  blocking_criteria:
    - criterion: "Конкретная проверка"
      command: "Команда для проверки"
      threshold: "Порог прохождения"
      failure_action: "Что делать при сбое"

  non_blocking_criteria:
    - criterion: "Проверка лучших практик"
      command: "Команда для проверки"
      warning: "Сообщение предупреждения при сбое"

  on_failure:
    - "Шаг 1 для восстановления"
    - "Шаг 2 для восстановления"
    - "Вариант переопределения пользователем"
```

---

## Типы точек

### Тип 1: Блокирующие точки

**Характеристики**:
- ⛔ ОСТАНАВЛИВАЕТ прогресс рабочего процесса, если критерии не пройдены
- Используется для критических стандартов качества
- Требует вмешательства пользователя (исправить или пропустить)
- Записывается с высокой степенью важности

**Примеры**:
- Сбои проверки типов
- Сбои сборки
- Критические сбои тестов
- Критические уязвимости безопасности
- Отсутствующие политики RLS

**Опыт пользователя**:
```
⛔ Контрольная точка качества БЛОКИРОВАНА: Валидация фазы 2

❌ Проверка типов: СБОЙ
   - 5 ошибок типов в src/components/
   - См. вывод выше для деталей

❌ Сборка: СБОЙ
   - Ошибка компиляции в src/utils/version.ts

Требуется действие:
1. Исправить ошибки, перечисленные выше
2. Перезапустить оркестратор для повторной попытки

Или: Введите "skip", чтобы все равно продолжить (не рекомендуется)
```

### Тип 2: Неблокирующие точки

**Характеристики**:
- ⚠️ ПРЕДУПРЕЖДАЕТ, но позволяет продолжение
- Используется для лучших практик и рекомендаций
- Записывается в сводный отчет
- Пользователь может устранить позже

**Примеры**:
- Бенчмарки производительности ниже целевых
- Покрытие кода ниже 80%
- Некритические проблемы безопасности
- Неполная документация
- Нарушения стиля кода

**Опыт пользователя**:
```
⚠️ Предупреждение контрольной точки качества: Валидация фазы 2

✅ Проверка типов: ПРОЙДЕНО
✅ Сборка: ПРОЙДЕНО
⚠️ Покрытие кода: 72% (цель: 80%)
⚠️ Производительность: Время отклика 350мс (цель: 200мс)

Рабочий процесс будет продолжен, но, пожалуйста, устраните предупреждения:
- Увеличить покрытие тестами до 80%
- Оптимизировать время отклика до целевого значения
```

---

## Специфичные для домена точки

### Домен багов

#### Точка 1: Обнаружение завершено

**Фаза**: После выполнения bug-hunter

**Блокирующие критерии**:
```yaml
- criterion: "Файл отчета существует"
  command: "test -f bug-hunting-report.md"
  threshold: "Файл существует"
  failure_action: "Сообщить о сбое bug-hunter, попросить повторить"

- criterion: "Отчет правильно сформирован"
  command: "grep -q '## Итоги' bug-hunting-report.md"
  threshold: "Содержит требуемые разделы"
  failure_action: "Ошибка формата отчета, попросить bug-hunter перегенерировать"

- criterion: "Статус валидации ПРОЙДЕН"
  command: "grep -q 'Валидация.*ПРОЙДЕНО' bug-hunting-report.md"
  threshold: "Статус ПРОЙДЕНО присутствует"
  failure_action: "Валидация обнаружения багов не удалась, проверить отчет"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Высокоприоритетные баги задокументированы"
  warning: "Высокоприоритетных багов не найдено - проверить тщательность"

- criterion: "Паттерны багов идентифицированы"
  warning: "Паттерны не идентифицированы - рассмотреть более глубокий анализ"
```

**Порог прохождения**: Все блокирующие критерии выполнены

**При сбое**:
1. ⛔ СТОП - Не переходить к фазе 2 (Исправление багов)
2. Сообщить, какие критерии не прошли с деталями
3. Показать сообщения об ошибках из команд
4. Спросить пользователя: "Исправить проблемы и повторить bug-hunter? (y/N)"
5. Если "N": Выйти из рабочего процесса с итогом ошибок

---

#### Точка 2: Исправления применены

**Фаза**: После выполнения bug-fixer

**Блокирующие критерии**:
```yaml
- criterion: "Проверка типов проходит"
  command: "pnpm type-check"
  threshold: "Код выхода 0, нет ошибок"
  failure_action: "Исправления ввели новые ошибки типов"

- criterion: "Сборка успешна"
  command: "pnpm build"
  threshold: "Код выхода 0, нет ошибок"
  failure_action: "Исправления сломали сборку"

- criterion: "Отчет об исправлениях существует"
  command: "test -f bug-fixing-report.md"
  threshold: "Файл существует"
  failure_action: "Bug-fixer не сгенерировал отчет"

- criterion: "Критические баги исправлены"
  command: "grep -q 'Критический.*Исправлен' bug-fixing-report.md"
  threshold: "Все критические баги устранены"
  failure_action: "Критические баги остались неисправленными"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Тесты проходят"
  command: "pnpm test"
  warning: "Некоторые тесты падают - проверить сбои тестов"

- criterion: "Линтинг проходит"
  command: "pnpm lint"
  warning: "Проблемы линтинга остаются"
```

**Порог прохождения**: Все блокирующие критерии выполнены

**При сбое**:
1. ⛔ СТОП - Не переходить к фазе 3 (Проверка)
2. Сообщить, какие критерии не прошли
3. Показать вывод команды
4. Спросить пользователя: "Откатить изменения и повторить? (y/N)"
5. Если "N": Спросить "Пропустить валидацию и продолжить? (не рекомендуется)"

---

#### Точка 3: Проверка

**Фаза**: После проверочного сканирования bug-hunter

**Блокирующие критерии**:
```yaml
- criterion: "Остается ноль критических багов"
  command: "grep -q 'Критический.*0' bug-hunting-report.md"
  threshold: "0 критических багов"
  failure_action: "Критические баги все еще присутствуют после исправлений"

- criterion: "Проверка типов все еще проходит"
  command: "pnpm type-check"
  threshold: "Код выхода 0"
  failure_action: "Проверка типов регрессировала"

- criterion: "Сборка все еще успешна"
  command: "pnpm build"
  threshold: "Код выхода 0"
  failure_action: "Сборка регрессировала"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Остается ноль багов высокого приоритета"
  warning: "Баги высокого приоритета все еще присутствуют"

- criterion: "Новые баги не введены"
  warning: "Новые баги обнаружены проверочным сканированием"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

### Домен безопасности

#### Точка 1: Аудит завершен

**Фаза**: После выполнения security-scanner

**Блокирующие критерии**:
```yaml
- criterion: "Файл отчета существует"
  command: "test -f security-audit-report.md"
  threshold: "Файл существует"
  failure_action: "Security scanner не завершил работу"

- criterion: "Отчет правильно сформирован"
  command: "grep -q '## Итоги' security-audit-report.md"
  threshold: "Содержит требуемые разделы"
  failure_action: "Ошибка формата отчета"

- criterion: "Уязвимости классифицированы"
  command: "grep -E '(Критический|Высокий|Средний|Низкий)' security-audit-report.md"
  threshold: "Категории присутствуют"
  failure_action: "Уязвимости не правильно классифицированы"

- criterion: "Статус валидации ПРОЙДЕН"
  command: "grep -q 'Валидация.*ПРОЙДЕНО' security-audit-report.md"
  threshold: "Статус ПРОЙДЕНО присутствует"
  failure_action: "Валидация сканирования безопасности не удалась"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Ноль критических уязвимостей"
  warning: "Критические уязвимости найдены - требуется немедленное внимание"

- criterion: "Политики RLS проверены"
  warning: "Проверка политики RLS неполна"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

#### Точка 2: Критические исправления применены

**Фаза**: После выполнения vulnerability-fixer (только критические)

**Блокирующие критерии**:
```yaml
- criterion: "Политики RLS добавлены/исправлены"
  command: "grep -q 'RLS.*Исправлен' security-fixing-report.md"
  threshold: "Проблемы RLS устранены"
  failure_action: "Политики RLS не исправлены"

- criterion: "Аутентификация исправлена"
  command: "grep -q 'Аутентификация.*Исправлен' security-fixing-report.md"
  threshold: "Проблемы аутентификации устранены"
  failure_action: "Уязвимости аутентификации остаются"

- criterion: "Учетные данные защищены"
  command: "! grep -r 'password.*=.*[\"']' src/ --exclude-dir=node_modules"
  threshold: "Нет жестко закодированных учетных данных"
  failure_action: "Жестко закодированные учетные данные все еще присутствуют"

- criterion: "Проверка типов проходит"
  command: "pnpm type-check"
  threshold: "Код выхода 0"
  failure_action: "Исправления безопасности сломали проверку типов"

- criterion: "Сборка успешна"
  command: "pnpm build"
  threshold: "Код выхода 0"
  failure_action: "Исправления безопасности сломали сборку"
```

**Неблокирующие критерии**:
```yaml
- criterion: "npm audit чист"
  command: "npm audit --audit-level=critical"
  warning: "Критические уязвимости npm остаются"

- criterion: "Добавлена валидация ввода"
  warning: "Улучшения валидации ввода неполны"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

#### Точка 3: Проверка

**Фаза**: После проверочного сканирования security-scanner

**Блокирующие критерии**:
```yaml
- criterion: "Ноль критических уязвимостей"
  command: "grep -q 'Критический.*0' security-audit-report.md"
  threshold: "0 критических уязвимостей"
  failure_action: "Критические уязвимости все еще присутствуют"

- criterion: "Новые уязвимости не введены"
  command: "Сравнить предыдущее и текущее количество уязвимостей"
  threshold: "Количество не увеличилось"
  failure_action: "Исправления ввели новые уязвимости"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Высокоприоритетные уязвимости уменьшены"
  warning: "Высокоприоритетные уязвимости все еще присутствуют"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

### Домен мертвого кода

#### Точка 1: Обнаружение завершено

**Фаза**: После выполнения dead-code-hunter

**Блокирующие критерии**:
```yaml
- criterion: "Файл отчета существует"
  command: "test -f dead-code-report.md"
  threshold: "Файл существует"
  failure_action: "Dead-code hunter не завершил работу"

- criterion: "Отчет правильно сформирован"
  command: "grep -q '## Итоги' dead-code-report.md"
  threshold: "Содержит требуемые разделы"
  failure_action: "Ошибка формата отчета"

- criterion: "Мертвый код классифицирован"
  command: "grep -E '(Неиспользуемый|Недостижимый|Закомментированный)' dead-code-report.md"
  threshold: "Категории присутствуют"
  failure_action: "Мертвый код не правильно классифицирован"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Мертвый код обнаружен"
  warning: "Мертвый код не найден - проверить тщательность сканирования"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

#### Точка 2: Очистка применена

**Фаза**: После выполнения dead-code-remover

**Блокирующие критерии**:
```yaml
- criterion: "Сборка успешна"
  command: "pnpm build"
  threshold: "Код выхода 0"
  failure_action: "Удаление мертвого кода сломало сборку"

- criterion: "Проверка типов проходит"
  command: "pnpm type-check"
  threshold: "Код выхода 0"
  failure_action: "Удаление мертвого кода сломало проверку типов"

- criterion: "Отчет об очистке существует"
  command: "test -f dead-code-cleanup-report.md"
  threshold: "Файл существует"
  failure_action: "Dead-code remover не сгенерировал отчет"

- criterion: "Удаленные файлы задокументированы"
  command: "grep -q 'Файлы удалены' dead-code-cleanup-report.md"
  threshold: "Статистика удаления присутствует"
  failure_action: "Статистика очистки отсутствует"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Тесты все еще проходят"
  command: "pnpm test"
  warning: "Некоторые тесты падают после очистки"

- criterion: "Новый мертвый код не введен"
  warning: "Очистка ввела новый мертвый код"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

#### Точка 3: Проверка

**Фаза**: После проверочного сканирования dead-code-hunter

**Блокирующие критерии**:
```yaml
- criterion: "Сборка все еще успешна"
  command: "pnpm build"
  threshold: "Код выхода 0"
  failure_action: "Сборка регрессировала"

- criterion: "Новый мертвый код не обнаружен"
  command: "Сравнить предыдущее и текущее количество мертвого кода"
  threshold: "Количество не увеличилось"
  failure_action: "Очистка неполна или ввела новый мертвый код"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

### Домен зависимостей

#### Точка 1: Аудит завершен

**Фаза**: После выполнения dependency-auditor

**Блокирующие критерии**:
```yaml
- criterion: "Файл отчета существует"
  command: "test -f dependency-audit-report.md"
  threshold: "Файл существует"
  failure_action: "Dependency auditor не завершил работу"

- criterion: "Отчет правильно сформирован"
  command: "grep -q '## Итоги' dependency-audit-report.md"
  threshold: "Содержит требуемые разделы"
  failure_action: "Ошибка формата отчета"

- criterion: "Зависимости классифицированы"
  command: "grep -E '(Устаревшие|Уязвимые|Неиспользуемые)' dependency-audit-report.md"
  threshold: "Категории присутствуют"
  failure_action: "Зависимости не правильно классифицированы"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Ноль критических CVE"
  warning: "Критические CVE найдены - требуется немедленное обновление"

- criterion: "Зависимости разумно актуальны"
  warning: "Много устаревших зависимостей - рассмотреть обновления"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

#### Точка 2: Обновления применены

**Фаза**: После выполнения dependency-updater (только критические)

**Блокирующие критерии**:
```yaml
- criterion: "Критические CVE исправлены"
  command: "npm audit --audit-level=critical"
  threshold: "Код выхода 0 или <5 критических"
  failure_action: "Критические CVE все еще присутствуют"

- criterion: "package.json обновлен"
  command: "git diff --exit-code package.json"
  threshold: "Файл изменен (код выхода 1)"
  failure_action: "Обновления не применены к package.json"

- criterion: "Зависимости установлены"
  command: "test -d node_modules"
  threshold: "Каталог существует"
  failure_action: "npm install не запущен"

- criterion: "Сборка успешна"
  command: "pnpm build"
  threshold: "Код выхода 0"
  failure_action: "Обновления сломали сборку"

- criterion: "Проверка типов проходит"
  command: "pnpm type-check"
  threshold: "Код выхода 0"
  failure_action: "Обновления сломали проверку типов"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Тесты проходят"
  command: "pnpm test"
  warning: "Некоторые тесты падают после обновлений"

- criterion: "Нет критических изменений"
  warning: "Обновления основных версий могут иметь критические изменения"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

#### Точка 3: Проверка

**Фаза**: После проверочного сканирования dependency-auditor

**Блокирующие критерии**:
```yaml
- criterion: "npm audit чист (критические)"
  command: "npm audit --audit-level=critical"
  threshold: "<5 критических CVE"
  failure_action: "Критические CVE остаются"

- criterion: "Сборка все еще успешна"
  command: "pnpm build"
  threshold: "Код выхода 0"
  failure_action: "Сборка регрессировала"
```

**Неблокирующие критерии**:
```yaml
- criterion: "Все CVE учтены"
  command: "npm audit"
  warning: "Некоторые некритические CVE остаются"
```

**Порог прохождения**: Все блокирующие критерии выполнены

---

## Шаблон реализации

### Интеграция оркестратора

Контрольные точки качества реализованы в подсказках оркестратора:

```markdown
## Фаза 2: Контрольная точка качества - {Имя фазы}

### Блокирующая валидация

Запустить следующие проверки (выйти, если какие-либо не пройдены):

1. **Проверка 1: {Критерий}**
   ```bash
   {command}
   ```
   Ожидаемый результат: {threshold}
   Если не пройдена: ⛔ СТОП - {failure_action}

2. **Проверка 2: {Критерий}**
   ```bash
   {command}
   ```
   Ожидаемый результат: {threshold}
   Если не пройдена: ⛔ СТОП - {failure_action}

### Неблокирующая валидация

Запустить следующие проверки (предупредить, если какие-либо не пройдены):

1. **Проверка 1: {Критерий}**
   ```bash
   {command}
   ```
   Ожидаемый результат: {threshold}
   Если не пройдена: ⚠️ ПРЕДУПРЕЖДЕНИЕ - {warning}

### Результат точки

Если ВСЕ блокирующие критерии пройдены:
  ✅ Контрольная точка качества ПРОЙДЕНА - Переход к фазе {N+1}
  Обновить TodoWrite: Отметить фазу {N} как завершенную

Если ЛЮБОЙ блокирующий критерий не пройден:
  ⛔ Контрольная точка качества БЛОКИРОВАНА - Рабочий процесс остановлен
  Обновить TodoWrite: Отметить фазу {N} как не пройденную
  Сообщить пользователю:
    "Контрольная точка заблокирована на фазе {N}.

    Не пройденные критерии:
    - {criterion1}: {details}
    - {criterion2}: {details}

    Действия:
    1. Исправить проблемы, перечисленные выше
    2. Перезапустить оркестратор для повторной попытки

    Или: Введите 'skip', чтобы обойти валидацию (не рекомендуется)"

Если неблокирующие критерии не пройдены:
  Добавить предупреждения в сводный отчет
  Продолжить к следующей фазе
```

---

## Пороги и метрики

### Числовые пороги

| Домен | Метрика | Блокирующий порог | Целевой не блокирующий |
|--------|--------|-------------------|---------------------|
| **Баги** | Критические баги | 0 | 0 |
| **Баги** | Баги высокого приоритета | Н/Д | 0 |
| **Баги** | Ошибки типов | 0 | 0 |
| **Безопасность** | Критические CVE | <5 | 0 |
| **Безопасность** | Высокие CVE | Н/Д | <10 |
| **Безопасность** | Отсутствующие политики RLS | 0 | 0 |
| **Зависимости** | Критические CVE | <5 | 0 |
| **Зависимости** | Устаревшие (основные) | Н/Д | <3 |
| **Качество кода** | Успешная сборка | 100% | 100% |
| **Качество кода** | Успешная проверка типов | 100% | 100% |
| **Качество кода** | Процент прохождения тестов | Н/Д | >90% |
| **Качество кода** | Покрытие кода | Н/Д | >80% |

### Философия порогов

**Блокирующие пороги**:
- Установлены на уровне, где сбой вызывает немедленные проблемы
- Ошибки типов, сбои сборки → Всегда блокируются
- Критические проблемы безопасности → Всегда блокируются
- Критические баги → Всегда блокируются

**Не блокирующие цели**:
- Установлены на уровне стремления
- Лучшие практики, качество кода → Не блокируются
- Производительность, покрытие → Не блокируются
- Пользователь может устранить со временем

---

## Обработка сбоев

### Поток ответа на сбой

```
1. Контрольная точка качества запускает проверки валидации
   ↓
2. Проверка не пройдена
   ↓
3. Захват деталей сбоя:
   - Какой критерий не пройден
   - Вывод команды
   - Ожидаемый vs фактический
   ↓
4. Определить серьезность:
   - Блокирующий → ОСТАНОВИТЬ рабочий процесс
   - Неблокирующий → Записать предупреждение, продолжить
   ↓
5. Сообщить пользователю:
   - Показать детали сбоя
   - Предоставить корректирующие действия
   - Предложить вариант переопределения (только блокирующий)
   ↓
6. Дождаться решения пользователя:
   - Исправить: Выйти из рабочего процесса, пользователь исправляет, перезапускает
   - Пропустить: Добавить предупреждение к итогу, продолжить
   - Прервать: Выйти из рабочего процесса с ошибкой
```

### Шаблон сообщения об ошибке

**Блокирующий сбой**:
```
⛔ КОНТРОЛЬНАЯ ТОЧКА КАЧЕСТВА БЛОКИРОВАНА: Фаза {N} - {Имя точки}

Не пройденные критерии:

❌ {Критерий 1}
   Команда: {command}
   Ожидаемый: {threshold}
   Фактический: {actual_output}
   Детали: {error_message}

❌ {Критерий 2}
   Команда: {command}
   Ожидаемый: {threshold}
   Фактический: {actual_output}
   Детали: {error_message}

Корректирующие действия:
1. {Действие 1}
2. {Действие 2}
3. Перезапустить оркестратор после исправлений

Переопределение:
Введите "skip", чтобы обойти валидацию (НЕ РЕКОМЕНДУЕТСЯ - может вызвать проблемы)
```

**Неблокирующее предупреждение**:
```
⚠️ ПРЕДУПРЕЖДЕНИЕ КОНТРОЛЬНОЙ ТОЧКИ КАЧЕСТВА: Фаза {N} - {Имя точки}

Критерии предупреждения:

⚠️ {Критерий 1}
   Команда: {command}
   Ожидаемый: {target}
   Фактический: {actual_output}
   Рекомендация: {recommendation}

⚠️ {Критерий 2}
   Команда: {command}
   Ожидаемый: {target}
   Фактический: {actual_output}
   Рекомендация: {recommendation}

Рабочий процесс будет продолжен. Пожалуйста, устраните предупреждения в будущих итерациях.
```

---

## Override Mechanisms

### When to Allow Override

**Blocking Gates CAN be overridden when**:
- User explicitly requests "skip"
- User accepts responsibility for potential issues
- Situation is time-sensitive or urgent
- User has expert knowledge of why it's safe

**Blocking Gates CANNOT be overridden when**:
- Security critical (e.g., RLS policies, authentication)
- Data safety critical (e.g., destructive operations)
- System stability critical (e.g., build must succeed for deploy)

### Override Process

1. **User Requests Override**:
   ```
   User: "skip validation"
   ```

2. **Orchestrator Confirms**:
   ```
   ⚠️ WARNING: Skipping Quality Gate

   You are bypassing blocking validation:
   - {Criterion 1}: FAILED
   - {Criterion 2}: FAILED

   This may cause:
   - {Risk 1}
   - {Risk 2}

   Are you sure? Type "confirm skip" to proceed.
   ```

3. **User Confirms**:
   ```
   User: "confirm skip"
   ```

4. **Orchestrator Logs and Continues**:
   ```
   ⚠️ Quality Gate OVERRIDDEN by user

   Adding to summary report:
   - Phase {N} validation was SKIPPED
   - Risks: {risks}
   - User accepted responsibility

   Proceeding to Phase {N+1}...
   ```

### Override Logging

All overrides are logged in:
1. **TodoWrite**: Warning marker on phase
2. **Summary Report**: Dedicated "Overrides" section
3. **Console Output**: Clear warning banner

**Summary Report Section**:
```markdown
## ⚠️ Quality Gate Overrides

### Phase 2: Bug Fixing Validation (SKIPPED)

**Failed Criteria**:
- Type check: 3 errors
- Build: 1 error

**Risks Accepted**:
- May introduce runtime errors
- May break downstream code

**User Decision**: Accepted override on 2025-10-16 14:30:00
```

---

## Testing Quality Gates

### Unit Testing (Per Gate)

Test each gate criterion individually:

```bash
# Test blocking criterion
{command}
if [ $? -ne 0 ]; then
  echo "✅ Gate correctly blocks on failure"
else
  echo "❌ Gate should block but didn't"
fi

# Test non-blocking criterion
{command}
if [ $? -ne 0 ]; then
  echo "✅ Gate correctly warns on failure"
  # Verify workflow continues
else
  echo "✅ Gate passes"
fi
```

### Integration Testing (With Orchestrators)

Test gates within orchestrator workflows:

```bash
# Create failing condition
echo "Introduce type error in src/test.ts"

# Run orchestrator
/health bugs

# Expected: Gate blocks at Phase 2
# Expected: Error message shows type error details
# Expected: Offers fix/skip options

# Fix the error
"Fix type error"

# Re-run orchestrator
/health bugs

# Expected: Gate passes
# Expected: Workflow continues to Phase 3
```

### Validation Checklist

For each Quality Gate:
- [ ] Blocking criteria defined
- [ ] Non-blocking criteria defined
- [ ] Thresholds are testable
- [ ] Commands are correct
- [ ] Failure actions are clear
- [ ] Override mechanism works
- [ ] Logging captures details
- [ ] Integration tested with orchestrator

---

## Maintenance

### Updating Thresholds

**When to Update**:
- Project quality improves → Raise thresholds
- Thresholds too strict → Lower thresholds
- New tools available → Add criteria
- Old tools deprecated → Remove criteria

**Process**:
1. Propose threshold change in issue/PR
2. Document rationale
3. Update this specification
4. Update affected orchestrators
5. Test with realistic scenarios
6. Announce change to team

### Adding New Gates

**When to Add**:
- New domain orchestrators added
- New phases added to existing orchestrators
- New validation tools become available

**Process**:
1. Define gate following template
2. Identify blocking vs non-blocking criteria
3. Set thresholds based on team standards
4. Document in this specification
5. Implement in orchestrator
6. Test thoroughly

---

**Document Status**: Complete - Ready for Phase 4 Implementation
**Next Phase**: Phase 3 - Implementation Planning

---

## Custom Quality Gates

**Added**: 2025-10-18 (Phase 4 - Task 4.3)

Custom quality gates allow projects to add domain-specific validation beyond the standard gates (type-check, build, tests, lint).

### Using Custom Gates

Use the **run-quality-gate** Skill with `gate="custom"`:

```markdown
Use run-quality-gate Skill:
- gate: "custom"
- custom_command: "your-command-here"
- blocking: true|false
```

### Common Custom Gates

#### 1. Bundle Size Check

**Purpose**: Ensure production bundle stays within size limits

**Configuration**:
```json
{
  "gate": "custom",
  "custom_command": "npm run check-bundle-size",
  "blocking": false
}
```

**Example Script** (package.json):
```json
{
  "scripts": {
    "check-bundle-size": "bundlewatch --config .bundlewatch.json"
  }
}
```

**.bundlewatch.json**:
```json
{
  "files": [
    {
      "path": "dist/bundle.js",
      "maxSize": "500kb"
    }
  ]
}
```

**Interpretation**:
- ✅ Pass: Bundle size < 500KB
- ⛔ Fail (non-blocking): Bundle size > 500KB, warn user
- Action: Review bundle contents, remove unused imports

---

#### 2. Performance Benchmark (Lighthouse CI)

**Purpose**: Validate performance metrics for critical pages

**Configuration**:
```json
{
  "gate": "custom",
  "custom_command": "npm run lighthouse-ci",
  "blocking": false
}
```

**Example Script** (package.json):
```json
{
  "scripts": {
    "lighthouse-ci": "lhci autorun --config=lighthouserc.json"
  }
}
```

**lighthouserc.json**:
```json
{
  "ci": {
    "collect": {
      "url": ["http://localhost:3000/"],
      "numberOfRuns": 3
    },
    "assert": {
      "assertions": {
        "categories:performance": ["error", {"minScore": 0.9}],
        "categories:accessibility": ["warn", {"minScore": 0.9}]
      }
    }
  }
}
```

**Interpretation**:
- ✅ Pass: Performance score > 90, Accessibility > 90
- ⚠️ Warn: Accessibility < 90 (non-blocking)
- ⛔ Fail: Performance < 90 (non-blocking, but should investigate)

---

#### 3. Security Scan (npm audit)

**Purpose**: Check for high/critical vulnerabilities in dependencies

**Configuration**:
```json
{
  "gate": "custom",
  "custom_command": "npm audit --audit-level=high",
  "blocking": true
}
```

**Interpretation**:
- ✅ Pass: No high/critical vulnerabilities
- ⛔ Fail (blocking): High/critical vulnerabilities found, MUST fix before merging

---

#### 4. Code Coverage

**Purpose**: Ensure test coverage meets minimum threshold

**Configuration**:
```json
{
  "gate": "custom",
  "custom_command": "npm run test:coverage -- --coverage-threshold=80",
  "blocking": false
}
```

**Example Script** (package.json):
```json
{
  "scripts": {
    "test:coverage": "jest --coverage"
  }
}
```

**jest.config.js**:
```javascript
module.exports = {
  coverageThresholds: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
}
```

**Interpretation**:
- ✅ Pass: Coverage > 80% for all metrics
- ⚠️ Warn: Coverage < 80% (non-blocking, but should improve)

---

#### 5. API Contract Validation

**Purpose**: Ensure API responses match OpenAPI/GraphQL schema

**Configuration**:
```json
{
  "gate": "custom",
  "custom_command": "npm run validate-api-contracts",
  "blocking": true
}
```

**Example Script**:
```bash
#!/bin/bash
# validate-api-contracts.sh

# Start test server
npm run start:test &
SERVER_PID=$!

# Wait for server
sleep 5

# Run validation
npx @openapitools/openapi-generator-cli validate -i openapi.yaml

EXIT_CODE=$?

# Cleanup
kill $SERVER_PID

exit $EXIT_CODE
```

**Interpretation**:
- ✅ Pass: API responses match schema
- ⛔ Fail (blocking): Schema mismatch, fix before merging

---

#### 6. Accessibility Audit (axe-core)

**Purpose**: Check for accessibility violations

**Configuration**:
```json
{
  "gate": "custom",
  "custom_command": "npm run test:a11y",
  "blocking": false
}
```

**Example Script** (package.json):
```json
{
  "scripts": {
    "test:a11y": "jest --testMatch='**/*.a11y.test.ts'"
  }
}
```

**Example Test** (Home.a11y.test.ts):
```typescript
import { axe, toHaveNoViolations } from 'jest-axe'
import { render } from '@testing-library/react'
import Home from './Home'

expect.extend(toHaveNoViolations)

test('Home page should have no accessibility violations', async () => {
  const { container } = render(<Home />)
  const results = await axe(container)
  expect(results).toHaveNoViolations()
})
```

**Interpretation**:
- ✅ Pass: No accessibility violations
- ⚠️ Warn: Violations found (non-blocking, should fix)

---

### Creating Custom Gate Scripts

**Location**: `.claude/scripts/gates/{gate-name}.sh`

**Template**:
```bash
#!/bin/bash
# .claude/scripts/gates/{gate-name}.sh

set -e

echo "Running {gate-name} validation..."

# Your validation logic here
# Example: Check file exists
if [ ! -f "required-file.txt" ]; then
  echo "Error: required-file.txt not found"
  exit 1
fi

# Example: Run command and check output
OUTPUT=$(your-command 2>&1)
if echo "$OUTPUT" | grep -q "ERROR"; then
  echo "Validation failed: $OUTPUT"
  exit 1
fi

echo "✅ {gate-name} validation passed"
exit 0
```

**Usage in Orchestrator**:
```markdown
Use run-quality-gate Skill:
- gate: "custom"
- custom_command: "bash .claude/scripts/gates/my-gate.sh"
- blocking: true
```

---

### Custom Gate Best Practices

1. **Make Scripts Idempotent**: Scripts should produce same result when run multiple times
2. **Fast Execution**: Custom gates should complete in < 5 minutes
3. **Clear Output**: Print clear success/failure messages
4. **Exit Codes**: Use 0 for success, non-zero for failure
5. **Dependencies**: Document required tools in gate script comments
6. **Thresholds**: Make thresholds configurable via environment variables

**Example with Configurable Threshold**:
```bash
#!/bin/bash
BUNDLE_SIZE_LIMIT=${BUNDLE_SIZE_LIMIT:-500000}  # Default 500KB

ACTUAL_SIZE=$(wc -c < dist/bundle.js)

if [ "$ACTUAL_SIZE" -gt "$BUNDLE_SIZE_LIMIT" ]; then
  echo "Bundle size ($ACTUAL_SIZE bytes) exceeds limit ($BUNDLE_SIZE_LIMIT bytes)"
  exit 1
fi

echo "✅ Bundle size OK: $ACTUAL_SIZE bytes (limit: $BUNDLE_SIZE_LIMIT bytes)"
exit 0
```

---

### Integration with Orchestrators

Orchestrators can use custom gates in their quality gate phases:

**Example** (bug-orchestrator):
```markdown
## Phase 4: Quality Gate - Custom Validations

Use run-quality-gate Skill with these custom gates:

1. Bundle size check (non-blocking):
   - gate: "custom"
   - custom_command: "npm run check-bundle-size"
   - blocking: false

2. Security audit (blocking):
   - gate: "custom"
   - custom_command: "npm audit --audit-level=high"
   - blocking: true

If any blocking gate fails:
- STOP workflow
- Report failure to user
- Provide fix instructions
- Ask: "Fix issues or skip validation?"
```

---

**Custom Gates Status**: Documented and Ready for Use
**Next Steps**: Teams can add project-specific custom gates as needed
