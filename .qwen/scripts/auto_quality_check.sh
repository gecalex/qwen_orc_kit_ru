#!/bin/bash
# Файл: .qwen/scripts/auto_quality_check.sh
# Оркестратор запускает эту проверку после каждого task

TASK_RESULT=$1
AGENT_TYPE=$2

echo "Автоматическая проверка качества после $AGENT_TYPE"

# Gate 2 проверки
./.qwen/scripts/run_quality_gate.sh 2

# Специфичные проверки для типа агента
case $AGENT_TYPE in
  "code-quality-checker")
    # Дополнительные проверки для аудитора качества
    if [ -f "state/quality_audits/latest.md" ]; then
      grep -q "CRITICAL" "state/quality_audits/latest.md" && echo "ВНИМАНИЕ: Найдены критические проблемы" || echo "Качество приемлемо"
    else
      echo "Файл отчета качества не найден"
    fi
    ;;

  "security-orchestrator")
    # Проверка безопасности
    if [ -f "state/security_scan.json" ]; then
      if command -v python3 &> /dev/null; then
        python3 -c "
import json
import sys
try:
    with open('state/security_scan.json') as f:
        scan = json.load(f)
    high_vulns = [v for v in scan.get('vulnerabilities', []) if v.get('severity') in ['HIGH', 'CRITICAL']]
    if high_vulns:
        print(f'ВНИМАНИЕ: Найдено {len(high_vulns)} высокоприоритетных уязвимостей')
    else:
        print('Критических уязвимостей не найдено')
except FileNotFoundError:
    print('Файл отчета безопасности не найден')
except json.JSONDecodeError:
    print('Файл отчета безопасности содержит невалидный JSON')
"
      else
        echo "Python3 не установлен, пропускаем проверку безопасности"
      fi
    else
      echo "Файл отчета безопасности не найден"
    fi
    ;;

  *)
    echo "Проверка для агента $AGENT_TYPE не определена"
    ;;
esac

echo "Автопроверка завершена"
