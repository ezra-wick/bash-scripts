from django.contrib import admin
from .models import Terminal, Command, Task, CommandSet, CommandSetOrder, Space, Folder, Scenario, ScenarioCommandSetOrder, CommandSetVariable, EnvironmentVariable

@admin.register(Terminal)
class TerminalAdmin(admin.ModelAdmin):
    list_display = ('name', 'identifier', 'connected', 'user', 'created', 'updated')
    search_fields = ('name', 'identifier')
    list_filter = ('connected', 'user')

@admin.register(Command)
class CommandAdmin(admin.ModelAdmin):
    list_display = ('command', 'description', 'parent', 'created', 'updated')
    search_fields = ('command',)
    list_filter = ('parent',)

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('terminal', 'status', 'output', 'created', 'updated')
    search_fields = ('terminal__name', 'commands__command')
    list_filter = ('status', 'terminal')

@admin.register(CommandSet)
class CommandSetAdmin(admin.ModelAdmin):
    list_display = ('name', 'main_commandset', 'created', 'updated')
    search_fields = ('name',)
    list_filter = ('created', 'updated')
    actions = ['set_as_main']

    def set_as_main(self, request, queryset):
        for commandset in queryset:
            CommandSet.objects.filter(space=commandset.space).update(main_commandset=False)
            commandset.main_commandset = True
            commandset.save()
        self.message_user(request, "Выбранные комбинации команд установлены как главные.")
    set_as_main.short_description = "Установить как главную комбинацию команд"

@admin.register(Space)
class SpaceAdmin(admin.ModelAdmin):
    list_display = ('name', 'path', 'main_folder', 'created', 'updated')
    search_fields = ('name', 'path')
    list_filter = ('created', 'updated')
    actions = ['set_main_folder']

    def set_main_folder(self, request, queryset):
        for space in queryset:
            folder_id = request.POST.get('folder_id')
            if folder_id:
                folder = Folder.objects.get(id=folder_id, space=space)
                space.main_folder = folder
                space.save()
        self.message_user(request, "Главная папка для выбранных пространств установлена.")
    set_main_folder.short_description = "Установить главную папку"

@admin.register(Folder)
class FolderAdmin(admin.ModelAdmin):
    list_display = ('name', 'space', 'main_commandset', 'main_folder', 'created', 'updated')
    search_fields = ('name', 'space__name')
    list_filter = ('space', 'created', 'updated')
    actions = ['set_main_commandset', 'set_as_main_folder']

    def set_main_commandset(self, request, queryset):
        for folder in queryset:
            command_set_id = request.POST.get('command_set_id')
            if command_set_id:
                command_set = CommandSet.objects.get(id=command_set_id)
                folder.main_commandset = command_set
                folder.save()
        self.message_user(request, "Главная комбинация команд для выбранных папок установлена.")
    set_main_commandset.short_description = "Установить главную комбинацию команд"

    def set_as_main_folder(self, request, queryset):
        for folder in queryset:
            Folder.objects.filter(space=folder.space).update(main_folder=False)
            folder.main_folder = True
            folder.save()
        self.message_user(request, "Выбранные папки установлены как главные.")
    set_as_main_folder.short_description = "Установить как главную папку"


class ScenarioCommandSetOrderInline(admin.TabularInline):
    model = ScenarioCommandSetOrder
    extra = 1

class CommandSetVariableInline(admin.TabularInline):
    model = CommandSetVariable
    extra = 1

@admin.register(Scenario)
class ScenarioAdmin(admin.ModelAdmin):
    list_display = ('name', 'created', 'updated')
    inlines = [ScenarioCommandSetOrderInline, CommandSetVariableInline]
    search_fields = ('name',)

    fieldsets = (
        (None, {
            'fields': ('name', 'global_environment_variables', 'output')
        }),
        ('Dates', {
            'fields': ('created', 'updated')
        }),
    )
    readonly_fields = ('created', 'updated')

@admin.register(ScenarioCommandSetOrder)
class ScenarioCommandSetOrderAdmin(admin.ModelAdmin):
    list_display = ('scenario', 'command_set', 'order', 'created', 'updated')
    search_fields = ('scenario__name', 'command_set__name')
    list_filter = ('scenario', 'command_set')

@admin.register(CommandSetVariable)
class CommandSetVariableAdmin(admin.ModelAdmin):
    list_display = ('scenario', 'command_set', 'environment_variable', 'created', 'updated')
    search_fields = ('scenario__name', 'command_set__name', 'environment_variable__name')
    list_filter = ('scenario', 'command_set', 'environment_variable')

@admin.register(EnvironmentVariable)
class EnvironmentVariableAdmin(admin.ModelAdmin):
    list_display = ('key', 'value', 'created', 'updated')
    search_fields = ('key', 'value')
    list_filter = ('created', 'updated')