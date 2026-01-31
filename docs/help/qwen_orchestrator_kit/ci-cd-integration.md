# Хуки для Git для интеграции с агентом-специалистом по Qwen Code CLI

# pre-commit хук для проверки стандартов
# Установите этот файл как .git/hooks/pre-commit

#!/bin/bash

echo "Запуск проверки соответствия стандартам Qwen Code CLI..."

# Проверяем YAML заголовки
echo "Проверка YAML заголовков..."
bash /home/alex/MyProjects/qwen_orc_kit_ru/scripts/validation/check-standards-compliance.sh

if [ $? -ne 0 ]; then
    echo "❌ Обнаружены нарушения стандартов. Коммит отменен."
    echo "Пожалуйста, исправьте ошибки и попробуйте снова."
    exit 1
fi

echo "✅ Все проверки пройдены успешно!"

exit 0