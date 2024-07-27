#!/bin/bash

declare -A commands

# Функция для проверки наличия команды в .bashrc
command_exists_in_bashrc() {
    local command="$1"
    grep -q -F "$command" ~/.bashrc
}

# 🚀 Функция для добавления команды
add_command() {
    local key="$1"
    local command="$2"
    commands["$key"]="$command"
    echo "✅ Команда '$key' успешно добавлена!"
}

# ✏️ Функция для редактирования команды
edit_command() {
    local key="$1"
    local command="$2"
    if [ "${commands["$key"]+isset}" ]; then
        commands["$key"]="$command"
        echo "✏️ Команда '$key' успешно отредактирована!"
    else
        echo "❌ Команда с ключом '$key' не существует."
    fi
}

# 🗑️ Функция для удаления команды
delete_command() {
    local key="$1"
    unset commands["$key"]
    echo "🗑️ Команда '$key' удалена."
}

# ▶️ Функция для выполнения команды
execute_command() {
    local key="$1"
    if [ "${commands["$key"]+isset}" ]; then
        eval "${commands["$key"]}"
    else
        echo "❌ Команда с ключом '$key' не существует."
    fi
}

# 🔍 Функция для отображения всех команд
list_commands() {
    echo "📋 Зарегистрированные команды:"
    for key in "${!commands[@]}"; do
        echo "🔑 $key: ${commands[$key]}"
    done
}

# Функция для загрузки команд из файла
load_commands() {
    if [ -f "$COMMANDS_DB" ]; then
        source $COMMANDS_DB
    fi
}

# Функция для сохранения команд в файл
save_commands() {
    declare -p commands > $COMMANDS_DB
}

# Загрузка команд при запуске
load_commands

# Сохранение команд при выходе
trap save_commands EXIT

# Функция для добавления алиаса, если его нет в .bashrc
add_alias_if_not_exists() {
    local alias_name="$1"
    local alias_command="$2"
    if ! command_exists_in_bashrc "alias $alias_name"; then
        echo "alias $alias_name='$alias_command'" >> ~/.bashrc
        echo "🔗 Алиас '$alias_name' добавлен."
    else
        echo "⏩ Алиас '$alias_name' уже существует."
    fi
}

# Добавление алиасов
add_alias_if_not_exists "prp" "poetry run python"
add_alias_if_not_exists "run" "DEBUG=True poetry run python manage.py runserver"
add_alias_if_not_exists "mm" "poetry run python manage.py makemigrations && poetry run python manage.py migrate"
add_alias_if_not_exists "migrate" "poetry run python manage.py migrate"
add_alias_if_not_exists "work" "cd /mnt/c/work/gallery360"
add_alias_if_not_exists "shop" "cd /mnt/c/code/shop/"
add_alias_if_not_exists "phasotech" "cd /mnt/c/code/phasotech/"
add_alias_if_not_exists "crearama" "cd /mnt/c/code/crearama/"
add_alias_if_not_exists "push" "./test_server.sh"
add_alias_if_not_exists "archive" "poetry run python archivator.py"
add_alias_if_not_exists "openwork" "explorer.exe C:\\work\\gallery360"
add_alias_if_not_exists "csu" "poetry run python manage.py createsuperuser"

# Установка PATH
if ! command_exists_in_bashrc 'export PATH="/usr/local/bin:$PATH"'; then
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
fi

# Функции для управления путями
addpath() {
    key=$1
    current_path=$(pwd)
    jq --arg key "$key" --arg path "$current_path" '.[$key] = $path' ~/paths.json > tmp.$$.json && mv tmp.$$.json ~/paths.json
}

goto() {
    key=$1
    path=$(jq -r --arg key "$key" '.[$key]' ~/paths.json)
    if [[ $path != "null" ]]; then
        cd $path
    else
        echo "❌ Ключ '$key' не найден."
    fi
}

listpaths() {
    echo "📋 Список сохраненных путей:"
    jq 'to_entries | .[] | "\(.key): \(.value)"' ~/paths.json -r
}

removepath() {
    key=$1
    jq --arg key "$key" 'del(.[$key])' ~/paths.json > tmp.$$.json && mv tmp.$$.json ~/paths.json
    echo "🗑️ Путь для ключа '$key' удален."
}
