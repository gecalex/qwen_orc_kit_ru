#!/bin/bash
# Скрипт: scripts/release-tools/create-release-artifact.sh
# Назначение: Создание релизного артефакта из шаблона

set -e

RELEASE_VERSION="$1"
OUTPUT_DIR="${2:-releases}"

if [ -z "$RELEASE_VERSION" ]; then
    echo "Использование: $0 <версия-релиза> [директория-вывода]"
    echo "Пример: $0 1.0.0 releases/"
    exit 1
fi

echo "=== Создание релизного артефакта версии $RELEASE_VERSION ==="

# Проверка наличия конфигурации релиза
if [ ! -f "release-config.toml" ]; then
    echo "Ошибка: Файл конфигурации релиза release-config.toml не найден"
    exit 1
fi

# Создание директории выпусков
mkdir -p "$OUTPUT_DIR"

# Создание временной директории для подготовки релиза
TEMP_DIR=$(mktemp -d)
echo "Временная директория: $TEMP_DIR"

# Копирование всех файлов в временную директорию
echo "Копирование файлов в временную директорию..."
cp -r . "$TEMP_DIR/source_project" --exclude='.git' 2>/dev/null || true

# Переход во временную директорию
cd "$TEMP_DIR/source_project"

# Запуск скрипта очистки
echo "Запуск скрипта очистки..."
../scripts/release-tools/clean-for-template.sh

# Проверка, что очистка прошла успешно
if [ $? -ne 0 ]; then
    echo "Ошибка: Скрипт очистки завершился с ошибкой"
    exit 1
fi

# Возвращение в исходную директорию
cd "$TEMP_DIR"

# Переименование директории в имя релиза
mv source_project "qwen-orc-kit-template-$RELEASE_VERSION"

# Создание архива
ARCHIVE_NAME="qwen-orc-kit-template-$RELEASE_VERSION.tar.gz"
tar -czf "$ARCHIVE_NAME" "qwen-orc-kit-template-$RELEASE_VERSION/"

# Перемещение архива в директорию выпусков
mv "$ARCHIVE_NAME" "../../$OUTPUT_DIR/"

# Возвращение в исходную директорию проекта
cd "../../"

# Удаление временной директории
rm -rf "$TEMP_DIR"

echo "=== Релизный артефакт создан ==="
echo "Файл: $OUTPUT_DIR/$ARCHIVE_NAME"
echo "Размер: $(du -h $OUTPUT_DIR/$ARCHIVE_NAME | cut -f1)"

# Проверка целостности архива
echo "Проверка целостности архива..."
if tar -tzf "$OUTPUT_DIR/$ARCHIVE_NAME" > /dev/null; then
    echo "✓ Архив действителен"
else
    echo "✗ Архив поврежден"
    exit 1
fi

echo ""
echo "Релизный артефакт $RELEASE_VERSION успешно создан!"
echo "Для тестирования можно распаковать архив и проверить его содержимое:"
echo "  tar -xzf $OUTPUT_DIR/$ARCHIVE_NAME"
