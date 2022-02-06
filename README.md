# Crimes In Colorado

In this project, we use a dataset provided by data.colorado.gov for Offenses in Colorado for 2016 through 2019 at the county level. The provided data is cleaned using SQL Server and visualized using Tableau. 

## Overview
- SQL Data Cleaning:
  - Clean county names with invalid values
  - Drop useless NULL values 
  - Replace NULL values with specific county averages
  - Create window functions (day, mtd, ytd running totals)
  - Create date columns (day of the week and month of the year)
  - Create main view that will be used in Tableau
- SQL Answer Various Questions:
  - For the county with the most crimes, which month has the most offenses? 
  - What is the most common hour of the day and day of the week?
  - Which offense category has the highest offenses and where?
- Create Tableau Dashboard

## Use cases
The end product is a Tableau dashboard that can drill down the data and give the user detailed information. 

Example: El Paso County had 240 shoplifting offenses for June in 2019, the most common hour of offense was 2:00 PM with 78 offenses, and the day with the most offenses was Saturday with a total of 42.

## Tableau Dashboard

https://public.tableau.com/views/CrimesInColorado/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link

## Resources

https://data.colorado.gov/



