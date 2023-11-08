SELECT *
FROM [dbo].[fifa21_raw_data]


--------------------------------------------------------------------------------------------------------------------
--convert joined date

SELECT CONVERT(date,joined) AS DateJoined
FROM fifa21_raw_data

UPDATE fifa21_raw_data
SET Joined =  CONVERT(date,joined)
-----------------
---clean weight column

SELECT Round(convert(int,LEFT(Weight, 3))* 0.45359237,0) as weightcleaned -- should convert to kg
FROM fifa21_raw_data

UPDATE fifa21_raw_data
SET Weight =   Round(convert(int,LEFT(Weight, 3))* 0.45359237,0)
-------------
---seperate team_contract column into 2 columns; end year and team

SELECT Team_Contract,
	CASE WHEN Team_Contract LIKE '%~%' THEN SUBSTRING(Team_Contract, CHARINDEX('~', Team_Contract)+2, 4)
	WHEN Team_Contract LIKE '%On Loan%' THEN SUBSTRING(Team_Contract,CHARINDEX(',', Team_Contract)+2,4)
	ELSE NULL
	END AS Contract_End_Year,

   CASE WHEN Team_Contract LIKE '%~%' THEN SUBSTRING(Team_Contract, 1, CHARINDEX('~', Team_Contract)-6)
   WHEN Team_Contract LIKE '%On Loan%' THEN SUBSTRING(Team_Contract, 1,CHARINDEX(',',Team_Contract)-6)
   ELSE Team_Contract
   END as Team

FROM fifa21_raw_data

--------------------------------------------------
--- Add and populate new columns

ALTER TABLE fifa21_raw_data
ADD Contract_End_Year  int

UPDATE fifa21_raw_data
SET Contract_End_Year = CASE WHEN Team_Contract LIKE '%~%' THEN SUBSTRING(Team_Contract, CHARINDEX('~', Team_Contract)+2, 4)
	WHEN Team_Contract LIKE '%On Loan%' THEN SUBSTRING(Team_Contract,CHARINDEX(',', Team_Contract)+2,4)
	ELSE NULL
	END

ALTER TABLE fifa21_raw_data
ADD Team nvarchar (MAX)


UPDATE fifa21_raw_data
SET Team =  CASE WHEN Team_Contract LIKE '%~%' THEN SUBSTRING(Team_Contract, 1, CHARINDEX('~', Team_Contract)-6)
   WHEN Team_Contract LIKE '%On Loan%' THEN SUBSTRING(Team_Contract, 1,CHARINDEX(',',Team_Contract)-6)
   ELSE Team_Contract
   END 

--- Add contract duration column
SELECT Contract_End_Year - YEAR(Joined) AS Contract_Duration
FROM fifa21_raw_data

ALTER TABLE fifa21_raw_data
ADD Contract_Duration int

UPDATE fifa21_raw_data
SET Contract_Duration =  Contract_End_Year - YEAR(Joined)

ALTER TABLE fifa21_raw_data
ADD Contract_Start_Year int

UPDATE fifa21_raw_data
SET Contract_Start_Year = YEAR(Joined)
----------------------------------------------------------------------------
---Convert value, wage and release clause columns

SELECT Value, Wage, Release_Clause,
		CASE WHEN RIGHT(Value,1) = 'M' THEN convert(float,SUBSTRING(Value,2, charindex('M', Value)-2)) *1000000
		WHEN RIGHT(Value,1) = 'K' THEN convert(float,SUBSTRING(Value,2, charindex('K', Value)-2)) *1000
		ELSE 0
		END AS Value_Euro,
		CASE WHEN Charindex('K',Wage)>1 THEN convert(int,SUBSTRING(Wage,2, charindex('K', Wage)-2)) *1000
		--WHEN RIGHT(Value,1) = 'K' THEN convert(float,SUBSTRING(Wage,2, charindex('K', Wage)-2)) *1000
		ELSE SUBSTRING(Wage,2,LEN(Wage)-1)
		END AS Wage_Euro,
		CASE WHEN RIGHT(Release_Clause,1) = 'M' THEN convert(float,SUBSTRING(Release_Clause,2, charindex('M', Release_Clause)-2)) *1000000
		WHEN RIGHT(Release_Clause,1) = 'K' THEN convert(float,SUBSTRING(Release_Clause,2, charindex('K', Release_Clause)-2)) *1000
		ELSE 0
		END AS Release_Clause_Euro
FROM fifa21_raw_data

-------------------------------------------------------------------------------------
--Populate new values in columns wage, value and release-clause

UPDATE fifa21_raw_data
SET Wage = CASE WHEN Charindex('K',Wage)>1 THEN convert(int,SUBSTRING(Wage,2, charindex('K', Wage)-2)) *1000
		--WHEN RIGHT(Value,1) = 'K' THEN convert(float,SUBSTRING(Wage,2, charindex('K', Wage)-2)) *1000
		ELSE SUBSTRING(Wage,2,LEN(Wage)-1)
		END 

UPDATE fifa21_raw_data
SET Release_Clause = CASE WHEN RIGHT(Release_Clause,1) = 'M' THEN convert(float,SUBSTRING(Release_Clause,2, charindex('M', Release_Clause)-2)) *1000000
		WHEN RIGHT(Release_Clause,1) = 'K' THEN convert(float,SUBSTRING(Release_Clause,2, charindex('K', Release_Clause)-2)) *1000
		ELSE 0
		END 

UPDATE fifa21_raw_data
SET Value = CASE WHEN RIGHT(Value,1) = 'M' THEN convert(float,SUBSTRING(Value,2, charindex('M', Value)-2)) *1000000
		WHEN RIGHT(Value,1) = 'K' THEN convert(float,SUBSTRING(Value,2, charindex('K', Value)-2)) *1000
		ELSE 0
		END


--------------------------------------------------------------------------------------------------------------------------------------------
--removing non printable characters from columns W_F,SM, IR

select convert(int,left(LTRIM(W_F),1)),
convert(int,left(LTRIM(SM),1)),convert(int,left(ltrim(IR),2))
from fifa21_raw_data

---------------------------------------------------------------------
--Updating new values
UPDATE fifa21_raw_data
SET W_F = convert(int,left(LTRIM(W_F),1)), SM = convert(int,left(LTRIM(SM),1)), IR = convert(int,left(ltrim(IR),2))

--------------------------------------------------------------------------------------------------------------------------------------------
---find duplicates

WITH RowNumCte AS (
Select *, ROW_NUMBER() OVER(Partition By Name, 
										Age, 
										Height,
										Weight,
										Value
										ORDER By 
										ID) as row_num
FROM fifa21_raw_data
)
--select *
DELETE
FROM RowNumCte
WHERE row_num > 1


select * from fifa21_raw_data

----------------------------------------------------------------------------
--change height column from feet and inches to centimeters

SELECT Height, (Convert(int,LEFT(Ltrim(Height),1))*30.48) +
(convert(int,SUBSTRING(Height,CHARINDEX('''', Height)+1, 1)) * 2.54)
FROM fifa21_raw_data

Update fifa21_raw_data
SET Height = (Convert(int,LEFT(Ltrim(Height),1))*30.48) +
(convert(int,SUBSTRING(Height,CHARINDEX('''', Height)+1, 1)) * 2.54)