/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM CovidDeaths
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
ORDER BY 3,4


-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY date

-- Select the new cases and total deaths for Portugal
	
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE location = 'Portugal' and new_cases is not NULL
ORDER BY date

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE location = 'Portugal' and total_deaths is not NULL
ORDER BY date
	
-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population in Portugal is infected with Covid-19

SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%Portugal%' AND total_deaths IS NOT NULL 
ORDER BY DeathPercentage DESC

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population)*100) as PercentPopInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopInfected DESC

-- Countries with Highest Death Count per Population

SELECT location, MAX(Total_deaths as int) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Number of persons that were vaccinated at a given time in a certain location

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

-- Using CTE to perform a Calculation on a Partition By in the previous query

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

-- Using Temp Table to perform a Calculation on a Partition By in the previous query

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

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
		     dea.location, 
		     dea.date, 
		     dea.population, 
		     vac.new_vaccinations,
		     SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
	FROM CovidDeaths dea JOIN CovidVaccinations vac
		On dea.location = vac.location AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later use

CREATE VIEW PercentPopVac AS
SELECT dea.continent, 
		     dea.location, 
		     dea.date, 
		     dea.population, 
		     vac.new_vaccinations,
		     SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
	FROM CovidDeaths dea JOIN CovidVaccinations vac
		On dea.location = vac.location AND dea.date = vac.date 

SELECT *
FROM PercentPopVac

-- Indexes creation to improve performance

CREATE INDEX index1 ON CovidDeaths (location)
CREATE INDEX index2 ON CovidDeaths (date)

CREATE INDEX index3 ON CovidDeaths (location, date)

-- Partitioning a table by an appropriate column to enhance query performance

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
