import uuid
import os
from django.db import models
from django.contrib.auth.models import User
from django.utils.translation import gettext_lazy as _
from django.db.models.signals import post_save, m2m_changed
from django.dispatch import receiver
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from bashpanel.logger_init import logger
import subprocess

class Terminal(models.Model):
    name = models.CharField(max_length=100, verbose_name="Название терминала")
    identifier = models.CharField(max_length=100, unique=True, verbose_name="Идентификатор")
    connected = models.BooleanField(default=False, verbose_name="Подключен")
    user = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="Пользователь", related_name='terminals', null=True, blank=True)
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('📅 Дата создания'))
    updated = models.DateTimeField(auto_now=True, verbose_name=_('🔄 Дата обновления'))

    class Meta:
        verbose_name = "Терминал"
        verbose_name_plural = "Терминалы"

    def __str__(self):
        return f"{self.name}({self.id})"

    def save(self, *args, **kwargs):
        if not self.identifier:
            self.identifier = str(uuid.uuid4())
            self.name = f"Терминал({self.identifier}) от {self.created}"
        super(Terminal, self).save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        if self.connected:
            # Отправляем команду на терминал
            logger.warning(f"Sending exit command to Terminal {self.identifier} before deletion.")
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                self.identifier,
                {
                    'type': 'send_command',
                    'command': 'exit',
                    'task_id': None
                }
            )
            logger.warning(f"Sent exit command to Terminal {self.identifier}")
        super(Terminal, self).delete(*args, **kwargs)


class Command(models.Model):
    command = models.CharField(max_length=255, verbose_name="Команда")
    description = models.TextField(blank=True, null=True, verbose_name="Описание")
    parent = models.ForeignKey('self', on_delete=models.CASCADE, blank=True, null=True, related_name='subcommands', verbose_name="Родительская команда")
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('📅 Дата создания'))
    updated = models.DateTimeField(auto_now=True, verbose_name=_('🔄 Дата обновления'))

    class Meta:
        verbose_name = "Команда"
        verbose_name_plural = "Команды"

    def __str__(self):
        return self.command


class CommandSet(models.Model):
    name = models.CharField(max_length=255, verbose_name="Название комбинации команд")
    commands = models.ManyToManyField(Command, through='CommandSetOrder', verbose_name="Команды", related_name='command_sets')
    main_commandset = models.BooleanField(default=False, verbose_name="Главная комбинация команд")
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('📅 Дата создания'))
    updated = models.DateTimeField(auto_now=True, verbose_name=_('🔄 Дата обновления'))

    class Meta:
        verbose_name = "Комбинация команд"
        verbose_name_plural = "Комбинации команд"

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if self.main_commandset:
            CommandSet.objects.filter(space=self.space).update(main_commandset=False)
        super(CommandSet, self).save(*args, **kwargs)


class CommandSetOrder(models.Model):
    command_set = models.ForeignKey(CommandSet, on_delete=models.CASCADE)
    command = models.ForeignKey(Command, on_delete=models.CASCADE)
    order = models.PositiveIntegerField()
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('📅 Дата создания'))
    updated = models.DateTimeField(auto_now=True, verbose_name=_('🔄 Дата обновления'))

    class Meta:
        ordering = ['order']


class Space(models.Model):
    name = models.CharField(max_length=255, verbose_name="Название пространства")
    path = models.CharField(max_length=255, verbose_name="Путь к пространству")
    command_sets = models.ManyToManyField(CommandSet, verbose_name="Комбинации команд", related_name='spaces')
    main_folder = models.OneToOneField('Folder', on_delete=models.SET_NULL, null=True, blank=True, related_name='main_in_space', verbose_name="Главная папка")
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('📅 Дата создания'))
    updated = models.DateTimeField(auto_now=True, verbose_name=_('🔄 Дата обновления'))

    class Meta:
        verbose_name = "Пространство"
        verbose_name_plural = "Пространства"

    def __str__(self):
        return self.name

    def update_folders(self):
        """Обновление списка папок в пространстве"""
        existing_folders = set(self.folders.values_list('name', flat=True))
        actual_folders = set(os.listdir(self.path))
        
        # Удаление папок, которых больше нет
        Folder.objects.filter(space=self, name__in=(existing_folders - actual_folders)).delete()
        
        # Добавление новых папок
        new_folders = actual_folders - existing_folders
        Folder.objects.bulk_create([Folder(name=folder, space=self) for folder in new_folders])


class Folder(models.Model):
    name = models.CharField(max_length=255, verbose_name="Название папки")
    space = models.ForeignKey(Space, on_delete=models.CASCADE, verbose_name="Пространство", related_name='folders')
    command_sets = models.ManyToManyField(CommandSet, verbose_name="Комбинации команд", related_name='folders')
    main_commandset = models.OneToOneField(CommandSet, on_delete=models.SET_NULL, null=True, blank=True, related_name='main_in_folder', verbose_name="Главная комбинация команд")
    main_folder = models.BooleanField(default=False, verbose_name="Главная папка")
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('📅 Дата создания'))
    updated = models.DateTimeField(auto_now=True, verbose_name=_('🔄 Дата обновления'))

    class Meta:
        verbose_name = "Папка"
        verbose_name_plural = "Папки"

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if self.main_folder:
            Folder.objects.filter(space=self.space).update(main_folder=False)
        super(Folder, self).save(*args, **kwargs)


class Task(models.Model):
    terminal = models.ForeignKey(Terminal, on_delete=models.CASCADE, verbose_name="Терминал", related_name='tasks')
    commands = models.ManyToManyField(Command, verbose_name="Команды", related_name='tasks', blank=True)
    status = models.CharField(max_length=50, choices=[('pending', 'В ожидании'), ('running', 'Выполняется'), ('completed', 'Завершено'), ('failed', 'Не выполнено')], default='pending', verbose_name="Статус")
    output = models.TextField(blank=True, null=True, verbose_name="Вывод")
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('📅 Дата создания'))
    updated = models.DateTimeField(auto_now=True, verbose_name=_('🔄 Дата обновления'))

    class Meta:
        verbose_name = "Задача"
        verbose_name_plural = "Задачи"

    def __str__(self):
        return f"Task {self.id} for {self.terminal}"


@receiver(post_save, sender=Space)
def update_folders_on_space_creation(sender, instance, created, **kwargs):
    if created:
        instance.update_folders()


@receiver(m2m_changed, sender=Task.commands.through)
def send_task_to_terminal(sender, instance, action, **kwargs):
    if action == "post_add":
        logger.warning(f"New Task {instance.id} updated with commands for Terminal {instance.terminal.identifier}")
        
        # Получаем команды, связанные с задачей
        commands = instance.commands.all()
        if not commands:
            logger.warning(f"No commands found for Task {instance.id}")

        commands_list = [command.command for command in commands]
        for command in commands_list:
            logger.warning(f"Command for Task {instance.id}: {command}")

        command_str = ' && '.join(commands_list)
        if command_str:
            logger.warning(f"Command string for Task {instance.id}: {command_str}")
        else:
            logger.warning(f"Command string is empty for Task {instance.id}")

        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            instance.terminal.identifier,
            {
                'type': 'send_command',
                'command': command_str,
                'task_id': instance.id
            }
        )
        logger.warning(f"Sent command for Task {instance.id} to Terminal {instance.terminal.identifier}")


@receiver(post_save, sender=Task)
def send_output_update(sender, instance, **kwargs):
    if instance.output:
        logger.warning(f"Task {instance.id} output updated: {instance.output}")

        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            instance.terminal.identifier,
            {
                'type': 'send_command',
                'command': instance.output,
                'task_id': instance.id
            }
        )
        logger.warning(f"Sent output for Task {instance.id} to Terminal {instance.terminal.identifier}")

class EnvironmentVariable(models.Model):
    key = models.CharField(max_length=255, verbose_name="Ключ переменной")
    value = models.CharField(max_length=255, verbose_name="Значение переменной")
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('📅 Дата создания'))
    updated = models.DateTimeField(auto_now=True, verbose_name=_('🔄 Дата обновления'))

    class Meta:
        verbose_name = "Переменная окружения"
        verbose_name_plural = "Переменные окружения"

    def __str__(self):
        return self.key


class Scenario(models.Model):
    name = models.CharField(max_length=255, verbose_name="Название сценария")
    global_environment_variables = models.ManyToManyField(EnvironmentVariable, verbose_name="Общие переменные окружения", related_name='scenarios_global')
    command_sets = models.ManyToManyField(CommandSet, through='ScenarioCommandSetOrder', verbose_name="Комбинации команд", related_name='scenarios')
    output = models.TextField(blank=True, null=True, verbose_name="Вывод")
    created = models.DateTimeField(auto_now_add=True, verbose_name='📅 Дата создания')
    updated = models.DateTimeField(auto_now=True, verbose_name='🔄 Дата обновления')

    class Meta:
        verbose_name = "Сценарий"
        verbose_name_plural = "Сценарии"

    def __str__(self):
        return f"Сценарий {self.name} ({self.id})"

class ScenarioCommandSetOrder(models.Model):
    scenario = models.ForeignKey(Scenario, on_delete=models.CASCADE)
    command_set = models.ForeignKey(CommandSet, on_delete=models.CASCADE)
    order = models.PositiveIntegerField()
    created = models.DateTimeField(auto_now_add=True, verbose_name='📅 Дата создания')
    updated = models.DateTimeField(auto_now=True, verbose_name='🔄 Дата обновления')

    class Meta:
        ordering = ['order']

@receiver(post_save, sender=Scenario)
def send_scenario_to_terminal(sender, instance, created, **kwargs):
    if created:
        environment_variables = instance.environment_variables.all()
        env_vars_str = ' '.join([f'{var.key}={var.value}' for var in environment_variables])

        command_set_orders = ScenarioCommandSetOrder.objects.filter(scenario=instance).order_by('order')
        
        for order in command_set_orders:
            # Создание нового терминала для каждого CommandSet
            result = subprocess.run(['cmd.exe', '/C', 'start', 'wsl', '/bin/bash', '-c', 'exec $SHELL'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            terminal = Terminal.objects.create(name='New Terminal', connected=True)

            commands = order.command_set.commands.all()
            commands_list = [command.command for command in commands]
            command_str = ' && '.join(commands_list)
            full_command = f'{env_vars_str} && {command_str}'

            task = Task.objects.create(
                terminal=terminal,
                status='pending',
                output='',
            )

            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                terminal.identifier,
                {
                    'type': 'send_command',
                    'command': full_command,
                    'task_id': task.id
                }
            )