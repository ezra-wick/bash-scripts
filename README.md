# WSL Bash Framework

🎩 Добро пожаловать в WSL Bash Framework! Этот инструмент помогает управлять командами в WSL, легко интегрируясь с Git.

## 🚀 Установка

Для установки фреймворка выполните следующую команду:

```
bash install.sh
```

Следуйте подсказкам для завершения настройки.

## 📖 Использование

- ➕ Для добавления команды: `add_command <ключ> <команда>`
- ✏️ Для редактирования команды: `edit_command <ключ> <команда>`
- 🗑️ Для удаления команды: `delete_command <ключ>`
- ▶️ Для выполнения команды: `execute_command <ключ>`
- 🔍 Для отображения всех команд: `list_commands`

Команды хранятся в локальном файле `commands.db`.

## 🗺️ Управление путями

- ➕ Добавление текущего пути по ключу: `addpath <ключ>`
- ▶️ Переход к сохранённому пути: `goto <ключ>`
- 📋 Отображение всех сохранённых путей: `listpaths`
- 🗑️ Удаление сохранённого пути: `removepath <ключ>`

## 🔄 Обновление команд

Чтобы получить обновления из удаленного репозитория:

```
git pull origin main
source commands.sh
```

## 📜 Конфигурация

Настройки можно изменить в файле `framework_config.sh`.

