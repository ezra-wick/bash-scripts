#!/bin/bash

declare -A commands
COMMANDS_DB=~/.commands_db.sh

# Цветовые коды
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[0;31m'
GRAY='\033[1;30m'
NC='\033[0m' # No Color

# Функция для проверки наличия команды в .bashrc
command_exists_in_bashrc() {
    local command="$1"
    grep -q -F "$command" ~/.bashrc
}

# 🚀 Функция для добавления команды с автоматическим сохранением
add_command() {
    local key="$1"
    local command="$2"
    commands["$key"]="$command"
    echo -e "${GREEN}✅ Команда '$key' успешно добавлена!${NC}"
    save_commands
}

# ✏️ Функция для редактирования команды
edit_command() {
    local key="$1"
    local command="$2"
    if [ "${commands["$key"]+isset}" ]; then
        commands["$key"]="$command"
        echo -e "${GREEN}✏️ Команда '$key' успешно отредактирована!${NC}"
        save_commands
    else
        echo -e "${RED}❌ Команда с ключом '$key' не существует.${NC}"
    fi
}

# 🗑️ Функция для удаления команды
delete_command() {
    local key="$1"
    unset commands["$key"]
    echo -e "${GREEN}🗑️ Команда '$key' удалена.${NC}"
    save_commands
}

# ▶️ Функция для выполнения команды
execute_command() {
    local key="$1"
    if [ "${commands["$key"]+isset}" ]; then
        eval "${commands["$key"]}"
    else
        echo -e "${RED}❌ Команда с ключом '$key' не существует.${NC}"
    fi
}

# 🔍 Функция для отображения всех команд с адаптивным выравниванием
list_commands() {
    echo -e "${CYAN}📋 Зарегистрированные команды:${NC}"
    local max_key_length=0
    local max_value_length=0
    for key in "${!commands[@]}"; do
        if [[ ${#key} -gt $max_key_length ]]; then
            max_key_length=${#key}
        fi
        if [[ ${#commands[$key]} -gt $max_value_length ]]; then
            max_value_length=${#commands[$key]}
        fi
    done

    for key in "${!commands[@]}"; do
        printf "${YELLOW}🔑 %-*s${NC} %s\n" $max_key_length "$key" "${commands[$key]}"
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
        echo -e "${GREEN}🔗 Алиас '$alias_name' добавлен.${NC}"
    else
        echo -e "${CYAN}⏩ Алиас '$alias_name' уже существует.${NC}"
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
    echo -e "${GREEN}➕ Путь для ключа '$key' успешно добавлен!${NC}"
}

goto() {
    key=$1
    path=$(jq -r --arg key "$key" '.[$key]' ~/paths.json)
    if [[ $path != "null" ]]; then
        cd $path
        echo -e "${CYAN}🔄 Перемещен в: $path${NC}"
    else
        echo -e "${RED}❌ Ключ '$key' не найден.${NC}"
    fi
}

listpaths() {
    echo -e "${CYAN}📋 Список сохраненных путей:${NC}"
    jq -r 'to_entries[] | "\(.key) \(.value)"' ~/paths.json | column -t
}

removepath() {
    key=$1
    jq --arg key "$key" 'del(.[$key])' ~/paths.json > tmp.$$.json && mv tmp.$$.json ~/paths.json
    echo -e "${GREEN}🗑️ Путь для ключа '$key' удален.${NC}"
}

# 🆘 Функция для отображения помощи с примерами использования
help() {
    echo -e "\n${CYAN}ℹ️  Доступные команды и функции:${NC}\n"
    sleep 0.5
    echo -e "${YELLOW}➕ add_command <ключ> <команда>${NC}      - Добавить команду"
    echo -e "${GRAY}   Пример: add_command start 'python3 app.py'${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}✏️ edit_command <ключ> <команда>${NC}     - Редактировать команду"
    echo -e "${GRAY}   Пример: edit_command start 'python3 server.py'${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}🗑️ delete_command <ключ>${NC}              - Удалить команду"
    echo -e "${GRAY}   Пример: delete_command start${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}▶️ execute_command <ключ>${NC}             - Выполнить команду"
    echo -e "${GRAY}   Пример: execute_command start${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}🔍 list_commands${NC}                       - Показать все команды"
    sleep 0.3
    echo -e "\n${YELLOW}➕ addpath <ключ>${NC}                      - Добавить текущий путь по ключу"
    echo -e "${GRAY}   Пример: addpath project${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}▶️ goto <ключ>${NC}                         - Перейти к сохранённому пути"
    echo -e "${GRAY}   Пример: goto project${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}📋 listpaths${NC}                           - Показать все сохранённые пути"
    sleep 0.3
    echo -e "\n${YELLOW}🗑️ removepath <ключ>${NC}                   - Удалить сохранённый путь"
    echo -e "${GRAY}   Пример: removepath project${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}🆘 help${NC}                                - Показать это сообщение\n"
    sleep 0.3
}
