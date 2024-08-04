from django.urls import path, re_path
from .consumers import TerminalConsumer, VideoConsumer

websocket_urlpatterns = [
    path('ws/terminal/<str:terminal_id>/', TerminalConsumer.as_asgi()),
    re_path(r'ws/video/', VideoConsumer.as_asgi()),
]