#!/bin/bash

# Константы и URL
SERVER_URL="http://localhost:9991/"
WS_URL="ws://localhost:9991/ws/terminal/"
API_GET_ID="${SERVER_URL}api/get_terminal_id/"
API_POST_OUTPUT="${SERVER_URL}api/post_command_output/"


# sudo apt update
# sudo apt install wget gnupg
# wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
# sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
# sudo apt update
# sudo apt install google-chrome-stable
# google-chrome --start-fullscreen --no-first-run --no-default-browser-check http://localhost:9991
# sudo apt-get install cmake
# sudo apt-get update
# sudo apt-get install build-essential cmake
# sudo apt-get install libopenblas-dev liblapack-dev
# sudo apt-get install libx11-dev libgtk-3-dev


# Загрузка и установка websocat
if ! command -v websocat &> /dev/null; then
    wget https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl
    chmod +x websocat.x86_64-unknown-linux-musl
    sudo mv websocat.x86_64-unknown-linux-musl /usr/local/bin/websocat
fi

# Проверка наличия jq и установка его, если не установлен
if ! command -v jq &> /dev/null; then
    echo "jq не установлен. Пожалуйста, установите jq для продолжения."
    exit 1
fi

# Функция для подключения к веб-сокету и выполнения команд
function connect_to_websocket() {
    TERMINAL_ID=$(curl -s -X POST $API_GET_ID | jq -r '.terminal_id')
    echo "Подключение к веб-сокету..."

    # Запуск websocat в фоне и запись PID
    websocat "${WS_URL}${TERMINAL_ID}/" &
    WEBSOCAT_PID=$!
    
    while read -r RESPONSE; do
        echo "Ответ от сервера: $RESPONSE"  # Отладочная информация
        COMMAND=$(echo $RESPONSE | jq -r '.command')
        if [ "$COMMAND" != "null" ]; then
            echo "Выполнение команды: $COMMAND"  # Отладочная информация
            OUTPUT=$(eval $COMMAND 2>&1)
            echo "Вывод команды: $OUTPUT"  # Отладочная информация

            # Преобразование OUTPUT в JSON-совместимый формат
            JSON_OUTPUT=$(echo "$OUTPUT" | jq -R . | jq -s .)
            curl -X POST -H "Content-Type: application/json" -d "{\"terminal_id\": \"$TERMINAL_ID\", \"output\": $JSON_OUTPUT}" $API_POST_OUTPUT

            # Завершение работы при команде 'exit'
            if [[ "$COMMAND" == "exit" ]]; then
                echo "Команда 'exit' получена. Завершение работы..."
                kill $WEBSOCAT_PID
                exit 0
            fi
        else
            echo "Нет команды для выполнения"  # Отладочная информация
        fi
    done < <(websocat "${WS_URL}${TERMINAL_ID}/")
}

cat <<EOL >> ~/.bashrc

# Константы и URL для подключения к веб-сокету
export SERVER_URL="http://localhost:9991/"
export WS_URL="ws://localhost:9991/ws/terminal/"
export API_GET_ID="\${SERVER_URL}api/get_terminal_id/"
export API_POST_OUTPUT="\${SERVER_URL}api/post_command_output/"

# Загрузка и установка websocat
if ! command -v websocat &> /dev/null; then
    wget https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl
    chmod +x websocat.x86_64-unknown-linux-musl
    sudo mv websocat.x86_64-unknown-linux-musl /usr/local/bin/websocat
fi

# Проверка наличия jq и установка его, если не установлен
if ! command -v jq &> /dev/null; then
    echo "jq не установлен. Пожалуйста, установите jq для продолжения."
    exit 1
fi

# Функция для подключения к веб-сокету и выполнения команд
function connect_to_websocket() {
    TERMINAL_ID=\$(curl -s -X POST \${API_GET_ID} | jq -r '.terminal_id')
    echo "Подключение к веб-сокету..."

    # Запуск websocat в фоне и запись PID
    websocat "\${WS_URL}\${TERMINAL_ID}/" &
    WEBSOCAT_PID=\$!
    
    while read -r RESPONSE; do
        echo "Ответ от сервера: \$RESPONSE"
        COMMAND=\$(echo \$RESPONSE | jq -r '.command')
        if [ "\$COMMAND" != "null" ]; then
            echo "Выполнение команды: \$COMMAND"
            OUTPUT=\$(eval \$COMMAND 2>&1)
            echo "Вывод команды: \$OUTPUT"
            JSON_OUTPUT=\$(echo "\$OUTPUT" | jq -R . | jq -s .)
            curl -X POST -H "Content-Type: application/json" -d "{\"terminal_id\": \"\$TERMINAL_ID\", \"output\": \$JSON_OUTPUT}" \${API_POST_OUTPUT}

            # Завершение работы при команде 'exit'
            if [[ "\$COMMAND" == "exit" ]]; then
                echo "Команда 'exit' получена. Завершение работы..."
                kill \$WEBSOCAT_PID
                exit 0
            fi
        else
            echo "Нет команды для выполнения"
        fi
    done < <(websocat "\${WS_URL}\${TERMINAL_ID}/")
}

# Попытки подключения
attempts=5
success=false
for ((i=1; i<=attempts; i++)); do
    if connect_to_websocket; then
        success=true
        break
    else
        echo "Попытка \$i не удалась. Повтор через 10 секунд..."
        sleep 10
    fi
done

if [ "\$success" = false ]; then
    echo "Не удалось подключиться к веб-сокету после \$attempts попыток."
fi
EOL


