from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Создаем роутер и регистрируем наши ViewSets
router = DefaultRouter()
router.register(r'terminals', views.TerminalViewSet)
router.register(r'commands', views.CommandViewSet)
router.register(r'commandsets', views.CommandSetViewSet)
router.register(r'spaces', views.SpaceViewSet)
router.register(r'folders', views.FolderViewSet)
router.register(r'tasks', views.TaskViewSet)
router.register(r'environment-variables', views.EnvironmentVariableViewSet)
router.register(r'scenarios', views.ScenarioViewSet)
router.register(r'scenario-command-set-orders', views.ScenarioCommandSetOrderViewSet)


urlpatterns = [
    # Основная страница
    path('', views.index, name='index'),
    path('terminals/', views.terminals_view, name='terminals'),
    path('tasks/', views.tasks_view, name='tasks'),
    path('commands/', views.commands_view, name='commands'),
    path('commandset/', views.commandset_view, name='commandset'),
    path('environment_variables/', views.environment_variables, name='environment_variables'),
    path('head/', views.head, name='head'),
    # Существующие API-эндпоинты
    path('api/get_terminal_id/', views.get_terminal_id, name='get_terminal_id'),
    path('api/post_command_output/', views.post_command_output, name='post_command_output'),
    path('api/start_terminal/', views.start_terminal, name='start_terminal'),
    # Новые API для работы с папками и пространствами
    path('api/get_folders/', views.get_folders, name='get_folders'),
    path('api/create_space/', views.create_space, name='create_space'),
    path('api/get_space_folders/', views.get_space_folders, name='get_space_folders'),
    # Маршруты для APIViewSets
    path('api/', include(router.urls)),
]
