import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

import subprocess

from django.shortcuts import render, get_object_or_404
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.decorators import api_view
from rest_framework import status, viewsets
from .models import Terminal, Command, CommandSet, Space, Folder, Task, EnvironmentVariable, Scenario, ScenarioCommandSetOrder
from .serializers import (
    TerminalSerializer, CommandSerializer, CommandSetSerializer,
    SpaceSerializer, FolderSerializer, TaskSerializer, EnvironmentVariableSerializer,
    ScenarioSerializer, ScenarioCommandSetOrderSerializer
)
from .filters import (
    TerminalFilter, CommandFilter, CommandSetFilter,
    SpaceFilter, FolderFilter, TaskFilter, EnvironmentVariableFilter, ScenarioFilter, ScenarioCommandSetOrderFilter
)
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from bashpanel.logger_init import logger


@csrf_exempt
def get_terminal_id(request):
    if request.method == 'POST':
        terminal = Terminal.objects.create(name='New Terminal', connected=True)
        logger.warning(f"'terminal_id': {terminal.identifier}")
        return JsonResponse({'terminal_id': terminal.identifier})

@csrf_exempt
def post_command_output(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        terminal_id = data.get('terminal_id')
        output = data.get('output')
        try:
            terminal = Terminal.objects.get(identifier=terminal_id)
            # task = Task.objects.create(terminal=terminal, output=output, status='completed')
            return JsonResponse({'status': 'success'})
        except Terminal.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'Terminal not found'}, status=404)

@api_view(['POST'])
def start_terminal(request):
    try:
        # Запуск команды через subprocess
        result = subprocess.run(['cmd.exe', '/C', 'start', 'wsl', '/bin/bash', '-c', 'exec $SHELL'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return Response({"message": "Terminal started", "output": result.stdout.decode('utf-8')}, status=status.HTTP_200_OK)
    except subprocess.CalledProcessError as e:
        return Response({"error": str(e), "output": e.stderr.decode('utf-8')}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    


def index(request):
    context = {}
    context['terminals'] = Terminal.objects.all()
    return render(request, 'index.html', context)


def terminals_view(request):
    context = {}
    # context['terminals'] = Terminal.objects.all()
    return render(request, 'pages/terminals.html', context)

def commands_view(request):
    context = {}
    # context['commands'] = Command.objects.all()
    return render(request, 'pages/commands.html', context)

def commandset_view(request):
    context = {}
    # context['commandset'] = Command.objects.all()
    return render(request, 'pages/commandset.html', context)

def tasks_view(request):
    context = {}
    # context['tasks'] = Task.objects.all()
    return render(request, 'pages/tasks.html', context)

def environment_variables(request):
    context = {}
    # context['tasks'] = Task.objects.all()
    return render(request, 'pages/environment_variables.html', context)

def head(request):
    context = {}
    # context['tasks'] = Task.objects.all()
    return render(request, 'plugins/humanhead.html', context)

class TerminalViewSet(viewsets.ModelViewSet):
    queryset = Terminal.objects.all()
    serializer_class = TerminalSerializer
    filterset_class = TerminalFilter
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['name', 'identifier', 'user__username']  # Added 'user__username'
    ordering_fields = '__all__'
    ordering = ['-created']

    def get_queryset(self):
        queryset = Terminal.objects.all()
        filter_data = self.request.query_params
        logger.info(f"Incoming filter parameters: {filter_data}")

        # Явное применение фильтра
        filterset = TerminalFilter(filter_data, queryset=queryset)
        if filterset.is_valid():
            queryset = filterset.qs
        else:
            logger.warning(f"Filterset is not valid: {filterset.errors}")

        logger.info(f"Filtered Queryset Count: {queryset.count()}")
        logger.info(f"Filtered Queryset: {list(queryset)}")

        return queryset

class CommandViewSet(viewsets.ModelViewSet):
    queryset = Command.objects.all()
    serializer_class = CommandSerializer
    filterset_class = CommandFilter
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['command']
    ordering_fields = '__all__'
    ordering = ['-created']

class CommandSetViewSet(viewsets.ModelViewSet):
    queryset = CommandSet.objects.all()
    serializer_class = CommandSetSerializer
    filterset_class = CommandSetFilter
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['name']
    ordering_fields = '__all__'
    ordering = ['-created']

    def create(self, request, *args, **kwargs):
        logger.info(f"Incoming data for CommandSet creation: {request.data}")
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except Exception as e:
            logger.exception("Exception occurred while creating CommandSet")
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def update(self, request, *args, **kwargs):
        logger.info(f"Incoming data for CommandSet update: {request.data}")
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        try:
            serializer.is_valid(raise_exception=True)
            self.perform_update(serializer)
            return Response(serializer.data)
        except Exception as e:
            logger.exception("Exception occurred while updating CommandSet")
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def set_main(self, request, pk=None):
        command_set = self.get_object()
        CommandSet.objects.filter(space=command_set.space).update(main_commandset=False)
        command_set.main_commandset = True
        command_set.save()
        return Response({'status': 'main command set updated'})

class FolderViewSet(viewsets.ModelViewSet):
    queryset = Folder.objects.all()
    serializer_class = FolderSerializer
    filterset_class = FolderFilter
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['name']
    ordering_fields = '__all__'
    ordering = ['-created']

    @action(detail=True, methods=['post'])
    def set_main_commandset(self, request, pk=None):
        folder = self.get_object()
        command_set_id = request.data.get('command_set_id')
        command_set = get_object_or_404(CommandSet, id=command_set_id)
        folder.main_commandset = command_set
        folder.save()
        return Response({'status': 'main command set for folder updated'})

    @action(detail=True, methods=['post'])
    def add_commandset(self, request, pk=None):
        folder = self.get_object()
        command_set_id = request.data.get('command_set_id')
        command_set = get_object_or_404(CommandSet, id=command_set_id)
        folder.command_sets.add(command_set)
        return Response({'status': 'command set added to folder'})



class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    filterset_class = TaskFilter
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['terminal__name', 'status']
    ordering_fields = '__all__'
    ordering = ['-created']



import os

@api_view(['GET'])
def get_folders(request):
    """Получить список папок в /mnt/c/"""
    folder_path = '/mnt/c/'
    try:
        folders = [f for f in os.listdir(folder_path) if os.path.isdir(os.path.join(folder_path, f))]
        return Response({'folders': folders}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def create_space(request):
    """Создать новое пространство для выбранной папки"""
    folder_name = request.data.get('folder')
    folder_path = f'/mnt/c/{folder_name}/'

    if not os.path.exists(folder_path) or not os.path.isdir(folder_path):
        return Response({'error': 'Folder does not exist'}, status=status.HTTP_400_BAD_REQUEST)

    space, created = Space.objects.get_or_create(name=folder_name, path=folder_path)
    space.update_folders()  # Обновляем список папок в пространстве
    return Response({'success': True, 'space_id': space.id}, status=status.HTTP_201_CREATED)

@api_view(['GET'])
def get_space_folders(request):
    """Получить список папок в пространстве"""
    space_id = request.query_params.get('space_id')
    try:
        space = Space.objects.get(id=space_id)
        folders = space.folders.values_list('name', flat=True)
        return Response({'folders': list(folders)}, status=status.HTTP_200_OK)
    except Space.DoesNotExist:
        return Response({'error': 'Space not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Обновленный ViewSet для пространства
class SpaceViewSet(viewsets.ModelViewSet):
    queryset = Space.objects.all()
    serializer_class = SpaceSerializer
    filterset_class = SpaceFilter
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['name', 'path']
    ordering_fields = '__all__'
    ordering = ['-created']

    @action(detail=True, methods=['post'])
    def set_main_folder(self, request, pk=None):
        space = self.get_object()
        folder_id = request.data.get('folder_id')
        folder = get_object_or_404(Folder, id=folder_id, space=space)
        space.main_folder = folder
        space.save()
        return Response({'status': 'main folder updated'})
    
from urllib.parse import unquote

class EnvironmentVariableViewSet(viewsets.ModelViewSet):
    queryset = EnvironmentVariable.objects.all()
    serializer_class = EnvironmentVariableSerializer
    filterset_class = EnvironmentVariableFilter
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['key', 'value']
    ordering_fields = '__all__'
    ordering = ['-created']

    def get_queryset(self):
        queryset = EnvironmentVariable.objects.all()
        filter_data = self.request.query_params
        decoded_filter_data = {k: unquote(v).strip() for k, v in filter_data.items()}
        logger.info(f"Incoming filter parameters: {decoded_filter_data}")

        filterset = EnvironmentVariableFilter(decoded_filter_data, queryset=queryset)
        if filterset.is_valid():
            queryset = filterset.qs
        else:
            logger.warning(f"Filterset is not valid: {filterset.errors}")

        logger.info(f"Filtered Queryset Count: {queryset.count()}")
        logger.info(f"Filtered Queryset: {list(queryset)}")

        return queryset


class ScenarioViewSet(viewsets.ModelViewSet):
    queryset = Scenario.objects.all()
    serializer_class = ScenarioSerializer
    filterset_class = ScenarioFilter
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['name', 'status']
    ordering_fields = '__all__'
    ordering = ['-created']

class ScenarioCommandSetOrderViewSet(viewsets.ModelViewSet):
    queryset = ScenarioCommandSetOrder.objects.all()
    serializer_class = ScenarioCommandSetOrderSerializer
    filterset_class = ScenarioCommandSetOrderFilter
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['scenario__name', 'command_set__name']
    ordering_fields = '__all__'
    ordering = ['-created']
