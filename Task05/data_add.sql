PRAGMA foreign_keys = ON;
-- 5 новых пользователей (себя и 4 соседей)
INSERT INTO users (name, email, gender, register_date, occupation) VALUES 
('Тимербаев Раиль Фаилович', 'railtim0301@gmail.com', 'male', date('now'), 'student'),
('Саляев Никита', 'salyaev_nikita@example.com', 'male', date('now'), 'student'),
('Сандин Максим', 'sandin_maxim@example.com', 'male', date('now'), 'student'),
('Федотов Александр', 'fedotov_alex@example.com', 'male', date('now'), 'student'),
('Якушкин Станислав', 'yakushkin_stas@example.com', 'male', date('now'), 'student');

-- 3 новых фильма, которых нет в исходной базе
INSERT INTO movies (id, title, year) VALUES 
((SELECT COALESCE(MAX(id), 0) + 1 FROM movies), 'Oppenheimer', 2023);
INSERT INTO movie_genres (movie_id, genre_id) VALUES 
(last_insert_rowid(), (SELECT id FROM genres WHERE name = 'Drama'));

INSERT INTO movies (id, title, year) VALUES 
((SELECT COALESCE(MAX(id), 0) + 1 FROM movies), 'Barbie', 2023);
INSERT INTO movie_genres (movie_id, genre_id) VALUES 
(last_insert_rowid(), (SELECT id FROM genres WHERE name = 'Comedy'));

INSERT INTO movies (id, title, year) VALUES 
((SELECT COALESCE(MAX(id), 0) + 1 FROM movies), 'Dune: Part Two', 2024);
INSERT INTO movie_genres (movie_id, genre_id) VALUES 
(last_insert_rowid(), (SELECT id FROM genres WHERE name = 'Sci-Fi'));

-- 3 отзыва от себя о добавленных фильмах
INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES 
((SELECT id FROM users WHERE email = 'railtim0301@gmail.com'), 
 (SELECT id FROM movies WHERE title = 'Oppenheimer' AND year = 2023), 5.0, strftime('%s','now'));

INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES 
((SELECT id FROM users WHERE email = 'railtim0301@gmail.com'), 
 (SELECT id FROM movies WHERE title = 'Barbie' AND year = 2023), 4.0, strftime('%s','now'));

INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES 
((SELECT id FROM users WHERE email = 'railtim0301@gmail.com'), 
 (SELECT id FROM movies WHERE title = 'Dune: Part Two' AND year = 2024), 4.5, strftime('%s','now'));
