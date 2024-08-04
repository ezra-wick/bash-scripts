#!/bin/bash

INSTALL_DIR="$HOME/terminal_task_manager"
SCRIPT_PATH="$(realpath "$0")"
TERMINAL_ID_FILE="$INSTALL_DIR/terminal_ids.json"
TASKS_FILE="$INSTALL_DIR/terminal_tasks.json"
HEARTBEAT_FILE="$INSTALL_DIR/terminal_heartbeats.json"
EXECUTING_TERMINAL_FILE="$INSTALL_DIR/executing_terminal_ids.json"
LOG_FILE="$INSTALL_DIR/terminal_manager.log"
MONITOR_INTERVAL=2
HEARTBEAT_INTERVAL=5
TERMINAL_TIMEOUT=10

# Создание рабочего каталога
mkdir -p "$INSTALL_DIR"
chmod 777 "$INSTALL_DIR"

# Функция для логирования
log() {
  local MESSAGE="$1"
  printf "%s - %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$MESSAGE" | tee -a "$LOG_FILE"
}


# Копирование скрипта в рабочий каталог
log "🚀 Запуск основной функции"
cp -f "$SCRIPT_PATH" "$INSTALL_DIR/terminal_manager.sh"
chmod +x "$INSTALL_DIR/terminal_manager.sh"


log "Создан путь $INSTALL_DIR"

# Функция для создания файлов данных
initialize_files() {
  [ ! -f "$TERMINAL_ID_FILE" ] && echo "[]" > "$TERMINAL_ID_FILE"
  [ ! -f "$TASKS_FILE" ] && echo "[]" > "$TASKS_FILE"
  [ ! -f "$HEARTBEAT_FILE" ] && echo "[]" > "$HEARTBEAT_FILE"
  [ ! -f "$EXECUTING_TERMINAL_FILE" ] && echo "[]" > "$EXECUTING_TERMINAL_FILE"
  chmod 666 "$TERMINAL_ID_FILE" "$TASKS_FILE" "$HEARTBEAT_FILE" "$EXECUTING_TERMINAL_FILE"

  log "Создан файл TERMINAL_ID_FILE $TERMINAL_ID_FILE"
  log "Создан файл TASKS_FILE $TASKS_FILE"
  log "Создан файл HEARTBEAT_FILE $HEARTBEAT_FILE"
  log "Создан файл EXECUTING_TERMINAL_FILE $EXECUTING_TERMINAL_FILE"
}

# Функция для генерации уникального идентификатора терминала
generate_terminal_id() {
  echo $(date +%s%N | sha256sum | head -c 32)
}

register_terminal() {
  local TERMINAL_ID=$1
  local IS_PRIMARY="false"
  local PRIMARY_TERMINAL_ID=$(jq -r '.[0] // empty' "$TERMINAL_ID_FILE")

  if [ -z "$PRIMARY_TERMINAL_ID" ]; then
    IS_PRIMARY="true"
    log "🛠️ Регистрация первого терминала как главного: $TERMINAL_ID"
  else
    log "🔧 Регистрация рабочего терминала: $TERMINAL_ID"
  fi

  add_terminal_id "$TERMINAL_ID_FILE" "$TERMINAL_ID"

  local ROLE_FILE="$INSTALL_DIR/terminal_role_$TERMINAL_ID"
  if [ "$IS_PRIMARY" == "true" ]; then
    echo "primary" > "$ROLE_FILE"
  else
    echo "worker" > "$ROLE_FILE"
  fi
  chmod 666 "$ROLE_FILE"  # Устанавливаем права на файл

  log "📣 Терминал $TERMINAL_ID ($IS_PRIMARY) готов к работе"
}

monitor_terminal_status() {
  local TERMINAL_ID=$1
  local ROLE_FILE="$INSTALL_DIR/terminal_role_$TERMINAL_ID"

  if [ ! -f "$ROLE_FILE" ]; then
    log "⚠️ Файл роли терминала не найден для $TERMINAL_ID. Создание файла."
    echo "worker" > "$ROLE_FILE"
    chmod 666 "$ROLE_FILE"
  fi

  local ROLE=$(cat "$ROLE_FILE")

  # Если терминал является главным, не отслеживаем его статус
  if [ "$ROLE" == "primary" ]; then
    log "🛠️ Терминал $TERMINAL_ID является главным, статус не отслеживается"
    return
  fi

  log "🔍 Начало мониторинга для $TERMINAL_ID"
  while true; do
    log "💓 Отправка heartbeat для терминала $TERMINAL_ID"
    send_heartbeat "$TERMINAL_ID"
    
    # Запуск асинхронной проверки задач в фоновом режиме
    check_tasks &

    sleep $MONITOR_INTERVAL
  done
}


# Функция для обработки добавления идентификаторов в файл
add_terminal_id() {
  local FILE_PATH="$1"
  local TERMINAL_ID="$2"

  if [ -f "$FILE_PATH" ]; then
    jq --arg id "$TERMINAL_ID" '. += [$id]' "$FILE_PATH" | sponge "$FILE_PATH"
  else
    echo '[]' | jq --arg id "$TERMINAL_ID" '. += [$id]' > "$FILE_PATH"
  fi
  chmod 666 "$FILE_PATH"
  log "💾 Идентификатор $TERMINAL_ID добавлен в $FILE_PATH"
}


# 🖥️ Функция для открытия нового терминала
open_new_terminal() {
  local TERMINAL_ID=$1

  if [ -z "$TERMINAL_ID" ]; then
    TERMINAL_ID=$(generate_terminal_id)
    log "🆕 Сгенерирован и сохранён новый идентификатор терминала: $TERMINAL_ID"
  else
    log "📥 Используется переданный идентификатор терминала: $TERMINAL_ID"
  fi

  add_terminal_id "$EXECUTING_TERMINAL_FILE" "$TERMINAL_ID"
  log "🚀 Запуск нового WSL терминала"
  cmd.exe /C start wsl /bin/bash -c "exec $SHELL"

  log "🖥️ Открыт новый терминал WSL с идентификатором $TERMINAL_ID"
  add_task "$TERMINAL_ID" "ls"
  add_task "$TERMINAL_ID" "nohup bash -c 'cd $INSTALL_DIR && bash terminal_manager.sh monitor-status $TERMINAL_ID' > /dev/null 2>&1 &"


  
}

# Функция для запуска мониторинга статуса терминала
start_terminal_monitoring() {
  monitor_terminal_status "$TERMINAL_ID"
}


# Функция регистрации терминала из .bashrc
register_terminal_from_bashrc() {
  log "🔍 Попытка регистрации терминала из .bashrc"
  local TERMINAL_ID

  if [ -f "$EXECUTING_TERMINAL_FILE" ]; then
    local EXISTING_IDS=$(jq -r '.' "$EXECUTING_TERMINAL_FILE")
    log "📄 Существующие идентификаторы: $EXISTING_IDS"
    
    if [ "$EXISTING_IDS" != "[]" ]; then
      TERMINAL_ID=$(jq -r '.[0]' <<< "$EXISTING_IDS")
      jq 'del(.[0])' "$EXECUTING_TERMINAL_FILE" | sponge "$EXECUTING_TERMINAL_FILE"
      log "🗑️ Идентификатор $TERMINAL_ID удален из $EXECUTING_TERMINAL_FILE"
    else
      TERMINAL_ID=$(generate_and_save_terminal_id)
    fi
  else
    log "⚠️ Файл $EXECUTING_TERMINAL_FILE не найден, создается новый"
    echo '[]' > "$EXECUTING_TERMINAL_FILE"
    TERMINAL_ID=$(generate_and_save_terminal_id)
  fi

  add_terminal_id "$TERMINAL_ID_FILE" "$TERMINAL_ID"
  log "💾 Идентификатор $TERMINAL_ID добавлен в $TERMINAL_ID_FILE"
  export TERMINAL_ID="$TERMINAL_ID"

  log "📋 Проверка задач для терминала $TERMINAL_ID"
  check_tasks $TERMINAL_ID

  # start_terminal_monitoring
  log "✅ Проверка задач завершена для терминала $TERMINAL_ID"

  # echo $TERMINAL_ID
}

# 📝 Функция для добавления новой задачи
add_task() {
  local TASK_TERMINAL_ID=$1
  local TASK_COMMAND=$2
  local TASK_ID=$(date +%s%N)
  local TASK_STATUS="new"

  jq --arg id "$TASK_ID" --arg terminal_id "$TASK_TERMINAL_ID" --arg status "$TASK_STATUS" --arg command "$TASK_COMMAND" '. += [{"id": $id, "terminal_id": $terminal_id, "status": $status, "command": $command}]' "$TASKS_FILE" | sponge "$TASKS_FILE"
  chmod 666 "$TASKS_FILE"

  log "📝 Добавлена задача $TASK_ID для терминала $TASK_TERMINAL_ID: $TASK_COMMAND"
}

# Функция для отправки heartbeat
send_heartbeat() {
  local TERMINAL_ID=$1
  local CURRENT_TIME=$(date +%s)

  jq --arg id "$TERMINAL_ID" --arg time "$CURRENT_TIME" 'map(if .id == $id then .time = $time else . end) | if length == 0 then . += [{"id": $id, "time": $time}] else . end' "$HEARTBEAT_FILE" | sponge "$HEARTBEAT_FILE"
  chmod 666 "$HEARTBEAT_FILE"
}


# Функция для проверки активности терминалов
check_active_terminals() {
  local CURRENT_TIME=$(date +%s)
  
  jq --arg current_time "$CURRENT_TIME" --arg timeout "$TERMINAL_TIMEOUT" 'map(select(($current_time | tonumber) - (.time | tonumber) < ($timeout | tonumber)))' "$HEARTBEAT_FILE" | sponge "$HEARTBEAT_FILE"
  chmod 666 "$HEARTBEAT_FILE"
}

# Функция для отображения списка задач
list_tasks() {
  jq -r '.[] | "\(.id) - \(.terminal_id) - \(.status) - \(.command)"' "$TASKS_FILE"
}

# Функция для выполнения задач терминала
check_tasks() {
  local TERMINAL_ID_ARG=$1
  local TERMINAL_ID=${TERMINAL_ID_ARG:-$TERMINAL_ID}
  local TASK_ID
  local TASK_TERMINAL_ID
  local TASK_STATUS
  local TASK_COMMAND

  log "Проверка задач для выполнения для терминала $TERMINAL_ID"

  jq -c '.[]' "$TASKS_FILE" | while read -r task; do
    TASK_ID=$(echo "$task" | jq -r '.id')
    TASK_TERMINAL_ID=$(echo "$task" | jq -r '.terminal_id')
    TASK_STATUS=$(echo "$task" | jq -r '.status')
    TASK_COMMAND=$(echo "$task" | jq -r '.command')

    if [ "$TASK_TERMINAL_ID" == "$TERMINAL_ID" ] && [ "$TASK_STATUS" == "new" ]; then
      log "🚀 Запуск задачи $TASK_ID на терминале $TERMINAL_ID: $TASK_COMMAND"
      update_task_status "$TASK_ID" "in_progress"
      # Запуск задачи в фоновом режиме
      (
        eval "$TASK_COMMAND"
        if [ $? -eq 0 ]; then
          log "✅ Задача $TASK_ID выполнена успешно"
          update_task_status "$TASK_ID" "completed"
        else
          log "❌ Ошибка при выполнении задачи $TASK_ID"
          update_task_status "$TASK_ID" "failed"
        fi
      ) &
    fi
  done
}

# Обновление статуса задачи
update_task_status() {
  local TASK_ID=$1
  local NEW_STATUS=$2

  jq --arg id "$TASK_ID" --arg status "$NEW_STATUS" 'map(if .id == $id then .status = $status else . end)' "$TASKS_FILE" | sponge "$TASKS_FILE"
  chmod 666 "$TASKS_FILE"
  log "📋 Статус задачи $TASK_ID обновлен на $NEW_STATUS"
}


# Функция для обновления статуса задачи
update_task_status() {
  local TASK_ID=$1
  local NEW_STATUS=$2

  jq --arg id "$TASK_ID" --arg status "$NEW_STATUS" 'map(if .id == $id then .status = $status else . end)' "$TASKS_FILE" | sponge "$TASKS_FILE"
  chmod 666 "$TASKS_FILE"
  log "📋 Статус задачи $TASK_ID обновлен на $NEW_STATUS"
}

# Функция для удаления определённого терминала и всех его задач
remove_terminal() {
  local TERMINAL_ID=$1

  # Удаление терминала из списка
  jq --arg id "$TERMINAL_ID" 'map(select(. != $id))' "$TERMINAL_ID_FILE" | sponge "$TERMINAL_ID_FILE"
  chmod 666 "$TERMINAL_ID_FILE"

  # Удаление задач терминала
  jq --arg id "$TERMINAL_ID" 'map(select(.terminal_id != $id))' "$TASKS_FILE" | sponge "$TASKS_FILE"
  chmod 666 "$TASKS_FILE"

  # Удаление роли терминала
  rm -f "$INSTALL_DIR/terminal_role_$TERMINAL_ID"

  log "🗑️ Терминал $TERMINAL_ID и его задачи удалены"
}

# Функция для сброса статуса всех задач
reset_task_statuses() {
  jq 'map(.status = "new")' "$TASKS_FILE" | sponge "$TASKS_FILE"
  chmod 666 "$TASKS_FILE"

  log "🔄 Статусы всех задач сброшены в 'new'"
}

# Функция для удаления старых heartbeat записей
cleanup_heartbeats() {
  local CURRENT_TIME=$(date +%s)
  local CLEANUP_THRESHOLD=$((CURRENT_TIME - TERMINAL_TIMEOUT))

  jq --arg threshold "$CLEANUP_THRESHOLD" 'map(select(.time | tonumber > ($threshold | tonumber)))' "$HEARTBEAT_FILE" | sponge "$HEARTBEAT_FILE"
  chmod 666 "$HEARTBEAT_FILE"

  log "🗑️ Удалены старые heartbeat записи"
}

# Функция для поиска задач по статусу
find_tasks_by_status() {
  local STATUS=$1
  jq --arg status "$STATUS" '.[] | select(.status == $status) | "\(.id) - \(.terminal_id) - \(.status) - \(.command)"' "$TASKS_FILE"
}

# Функция для хардресета
hard_reset() {
  rm -f "$TERMINAL_ID_FILE" "$EXECUTING_TERMINAL_FILE" "$TASKS_FILE" "$HEARTBEAT_FILE"
  initialize_files
  log "🔄 Хардресет выполнен: все файлы восстановлены"
}

command_handler() {
  case "$1" in
    status)
      terminal_status
      ;;
    add-task)
      add_task "$2" "$3"
      ;;
    list-tasks)
      list_tasks
      ;;
    complete-task)
      complete_task "$2"
      ;;
    remove-terminal)
      remove_terminal "$2"
      ;;
    reset-task-statuses)
      reset_task_statuses
      ;;
    cleanup-heartbeats)
      cleanup_heartbeats
      ;;
    find-tasks)
      find_tasks_by_status "$2"
      ;;
    hard-reset)
      hard_reset
      ;;
    open-new-terminal)
      open_new_terminal
      ;;
    register-terminal-from-bashrc)
      register_terminal_from_bashrc
      ;;
    check-tasks)
      check_tasks
      ;;
    monitor-status)
      log "starting for $2"
      monitor_terminal_status "$2"
      ;;
    *)
      echo "Неизвестная команда: $1"
      echo "Доступные команды:"
      echo "  status - Показать статус терминалов"
      echo "  add-task [terminal_id] [command] - Добавить задачу"
      echo "  list-tasks - Показать список задач"
      echo "  complete-task [task_id] - Завершить задачу"
      echo "  remove-terminal [terminal_id] - Удалить терминал и его задачи"
      echo "  reset-task-statuses - Сбросить статус всех задач"
      echo "  cleanup-heartbeats - Удалить старые heartbeat записи"
      echo "  find-tasks [status] - Найти задачи по статусу"
      echo "  hard-reset - Выполнить хардресет"
      echo "  open-new-terminal - Открыть новый терминал"
      echo "  register-terminal-from-bashrc - Регистрация терминала из .bashrc"
      echo "  monitor-status [terminal_id] - Мониторинг статуса терминала"
      ;;
  esac
}


setup_bashrc() {
  local BASHRC_FILE="$HOME/.bashrc"
  if ! grep -q "terminal_task_manager" "$BASHRC_FILE"; then
    echo '
# Terminal Task Manager
if [ -f "$HOME/terminal_task_manager/terminal_ids.json" ]; then
  TERMINAL_ID=$(bash $HOME/terminal_task_manager/terminal_manager.sh register-terminal-from-bashrc)
  export TERMINAL_ID
  echo "Terminal ID set to $TERMINAL_ID" | tee -a $HOME/terminal_task_manager/terminal_manager.log
  bash $HOME/terminal_task_manager/terminal_manager.sh check-tasks $TERMINAL_ID # Запуск проверки задач
fi
' >> "$BASHRC_FILE"
    log "📝 Команды для управления терминалом добавлены в .bashrc"
  fi
}


# Основная функция установки
main() {
  log "🚀 Запуск основной функции установки"
  
  initialize_files
  log "🗃️ Файлы данных инициализированы"

  setup_bashrc
  log "📝 Настройка .bashrc завершена"

  TERMINAL_ID=$(generate_terminal_id)
  log "🆔 Сгенерирован идентификатор терминала: $TERMINAL_ID"
  
  register_terminal "$TERMINAL_ID"
  
  log "🔧 Терминал зарегистрирован с идентификатором: $TERMINAL_ID"

  monitor_terminal_status $TERMINAL_ID
}

if [[ $# -gt 0 ]]; then
  if [[ $1 == "register-terminal-from-bashrc" ]]; then
    register_terminal_from_bashrc
  elif [[ $1 == "get-task" ]]; then
    get_task "$2"
  else
    command_handler "$@"
    echo "🔄 Выполнение команды: $@"

  fi
else
  log "🏁 Запуск основного процесса"
  main
fi