#!/bin/bash
# Тест для проверки корректности создания навыков

echo "Запуск тестов для экспериментальных навыков..."

# Проверка наличия директории навыков
if [ -d ".qwen/skills" ]; then
  echo "✓ Директория .qwen/skills существует"
else
  echo "✗ Директория .qwen/skills отсутствует"
  exit 1
fi

# Проверка наличия файлов настроек
if [ -f ".qwen/settings.json" ]; then
  echo "✓ Файл настроек .qwen/settings.json существует"
else
  echo "✗ Файл настроек .qwen/settings.json отсутствует"
  exit 1
fi

# Проверка наличия основных навыков
SKILLS=("security-analyzer" "code-quality-checker" "bug-hunter" "bug-fixer" "tech-translator-ru" "documentation-generator" "code-refactorer" "skill-template")

for skill in "${SKILLS[@]}"; do
  if [ -f ".qwen/skills/$skill/SKILL.md" ]; then
    echo "✓ Навык $skill и его файл SКILL.md существуют"
  else
    echo "✗ Навык $skill или его файл SКILL.md отсутствует"
    exit 1
  fi
done

# Проверка содержимого файла настроек
if grep -q "skills.*true" ".qwen/settings.json"; then
  echo "✓ Настройки экспериментальных навыков корректны"
else
  echo "✗ Настройки экспериментальных навыков некорректны"
  exit 1
fi

# Проверка YAML заголовков в файлах навыков
for skill in "${SKILLS[@]}"; do
  if head -n 10 ".qwen/skills/$skill/SKILL.md" | grep -q "^---$" && \
     head -n 10 ".qwen/skills/$skill/SKILL.md" | grep -q "name:" && \
     head -n 10 ".qwen/skills/$skill/SKILL.md" | grep -q "description:"; then
    echo "✓ YAML заголовок для навыка $skill корректен"
  else
    echo "✗ YAML заголовок для навыка $skill некорректен"
    exit 1
  fi
done

echo ""
echo "Все тесты для экспериментальных навыков пройдены успешно!"
echo "Система навыков агента готова к использованию."
