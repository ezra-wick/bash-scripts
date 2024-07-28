#!/bin/bash

# Путь к вашему скрипту
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
TARGET_DIR="$HOME/.bash-scripts"
TARGET_PATH="$TARGET_DIR/$SCRIPT_NAME"
BASHRC_PATH="$HOME/.bashrc"
LOG_FILE="$HOME/script.log"
CONFIG_FILE="$TARGET_DIR/config.json"
COMMANDS_DB="$TARGET_DIR/commands_db.sh"
PATHS_FILE="$HOME/paths.json"

# Создание директории для скрипта в home, если не существует
mkdir -p "$TARGET_DIR"
sudo apt install jq
# Копирование скрипта в TARGET_DIR
cp "$SCRIPT_PATH" "$TARGET_PATH"

# Создание файла paths.json, если его нет
if [ ! -f "$PATHS_FILE" ]; then
    echo "{}" > "$PATHS_FILE"
    echo "Файл paths.json создан."
fi

# Функция для логгирования
log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

log "Скрипт запущен"

# Функция для добавления строки в .bashrc, если ее там нет
add_to_bashrc() {
    local line="$1"
    if ! grep -qF "$line" "$BASHRC_PATH"; then
        echo "$line" >> "$BASHRC_PATH"
        log "Добавлена строка в .bashrc: $line"
    fi
}

# Проверка и добавление строки в .bashrc
add_to_bashrc "if [ -f \"$TARGET_PATH\" ]; then . \"$TARGET_PATH\"; fi"

# Функция для загрузки конфигурации
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        USERNAME=$(grep '"username"' "$CONFIG_FILE" | cut -d '"' -f 4)
        REPOSITORY=$(grep '"repository"' "$CONFIG_FILE" | cut -d '"' -f 4)
        log "Конфигурация загружена: USERNAME=$USERNAME, REPOSITORY=$REPOSITORY"
    else
        log "Файл конфигурации не найден, использую значения по умолчанию"
        USERNAME=""
        REPOSITORY=""
    fi
}

# Функция для сохранения конфигурации
save_config() {
    cat <<EOF > "$CONFIG_FILE"
{
    "username": "$USERNAME",
    "repository": "$REPOSITORY"
}
EOF
    log "Конфигурация сохранена: USERNAME=$USERNAME, REPOSITORY=$REPOSITORY"
}

# Функция для установки имени пользователя
set_username() {
    USERNAME="$1"
    save_config
    echo -e "${GREEN}Имя пользователя установлено: $USERNAME${NC}"
}

# Функция для установки имени репозитория
set_repository() {
    REPOSITORY="$1"
    save_config
    echo -e "${GREEN}Имя репозитория установлено: $REPOSITORY${NC}"
}

# Загрузка конфигурации
load_config

# Создание алиасов и команд
declare -A commands
echo "Путь к файлу базы данных команд: $COMMANDS_DB"

# Цветовые коды
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[0;31m'
GRAY='\033[1;30m'
NC='\033[0m' # No Color

# Функция загрузки команд из базы данных
load_commands() {
    if [ -f "$COMMANDS_DB" ]; then
        source "$COMMANDS_DB"
        log "Команды загружены из $COMMANDS_DB"
    fi
}

# Функция сохранения команд в базу данных
save_commands() {
    echo "Сохранение команд в файл $COMMANDS_DB..."
    {
        for key in "${!commands[@]}"; do
            echo "commands[$key]='${commands[$key]}'"
        done
    } > "$COMMANDS_DB"
    log "Команды успешно сохранены в $COMMANDS_DB"
    echo "✅ Команды успешно сохранены в $COMMANDS_DB"
}

# Функция для добавления алиасов, если они еще не существуют
add_alias_if_not_exists() {
    local alias_name="$1"
    local alias_command="$2"
    if ! grep -qF "alias $alias_name" "$BASHRC_PATH"; then
        echo "alias $alias_name='$alias_command'" >> "$BASHRC_PATH"
        echo -e "${GREEN}🔗 Алиас '$alias_name' добавлен.${NC}"
        log "Алиас '$alias_name' добавлен"
    else
        echo -e "${CYAN}⏩ Алиас '$alias_name' уже существует.${NC}"
        log "Алиас '$alias_name' уже существует"
    fi
}

# Установка алиасов
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
if ! grep -qF 'export PATH="/usr/local/bin:$PATH"' "$BASHRC_PATH"; then
    echo 'export PATH="/usr/local/bin:$PATH"' >> "$BASHRC_PATH"
fi

# Функция для регистрации алиасов в текущей сессии
register_command_in_current_session() {
    local key="$1"
    local command="${commands[$key]}"
    alias "$key"="$command"
    log "Команда '$key' зарегистрирована в текущей сессии"
}


# Функция для добавления команды с автоматическим сохранением
add_command() {
    local key="$1"
    local command="$2"
    commands["$key"]="$command"
    save_commands
    register_command_in_current_session "$key"
    echo -e "${GREEN}✅ Команда '$key' успешно добавлена!${NC}"
    log "Команда '$key' добавлена с командой '$command'"
}


# Функция для редактирования команды
edit_command() {
    local key="$1"
    local command="$2"
    if [ "${commands["$key"]+isset}" ]; then
        commands["$key"]="$command"
        echo -e "${GREEN}✏️ Команда '$key' успешно отредактирована!${NC}"
        save_commands
        register_command_in_bashrc "$key"
        log "Команда '$key' отредактирована"
    else
        echo -e "${RED}❌ Команда с ключом '$key' не существует.${NC}"
        log "Попытка редактирования несуществующей команды '$key'"
    fi
}

# Функция для удаления команды
delete_command() {
    local key="$1"
    unset commands["$key"]
    echo -e "${GREEN}🗑️ Команда '$key' удалена.${NC}"
    save_commands
    log "Команда '$key' удалена"
}

# Функция для выполнения команды
execute_command() {
    local key="$1"
    if [ "${commands["$key"]+isset}" ]; then
        eval "${commands["$key"]}"
        log "Команда '$key' выполнена: ${commands["$key"]}"
    else
        echo -e "${RED}❌ Команда с ключом '$key' не существует.${NC}"
        log "Попытка выполнения несуществующей команды '$key'"
    fi
}

# Функция для отображения всех команд с адаптивным выравниванием
list_commands() {
    echo -e "${CYAN}📋 Зарегистрированные команды:${NC}"
    local max_key_length=0
    for key in "${!commands[@]}"; do
        if [[ ${#key} -gt $max_key_length ]]; then
            max_key_length=${#key}
        fi
    done

    for key in "${!commands[@]}"; do
        printf "${YELLOW}🔑 %-*s${NC} %s\n" $max_key_length "$key" "${commands[$key]}"
    done
    log "Показан список команд"
}

# Функция для добавления алиаса, если его нет в .bashrc
register_command_in_bashrc() {
    local key="$1"
    if ! grep -qF "alias $key='execute_command $key'" "$BASHRC_PATH"; then
        echo "alias $key='execute_command $key'" >> "$BASHRC_PATH"
        echo -e "${GREEN}🔗 Команда '$key' зарегистрирована в .bashrc.${NC}"
        log "Команда '$key' зарегистрирована в .bashrc"
    fi
}

load_and_register_commands() {
    load_commands
    for key in "${!commands[@]}"; do
        register_command_in_current_session "$key"
    done
}

load_and_register_commands

# Функции для управления путями
addpath() {
    key=$1
    current_path=$(pwd)
    paths_file="$HOME/paths.json"

    # Создание файла paths.json, если его нет
    if [ ! -f "$paths_file" ]; then
        echo "{}" > "$paths_file"
    fi

    # Добавление нового пути в paths.json
    jq --arg key "$key" --arg path "$current_path" '. + {($key): $path}' "$paths_file" > "$paths_file.tmp" && mv "$paths_file.tmp" "$paths_file"

    echo -e "${GREEN}➕ Путь для ключа '$key' успешно добавлен!${NC}"
    log "Путь для ключа '$key' добавлен: $current_path"
}

goto() {
    key=$1
    paths_file="$HOME/paths.json"

    # Проверка существования файла paths.json
    if [ ! -f "$paths_file" ]; then
        echo -e "${RED}❌ Файл paths.json не найден.${NC}"
        log "Файл paths.json не найден при попытке перемещения"
        return 1
    fi

    path=$(jq -r --arg key "$key" '.[$key] // empty' "$paths_file")

    if [[ $path != "" ]]; then
        cd "$path"
        echo -e "${CYAN}🔄 Перемещен в: $path${NC}"
        log "Перемещен в: $path"
    else
        echo -e "${RED}❌ Ключ '$key' не найден.${NC}"
        log "Ключ '$key' не найден при попытке перемещения"
    fi
}

listpaths() {
    paths_file="$HOME/paths.json"

    # Проверка существования файла paths.json
    if [ ! -f "$paths_file" ]; then
        echo -e "${RED}❌ Файл paths.json не найден.${NC}"
        log "Файл paths.json не найден при попытке отображения путей"
        return 1
    fi

    echo -e "${CYAN}📋 Список сохраненных путей:${NC}"
    jq -r 'to_entries[] | "\(.key): \(.value)"' "$paths_file"
    log "Показан список путей"
}

removepath() {
    key=$1
    paths_file="$HOME/paths.json"

    # Проверка существования файла paths.json
    if [ ! -f "$paths_file" ]; then
        echo -e "${RED}❌ Файл paths.json не найден.${NC}"
        log "Файл paths.json не найден при попытке удаления пути"
        return 1
    fi

    # Удаление ключа из paths.json
    jq --arg key "$key" 'del(.[$key])' "$paths_file" > "$paths_file.tmp" && mv "$paths_file.tmp" "$paths_file"

    echo -e "${GREEN}🗑️ Путь для ключа '$key' удален.${NC}"
    log "Путь для ключа '$key' удален"
}

# Функция для комбинирования команд
combine_commands() {
    local new_key="$1"
    shift
    local combined_command=""
    for key in "$@"; do
        if [ "${commands["$key"]+isset}" ]; then
            combined_command+="${commands["$key"]} && "
        else
            echo -e "${RED}❌ Команда с ключом '$key' не существует.${NC}"
            log "Попытка комбинирования с несуществующей командой '$key'"
            return 1
        fi
    done
    combined_command="${combined_command::-4}" # Удаление последнего ' && '
    add_command "$new_key" "$combined_command"
    log "Скомбинирована команда '$new_key' из команд: $@"
}


# 🆘 Функция для отображения помощи с примерами использования
show_help() {
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
    echo -e "\n${YELLOW}▶️ goto <ключ>${NC}                        - Перейти к пути по ключу"
    echo -e "${GRAY}   Пример: goto project${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}🔍 listpaths${NC}                         - Показать все сохраненные пути"
    sleep 0.3
    echo -e "\n${YELLOW}🗑️ removepath <ключ>${NC}                   - Удалить путь по ключу"
    echo -e "${GRAY}   Пример: removepath project${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}🔗 combine_commands <новый_ключ> <ключ1> <ключ2> ...${NC} - Комбинировать несколько команд"
    echo -e "${GRAY}   Пример: combine_commands all start stop${NC}"
    sleep 0.3
    echo -e "\n${YELLOW}📖 show_help${NC}                         - Показать это сообщение"
    log "Показано сообщение помощи"
}


# Обработка команд
case "$1" in
    add_command)
        shift
        add_command "$@"
        ;;
    edit_command)
        shift
        edit_command "$@"
        ;;
    delete_command)
        shift
        delete_command "$1"
        ;;
    execute_command)
        shift
        execute_command "$1"
        ;;
    list_commands)
        list_commands
        ;;
    addpath)
        shift
        addpath "$1"
        ;;
    goto)
        shift
        goto "$1"
        ;;
    listpaths)
        listpaths
        ;;
    removepath)
        shift
        removepath "$1"
        ;;
    combine_commands)
        shift
        combine_commands "$@"
        ;;
    set_username)
        shift
        set_username "$1"
        ;;
    set_repository)
        shift
        set_repository "$1"
        ;;
    help|*)
        show_help
        ;;
esac

