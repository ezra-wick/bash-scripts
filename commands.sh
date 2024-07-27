#!/bin/bash

declare -A commands
COMMANDS_DB=~/.commands_db.sh
LOG_FILE=commands.log

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

# 🚀 Функция для добавления команды с автоматическим сохранением и регистрацией
add_command() {
    local key="$1"
    local command="$2"
    commands["$key"]="$command"
    echo -e "${GREEN}✅ Команда '$key' успешно добавлена!${NC}"
    save_commands
    register_command_in_bashrc "$key"
    source ~/.bashrc
    echo "Команда '$key' добавлена с командой: '$command'" | tee -a $LOG_FILE
}

# ✏️ Функция для редактирования команды с перерегистрацией
edit_command() {
    local key="$1"
    local command="$2"
    if [ "${commands["$key"]+isset}" ]; then
        commands["$key"]="$command"
        echo -e "${GREEN}✏️ Команда '$key' успешно отредактирована!${NC}"
        save_commands
        register_command_in_bashrc "$key"
        source ~/.bashrc
        echo "Команда '$key' отредактирована на: '$command'" | tee -a $LOG_FILE
    else
        echo -e "${RED}❌ Команда с ключом '$key' не существует.${NC}"
        echo "Ошибка: Команда с ключом '$key' не существует." | tee -a $LOG_FILE
    fi
}

# 🗑️ Функция для удаления команды
delete_command() {
    local key="$1"
    unset commands["$key"]
    echo -e "${GREEN}🗑️ Команда '$key' удалена.${NC}"
    save_commands
    # Удаление алиаса из .bashrc
    sed -i "/alias $key=/d" ~/.bashrc
    source ~/.bashrc
    echo "Команда '$key' удалена." | tee -a $LOG_FILE
}

# ▶️ Функция для выполнения команды
execute_command() {
    local key="$1"
    if [ "${commands["$key"]+isset}" ]; then
        eval "${commands["$key"]}"
        echo "Команда '$key' выполнена." | tee -a $LOG_FILE
    else
        echo -e "${RED}❌ Команда с ключом '$key' не существует.${NC}"
        echo "Ошибка: Команда с ключом '$key' не существует." | tee -a $LOG_FILE
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
    echo "Команды выведены." | tee -a $LOG_FILE
}

# Функция для загрузки команд из файла
load_commands() {
    if [ -f "$COMMANDS_DB" ];то
        source $COMMANDS_DB
        echo "Команды загружены из $COMMANDS_DB." | tee -a $LOG_FILE
    else
        echo "Файл $COMMANDS_DB не найден." | tee -a $LOG_FILE
    fi
}

# Функция для сохранения команд в файл
save_commands() {
    declare -p commands > $COMMANDS_DB
    echo "Команды сохранены в $COMMANDS_DB." | tee -a $LOG_FILE
}

# Загрузка команд при запуске
load_commands

# Сохранение команд при выходе
trap save_commands EXIT

# Функция для добавления алиаса, если его нет в .bashrc
register_command_in_bashrc() {
    local key="$1"
    if ! command_exists_in_bashrc "alias $key"; then
        echo "alias $key='execute_command $key'" >> ~/.bashrc
        echo -e "${GREEN}🔗 Команда '$key' зарегистрирована в .bashrc.${NC}"
        echo "Алиас для '$key' добавлен в .bashrc." | tee -a $LOG_FILE
    else
        echo -е "${CYAN}⏩ Команда '$key' уже зарегистрирована.${NC}"
        echo "Алиас для '$key' уже существует в .bashrc." | tee -а $LOG_FILE
    fi
}

# Функция для комбинирования команд
combine_commands() {
    local new_key="$1"
    shift
    local combined_command=""
    for key in "$@"; do
        if [ "${commands["$key"]+isset}" ];то
            combined_command+="${commands["$key"]} && "
        else
            echo -е "${RED}❌ Команда с ключом '$key' не существует.${NC}"
            echo "Ошибка: Команда с ключом '$key' не существует." | tee -а $LOG_FILE
            return 1
        fi
    done
    combined_command="${combined_command::-4}" # Удаление последнего ' && '
    add_command "$new_key" "$combined_command"
    echo "Команда '$new_key' создана как комбинация команд: $combined_command" | tee -а $LOG_FILE
}

# 🆘 Функция для отображения помощи с примерами использования
help() {
    echo -е "\n${CYAN}ℹ️  Доступные команды и функции:${NC}\n"
    sleep 0.5
    echo -е "${YELLOW}➕ add_command <ключ> <команда>${NC}      - Добавить команду"
    echo -е "${GRAY}   Пример: add_command start 'python3 app.py'${NC}"
    sleep 0.3
    echo -е "\n${YELLOW}✏️ edit_command <ключ> <команда>${NC}     - Редактировать команду"
    echo -е "${GRAY}   Пример: edit_command start 'python3 server.py'${NC}"
    sleep 0.3
    echo -е "\n${YELLOW}🗑️ delete_command <ключ>${NC}              - Удалить команду"
    echo -е "${GRAY}   Пример: delete_command start${NC}"
    sleep 0.3
    echo -е "\n${YELLOW}▶️ execute_command <ключ>${NC}             - Выполнить команду"
    echo -е "${GRAY}   Пример: execute_command start${NC}"
    sleep 0.3
    echo -е "\n${YELLOW}🔍 list_commands${NC}                       - Показать все команды"
    sleep 0.3
    echo -е "\n${YELLOW}➕ addpath <ключ>${NC}                      - Добавить текущий путь по ключу"
    echo -е "${GRAY}   Пример: addpath project${NC}"
    sleep 0.3
    echo -е "\n${YELLOW}▶️ goto <ключ>${NC}                         - Перейти к сохранённому пути"
    echo -е "${GRAY}   Пример: goto project${NC}"
    sleep 0.3
    echo -е "\n${YELLOW}📋 listpaths${NC}                           - Показать все сохранённые пути"
    sleep 0.3
    echo -е "\n${YELLOW}🗑️ removepath <ключ>${NC}                   - Удалить сохранённый путь"
    echo -е "${GRAY}   Пример: removepath project${NC}"
    sleep 0.3
    echo -е "\n${YELLOW}🆘 help${NC}                                - Показать это сообщение\n"
    sleep 0.3
    echo "Сообщение помощи отображено." | tee -а $LOG_FILE
}
