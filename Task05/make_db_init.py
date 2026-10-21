#!/usr/bin/env python3
import csv
import re
from pathlib import Path

BASE = Path(__file__).parent
DATASET = BASE / "dataset"
OUT = BASE / "db_init.sql"

SCHEMA = """
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS movie_genres;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id            INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    gender        TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    register_date TEXT NOT NULL DEFAULT (date('now')),
    occupation    TEXT DEFAULT 'other'
);
CREATE INDEX idx_users_name ON users(name);

CREATE TABLE movies (
    id    INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year  INTEGER CHECK (year BETWEEN 1888 AND 2100)
);
CREATE INDEX idx_movies_title ON movies(title);
CREATE INDEX idx_movies_year ON movies(year);

CREATE TABLE genres (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE movie_genres (
    movie_id INTEGER NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
    genre_id INTEGER NOT NULL REFERENCES genres(id) ON DELETE RESTRICT,
    PRIMARY KEY (movie_id, genre_id)
);

CREATE TABLE ratings (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    movie_id  INTEGER NOT NULL REFERENCES movies(id) ON DELETE RESTRICT,
    rating    REAL NOT NULL CHECK (rating BETWEEN 0 AND 5),
    timestamp INTEGER NOT NULL DEFAULT (strftime('%s','now'))
);

CREATE TABLE tags (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    movie_id  INTEGER NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
    tag       TEXT NOT NULL,
    timestamp INTEGER NOT NULL DEFAULT (strftime('%s','now'))
);
""".strip()


def esc(s):
    return s.replace("'", "''")


def parse_title(raw):
    m = re.match(r"^(.*)\s*\((\d{4})\)\s*$", raw.strip())
    if m:
        return m.group(1).strip(), int(m.group(2))
    return raw.strip(), None


def gen_genres(lines):
    genres_set = set()
    with open(DATASET / "movies.csv", encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    for row in rows:
        for g in row["genres"].split("|"):
            g = g.strip()
            if g:
                genres_set.add(g)
    lines.append("-- genres")
    for i, g in enumerate(sorted(genres_set), start=1):
        lines.append(f"INSERT INTO genres (id, name) VALUES ({i}, '{esc(g)}');")
    return {g: i for i, g in enumerate(sorted(genres_set), start=1)}


def gen_movies(lines):
    lines.append("-- movies")
    with open(DATASET / "movies.csv", encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            mid = int(row["movieId"])
            title, year = parse_title(row["title"])
            year_sql = "NULL" if year is None else str(year)
            lines.append(f"INSERT INTO movies (id, title, year) VALUES ({mid}, '{esc(title)}', {year_sql});")


def gen_movie_genres(lines, genre_id):
    lines.append("-- movie_genres")
    with open(DATASET / "movies.csv", encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            mid = int(row["movieId"])
            for g in row["genres"].split("|"):
                g = g.strip()
                if g:
                    lines.append(f"INSERT INTO movie_genres (movie_id, genre_id) VALUES ({mid}, {genre_id[g]});")


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
            lines.append(f"INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES ({int(uid)}, '{esc(name)}', '{esc(email)}', '{esc(gender)}', '{esc(birth)}', '{esc(occ)}');")


def gen_ratings(lines):
    lines.append("-- ratings")
    with open(DATASET / "ratings.csv", encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            lines.append(f"INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES ({int(row['userId'])}, {int(row['movieId'])}, {float(row['rating'])}, {int(row['timestamp'])});")


def gen_tags(lines):
    lines.append("-- tags")
    with open(DATASET / "tags.csv", encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            lines.append(f"INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES ({int(row['userId'])}, {int(row['movieId'])}, '{esc(row['tag'])}', {int(row['timestamp'])});")


def main():
    lines = [SCHEMA, "BEGIN TRANSACTION;", ""]
    genre_id = gen_genres(lines); lines.append("")
    gen_movies(lines); lines.append("")
    gen_movie_genres(lines, genre_id); lines.append("")
    gen_users(lines); lines.append("")
    gen_ratings(lines); lines.append("")
    gen_tags(lines); lines.append("")
    lines.append("COMMIT;")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {OUT}")


if __name__ == "__main__":
    main()
