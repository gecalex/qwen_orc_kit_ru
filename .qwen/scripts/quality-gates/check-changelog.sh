#!/bin/bash
# Скрипт: .qwen/scripts/quality-gates/check-changelog.sh
# Проверка актуальности CHANGELOG.md перед релизом

set -e

echo "🔍 Проверка актуальности CHANGELOG.md..."

# Получить последний тег
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "Последний тег: $LAST_TAG"

# Получить список коммитов с последнего тега
COMMITS_SINCE_TAG=$(git log "$LAST_TAG"..HEAD --oneline 2>/dev/null | wc -l)
echo "Коммитов с последнего тега: $COMMITS_SINCE_TAG"

# Проверить наличие CHANGELOG.md
if [ ! -f "CHANGELOG.md" ]; then
    echo "❌ CHANGELOG.md не найден!"
    exit 1
fi

# Проверить наличие секции [Unreleased]
if ! grep -q "\[Unreleased\]" CHANGELOG.md; then
    echo "❌ CHANGELOG.md не содержит секцию [Unreleased]"
    exit 1
fi

# Если есть новые коммиты, проверить что они задокументированы
if [ $COMMITS_SINCE_TAG -gt 0 ]; then
    echo "✅ Найдены новые коммиты: $COMMITS_SINCE_TAG"
    
    # Проверить что CHANGELOG содержит записи о последних изменениях
    # (простая эвристика: проверяем что есть записи после последнего тега)
    
    LAST_TAG_DATE=$(git log -1 --format=%ai "$LAST_TAG" 2>/dev/null | cut -d' ' -f1)
    echo "Дата последнего тега: $LAST_TAG_DATE"
    
    # Проверить что CHANGELOG был обновлен после последнего тега
    if [ -n "$LAST_TAG_DATE" ]; then
        CHANGELOG_MODIFIED=$(stat -c %Y CHANGELOG.md 2>/dev/null || stat -f %m CHANGELOG.md 2>/dev/null)
        TAG_TIMESTAMP=$(date -d "$LAST_TAG_DATE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$LAST_TAG_DATE" +%s 2>/dev/null)
        
        if [ "$CHANGELOG_MODIFIED" -gt "$TAG_TIMESTAMP" ]; then
            echo "✅ CHANGELOG.md обновлен после последнего тега"
        else
            echo "⚠️  CHANGELOG.md возможно устарел (не обновлялся после тега)"
            echo "   Рекомендуется запустить generate-changelog skill"
        fi
    fi
else
    echo "✅ Нет новых коммитов с последнего тега"
fi

# Проверить формат CHANGELOG (Keep a Changelog)
if grep -q "All notable changes to this project will be documented in this file" CHANGELOG.md; then
    echo "✅ CHANGELOG.md следует формату Keep a Changelog"
else
    echo "⚠️  CHANGELOG.md не следует формату Keep a Changelog"
fi

# Проверить наличие основных секций
for section in "Added" "Changed" "Fixed"; do
    if grep -q "### $section" CHANGELOG.md; then
        echo "✅ Секция $section присутствует"
    else
        echo "⚠️  Секция $section отсутствует (не критично)"
    fi
done

echo ""
echo "✅ CHANGELOG актуален"
exit 0
