-- ============================================================
-- Лабораторная работа 6. База данных СТО
-- СУБД: SQLite 3
-- ============================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS salary_payments;
DROP TABLE IF EXISTS completed_works;
DROP TABLE IF EXISTS appointment_services;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS work_schedules;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS positions;

-- 1. Должности
CREATE TABLE positions (
    position_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    title         TEXT    NOT NULL UNIQUE
                          CHECK (length(trim(title)) > 0)
);

-- 2. Работники (кадровый учёт). Уволенные не удаляются.
CREATE TABLE employees (
    employee_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    position_id     INTEGER NOT NULL,
    last_name       TEXT    NOT NULL CHECK (length(trim(last_name)) > 0),
    first_name      TEXT    NOT NULL CHECK (length(trim(first_name)) > 0),
    middle_name     TEXT,
    phone           TEXT,
    hire_date       DATE    NOT NULL DEFAULT (date('now')),
    fire_date       DATE,
    salary_percent  REAL    NOT NULL DEFAULT 30.0
                            CHECK (salary_percent >= 0 AND salary_percent <= 100),
    is_active       INTEGER NOT NULL DEFAULT 1
                            CHECK (is_active IN (0, 1)),
    FOREIGN KEY (position_id) REFERENCES positions(position_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK ( (is_active = 1 AND fire_date IS NULL)
         OR (is_active = 0 AND fire_date IS NOT NULL) ),
    CHECK (fire_date IS NULL OR fire_date >= hire_date)
);

-- 3. Справочник услуг
CREATE TABLE services (
    service_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT    NOT NULL UNIQUE CHECK (length(trim(name)) > 0),
    duration_min  INTEGER NOT NULL CHECK (duration_min > 0),
    price         REAL    NOT NULL CHECK (price >= 0)
);

-- 4. Клиенты
CREATE TABLE clients (
    client_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    last_name   TEXT NOT NULL CHECK (length(trim(last_name)) > 0),
    first_name  TEXT NOT NULL CHECK (length(trim(first_name)) > 0),
    phone       TEXT UNIQUE,
    email       TEXT
);

-- 5. Индивидуальный график мастеров (weekday: 1=Пн ... 7=Вс)
CREATE TABLE work_schedules (
    schedule_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id  INTEGER NOT NULL,
    weekday      INTEGER NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    start_time   TEXT    NOT NULL CHECK (start_time GLOB '[0-2][0-9]:[0-5][0-9]'),
    end_time     TEXT    NOT NULL CHECK (end_time   GLOB '[0-2][0-9]:[0-5][0-9]'),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (employee_id, weekday, start_time),
    CHECK (end_time > start_time)
);

-- 6. Предварительная запись (status: planned | done | cancelled)
CREATE TABLE appointments (
    appointment_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id       INTEGER NOT NULL,
    employee_id     INTEGER NOT NULL,
    scheduled_at    TEXT    NOT NULL,
    status          TEXT    NOT NULL DEFAULT 'planned'
                            CHECK (status IN ('planned', 'done', 'cancelled')),
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (client_id)   REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 7. Услуги в записи (M:N)
CREATE TABLE appointment_services (
    appointment_id  INTEGER NOT NULL,
    service_id      INTEGER NOT NULL,
    quantity        INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    PRIMARY KEY (appointment_id, service_id),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (service_id)     REFERENCES services(service_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 8. Фактически выполненные работы
CREATE TABLE completed_works (
    work_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id      INTEGER NOT NULL,
    appointment_id   INTEGER,
    service_id       INTEGER NOT NULL,
    work_date        DATE    NOT NULL DEFAULT (date('now')),
    quantity         INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    price_at_moment  REAL    NOT NULL CHECK (price_at_moment >= 0),
    FOREIGN KEY (employee_id)    REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (service_id)     REFERENCES services(service_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 9. Начисления зарплаты за период
CREATE TABLE salary_payments (
    payment_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id    INTEGER NOT NULL,
    period_start   DATE    NOT NULL,
    period_end     DATE    NOT NULL,
    revenue_amount REAL    NOT NULL DEFAULT 0 CHECK (revenue_amount >= 0),
    salary_amount  REAL    NOT NULL DEFAULT 0 CHECK (salary_amount  >= 0),
    paid_at        TEXT    NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (period_end >= period_start),
    UNIQUE (employee_id, period_start, period_end)
);

-- Индексы
CREATE INDEX idx_employees_active    ON employees(is_active);
CREATE INDEX idx_appointments_emp    ON appointments(employee_id, scheduled_at);
CREATE INDEX idx_appointments_client ON appointments(client_id);
CREATE INDEX idx_works_emp_date      ON completed_works(employee_id, work_date);
CREATE INDEX idx_salary_emp_period   ON salary_payments(employee_id, period_start, period_end);

-- ============================================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- ============================================================

INSERT INTO positions (title) VALUES
    ('Мастер-автомеханик'),
    ('Мастер-электрик'),
    ('Администратор');

INSERT INTO employees
    (position_id, last_name, first_name, middle_name, phone,
     hire_date, fire_date, salary_percent, is_active)
VALUES
    (1, 'Иванов',  'Пётр',   'Сергеевич', '+79001112233', '2021-03-01', NULL,         35.0, 1),
    (1, 'Сидоров', 'Алексей','Иванович',  '+79002223344', '2020-06-15', NULL,         40.0, 1),
    (2, 'Кузнецов','Дмитрий','Олегович',  '+79003334455', '2022-01-10', NULL,         45.0, 1),
    (2, 'Петров',  'Николай','Петрович',  '+79004445566', '2018-09-01', '2024-05-31', 30.0, 0),
    (3, 'Смирнова','Анна',   'Викторовна','+79005556677', '2023-02-01', NULL,         20.0, 1);

INSERT INTO services (name, duration_min, price) VALUES
    ('Замена масла',             30,  800.00),
    ('Замена тормозных колодок', 60, 2500.00),
    ('Диагностика подвески',     45, 1200.00),
    ('Шиномонтаж (4 колеса)',    60, 1600.00),
    ('Замена аккумулятора',      20,  500.00),
    ('Компьютерная диагностика', 40, 1500.00);

INSERT INTO clients (last_name, first_name, phone, email) VALUES
    ('Орлов',   'Игорь',  '+79110000001', 'orlov@mail.ru'),
    ('Белова',  'Мария',  '+79110000002', 'belova@mail.ru'),
    ('Титов',   'Сергей', '+79110000003', NULL),
    ('Громова', 'Ольга',  '+79110000004', 'gromova@mail.ru');

INSERT INTO work_schedules (employee_id, weekday, start_time, end_time) VALUES
    (1, 1, '09:00', '18:00'),
    (1, 2, '09:00', '18:00'),
    (1, 3, '09:00', '18:00'),
    (1, 4, '09:00', '18:00'),
    (1, 5, '09:00', '18:00'),
    (2, 1, '10:00', '19:00'),
    (2, 3, '10:00', '19:00'),
    (2, 5, '10:00', '19:00'),
    (3, 2, '08:00', '17:00'),
    (3, 4, '08:00', '17:00'),
    (3, 6, '08:00', '14:00');

INSERT INTO appointments (client_id, employee_id, scheduled_at, status) VALUES
    (1, 1, '2025-01-15 10:00', 'done'),
    (2, 1, '2025-01-15 12:00', 'done'),
    (3, 2, '2025-01-16 11:00', 'done'),
    (4, 3, '2025-01-17 09:00', 'planned'),
    (1, 2, '2025-01-18 15:00', 'cancelled');

INSERT INTO appointment_services (appointment_id, service_id, quantity) VALUES
    (1, 1, 1),
    (1, 3, 1),
    (2, 2, 1),
    (3, 6, 1),
    (3, 3, 1),
    (4, 4, 1),
    (5, 1, 1);

INSERT INTO completed_works
    (employee_id, appointment_id, service_id, work_date, quantity, price_at_moment)
VALUES
    (1, 1, 1, '2025-01-15', 1,  800.00),
    (1, 1, 3, '2025-01-15', 1, 1200.00),
    (1, 2, 2, '2025-01-15', 1, 2500.00),
    (2, 3, 6, '2025-01-16', 1, 1500.00),
    (2, 3, 3, '2025-01-16', 1, 1200.00),
    (4, NULL, 1, '2024-05-20', 1, 750.00),
    (4, NULL, 2, '2024-05-25', 1, 2400.00);

INSERT INTO salary_payments
    (employee_id, period_start, period_end, revenue_amount, salary_amount, paid_at)
VALUES
    (1, '2025-01-01', '2025-01-31', 4500.00, 1575.00, '2025-02-01 10:00:00'),
    (3, '2025-01-01', '2025-01-31', 2700.00, 1215.00, '2025-02-01 10:00:00'),
    (4, '2024-05-01', '2024-05-31', 3150.00,  945.00, '2024-06-01 10:00:00');
