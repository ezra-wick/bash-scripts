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

# Настройка автозапуска через .profile или .bash_profile
{
    if [ -f ~/.profile ]; then
        if ! grep -q "source ~/.wsl_startup.sh" ~/.profile; then
            echo "source ~/.wsl_startup.sh" >> ~/.profile
            echo "source ~/.wsl_startup.sh добавлен в ~/.profile" >> $LOG_FILE
        fi
    elif [ -f ~/.bash_profile ]; then
        if ! grep -q "source ~/.wsl_startup.sh" ~/.bash_profile; then
            echo "source ~/.wsl_startup.sh" >> ~/.bash_profile
            echo "source ~/.wsl_startup.sh добавлен в ~/.bash_profile" >> $LOG_FILE
        fi
    else
        # Если оба файла отсутствуют, создаем ~/.profile
        echo "source ~/.wsl_startup.sh" > ~/.profile
        echo "Создан ~/.profile и добавлен source ~/.wsl_startup.sh" >> $LOG_FILE
    fi
} >> $LOG_FILE 2>&1

echo "🎉 Установка завершена! 🎉 Пожалуйста, следуйте инструкциям в файле README.md."
