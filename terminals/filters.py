import django_filters
from .models import Terminal, Command, CommandSet, Space, Folder, Task, EnvironmentVariable, Scenario, ScenarioCommandSetOrder, CommandSetVariable
from bashpanel.logger_init import logger

class TerminalFilter(django_filters.FilterSet):
    name__icontains = django_filters.CharFilter(field_name='name', lookup_expr='icontains')
    identifier__icontains = django_filters.CharFilter(field_name='identifier', lookup_expr='icontains')

    class Meta:
        model = Terminal
        fields = ['name__icontains', 'identifier__icontains']

class CommandFilter(django_filters.FilterSet):
    command = django_filters.CharFilter(field_name='command', lookup_expr='icontains')
    created = django_filters.DateFromToRangeFilter()

    class Meta:
        model = Command
        fields = ['command', 'created']

class CommandSetFilter(django_filters.FilterSet):
    name = django_filters.CharFilter(field_name='name', lookup_expr='icontains')
    created = django_filters.DateFromToRangeFilter()

    class Meta:
        model = CommandSet
        fields = ['name', 'created']

class SpaceFilter(django_filters.FilterSet):
    name = django_filters.CharFilter(field_name='name', lookup_expr='icontains')
    path = django_filters.CharFilter(field_name='path', lookup_expr='icontains')
    created = django_filters.DateFromToRangeFilter()

    class Meta:
        model = Space
        fields = ['name', 'path', 'created']

class FolderFilter(django_filters.FilterSet):
    name = django_filters.CharFilter(field_name='name', lookup_expr='icontains')
    created = django_filters.DateFromToRangeFilter()

    class Meta:
        model = Folder
        fields = ['name', 'space', 'created']

class TaskFilter(django_filters.FilterSet):
    created = django_filters.DateFromToRangeFilter()

    class Meta:
        model = Task
        fields = ['terminal', 'status', 'created']

class EnvironmentVariableFilter(django_filters.FilterSet):
    key__icontains = django_filters.CharFilter(field_name='key', lookup_expr='icontains')
    value__icontains = django_filters.CharFilter(field_name='value', lookup_expr='icontains')

    class Meta:
        model = EnvironmentVariable
        fields = ['key__icontains', 'value__icontains']

class ScenarioFilter(django_filters.FilterSet):
    name = django_filters.CharFilter(field_name='name', lookup_expr='icontains')
    # status = django_filters.ChoiceFilter(field_name='status', choices=Scenario.STATUS_CHOICES)
    created = django_filters.DateFromToRangeFilter()

    class Meta:
        model = Scenario
        fields = ['name', 'created']

class ScenarioCommandSetOrderFilter(django_filters.FilterSet):
    scenario__name = django_filters.CharFilter(field_name='scenario__name', lookup_expr='icontains')
    command_set__name = django_filters.CharFilter(field_name='command_set__name', lookup_expr='icontains')
    created = django_filters.DateFromToRangeFilter()

    class Meta:
        model = ScenarioCommandSetOrder
        fields = ['scenario__name', 'command_set__name', 'created']

class CommandSetVariableFilter(django_filters.FilterSet):
    scenario = django_filters.CharFilter(field_name='scenario__name', lookup_expr='icontains')
    command_set = django_filters.CharFilter(field_name='command_set__name', lookup_expr='icontains')
    environment_variable = django_filters.CharFilter(field_name='environment_variable__key', lookup_expr='icontains')

    class Meta:
        model = CommandSetVariable
        fields = ['scenario', 'command_set', 'environment_variable']