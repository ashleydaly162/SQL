/* First I will create a copy of this table and then insert the data in
to clean so I have the raw data available if mistakes are made */

CREATE TABLE hr_copy
LIKE hr_data;

INSERT INTO hr_copy
SELECT *
FROM hr_data;

/* Now I am going to see if there are duplicate rows so I can remove them.
I will use the ROW_NUMBER(), PARTITION BY, and a CTE
If a row has a row number greater than 1 than it is a duplicate */

/* I was concerned about the 'Employee ID' column having duplicates. This query showed
me that it had a lot*/
SELECT `Employee ID`, COUNT(*) as count
FROM hr_copy
GROUP BY `Employee ID`
HAVING COUNT(*) > 1;

/* I wanted to see if the 'Unnamed:0' column was a valid row number column so I could do
an inner self join to delete the duplicate 'Employee ID' rows. I ran this query and found 
that there were many duplicates so it is not valid */
SELECT `Unnamed: 0` AS 'row', COUNT(*) as count
FROM hr_copy
GROUP BY `Unnamed: 0`
HAVING COUNT(*) > 1;

-- This query showed me all the duplicate EmployeeID rows
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Employee ID`)
AS row_num
FROM hr_copy
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- This query showed me that there were 150 duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Employee ID`)
AS row_num
FROM hr_copy
)
SELECT COUNT(*)
FROM duplicate_cte
WHERE row_num > 1;

/* This query showed me all the duplicate `Unnamed: 0` column rows. I found that 
where there was a duplicated `Unnamed: 0` there was also a duplicate 'Employee ID' */
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Unnamed: 0`)
AS row_num
FROM hr_copy
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Unnamed: 0`, `Employee ID` ORDER BY `Employee ID`)
AS row_num
FROM hr_copy
)
SELECT COUNT(*)
FROM duplicate_cte
WHERE row_num > 1;

/* I then created a new table called hr_cleaned as a safegaurd and add 
a row_num INT column so I can filter out the duplicates */

CREATE TABLE `hr_cleaned` (
  `Unnamed: 0` int DEFAULT NULL,
  `FirstName` text,
  `LastName` text,
  `StartDate` text,
  `ExitDate` text,
  `Title` text,
  `Supervisor` text,
  `ADEmail` text,
  `BusinessUnit` text,
  `EmployeeStatus` text,
  `EmployeeType` text,
  `PayZone` text,
  `EmployeeClassificationType` text,
  `TerminationType` text,
  `TerminationDescription` text,
  `DepartmentType` text,
  `Division` text,
  `DOB` text,
  `State` text,
  `JobFunctionDescription` text,
  `GenderCode` text,
  `LocationCode` int DEFAULT NULL,
  `RaceDesc` text,
  `MaritalDesc` text,
  `Performance Score` text,
  `Current Employee Rating` int DEFAULT NULL,
  `Employee ID` int DEFAULT NULL,
  `Survey Date` text,
  `Engagement Score` int DEFAULT NULL,
  `Satisfaction Score` int DEFAULT NULL,
  `Work-Life Balance Score` int DEFAULT NULL,
  `Training Date` text,
  `Training Program Name` text,
  `Training Type` text,
  `Training Outcome` text,
  `Location` text,
  `Trainer` text,
  `Training Duration(Days)` int DEFAULT NULL,
  `Training Cost` double DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- I inserted all the data into the created table with this query
INSERT INTO hr_cleaned
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Employee ID`)
AS row_num
FROM hr_copy;

-- Then I deleted the duplicates
DELETE FROM hr_cleaned
WHERE row_num > 1;

-- Now we can drop the row_num column
ALTER TABLE hr_cleaned
DROP COLUMN row_num;

/* Then I moved on to standardizing the data. After running the queries below,
I found that there were two 'Data Analyst' values due to a spacing mistake. All the other
columns I looked at were fine */

SELECT DISTINCT Title
FROM hr_cleaned;

SELECT DISTINCT TRIM(Title)
FROM hr_cleaned;

UPDATE hr_cleaned
SET Title = TRIM(Title);

/*I want to convert the empty string 'ExitDate' values to NULLS */

SELECT DISTINCT `ExitDate`
FROM hr_cleaned;

UPDATE hr_cleaned
SET `ExitDate` = NULL
WHERE `ExitDate` = '';

SELECT DISTINCT `StartDate`
FROM hr_cleaned;

/* Then I moved on to standardizing the dates. First I converted them into the appropriate 
format and then I changed the data type from TEXT to DATE */

UPDATE hr_cleaned
SET StartDate = STR_TO_DATE(StartDate, '%d-%b-%y'),
	DOB = STR_TO_DATE(DOB, '%d-%m-%Y'),
    `Survey Date` = STR_TO_DATE(`Survey Date`, '%d-%m-%Y'),
    `Training Date` = STR_TO_DATE(`Training Date`, '%d-%b-%y'),
    ExitDate = STR_TO_DATE(ExitDate, '%d-%b-%y');


ALTER TABLE hr_cleaned
MODIFY COLUMN StartDate DATE,
MODIFY COLUMN DOB DATE,
MODIFY COLUMN `Survey Date` DATE,
MODIFY COLUMN `Training Date` DATE,
MODIFY COLUMN ExitDate DATE;

/* To check for NULL values and blanks in the columns that are relevant, I ran
these queries with the appropriate column names and found nothing */

SELECT * 
FROM hr_cleaned
WHERE Title IS NULL;

SELECT *
FROM hr_cleaned
WHERE Title = '';


-- I'm going to standardize column names to remove spaces
ALTER TABLE hr_cleaned
CHANGE COLUMN `Performance Score` PerformanceScore TEXT,
CHANGE COLUMN `Current Employee Rating` EmployeeRating INT,
CHANGE COLUMN `Employee ID` EmployeeID INT,
CHANGE COLUMN `Survey Date` SurveyDate INT,
CHANGE COLUMN `Engagement Score` EngagementScore INT,
CHANGE COLUMN `Satisfaction Score` SatisfactionScore INT,
CHANGE COLUMN `Work-Life Balance Score` WorkLifeBalanceScore INT,
CHANGE COLUMN `Training Date` TrainingDate DATE,
CHANGE COLUMN `Training Program Name` TrainingProgram TEXT,
CHANGE COLUMN `Training Type` TrainingType TEXT,
CHANGE COLUMN `Training Outcome` TrainingOutcome TEXT,
CHANGE COLUMN `Training Duration(Days)` TrainingDays TEXT,
CHANGE COLUMN `Training Cost` TrainingCost DOUBLE;