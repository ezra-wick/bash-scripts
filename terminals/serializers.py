from rest_framework import serializers
from .models import Terminal, Command, CommandSet, Space, Folder, Task, CommandSetOrder, EnvironmentVariable, Scenario, ScenarioCommandSetOrder

class TerminalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Terminal
        fields = '__all__'



class CommandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Command
        fields = '__all__'

class CommandSetOrderReadSerializer(serializers.ModelSerializer):
    command = CommandSerializer()

    class Meta:
        model = CommandSetOrder
        fields = ['command', 'order']


class CommandSetOrderWriteSerializer(serializers.ModelSerializer):
    command = serializers.PrimaryKeyRelatedField(queryset=Command.objects.all())

    class Meta:
        model = CommandSetOrder
        fields = ['command', 'order']

class CommandSetOrderSerializer(serializers.ModelSerializer):
    command_set = serializers.PrimaryKeyRelatedField(queryset=CommandSet.objects.all(), required=False)
    command = serializers.PrimaryKeyRelatedField(queryset=Command.objects.all())

    class Meta:
        model = CommandSetOrder
        fields = ['command', 'order', 'command_set']
        read_only_fields = ['command_set']

class CommandSetSerializer(serializers.ModelSerializer):
    commands = serializers.SerializerMethodField()

    class Meta:
        model = CommandSet
        fields = ['id', 'name', 'commands', 'created', 'updated', 'main_commandset']

    def get_commands(self, obj):
        if self.context['request'].method in ['POST', 'PUT', 'PATCH']:
            return CommandSetOrderWriteSerializer(obj.commandsetorder_set.all(), many=True).data
        return CommandSetOrderReadSerializer(obj.commandsetorder_set.all(), many=True).data

    def create(self, validated_data):
        commands_data = self.context['request'].data.get('commands', [])
        command_set = CommandSet.objects.create(**validated_data)
        for command_data in commands_data:
            CommandSetOrder.objects.create(
                command_set=command_set,
                command_id=command_data['command'],  # Используем command_id
                order=command_data['order']
            )
        return command_set

    def update(self, instance, validated_data):
        commands_data = self.context['request'].data.get('commands', [])
        instance.name = validated_data.get('name', instance.name)
        instance.main_commandset = validated_data.get('main_commandset', instance.main_commandset)
        instance.save()

        # Очистка существующих команд
        instance.commandsetorder_set.all().delete()
        # Создание новых команд
        for command_data in commands_data:
            CommandSetOrder.objects.create(
                command_set=instance,
                command_id=command_data['command'],
                order=command_data['order']
            )

        return instance


class SpaceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Space
        fields = '__all__'

class FolderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Folder
        fields = '__all__'

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = '__all__'

class EnvironmentVariableSerializer(serializers.ModelSerializer):
    class Meta:
        model = EnvironmentVariable
        fields = '__all__'

class ScenarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Scenario
        fields = '__all__'

class ScenarioCommandSetOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = ScenarioCommandSetOrder
        fields = '__all__'
