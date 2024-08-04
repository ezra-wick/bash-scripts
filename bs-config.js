module.exports = {
    proxy: "localhost:9991", // адрес вашего Django-сервера
    files: [
        "templates/**/*.html", // путь к вашим шаблонам
        "static/**/*.*" // путь к вашим статическим файлам
    ],
    open: false,
    notify: false
};
