-- Now I'm going to explore the data

/* This query is going to show me which age groups dominate this company. I used TIMESTAMPDIFF(YEAR, DOB, CURDATE()) to get the age 
because there is only a DOB column*/

SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) < 25 THEN 'Under 25'
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 25 AND 34 THEN '25-34'
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 35 AND 44 THEN '35-44'
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 45 AND 54 THEN '45-54'
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_group,
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hr_cleaned), 2) AS percentage
FROM hr_cleaned
GROUP BY age_group
ORDER BY age_group; -- The largest percentage (31.87%) of employee is 65+. The lowest percentage (2.40%) is under 25

/* Now this query is going to show the diversity of the company */

SELECT 
    RaceDesc, 
    COUNT(*) AS total_employees,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hr_cleaned), 2) AS percentage
FROM hr_cleaned
GROUP BY RaceDesc
ORDER BY percentage DESC; -- It looks like we have a pretty good race ratio

/* Now I'm going to run this query to see which departments are the largest/smallest */

SELECT 
    DepartmentType, 
    COUNT(*) AS department_size,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hr_cleaned), 2) AS percentage
FROM hr_cleaned
GROUP BY DepartmentType
ORDER BY percentage DESC; -- We can see that production is by far the largest and executive office is the smallest


-- do certain departments have a gender imbalance?

SELECT 
    DepartmentType, 
    GenderCode, 
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY DepartmentType), 2) AS percentage
FROM hr_cleaned
GROUP BY DepartmentType, GenderCode
ORDER BY DepartmentType, percentage DESC; -- executive office has a major gender imbalance(95.83% males, 4.17% females), sales and production also does

-- now lets see how long employees worked before exiting

SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, StartDate, ExitDate) < 1 THEN 'Less than 1 year'
        WHEN TIMESTAMPDIFF(YEAR, StartDate, ExitDate) BETWEEN 1 AND 3 THEN '1-3 years'
        WHEN TIMESTAMPDIFF(YEAR, StartDate, ExitDate) BETWEEN 4 AND 7 THEN '4-7 years'
        WHEN TIMESTAMPDIFF(YEAR, StartDate, ExitDate) BETWEEN 8 AND 12 THEN '8-12 years'
        ELSE '13+ years'
    END AS tenure_bracket,
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hr_cleaned WHERE ExitDate IS NOT NULL), 2) AS percentage
FROM hr_cleaned
WHERE ExitDate IS NOT NULL
GROUP BY tenure_bracket
ORDER BY tenure_bracket; -- most employees stay 0-3 years(97.46%)

-- pay zones for race and gender

SELECT 
    GenderCode, 
    PayZone, 
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY GenderCode), 2) AS percentage
FROM hr_cleaned
GROUP BY GenderCode, PayZone
ORDER BY GenderCode, percentage DESC; -- pay is pretty even across gender


SELECT 
    RaceDesc, 
    PayZone, 
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY RaceDesc), 2) AS percentage
FROM hr_cleaned
GROUP BY RaceDesc, PayZone
ORDER BY RaceDesc, percentage DESC; -- pay is pretty even across race


-- does tenure affect pay? no
WITH TenureData AS (
    SELECT 
        CASE 
            WHEN TIMESTAMPDIFF(YEAR, StartDate, CURDATE()) < 1 THEN 'Less than 1 year'
            WHEN TIMESTAMPDIFF(YEAR, StartDate, CURDATE()) BETWEEN 1 AND 3 THEN '1-3 years'
            WHEN TIMESTAMPDIFF(YEAR, StartDate, CURDATE()) BETWEEN 4 AND 7 THEN '4-7 years'
            WHEN TIMESTAMPDIFF(YEAR, StartDate, CURDATE()) BETWEEN 8 AND 12 THEN '8-12 years'
            ELSE '13+ years'
        END AS tenure_bracket,
        PayZone
    FROM hr_cleaned
)
SELECT 
    tenure_bracket, 
    PayZone,
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY tenure_bracket), 2) AS percentage
FROM TenureData
GROUP BY tenure_bracket, PayZone
ORDER BY tenure_bracket, percentage DESC;