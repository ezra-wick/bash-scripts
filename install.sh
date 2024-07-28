#!/bin/bash

LOG_FILE=~/install.log

echo "🌟 Добро пожаловать в установщик WSL Bash Framework! 🌟"

read -p "👤 Введите ваше имя пользователя на GitHub: " github_user
read -p "📂 Введите название вашего репозитория: " repo_name

REPO_URL="https://github.com/$github_user/$repo_name.git"

echo "🔧 Установка фреймворка..."

# Инициализация git и отправка в репозиторий
{
    git init
    git remote add origin $REPO_URL
    git add .
    git commit -m "Initial commit"
    git branch -M main
    git push -u origin main
} >> $LOG_FILE 2>&1

# Создание скрипта автозапуска
{
    echo "#!/bin/bash" > ~/.wsl_startup.sh
    echo "source ~/.bashrc" >> ~/.wsl_startup.sh
    echo "echo '🛠️  WSL Bash Framework готов к работе!'" >> ~/.wsl_startup.sh
    chmod +x ~/.wsl_startup.sh
    echo "Создан скрипт автозапуска ~/.wsl_startup.sh" >> $LOG_FILE
} >> $LOG_FILE 2>&1

# Проверка и установка необходимых пакетов
{
    echo "🔍 Проверка необходимых пакетов..."
    sudo apt update
    sudo apt install -y git curl wget
    echo "✅ Необходимые пакеты установлены." >> $LOG_FILE
} >> $LOG_FILE 2>&1

# Настройка переменных окружения
{
    echo "🔧 Настройка переменных окружения..."
    echo "export GITHUB_USER=$github_user" >> ~/.bashrc
    echo "export REPO_NAME=$repo_name" >> ~/.bashrc
    echo "Переменные окружения добавлены в ~/.bashrc." >> $LOG_FILE
} >> $LOG_FILE 2>&1

# Источник и выполнение команд из commands.sh
if [ -f "commands.sh" ]; then
    source commands.sh >> $LOG_FILE 2>&1
    echo "📜 Файл commands.sh выполнен." >> $LOG_FILE
else
    echo "⚠️  Внимание: файл commands.sh не найден!" >> $LOG_FILE
fi

source ~/.bashrc

echo "🎉 Установка завершена! 🎉 Пожалуйста, следуйте инструкциям в файле README.md."
echo "Чтобы начать использование фреймворка, выполните команду:"
echo "🖥️  source commands.sh"
