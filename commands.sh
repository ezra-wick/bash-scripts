#!/bin/bash

declare -A commands
COMMANDS_DB=~/.commands_db.sh
LOG_FILE=~/commands.log

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
    echo -e "${GREEN}✅ Команда '$key' успешно добавлена!${NC}" | tee -a $LOG_FILE
    save_commands
    register_command_in_bashrc "$key"
    source ~/.bashrc
    echo "Команда '$key' добавлена и .bashrc обновлен." | tee -a $LOG_FILE
}

# ✏️ Функция для редактирования команды с перерегистрацией
edit_command() {
    local key="$1"
    local command="$2"
    if [ "${commands["$key"]+isset}" ];then
        commands["$key"]="$command"
        echo -е "${GREEN}✏️ Команда '$key' успешно отредактирована!${NC}" | tee -a $LOG_FILE
        save_commands
        register_command_in_bashrc "$key"
        source ~/.bashrc
        echo "Команда '$key' отредактирована и .bashrc обновлен." | tee -a $LOG_FILE
    else
        echo -е "${RED}❌ Команда с ключом '$key' не существует.${NC}" | tee -a $LOG_FILE
    fi
}

# 🗑️ Функция для удаления команды
delete_command() {
    local key="$1"
    unset commands["$key"]
    echo -е "${GREEN}🗑️ Команда '$key' удалена.${NC}" | tee -a $LOG_FILE
    save_commands
    # Удаление алиаса из .bashrc
    sed -i "/alias $key=/d" ~/.bashrc
    source ~/.bashrc
    echo "Команда '$key' удалена и .bashrc обновлен." | tee -a $LOG_FILE
}

# ▶️ Функция для выполнения команды
execute_command() {
    local key="$1"
    if [ "${commands["$key"]+isset}" ];then
        echo "Выполнение команды '$key': ${commands[$key]}" | tee -a $LOG_FILE
        eval "${commands["$key"]}"
    else
        echo -е "${RED}❌ Команда с ключом '$key' не существует.${NC}" | tee -a $LOG_FILE
    fi
}

# 🔍 Функция для отображения всех команд с адаптивным выравниванием
list_commands() {
    echo -е "${CYAN}📋 Зарегистрированные команды:${NC}" | tee -a $LOG_FILE
    local max_key_length=0
    local max_value_length=0
    for key in "${!commands[@]}";do
        if [[ ${#key} -gt $max_key_length ]];then
            max_key_length=${#key}
        fi
        if [[ ${#commands[$key]} -gt $max_value_length ]];then
            max_value_length=${#commands[$key]}
        fi
    done

    for key in "${!commands[@]}";do
        printf "${YELLOW}🔑 %-*s${NC} %s\n" $max_key_length "$key" "${commands[$key]}" | tee -a $LOG_FILE
    done
}

# Функция для загрузки команд из файла
load_commands() {
    if [ -f "$COMMANDS_DB" ];then
        source $COMMANDS_DB
        echo "Команды загружены из $COMMANDS_DB" | tee -a $LOG_FILE
    fi
}

# Функция для сохранения команд в файл
save_commands() {
    declare -p commands > $COMMANDS_DB
    echo "Команды сохранены в $COMMANDS_DB" | tee -a $LOG_FILE
}

# Загрузка команд при запуске
load_commands

# Сохранение команд при выходе
trap save_commands EXIT

# Функция для добавления алиаса, если его нет в .bashrc
register_command_in_bashrc() {
    local key="$1"
    if ! command_exists_in_bashrc "alias $key";then
        echo "alias $key='execute_command $key'" >> ~/.bashrc
        echo -е "${GREEN}🔗 Команда '$key' зарегистрирована в .bashrc.${NC}" | tee -a $LOG_FILE
    else
        echo -е "${CYAN}⏩ Команда '$key' уже зарегистрирована.${NC}" | tee -a $LOG_FILE
    fi
}

# Функция для комбинирования команд
combine_commands() {
    local new_key="$1"
    shift
    local combined_command=""
    for key in "$@";do
        if [ "${commands["$key"]+isset}" ];then
            combined_command+="${commands["$key"]} && "
        else
            echo -е "${RED}❌ Команда с ключом '$key' не существует.${NC}" | tee -a $LOG_FILE
            return 1
        fi
    done
    combined_command="${combined_command::-4}" # Удаление последнего ' && '
    add_command "$new_key" "$combined_command"
    echo "Комбинированная команда '$new_key' добавлена." | tee -a $LOG_FILE
}

# 🆘 Функция для отображения помощи с примерами использования
help() {
    echo -е "\n${CYAN}ℹ️  Доступные команды и функции:${NC}\n" | tee -a $LOG_FILE
    sleep 0.5
    echo -е "${YELLOW}➕ add_command <ключ> <команда>${NC}      - Добавить команду" | tee -a $LOG_FILE
    echo -е "${GRAY}   Пример: add_command start 'python3 app.py'${NC}" | tee -a $LOG_FILE
    sleep 0.3
    echo -е "\n${YELLOW}✏️ edit_command <ключ> <команда>${NC}     - Редактировать команду" | tee -a $LOG_FILE
    echo -е "${GRAY}   Пример: edit_command start 'python3 server.py'${NC}" | tee -a $LOG_FILE
    sleep 0.3
    echo -е "\n${YELLOW}🗑️ delete_command <ключ>${NC}              - Удалить команду" | tee -a $LOG_FILE
    echo -е "${GRAY}   Пример: delete_command start${NC}" | tee -a $LOG_FILE
    sleep 0.3
    echo -е "\n${YELLOW}▶️ execute_command <ключ>${NC}             - Выполнить команду" | tee -a $LOG_FILE
    echo -е "${GRAY}   Пример: execute_command start${NC}" | tee -a $LOG_FILE
    sleep 0.3
    echo -е "\n${YELLOW}🔍 list_commands${NC}                       - Показать все команды" | tee -a $LOG_FILE
    sleep 0.3
    echo -е "\n${YELLOW}➕ addpath <ключ>${NC}                      - Добавить текущий путь по ключу" | tee -a $LOG_FILE
    echo -е "${GRAY}   Пример: addpath project${NC}" | tee -a $LOG_FILE
    sleep 0.3
    echo -е "\n${YELLOW}▶️ goto <ключ>${NC}                         - Перейти к сохранённому пути" | tee -a $LOG_FILE
    echo -е "${GRAY}   Пример: goto project${NC}" | tee -a $LOG_FILE
    sleep 0.3
    echo -е "\n${YELLOW}📋 listpaths${NC}                           - Показать все сохранённые пути" | tee -a $LOG_FILE
    sleep 0.3
    echo -е "\n${YELLOW}🗑️ removepath <ключ>${NC}                   - Удалить сохранённый путь" | tee -a $LOG_FILE
    echo -е "${GRAY}   Пример: removepath project${NC}" | tee -a $LOG_FILE
    sleep 0.3
    echo -е "\n${YELLOW}🆘 help${NC}                                - Показать это сообщение\n" | tee -a $LOG_FILE
    sleep 0.3
}
