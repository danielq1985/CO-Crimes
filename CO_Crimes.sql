USE [colorado-crimes]

--Total rows 
SELECT COUNT(*)
FROM Crimes_in_Colorado; --1,851,996

/*
Overview:
Data Cleaning
-Verify county names are valid locations
-NULL Values
-Clean numeric columns with NULL Values
Window Functions 
--for running total of offenses: day, mtd, ytd
Date Columns
-Day of the week
-Month of the year
Create Main View
Questions
*/

------------------------------------------------------------------
--Verify county names are valid locations

SELECT TOP (20) county_name
FROM Crimes_in_Colorado;

--county name has columns with multiple counties, which will give us problems when plotting
SELECT county_name
FROM Crimes_in_Colorado
WHERE county_name LIKE '%;%'; --323756 rows with multiple counties sperated by ';'
							  --look into all columns with multiple counties, spec the agency
SELECT *
FROM Crimes_in_Colorado
WHERE county_name LIKE '%;%';

--Findings: column containing 'JEFFERSON; ADAMS' had 'Westminster' as the agency.
--Looking at google maps Jefferson and Adams county are touching and Westminster is right in between them.
--To plot the data we can only use one county, so the first county listed will be used only.

SELECT
	CASE WHEN county_name LIKE '%;%' THEN LEFT(county_name, CHARINDEX(';', county_name) - 1) ELSE county_name END
FROM Crimes_in_Colorado;

-------------------------------------------------------------------
--NULL Values

--Any NULL values, how many per column?
SELECT SUM(CASE WHEN pub_agency_name IS NULL THEN 1 ELSE 0 END) pub_agency_name_nulls,
       SUM(CASE WHEN county_name IS NULL THEN 1 ELSE 0 END) county_name_nulls,
	   SUM(CASE WHEN incident_date IS NULL THEN 1 ELSE 0 END) incident_date_nulls,
	   SUM(CASE WHEN incident_hour IS NULL THEN 1 ELSE 0 END) incident_hour_nulls,
	   SUM(CASE WHEN offense_name IS NULL THEN 1 ELSE 0 END) offense_name_nulls,
	   SUM(CASE WHEN crime_against IS NULL THEN 1 ELSE 0 END) crime_against_nulls,
	   SUM(CASE WHEN offense_category_name IS NULL THEN 1 ELSE 0 END) offense_category_name_nulls,
	   SUM(CASE WHEN offense_group IS NULL THEN 1 ELSE 0 END) offense_group_nulls,
	   SUM(CASE WHEN age_num IS NULL THEN 1 ELSE 0 END) age_num_nulls
FROM Crimes_in_Colorado; --NULLS in every column. Age having the greatest at 802925. 
                         --Also, there are 6 columns with 624 NULLS that we will look into

--Find trends in NULL values and to determine an action for each column
SELECT * 
FROM Crimes_in_Colorado
WHERE pub_agency_name IS NULL; --624 NULLS where every column except Age are also NULLS. 
                               --We will def drop those row as Age alone cannot be used.
SELECT * 
FROM Crimes_in_Colorado
WHERE county_name IS NULL; --6346 NULLS. Out of all NULLS the Agency responsible for the offense/arrest is 'State Patrol'
						   --or 'Colorado Bureau of Investigation'. This is an important finding seeing as we are location driven in 
						   --our analysis. We will drop these values.
SELECT * 
FROM Crimes_in_Colorado
WHERE incident_date IS NULL; --624 NULLS where every column except Age are also NULLS
							 --Exact results from checking pub_agency name NULLS
SELECT * 
FROM Crimes_in_Colorado
WHERE incident_hour IS NULL; --25821 NULLS where incident hour was not recorded
							 --Every column has records except there are some NULLS in age
							 --These are usefull rows and 
SELECT * 
FROM Crimes_in_Colorado
WHERE offense_name IS NULL; --repeat of the 624

SELECT * 
FROM Crimes_in_Colorado
WHERE crime_against IS NULL; --repeat of the 624

SELECT * 
FROM Crimes_in_Colorado
WHERE offense_category_name IS NULL; --repeat of the 624

SELECT * 
FROM Crimes_in_Colorado
WHERE offense_group IS NULL; --repeat of the 624

SELECT * 
FROM Crimes_in_Colorado
WHERE age_num IS NULL; --802925 NULLS, with the other columns still being useful

------------------------------------------------------------------
--Clean numeric columns with NULL Values

--NOTE: to deal with numeric column NULLS we will first look into averages by county to see 
--if we can simply coalesce OVERALL averages or if we should coalesce with COUNTY averages
--Example: incident hour overall average is 17, but the incident average for ADAMS COUNTY is 13
--This is the method we will use for Age as well

--change incident hour from nvarchar to smallint
ALTER TABLE Crimes_in_Colorado
ALTER COLUMN incident_hour SMALLINT;

SELECT TOP (5) * 
FROM Crimes_in_Colorado;

--Incident hour NULLS
SELECT AVG(incident_hour) mean_overall
FROM Crimes_in_Colorado; --overall mean incident hour is 12

SELECT county_name, AVG(incident_hour) mean_by_county
FROM Crimes_in_Colorado
WHERE county_name = county_name
GROUP BY county_name
ORDER BY 2 DESC; --mean incident hour by county ranges from 14 - 0

--Age NULLS
SELECT AVG(age_num) mean_overall
FROM Crimes_in_Colorado; --overall mean age is 30

SELECT county_name, AVG(age_num) mean_by_county
FROM Crimes_in_Colorado
WHERE county_name = county_name
GROUP BY county_name 
ORDER BY 2 DESC; --mean age by county ranges from 42 - 27

--It will be important to use the averages by county and not overall averages

---------------------------------------------------------------
--Window Functions 
--for running total of offenses: day, mtd, ytd

SELECT *,
		COUNT(county_name) OVER (PARTITION BY county_name, incident_date ORDER BY incident_date) as offs_day,
		COUNT(county_name) OVER (PARTITION BY county_name, MONTH(incident_date), YEAR(incident_date) ORDER BY incident_date) as offs_mtd,
		COUNT(county_name) OVER (PARTITION BY county_name, YEAR(incident_date) ORDER BY incident_date) as offs_ytd

FROM Crimes_in_Colorado
ORDER BY incident_date ASC;

------------------------------------------------------------------------
--Date Columns
--Day of the week
--Month of the year

SELECT TOP 100 *, 
		   DATENAME(WEEKDAY, incident_date) day, 
		   DATENAME(MONTH, incident_date) month
FROM Crimes_in_Colorado;

-------------------------------------------------------------------------
--Create Main View

CREATE VIEW ColoradoCrimesView AS

WITH CountyName AS --clean county names that contain multiple counties
(SELECT *,
	CASE WHEN county_name LIKE '%;%' THEN LEFT(county_name, CHARINDEX(';', county_name) - 1) ELSE county_name END AS county_name_update
FROM Crimes_in_Colorado),

IncidentHour AS --change incident hours that are NULL to correlating counties average
(SELECT county_name_update, 
        AVG(incident_hour) ih_mean_by_county
FROM CountyName
WHERE county_name_update = county_name_update
GROUP BY county_name_update),

AgeNum AS --change ages that are NULL to correlating counties average
(SELECT county_name_update, 
        AVG(age_num) age_mean_by_county
FROM CountyName
WHERE county_name_update = county_name_update
GROUP BY county_name_update)

SELECT CountyName.county_name_update AS county_name, 
	   CountyName.pub_agency_name, 
	   CountyName.incident_date, 
	   CountyName.offense_name,
	   CountyName.crime_against, 
	   CountyName.offense_category_name,
	   CASE WHEN CountyName.incident_hour IS NULL 
		   THEN IncidentHour.ih_mean_by_county 
		   ELSE CountyName.incident_hour END AS incident_hour,
	   CASE WHEN CountyName.age_num IS NULL
		   THEN AgeNum.age_mean_by_county
		   ELSE CountyName.age_num END AS age_num,
	   COUNT(CountyName.county_name) OVER (PARTITION BY CountyName.county_name, CountyName.incident_date ORDER BY CountyName.incident_date) as offs_day,
	   COUNT(CountyName.county_name) OVER (PARTITION BY CountyName.county_name, MONTH(CountyName.incident_date), YEAR(CountyName.incident_date) ORDER BY CountyName.incident_date) as offs_mtd,
	   COUNT(CountyName.county_name) OVER (PARTITION BY CountyName.county_name, YEAR(CountyName.incident_date) ORDER BY CountyName.incident_date) as offs_ytd
FROM CountyName

LEFT JOIN IncidentHour
	ON CountyName.county_name_update = IncidentHour.county_name_update

LEFT JOIN AgeNum
	ON CountyName.county_name_update = AgeNum.county_name_update

WHERE CountyName.pub_agency_name IS NOT NULL --drop NULLS from agency
AND 
CountyName.county_name IS NOT NULL; --drop NULLS from county

--Result of 1,845,650 rows with no NULLS

-------------------------------------------------------------------
--Questions

-- What are the diff agencies? # of offences per agency
SELECT pub_agency_name, 
	COUNT(*) number_of_offenses
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]
GROUP BY pub_agency_name
ORDER BY 2 DESC; --217 agencies

-- What are the diff counties? # of offences per county
SELECT county_name, 
	COUNT(county_name) number_of_offenses
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]
GROUP BY county_name
ORDER by 2 DESC; --63 diff counties, Denver having the most offenses at 291,398

-- What is the date range?
SELECT MIN(incident_date) min_date, 
		MAX(incident_date) max_date
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]; --2016-01-01, 2019-12-31

--diff types of offenses
SELECT DISTINCT offense_name
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]; --51 diff types

--diff types of crime against
SELECT DISTINCT crime_against
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]; --Property, Society, Person

--diff types of offense category names
SELECT DISTINCT offense_category_name
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]; --24 diff types

--Which offense category has the highest offenses, and where?
SELECT offense_category_name, county_name, COUNT(*) offense_count
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]
GROUP BY offense_category_name, county_name
ORDER BY 3 DESC; --Larceny/Theft Offenses in DENVER with 90325

--For the county with the most crimes, which month has the most assault offenses?
WITH t1 AS
(SELECT county_name, 
		COUNT(county_name) number_of_offenses
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]
GROUP BY county_name)

SELECT county_name, 
	   DATEPART(MONTH, incident_date) month, 
	   COUNT(*) number_of_offenses
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]
WHERE county_name = 
	(SELECT TOP(1) county_name
	FROM t1
	ORDER BY number_of_offenses DESC)
	AND
	offense_category_name = 'Assault Offenses'
GROUP BY county_name, DATEPART(MONTH, incident_date)
ORDER BY 3 DESC; --Denver in July with 4489


--For the above, which hour and day of the week is most dangerous, and for which age?
SELECT DATENAME(WEEKDAY, incident_date) day_group, 
	   incident_hour, 
	   age_num,
	   COUNT(*) off_count
FROM [colorado-crimes].[dbo].[ColoradoCrimesView]
WHERE county_name = 'DENVER'
GROUP BY DATENAME(WEEKDAY, incident_date), 
         incident_hour, 
		 age_num
ORDER BY off_count DESC; --according to the data, Friday at the 17th hour, with the age of 32.