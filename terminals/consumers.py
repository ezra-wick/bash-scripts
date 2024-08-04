# consumers.py
from channels.generic.websocket import AsyncWebsocketConsumer
import json
from .models import Terminal, Task
from channels.db import database_sync_to_async
from bashpanel.logger_init import logger

class TerminalConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.terminal_id = self.scope['url_route']['kwargs']['terminal_id']
        logger.warning(f"Terminal with ID {self.terminal_id} connected")
        await self.channel_layer.group_add(self.terminal_id, self.channel_name)
        await self.accept()
        await self.set_terminal_connected(self.terminal_id, True)

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.terminal_id, self.channel_name)
        await self.set_terminal_connected(self.terminal_id, False)

    async def receive(self, text_data):
        if not text_data.strip():
            logger.warning("Пустое сообщение получено")
            return
        try:
            data = json.loads(text_data)
            task_id = data.get('task_id')
            output = data.get('output')

            if task_id and output is not None:
                await self.update_task_output(task_id, output)
        except json.JSONDecodeError as e:
            logger.warning(f"ERROR FROM WSL JSON {e}")
            return

    async def send_command(self, event):
        command = event['command']
        task_id = event['task_id']
        logger.warning(f"Sending command to terminal: {command} for Task {task_id}")
        await self.send(text_data=json.dumps({
            'command': command,
            'task_id': task_id
        }))

    @database_sync_to_async
    def set_terminal_connected(self, terminal_id, connected):
        try:
            terminal = Terminal.objects.get(identifier=terminal_id)
            terminal.connected = connected
            terminal.save()
        except Terminal.DoesNotExist:
            pass

    @database_sync_to_async
    def update_task_output(self, task_id, output):
        try:
            task = Task.objects.get(id=task_id)
            task.output = output
            task.status = 'completed'
            task.save()
        except Task.DoesNotExist:
            pass

import os
import cv2
import dlib
import numpy as np
from django.conf import settings
import json
from channels.generic.websocket import AsyncWebsocketConsumer

# Определяем путь к файлу shape_predictor_81_face_landmarks.dat
landmark_path = os.path.join(settings.BASE_DIR, "models", "shape_predictor_81_face_landmarks.dat")

face_detector = dlib.get_frontal_face_detector()
landmark_predictor = dlib.shape_predictor(landmark_path)

class VideoConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.accept()

    async def disconnect(self, close_code):
        pass

    async def receive(self, text_data=None, bytes_data=None):
        if bytes_data:
            frame = np.frombuffer(bytes_data, dtype=np.uint8).reshape((150, 200, 4))  # Увеличенный размер
            frame = cv2.cvtColor(frame, cv2.COLOR_RGBA2BGR)

            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = face_detector(gray)

            keypoints = []

            for face in faces:
                landmarks = landmark_predictor(gray, face)
                points = [(landmarks.part(i).x, landmarks.part(i).y) for i in range(81)]

                keypoints.append({
                    "upper_nose": points[27:31],
                    "right_eyebrow": points[17:22],
                    "left_eyebrow": points[22:27],
                    "right_eye": points[36:42],
                    "left_eye": points[42:48],
                    "mouth": points[48:68],
                    "jaw": points[0:17],
                    "cheeks": points[31:36],  # Добавление скул и щек
                    "chin": points[6:11]  # Добавление подбородка
                })

            await self.send(text_data=json.dumps(keypoints))
