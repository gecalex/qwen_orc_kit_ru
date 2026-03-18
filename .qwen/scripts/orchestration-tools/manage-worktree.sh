#!/bin/bash

# Скрипт управления worktree
# Позволяет создавать, просматривать и удалять worktree для параллельной разработки

set -e  # Прервать при ошибке

WORKTREE_DIR=".worktrees"
COMMAND="${1:-help}"

# Проверить, является ли текущий каталог Git-репозиторием
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Ошибка: Текущий каталог не является Git-репозиторием"
    exit 1
fi

create_worktree() {
    local feature_name="$1"
    
    if [ -z "$feature_name" ]; then
        echo "Ошибка: Не указано название фичи"
        echo "Использование: $0 create <feature-name>"
        exit 1
    fi
    
    # Создать имя ветки
    BRANCH_NAME="feature/$feature_name"
    
    # Проверить, существует ли уже ветка
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "Ошибка: Ветка $BRANCH_NAME уже существует"
        exit 1
    fi
    
    # Создать ветку на основе текущей
    git checkout -b "$BRANCH_NAME" >/dev/null 2>&1
    echo "Создана ветка: $BRANCH_NAME"
    
    # Создать директорию для worktree
    mkdir -p "$WORKTREE_DIR"
    
    # Создать worktree
    WORKTREE_PATH="$WORKTREE_DIR/$feature_name"
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME" >/dev/null 2>&1
    echo "Создан worktree: $WORKTREE_PATH"
    echo "Ветка: $BRANCH_NAME"
    echo ""
    echo "Worktree успешно создан!"
    echo "Перейдите в директорию: cd $WORKTREE_PATH"
    echo "Для возврата в основной проект: cd ../.."
}

list_worktrees() {
    echo "Список worktree:"
    git worktree list
    echo ""
    
    # Показать дополнительную информацию о worktree в .worktrees/
    if [ -d "$WORKTREE_DIR" ]; then
        echo "Worktree в $WORKTREE_DIR:"
        for dir in "$WORKTREE_DIR"/*/; do
            if [ -d "$dir" ]; then
                dir_name=$(basename "$dir")
                echo "- $dir_name"
            fi
        done
    else
        echo "Директория $WORKTREE_DIR не существует или пуста"
    fi
}

remove_worktree() {
    local feature_name="$1"
    
    if [ -z "$feature_name" ]; then
        echo "Ошибка: Не указано название фичи"
        echo "Использование: $0 remove <feature-name>"
        exit 1
    fi
    
    # Найти путь к worktree
    WORKTREE_PATH="$WORKTREE_DIR/$feature_name"
    
    if [ ! -d "$WORKTREE_PATH" ]; then
        echo "Ошибка: Worktree $WORKTREE_PATH не существует"
        exit 1
    fi
    
    # Получить имя ветки из worktree
    cd "$WORKTREE_PATH"
    BRANCH_NAME=$(git branch --show-current)
    cd - >/dev/null
    
    # Удалить worktree
    git worktree remove "$WORKTREE_PATH" >/dev/null 2>&1
    echo "Удален worktree: $WORKTREE_PATH"
    
    # Удалить директорию worktree
    rm -rf "$WORKTREE_PATH"
    echo "Удалена директория: $WORKTREE_PATH"
    
    # Удалить ветку (локально)
    git branch -D "$BRANCH_NAME" >/dev/null 2>&1
    echo "Удалена ветка: $BRANCH_NAME"
    
    echo ""
    echo "Worktree успешно удален!"
}

show_help() {
    echo "Скрипт управления worktree"
    echo ""
    echo "Использование: $0 <command> [arguments]"
    echo ""
    echo "Команды:"
    echo "  create <feature-name> - создать новый worktree для фичи"
    echo "  list                 - показать список всех worktree"
    echo "  remove <feature-name> - удалить указанный worktree"
    echo "  help                 - показать это справочное сообщение"
    echo ""
    echo "Примеры:"
    echo "  $0 create new-auth-system"
    echo "  $0 list"
    echo "  $0 remove new-auth-system"
}

case "$COMMAND" in
    "create")
        create_worktree "$2"
        ;;
    "list")
        list_worktrees
        ;;
    "remove")
        remove_worktree "$2"
        ;;
    "help"|*)
        show_help
        ;;
esac