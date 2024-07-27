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

# Установка команды для автоматического вызова .bashrc при запуске
{
    if ! grep -q "source ~/.bashrc" ~/.bash_profile 2>/dev/null; then
        echo "source ~/.bashrc" >> ~/.bash_profile
    fi

    if ! grep -q "source ~/.bashrc" ~/.profile 2>/dev/null; then
        echo "source ~/.bashrc" >> ~/.profile
    fi
} >> $LOG_FILE 2>&1

# Проверка, что изменения в .bashrc применились
{
    source ~/.bashrc
    echo "source ~/.bashrc добавлен в ~/.bash_profile и ~/.profile" >> $LOG_FILE
} >> $LOG_FILE 2>&1

echo "🎉 Установка завершена! 🎉 Пожалуйста, следуйте инструкциям в файле README.md."
echo "Чтобы начать использование фреймворка, выполните команду:"
echo "🖥️  source commands.sh"
