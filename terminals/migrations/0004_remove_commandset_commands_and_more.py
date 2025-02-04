# Generated by Django 5.0.7 on 2024-08-01 21:32

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('terminals', '0003_commandset_space_folder'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='commandset',
            name='commands',
        ),
        migrations.AddField(
            model_name='commandset',
            name='main_commandset',
            field=models.BooleanField(default=False, verbose_name='Главная комбинация команд'),
        ),
        migrations.AddField(
            model_name='folder',
            name='command_sets',
            field=models.ManyToManyField(related_name='folders', to='terminals.commandset', verbose_name='Комбинации команд'),
        ),
        migrations.AddField(
            model_name='folder',
            name='main_commandset',
            field=models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='main_in_folder', to='terminals.commandset', verbose_name='Главная комбинация команд'),
        ),
        migrations.AddField(
            model_name='folder',
            name='main_folder',
            field=models.BooleanField(default=False, verbose_name='Главная папка'),
        ),
        migrations.AddField(
            model_name='space',
            name='main_folder',
            field=models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='main_in_space', to='terminals.folder', verbose_name='Главная папка'),
        ),
        migrations.CreateModel(
            name='CommandSetOrder',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('order', models.PositiveIntegerField()),
                ('created', models.DateTimeField(auto_now_add=True, verbose_name='📅 Дата создания')),
                ('updated', models.DateTimeField(auto_now=True, verbose_name='🔄 Дата обновления')),
                ('command', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='terminals.command')),
                ('command_set', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='terminals.commandset')),
            ],
            options={
                'ordering': ['order'],
            },
        ),
    ]
