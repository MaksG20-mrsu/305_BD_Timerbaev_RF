# Task02 — ETL и генерация БД movies_rating

## Назначение

Утилита ETL (`make_db_init.py`) читает исходные файлы из `dataset/`, генерирует SQL-скрипт `db_init.sql` (создание таблиц + загрузка данных). Скрипт `db_init.bat` запускает генерацию и загружает SQL в базу `movies_rating.db`.

## Требования к окружению

- **Python 3** (команда `python3` должна быть в `PATH`)
- **SQLite 3** (команда `sqlite3` должна быть в `PATH`; проверено на версии 3.53.4)
- ОС: Windows / Linux / macOS
- Кодировка исходных файлов — UTF-8

## Запуск

git update-index --chmod=+x Task02/db_init.bat
bash Task02/db_init.bat

## Структура

- dataset/ — исходные файлы (movies.csv, ratings.csv, tags.csv, users.txt)
- make_db_init.py — ETL-утилита
- db_init.sql — SQL-скрипт (генерируется)
- db_init.bat — кроссплатформенный запускатор
