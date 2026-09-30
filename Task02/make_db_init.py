#!/usr/bin/env python3
"""ETL: dataset/* -> db_init.sql"""
import csv
import re
from pathlib import Path

BASE = Path(__file__).parent
DATASET = BASE / "dataset"
OUT = BASE / "db_init.sql"

SCHEMA = """
DROP TABLE IF EXISTS movies;
CREATE TABLE movies (
    id      INTEGER PRIMARY KEY,
    title   TEXT NOT NULL,
    year    INTEGER,
    genres  TEXT
);

DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id   INTEGER NOT NULL,
    movie_id  INTEGER NOT NULL,
    rating    REAL NOT NULL,
    timestamp INTEGER NOT NULL
);

DROP TABLE IF EXISTS tags;
CREATE TABLE tags (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id   INTEGER NOT NULL,
    movie_id  INTEGER NOT NULL,
    tag       TEXT,
    timestamp INTEGER NOT NULL
);

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id            INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    email         TEXT,
    gender        TEXT,
    register_date TEXT,
    occupation    TEXT
);
""".strip()


def esc(s):
    return s.replace("'", "''")


def parse_title(raw):
    m = re.match(r"^(.*)\s*\((\d{4})\)\s*$", raw.strip())
    if m:
        return m.group(1).strip(), int(m.group(2))
    return raw.strip(), None


def gen_movies(lines):
    lines.append("-- movies")
    with open(DATASET / "movies.csv", encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            mid = int(row["movieId"])
            title, year = parse_title(row["title"])
            year_sql = "NULL" if year is None else str(year)
            lines.append(
                f"INSERT INTO movies (id, title, year, genres) "
                f"VALUES ({mid}, '{esc(title)}', {year_sql}, '{esc(row['genres'])}');"
            )


def gen_ratings(lines):
    lines.append("-- ratings")
    with open(DATASET / "ratings.csv", encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            lines.append(
                f"INSERT INTO ratings (user_id, movie_id, rating, timestamp) "
                f"VALUES ({int(row['userId'])}, {int(row['movieId'])}, "
                f"{float(row['rating'])}, {int(row['timestamp'])});"
            )


def gen_tags(lines):
    lines.append("-- tags")
    with open(DATASET / "tags.csv", encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            lines.append(
                f"INSERT INTO tags (user_id, movie_id, tag, timestamp) "
                f"VALUES ({int(row['userId'])}, {int(row['movieId'])}, "
                f"'{esc(row['tag'])}', {int(row['timestamp'])});"
            )


def gen_users(lines):
    lines.append("-- users")
    with open(DATASET / "users.txt", encoding="utf-8") as f:
        for raw in f:
            raw = raw.rstrip("\n")
            if not raw:
                continue
            parts = raw.split("|")
            if len(parts) < 6:
                continue
            uid, name, email, gender, birth, occ = parts[:6]
            lines.append(
                f"INSERT INTO users (id, name, email, gender, register_date, occupation) "
                f"VALUES ({int(uid)}, '{esc(name)}', '{esc(email)}', "
                f"'{esc(gender)}', '{esc(birth)}', '{esc(occ)}');"
            )


def main():
    lines = ["BEGIN TRANSACTION;", SCHEMA, ""]
    gen_movies(lines); lines.append("")
    gen_ratings(lines); lines.append("")
    gen_tags(lines); lines.append("")
    gen_users(lines); lines.append("")
    lines.append("COMMIT;")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {OUT}")


if __name__ == "__main__":
    main()
