// scripts.js

document.addEventListener("DOMContentLoaded", function () {
  const terminalList = document.getElementById("terminals");
  const taskList = document.getElementById("tasks");
  const registerTerminalButton = document.getElementById("register-terminal");
  const createTerminalButton = document.getElementById("create-terminal");
  const addTaskButton = document.getElementById("add-task");
  const newTaskTerminalInput = document.getElementById("new-task-terminal");
  const newTaskCommandInput = document.getElementById("new-task-command");

  const API_BASE_URL = "http://localhost:9991";

  // Fetch and display terminals
  function fetchTerminals() {
    axios.get(`${API_BASE_URL}/terminals/`)
      .then(response => {
        terminalList.innerHTML = '';
        response.data.forEach(terminal => {
          const terminalItem = document.createElement("li");
          terminalItem.className = "p-2 border rounded bg-gray-100 flex justify-between items-center";
          terminalItem.innerHTML = `
            <span>Terminal ID: ${terminal}</span>
            <span class="text-green-500"><i class="fas fa-check-circle"></i> Active</span>
          `;
          terminalList.appendChild(terminalItem);
        });
      })
      .catch(error => {
        console.error("Error fetching terminals:", error);
      });
  }

  // Fetch and display tasks
  function fetchTasks() {
    axios.get(`${API_BASE_URL}/tasks/`)
      .then(response => {
        taskList.innerHTML = '';
        response.data.forEach(task => {
          const taskItem = document.createElement("li");
          taskItem.className = "p-2 border rounded bg-gray-100 flex justify-between items-center";
          taskItem.innerHTML = `
            <span>Task ID: ${task.id}, Terminal ID: ${task.terminal_id}, Command: ${task.command}</span>
            <span class="${task.status === 'completed' ? 'text-green-500' : 'text-yellow-500'}">
              <i class="${task.status === 'completed' ? 'fas fa-check-circle' : 'fas fa-hourglass-half'}"></i> ${task.status.charAt(0).toUpperCase() + task.status.slice(1)}
            </span>
          `;
          taskList.appendChild(taskItem);
        });
      })
      .catch(error => {
        console.error("Error fetching tasks:", error);
      });
  }

  // Register new terminal
  registerTerminalButton.addEventListener("click", () => {
    axios.post(`${API_BASE_URL}/register_terminal/`)
      .then(response => {
        fetchTerminals();
        alert(response.data.message);
      })
      .catch(error => {
        console.error("Error registering terminal:", error);
      });
  });

  // Create new terminal
  createTerminalButton.addEventListener("click", () => {
    axios.post(`${API_BASE_URL}/create_terminal/`)
      .then(response => {
        fetchTerminals();
        alert(response.data.message);
      })
      .catch(error => {
        console.error("Error creating terminal:", error);
      });
  });

  // Add new task
  addTaskButton.addEventListener("click", () => {
    const terminalId = newTaskTerminalInput.value.trim();
    const command = newTaskCommandInput.value.trim();

    if (terminalId && command) {
      axios.post(`${API_BASE_URL}/add_task/`, {
        terminal_id: terminalId,
        command: command,
        id: Date.now().toString(),
        status: "new"
      })
      .then(response => {
        fetchTasks();
        newTaskTerminalInput.value = '';
        newTaskCommandInput.value = '';
      })
      .catch(error => {
        console.error("Error adding task:", error);
      });
    } else {
      alert("Please enter both terminal ID and command.");
    }
  });

  // Initial fetch
  fetchTerminals();
  fetchTasks();

  // Update tasks and terminals every 5 seconds
  setInterval(() => {
    fetchTerminals();
    fetchTasks();
  }, 5000);
});
