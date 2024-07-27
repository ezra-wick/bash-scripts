#!/bin/bash

declare -A commands

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
    if [ -f "commands.db" ]; then
        source commands.db
    fi
}

# Функция для сохранения команд в файл
save_commands() {
    declare -p commands > commands.db
}

# Загрузка команд при запуске
load_commands

# Сохранение команд при выходе
trap save_commands EXIT

# Базовые алиасы
# Проверяем наличие алиасов в .bashrc перед добавлением
function add_alias_if_not_exists {
    local alias_name="$1"
    local alias_command="$2"
    if ! command_exists_in_bashrc "alias $alias_name"; then
        echo "alias $alias_name='$alias_command'" >> /home/ezra-laptop/.bashrc
        echo "🔗 Алиас '$alias_name' добавлен."
    else
        echo "⏩ Алиас '$alias_name' уже существует."
    fi
}

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
add_alias_if_not_exists "openwork" "explorer.exe C:\work\gallery360"
add_alias_if_not_exists "csu" "poetry run python manage.py createsuperuser"

# Установка PATH
if ! command_exists_in_bashrc 'export PATH="/usr/local/bin:/home/ezra-laptop/.local/bin:/home/ezra-laptop/.pyenv/shims:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/mnt/c/code/emsdk:/mnt/c/code/emsdk/upstream/emscripten:/home/ezra-laptop/.pyenv/libexec:/home/ezra-laptop/.pyenv/plugins/python-build/bin:/home/ezra-laptop/.nvm/versions/node/v18.19.1/bin:/home/ezra-laptop/.pyenv/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib:/mnt/c/Python312/Scripts/:/mnt/c/Python312/:/mnt/c/Windows/system32:/mnt/c/Windows:/mnt/c/Windows/System32/Wbem:/mnt/c/Windows/System32/WindowsPowerShell/v1.0/:/mnt/c/Windows/System32/OpenSSH/:/mnt/c/Program Files (x86)/NVIDIA Corporation/PhysX/Common:/mnt/c/Program Files/NVIDIA Corporation/NVIDIA NvDLISR:/mnt/c/Program Files/nodejs/:/mnt/c/ProgramData/chocolatey/bin:/mnt/c/Program Files/Git/cmd:/mnt/c/Users/user/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/user/AppData/Local/Programs/Microsoft VS Code/bin:/mnt/c/Users/user/AppData/Local/Microsoft/WinGet/Packages/Schniz.fnm_Microsoft.Winget.Source_8wekyb3d8bbwe:/mnt/c/Users/user/AppData/Roaming/npm:/snap/bin"'; then
    echo 'export PATH="/usr/local/bin:/home/ezra-laptop/.local/bin:/home/ezra-laptop/.pyenv/shims:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/home/ezra-laptop/.pyenv/bin:/mnt/c/code/emsdk:/mnt/c/code/emsdk/upstream/emscripten:/home/ezra-laptop/.pyenv/libexec:/home/ezra-laptop/.pyenv/plugins/python-build/bin:/home/ezra-laptop/.nvm/versions/node/v18.19.1/bin:/home/ezra-laptop/.pyenv/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib:/mnt/c/Python312/Scripts/:/mnt/c/Python312/:/mnt/c/Windows/system32:/mnt/c/Windows:/mnt/c/Windows/System32/Wbem:/mnt/c/Windows/System32/WindowsPowerShell/v1.0/:/mnt/c/Windows/System32/OpenSSH/:/mnt/c/Program Files (x86)/NVIDIA Corporation/PhysX/Common:/mnt/c/Program Files/NVIDIA Corporation/NVIDIA NvDLISR:/mnt/c/Program Files/nodejs/:/mnt/c/ProgramData/chocolatey/bin:/mnt/c/Program Files/Git/cmd:/mnt/c/Users/user/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/user/AppData/Local/Programs/Microsoft VS Code/bin:/mnt/c/Users/user/AppData/Local/Microsoft/WinGet/Packages/Schniz.fnm_Microsoft.Winget.Source_8wekyb3d8bbwe:/mnt/c/Users/user/AppData/Roaming/npm:/snap/bin"' >> /home/ezra-laptop/.bashrc
fi

# Функции для управления путями
addpath() {
    key=$1
    current_path=$(pwd)
    jq --arg key "$key" --arg path "$current_path" '.[] = ' ~/paths.json > tmp.211416.json && mv tmp.211416.json ~/paths.json
}

goto() {
    key=$1
    path=$(jq -r --arg key "$key" '.[]' ~/paths.json)
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
    jq --arg key "$key" 'del(.[])' ~/paths.json > tmp.211416.json && mv tmp.211416.json ~/paths.json
    echo "🗑️ Путь для ключа '$key' удален."
}
