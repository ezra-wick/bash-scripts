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

# Настройка WSL для автозапуска скрипта
{
    if [ ! -f /etc/wsl.conf ]; then
        sudo touch /etc/wsl.conf
    fi
    sudo bash -c 'echo "[automount]" > /etc/wsl.conf'
    sudo bash -c 'echo "root = /" >> /etc/wsl.conf'
    sudo bash -c 'echo "options = "metadata"' >> /etc/wsl.conf'
    sudo bash -c 'echo "[boot]" >> /etc/wsl.conf'
    sudo bash -c 'echo "command = /bin/bash ~/.wsl_startup.sh"' >> /etc/wsl.conf'
    echo "Настроен автозапуск WSL для выполнения ~/.wsl_startup.sh" >> $LOG_FILE
} >> $LOG_FILE 2>&1

echo "🎉 Установка завершена! 🎉 Пожалуйста, следуйте инструкциям в файле README.md."
