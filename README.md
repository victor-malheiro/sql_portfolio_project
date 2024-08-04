# COVID-19 Deaths and Vaccination Analysis
In his project the goal is to analyze data regarding COVID-19 deaths and vaccinations downloaded from https://ourworldindata.org.

The repository contains three files, two with the data used and a file with all the queries created.

## Table of Contents
1. [Project Statement](#project-statement)
2. [Objectives](#objectives)
3. [Data](#data)
4. [SQL](#sql)
   - [Importing Data Into SQL](#importing-data-into-sql)
   - [SQL Queries](#sql-queries)
   - [Optimization Suggestions](#optimization-suggestions)
6. [Recommendations](#recommendations)

## Project Statement
<div align="justify">This project will provide information about deaths by country, the proportion of total deaths relating to the total cases and total population, infection rates, 
  the percentage of a certain population that received the vacines. To achieve this goal i will use SQL queries, Common Table Expressions (CTE) to perform calculations, 
  a Temporary Table to perform a Calculation on Partition By and i will also Create a View to store data for later visualizations.</div></br>

<div align="justify">Using the Microsoft SQL Server Studio, i will to store, retrieve, manage and manipulate the data to extract the required insights that are important to understand the data. 
  Optimization suggestions are also done using indexing and partitioning of the data.</div></br>

## Objectives
With this project i want to answer several question to help understand the impact that COVID-19 had in different countries or continentes and how vaccination helped to mitigated the problem.
- Total Cases vs Total Deaths in a certain country
- Total Cases vs Population of a certain country
- Countries with Highest Infection Rate compared to Population
- Countries with Highest Death Count per Population
- number of persons that were vaccinated at a given time in a certain location
- Percentage of Population that has recieved at least one Covid Vaccine

## Data
The data used is taken from a website that provides informationrelated with the confirmed deaths and vaccinations from COVID-19 on the [Our World in Data](https://ourworldindata.org/covid-deaths) website.

<div align="justify">The dataset was divided into two files so we could have two diferente tables with information about the covid-19 deaths and vaccinations.</div></br>

## SQL
The database used is the Microsoft SQL Server 2022 and the Microsoft SQL server management studio was used to query the data.

### Importing Data Into SQL
Two diferent tables were imported from two excel files with information about the deaths and vaccinations. The tables are CovidDeaths and CovidVaccinations.
We can see on the image below the two tables ordered by the country and the date using a queries

![image](https://github.com/user-attachments/assets/155ea1f3-42a5-431b-ac35-b84f2e4457e6)

```
SELECT *
FROM CovidDeaths
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
ORDER BY 3,4
```

### SQL Queries
To do an analysis on how the data that i will use looks, i will create a query to show me from the CovidDeaths table the location, date, total_cases, new_cases, total_deaths and population.

```
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY date
```

We can see that we have several fields with missing values and that the the first case reported was on the 1st of January, 2020. And the data goes until the 22nd of July 2024.

Analyzing the data for Portugal, with the query below, i can see that the first case was recorded on the 23/02/2020 and that the first deaths were registered on the 22/03/2020.

```
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE location = 'Portugal' and new_cases is not NULL
ORDER BY date

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE location = 'Portugal' and total_deaths is not NULL
ORDER BY date
```

**1 - Total Cases vs Total Deaths in a certain country**
First we want to know if the Total Deaths is big in relation to the total cases for Portugal

```
SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%Portugal%' and total_deaths IS NOT NULL 
ORDER BY DeathPercentage DESC
```
![image](https://github.com/user-attachments/assets/02a18dec-7d83-427e-b20e-b729710cf274)
![image](https://github.com/user-attachments/assets/e2b87fd2-0037-4074-9576-9bc11d183a6d)

We can see that the higgest percentage was on the beggining of the pandemic in April, May and June 2020. The lowest was on the second half of 2022, probaly because it was after the vacines were taking its effect.

**2 - Total Cases vs Population of Portugal**
Since the vírus is becoming endemic we can see that the percentage of the population infected is increasing through time, but the death percentage is decreasing.
````
SELECT location, date, total_cases,population, (total_cases/population)*100 as PercentPopInfected
FROM CovidDeaths
WHERE location like '%Portugal%' and total_deaths is not NULL 
ORDER BY PercentPopInfected DESC
````
![image](https://github.com/user-attachments/assets/2d148882-ae28-4ca6-9962-22132b7a8407)
![image](https://github.com/user-attachments/assets/aa7a83b2-d9bd-4bf8-bddd-0fa04a9b4bd0)

**3 - Countries with Highest Infection Rate compared to Population**
````
SELECT location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population)*100) as PercentPopInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopInfected DESC
````
![image](https://github.com/user-attachments/assets/48d33a94-176a-4f82-a765-4d568b5ba06b)

We can see that the country with the highest percentage of population infected is Cypress with 77%.

**4 - Countries with Highest Death Count per Population**
````
SELECT location, MAX(Total_deaths as int) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC
````
With the "Where continent is not null " we garuantee that the data shown is only the countries and not the continentes, becaus ethe dataset has some lines with the number for the continent in the location column.
![image](https://github.com/user-attachments/assets/e2195649-95a0-4a4a-a82d-62d7f18f0ffe)
![image](https://github.com/user-attachments/assets/5ef5a522-ac73-4e27-bbce-cca4ccb80b53)

**5 - Number of persons that were vaccinated at a given time in a certain location**
To know the total number of persons that were vaccinated until a given time, on a certain location and also several information from the CovidDeaths table, i added the numbers of the new vaccinations,
partitioning the data by location and ordering by the location and date. To do this i also did a join of the two tables by location and date.
````
SELECT dea.continent, 
	     dea.location, 
	     dea.date, 
	     dea.population, 
	     vac.new_vaccinations, 
	     SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY location, date
````
The 'OVER' clause was used to compute the aggregated values over a group of rows. With this clause i can have control over where the window starts and ends for each row in the result set. 
The difference in relation to GROUP BY is that it divides the results in windows instead of aggregating the entire result set.
![image](https://github.com/user-attachments/assets/bc80eee4-cd5b-4559-8037-8bbf420c95e3)

**6 - Percentage of Population that has recieved at least one Covid Vaccine**
To simplify the queries i created a **common table expression(CTE)**, this is usefull with a subquery that will make the understanding of the whole query very hard.  

To compute the percentage of the population that received at least one vaccine, i created the CTE below and then i could use it to query the data.
````
WITH PopVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
AS 
(
	SELECT dea.continent, 
		     dea.location, 
		     dea.date, 
		     dea.population, 
		     vac.new_vaccinations,
		     SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
	FROM CovidDeaths dea JOIN CovidVaccinations vac
		On dea.location = vac.location AND dea.date = vac.date
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercPopVac
FROM PopVac
````

A **temporary table** can be created in case the results of a certain query are used on other queries.

First i create a new temp table with the column of the previous query. The DROP TABLE IF EXISTS statement is necessary in case i need to change something in the table since i will create the table again.
````
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
  Continent nvarchar(255),
  Location nvarchar(255),
  Date datetime,
  Population numeric,
  New_vaccinations numeric,
  RollingPeopleVaccinated numeric
)
````

Then i insert the results of the previous query into the table.

````
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
		     dea.location, 
		     dea.date, 
		     dea.population, 
		     vac.new_vaccinations,
		     SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
	FROM CovidDeaths dea JOIN CovidVaccinations vac
		On dea.location = vac.location AND dea.date = vac.date
````

And finally, i can use the new table on a new query.

````
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated
````

If i want something more permanent, to use latter for visualizations, for example, or as security mechanism by letting users access data through the view, without granting users permissions to directly access the underlying tables of the query, i can create views. 
Views can also be used to emulate a table that used to exist but whose schema has changed or when someone copies data to and from a SQL Server to improve performance and to partition data.

I created a view with the code below,

````
CREATE VIEW PercentPopVac AS
SELECT dea.continent, 
		     dea.location, 
		     dea.date, 
		     dea.population, 
		     vac.new_vaccinations,
		     SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
	FROM CovidDeaths dea JOIN CovidVaccinations vac
		On dea.location = vac.location AND dea.date = vac.date 
````

And then i can create queries with it.

````
SELECT *
FROM PercentPopVac
````

### Optimization Suggestions
If the tables grows significantly in size, it is beneficial to optimize the table for efficient query execution considering the following suggestions

#### Indexing
Ensures that a certain table is properly indexed to improve performance when grouping and filtering the data. In this case, creating indexes on the location and date columns can significantly enhance query execution speed. 
I used following SQL statements to create the necessary indexes:
````
CREATE INDEX index1 ON CovidDeaths (location)
CREATE INDEX index2 ON CovidDeaths (date)
````

In case i need to frequently filter scores for a specific location within a date range, as we did for Portugal previously, i can create a multi-column index on (location, date) to further improve performance when filtering data based on both columns. 
To create the multi-column index, i used the following SQL statement:
````
CREATE INDEX index3 ON CovidDeaths (location, date)
````

#### Partitioning
Partitioning a table by an appropriate column can also enhance query performance, such as the date, can provide more efficient querying by scanning only relevant partitions. 
For example, i can partition the CovidDeaths table by month, using the date column as the partition key. Bellow is an example of creating partitioned tables to separate the data of June of 2020.
````
-Partition on table CovidDeaths
USE CovidDeaths
GO

--- create partition function
CREATE PARTITION FUNCTION CovidDeaths_Partition (datetime2(0))
AS RANGE RIGHT FOR VALUES ('2020-06-01', '2020-07-01') ;  
GO  

--- create scheme
CREATE PARTITION SCHEME CovidDeaths_Scheme  
    AS PARTITION CovidDeaths_Partition  
    ALL TO ('PRIMARY') ;  
GO 

--- create table
CREATE TABLE dbo.PartitionTable (date datetime2(0) PRIMARY KEY, location varchar(255), new_deaths(255))  
    ON CovidDeaths_Scheme (date) ;  
GO
````

Partitioning the table allows queries that filters or group by date to scan only the relevant partitions, resulting in faster query times. The decision to partition a table should be carefully 
considered based on the size of the table, the frequency and complexity of the queries and the available resources.

## Recommendations
<div align="justify">To run the SQL queries, open the code file in Microsoft SQL Server Management Studio and load the tables using the excel files on the repository.</div></br>

© 2024 Victor Malheiro
