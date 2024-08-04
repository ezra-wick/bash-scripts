import subprocess
from fastapi.staticfiles import StaticFiles
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
import json

app = FastAPI()
# Маршрутизация для статических файлов
app.mount("/static", StaticFiles(directory=os.path.join(os.path.dirname(__file__), "static")), name="static")

@app.get("/")
def read_root():
    return {"message": "Welcome to the Terminal Manager API"}
INSTALL_DIR = os.getenv("HOME") + "/terminal_task_manager"
TERMINAL_ID_FILE = f"{INSTALL_DIR}/terminal_ids.json"
TASKS_FILE = f"{INSTALL_DIR}/terminal_tasks.json"
HEARTBEAT_FILE = f"{INSTALL_DIR}/terminal_heartbeats.json"
SCRIPT_PATH = os.path.join(os.path.dirname(__file__), "taskmanager.sh")


class Task(BaseModel):
    id: str
    terminal_id: str
    status: str
    command: str


@app.on_event("startup")
def startup():
    os.makedirs(INSTALL_DIR, exist_ok=True)
    for file_path in [TERMINAL_ID_FILE, TASKS_FILE, HEARTBEAT_FILE]:
        if not os.path.exists(file_path):
            with open(file_path, "w") as file:
                json.dump([], file)


def run_script(args: List[str]) -> str:
    """Run the task manager script with provided arguments and return the output."""
    try:
        result = subprocess.run([SCRIPT_PATH] + args, capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"Script error: {e.stderr}")


@app.post("/register_terminal/")
def register_terminal():
    terminal_id = run_script(["register-terminal-from-bashrc"]).strip()
    return {"message": "Terminal registered", "terminal_id": terminal_id}


@app.get("/terminals/", response_model=List[str])
def list_terminals():
    with open(TERMINAL_ID_FILE, "r") as file:
        terminals = json.load(file)
    return terminals


@app.post("/add_task/", response_model=Task)
def add_task(task: Task):
    run_script(["add-task", task.terminal_id, task.command])
    return task


@app.get("/tasks/", response_model=List[Task])
def list_tasks():
    with open(TASKS_FILE, "r") as file:
        tasks = json.load(file)
    return tasks


@app.post("/complete_task/{task_id}")
def complete_task(task_id: str):
    run_script(["complete-task", task_id])
    return {"message": "Task completed", "task_id": task_id}


@app.get("/status")
def status():
    return run_script(["status"])


@app.post("/open_new_terminal")
def open_new_terminal():
    run_script(["open-new-terminal"])
    return {"message": "New terminal opened"}


@app.post("/hard_reset")
def hard_reset():
    run_script(["hard-reset"])
    return {"message": "System hard reset performed"}


@app.post("/cleanup_heartbeats")
def cleanup_heartbeats():
    run_script(["cleanup-heartbeats"])
    return {"message": "Old heartbeats cleaned up"}


@app.post("/reset_task_statuses")
def reset_task_statuses():
    run_script(["reset-task-statuses"])
    return {"message": "All task statuses reset"}


@app.post("/create_terminal/")
def create_terminal():
    script_path = os.path.join(os.path.dirname(__file__), "taskmanager.sh")
    try:
        result = subprocess.run([script_path, "open-new-terminal"], capture_output=True, text=True, check=True)
        return {"message": "New terminal created", "output": result.stdout}
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"Error creating terminal: {e.stderr}")