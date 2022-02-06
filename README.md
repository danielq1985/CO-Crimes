# Crimes In Colorado

In this project we use a dataset provided by data.colorado.gov for Colorado crimes from 2016-2019 to explore crimes at the county level. The provided data is cleaned using SQL Server and visualized using Tableau.

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
The end product is a Tableau dashboard that is able to drill down the data and answer detailed questions. 
Example:

## Tableau Dashboard

https://public.tableau.com/app/profile/daniel.martinez8870/viz/CrimesInColorado/Dashboard1

## Resources

https://data.colorado.gov/



