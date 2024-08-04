import logging
import colorlog

# Создаем объект logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Создаем форматтер с цветным форматированием
formatter = colorlog.ColoredFormatter(
    '%(log_color)s%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    log_colors={
        'DEBUG':    'cyan',
        'INFO':     'green',
        'WARNING':  'yellow',
        'ERROR':    'red',
        'CRITICAL': 'bold_red',
    },
)

# Создаем обработчик, например, вывод в консоль
console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)

# Добавляем обработчик к logger
logger.addHandler(console_handler)

# Примеры логирования
logger.debug('🐛 Это сообщение DEBUG')
logger.info('✅ Это сообщение INFO')
logger.warning('⚠️ Это сообщение WARNING')
logger.error('🚫 Это сообщение ERROR')
logger.critical('🔥 Это сообщение CRITICAL')
