# Generated by Django 5.0.7 on 2024-08-05 13:44

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('terminals', '0009_scenario_scenariocommandsetorder_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='CommandSetVariable',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created', models.DateTimeField(auto_now_add=True, verbose_name='📅 Дата создания')),
                ('updated', models.DateTimeField(auto_now=True, verbose_name='🔄 Дата обновления')),
                ('command_set', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='terminals.commandset')),
                ('environment_variable', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='terminals.environmentvariable')),
                ('scenario', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='terminals.scenario')),
            ],
            options={
                'unique_together': {('scenario', 'command_set', 'environment_variable')},
            },
        ),
    ]
