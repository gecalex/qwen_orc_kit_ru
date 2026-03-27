---
name: calculate-bug-priority
description: Расчет приоритета багов на основе серьезности, воздействия и вероятности (БЕЗ HARDCODE)
tools:
 - run_shell_command
color: yellow
---

# Навык: Расчет приоритета багов

## When to Use

Используйте этот навык для расчета приоритетного балла бага на основе универсальных критериев. Навык НЕ зависит от конкретного проекта или технологии.

## Instructions

**Формула расчета:**

```
Priority Score = Severity + Impact + Probability

Max: 30 баллов (P0 - Critical)
Min: 3 балла (P3 - Low)
```

## Входные данные

```json
{
  "severity": "critical|high|medium|low",
  "impact": "all|many|some|few",
  "probability": "always|often|sometimes|rarely"
}
```

## Таблица баллов

### Severity (Серьезность)

| Уровень | Баллы | Описание |
|---------|-------|----------|
| critical | 10 | Полная неработоспособность |
| high | 7 | Серьёзная проблема |
| medium | 4 | Проблема с обходным путём |
| low | 1 | Косметическая проблема |

### Impact (Воздействие)

| Уровень | Баллы | Описание |
|---------|-------|----------|
| all | 10 | Все пользователи затронуты |
| many | 7 | Много пользователей затронуто |
| some | 4 | Некоторые пользователи затронуты |
| few | 1 | Мало пользователей затронуто |

### Probability (Вероятность)

| Уровень | Баллы | Описание |
|---------|-------|----------|
| always | 10 | Всегда воспроизводится |
| often | 7 | Часто воспроизводится |
| sometimes | 4 | Иногда воспроизводится |
| rarely | 1 | Редко воспроизводится |

## Расчет приоритета

```
Total Score = Severity + Impact + Probability

P0 (Critical): 25-30 баллов
P1 (High): 18-24 баллов
P2 (Medium): 10-17 баллов
P3 (Low): 3-9 баллов
```

## Примеры

### Пример 1: Критический баг

```json
{
  "severity": "critical",
  "impact": "all",
  "probability": "always"
}

Calculation:
- Severity: 10 (critical)
- Impact: 10 (all)
- Probability: 10 (always)
- Total: 30 → P0 (Critical)
```

### Пример 2: Серьёзный баг

```json
{
  "severity": "high",
  "impact": "many",
  "probability": "often"
}

Calculation:
- Severity: 7 (high)
- Impact: 7 (many)
- Probability: 7 (often)
- Total: 21 → P1 (High)
```

### Пример 3: Средний баг

```json
{
  "severity": "medium",
  "impact": "some",
  "probability": "sometimes"
}

Calculation:
- Severity: 4 (medium)
- Impact: 4 (some)
- Probability: 4 (sometimes)
- Total: 12 → P2 (Medium)
```

## Вывод

```json
{
  "severity_score": 10,
  "impact_score": 10,
  "probability_score": 10,
  "total_score": 30,
  "priority": "P0",
  "priority_label": "Critical"
}
```

## Bash реализация (универсальная)

```bash
#!/bin/bash

calculate_bug_priority() {
  local severity="$1"
  local impact="$2"
  local probability="$3"
  
  # Severity scores
  case "$severity" in
    critical) severity_score=10 ;;
    high) severity_score=7 ;;
    medium) severity_score=4 ;;
    low) severity_score=1 ;;
    *) severity_score=4 ;;
  esac
  
  # Impact scores
  case "$impact" in
    all) impact_score=10 ;;
    many) impact_score=7 ;;
    some) impact_score=4 ;;
    few) impact_score=1 ;;
    *) impact_score=4 ;;
  esac
  
  # Probability scores
  case "$probability" in
    always) probability_score=10 ;;
    often) probability_score=7 ;;
    sometimes) probability_score=4 ;;
    rarely) probability_score=1 ;;
    *) probability_score=4 ;;
  esac
  
  # Total
  total_score=$((severity_score + impact_score + probability_score))
  
  # Priority
  if [ "$total_score" -ge 25 ]; then
    priority="P0"
    priority_label="Critical"
  elif [ "$total_score" -ge 18 ]; then
    priority="P1"
    priority_label="High"
  elif [ "$total_score" -ge 10 ]; then
    priority="P2"
    priority_label="Medium"
  else
    priority="P3"
    priority_label="Low"
  fi
  
  # Output JSON
  cat << EOF
{
  "severity_score": $severity_score,
  "impact_score": $impact_score,
  "probability_score": $probability_score,
  "total_score": $total_score,
  "priority": "$priority",
  "priority_label": "$priority_label"
}
EOF
}

# Пример использования
calculate_bug_priority "critical" "all" "always"
```

## Интеграция с work_monitoring_bug_tracker

```bash
# Источник навыка
source .qwen/skills/calculate-bug-priority/SKILL.md

# Автоматическое определение из тестов
auto_detect_severity() {
  local errors="$1"
  local failed="$2"
  
  if [ "$errors" -gt 0 ]; then
    echo "critical"
  elif [ "$failed" -gt 10 ]; then
    echo "high"
  elif [ "$failed" -gt 0 ]; then
    echo "medium"
  else
    echo "low"
  fi
}

auto_detect_impact() {
  local failed="$1"
  local total="$2"
  
  local ratio=$((failed * 100 / total))
  
  if [ "$ratio" -ge 75 ]; then
    echo "all"
  elif [ "$ratio" -ge 50 ]; then
    echo "many"
  elif [ "$ratio" -ge 25 ]; then
    echo "some"
  else
    echo "few"
  fi
}

auto_detect_probability() {
  # Всегда "always" для автотестов
  echo "always"
}

# Использование
SEVERITY=$(auto_detect_severity "$ERRORS" "$FAILED")
IMPACT=$(auto_detect_impact "$FAILED" "$TOTAL")
PROBABILITY=$(auto_detect_probability)

PRIORITY_JSON=$(calculate_bug_priority "$SEVERITY" "$IMPACT" "$PROBABILITY")
PRIORITY=$(echo "$PRIORITY_JSON" | jq -r '.priority')
```
