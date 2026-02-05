
-- Крок 1. Завантаження даних
USE pandemic;

-- Перевірка кількості рядків після імпорту
SELECT COUNT(*) AS total_rows FROM infectious_cases;

-- Крок 2. Нормалізація до 3НФ
-- Створюємо таблицю entities (унікальні Entity + Code)
CREATE TABLE entities (
    entity_id INT AUTO_INCREMENT PRIMARY KEY,
    Entity TEXT,
    Code TEXT
);

INSERT INTO entities (Entity, Code)
SELECT DISTINCT Entity, Code 
FROM infectious_cases
WHERE Entity IS NOT NULL AND Code IS NOT NULL;

-- Створюємо таблицю cases
CREATE TABLE cases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_id INT,
    Year INT,
    Number_yaws TEXT,
    polio_cases TEXT,
    cases_guinea_worm TEXT,
    Number_rabies TEXT,
    Number_malaria TEXT,
    Number_hiv TEXT,
    Number_tuberculosis TEXT,
    Number_smallpox TEXT,
    Number_cholera_cases TEXT
);

-- Заповнюємо cases
INSERT INTO cases (
    entity_id, Year, Number_yaws, polio_cases, cases_guinea_worm,
    Number_rabies, Number_malaria, Number_hiv, Number_tuberculosis,
    Number_smallpox, Number_cholera_cases
)
SELECT 
    e.entity_id,
    ic.Year,
    ic.Number_yaws,
    ic.polio_cases,
    ic.cases_guinea_worm,
    ic.Number_rabies,
    ic.Number_malaria,
    ic.Number_hiv,
    ic.Number_tuberculosis,
    ic.Number_smallpox,
    ic.Number_cholera_cases
FROM infectious_cases ic
JOIN entities e ON ic.Entity = e.Entity AND ic.Code = e.Code;

-- Крок 3. Аналіз Number_rabies
SELECT 
    e.Entity,
    e.Code,
    AVG(CAST(NULLIF(ic.Number_rabies, '') AS DOUBLE)) AS avg_rabies,
    MIN(CAST(NULLIF(ic.Number_rabies, '') AS DOUBLE)) AS min_rabies,
    MAX(CAST(NULLIF(ic.Number_rabies, '') AS DOUBLE)) AS max_rabies,
    SUM(CAST(NULLIF(ic.Number_rabies, '') AS DOUBLE)) AS sum_rabies
FROM infectious_cases ic
JOIN entities e ON ic.Entity = e.Entity AND ic.Code = e.Code
WHERE ic.Number_rabies != '' 
  AND ic.Number_rabies IS NOT NULL
GROUP BY e.Entity, e.Code
HAVING avg_rabies IS NOT NULL
ORDER BY avg_rabies DESC
LIMIT 10;

-- Крок 4. Різниця в роках (з оригінальної таблиці)
SELECT 
    Year,
    STR_TO_DATE(CONCAT(Year, '-01-01'), '%Y-%m-%d') AS date_from_year,
    CURDATE() AS today,
    TIMESTAMPDIFF(YEAR, 
                  STR_TO_DATE(CONCAT(Year, '-01-01'), '%Y-%m-%d'), 
                  CURDATE()) AS years_diff
FROM infectious_cases
LIMIT 20;

-- Крок 5. Власна функція
DELIMITER //

CREATE FUNCTION years_since_year(p_year INT)
RETURNS INT DETERMINISTIC
BEGIN
    DECLARE d DATE;
    SET d = STR_TO_DATE(CONCAT(p_year, '-01-01'), '%Y-%m-%d');
    RETURN TIMESTAMPDIFF(YEAR, d, CURDATE());
END //

DELIMITER ;

-- Використання функції на даних
SELECT 
    Year,
    years_since_year(Year) AS years_diff
FROM infectious_cases
LIMIT 20;