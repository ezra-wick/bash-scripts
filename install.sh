#!/bin/bash

echo "🌟 Добро пожаловать в установщик WSL Bash Framework! 🌟"

read -p "👤 Введите ваше имя пользователя на GitHub: " github_user
read -p "📂 Введите название вашего репозитория: " repo_name

REPO_URL="https://github.com/$github_user/$repo_name.git"

echo "🔧 Установка фреймворка..."

# Инициализация git и отправка в репозиторий
git init
git remote add origin $REPO_URL
git add .
git commit -m "Initial commit"
git branch -M main
git push -u origin main

echo "🎉 Установка завершена! 🎉 Пожалуйста, следуйте инструкциям в файле README.md."
echo "Чтобы начать использование фреймворка, выполните команду:"
echo "🖥️  source commands.sh"
