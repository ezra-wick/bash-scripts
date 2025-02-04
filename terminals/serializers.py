from rest_framework import serializers
from .models import Terminal, Command, CommandSet, Space, Folder, Task, CommandSetOrder, EnvironmentVariable, Scenario, ScenarioCommandSetOrder, CommandSetVariable

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

class EnvironmentVariableReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = EnvironmentVariable
        fields = ['id', 'key', 'value']

class EnvironmentVariableWriteSerializer(serializers.ModelSerializer):
    id = serializers.PrimaryKeyRelatedField(queryset=EnvironmentVariable.objects.all())

    class Meta:
        model = EnvironmentVariable
        fields = ['id']


class EnvironmentVariableSerializer(serializers.ModelSerializer):
    class Meta:
        model = EnvironmentVariable
        fields = ['id', 'key', 'value']

class CommandSetVariableSerializer(serializers.ModelSerializer):
    environment_variable = EnvironmentVariableSerializer()

    class Meta:
        model = CommandSetVariable
        fields = ['environment_variable']

class CommandSetSerializerScenario(serializers.ModelSerializer):
    variables = CommandSetVariableSerializer(many=True, source='commandsetvariable_set')

    class Meta:
        model = CommandSet
        fields = ['id', 'name', 'variables']

class ScenarioReadNewSerializer(serializers.ModelSerializer):
    global_environment_variables = EnvironmentVariableSerializer(many=True)
    command_sets = CommandSetSerializerScenario(many=True)

    class Meta:
        model = Scenario
        fields = ['id', 'name', 'global_environment_variables', 'command_sets', 'output', 'created', 'updated']


class ScenarioWriteNewSerializer(serializers.ModelSerializer):
    global_environment_variables = serializers.PrimaryKeyRelatedField(queryset=EnvironmentVariable.objects.all(), many=True)
    command_sets = serializers.ListField(
        child=serializers.DictField(),
        write_only=True
    )

    class Meta:
        model = Scenario
        fields = ['name', 'global_environment_variables', 'command_sets', 'output']

    def create(self, validated_data):
        global_environment_variables = validated_data.pop('global_environment_variables')
        command_sets_data = validated_data.pop('command_sets', [])
        
        # Создаем объект сценария без глобальных переменных окружения
        scenario = Scenario.objects.create(**validated_data)
        
        # Устанавливаем глобальные переменные окружения
        scenario.global_environment_variables.set(global_environment_variables)
        
        # Обрабатываем командные наборы
        for command_set_data in command_sets_data:
            command_set = CommandSet.objects.get(id=command_set_data['id'])
            ScenarioCommandSetOrder.objects.create(scenario=scenario, command_set=command_set, order=command_set_data['order'])
            
            for variable_data in command_set_data.get('variables', []):
                CommandSetVariable.objects.create(
                    scenario=scenario,
                    command_set=command_set,
                    environment_variable=EnvironmentVariable.objects.get(id=variable_data['environment_variable'])
                )
        return scenario

    def update(self, instance, validated_data):
        global_environment_variables = validated_data.pop('global_environment_variables', [])
        command_sets_data = validated_data.pop('command_sets', [])
        
        instance.name = validated_data.get('name', instance.name)
        instance.output = validated_data.get('output', instance.output)
        instance.save()
        
        # Обновляем глобальные переменные окружения
        instance.global_environment_variables.set(global_environment_variables)
        
        # Обрабатываем командные наборы
        ScenarioCommandSetOrder.objects.filter(scenario=instance).delete()
        for command_set_data in command_sets_data:
            command_set = CommandSet.objects.get(id=command_set_data['id'])
            ScenarioCommandSetOrder.objects.create(scenario=instance, command_set=command_set, order=command_set_data['order'])
            
            for variable_data in command_set_data.get('variables', []):
                CommandSetVariable.objects.create(
                    scenario=instance,
                    command_set=command_set,
                    environment_variable=EnvironmentVariable.objects.get(id=variable_data['environment_variable'])
                )
        return instance