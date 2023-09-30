/*

Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
	FROM PortfolioProject..CovidDeaths
	ORDER BY location, date

SELECT *
	FROM PortfolioProject..CovidVaccinations
	ORDER BY location, date

------------------------------------------------------------------------------------------------------------------------

-- Select Data that we are going to be using

SELECT continent, location, date, total_cases, new_cases, total_deaths, population
	FROM PortfolioProject..CovidDeaths
	ORDER BY 2, 3

SELECT continent, location, date, new_vaccinations
	FROM PortfolioProject..CovidVaccinations
	ORDER BY 2, 3

------------------------------------------------------------------------------------------------------------------------

-- Total Cases vs. Total Deaths
-- Shows likelihood of dying if you contract Covid

SELECT location, date, total_cases, total_deaths, (CONVERT(DECIMAL, total_deaths)/total_cases)*100 'percentageDeath'
	FROM PortfolioProject..CovidDeaths
	ORDER BY 1, 2

-- Shows likelihood of dying in you contract Covid in Canada

SELECT location, date, total_cases, total_deaths, (CONVERT(DECIMAL, total_deaths)/total_cases)*100 'percentageDeath'
	FROM PortfolioProject..CovidDeaths
	WHERE location = 'Canada'
	ORDER BY 2

-- Total Cases vs Population
-- Shows percentage of population who got Covid (optional: in Canada)

SELECT location, date, population, total_cases, total_cases/CONVERT(DECIMAL, population)*100 'percentagePopulation'
	FROM PortfolioProject..CovidDeaths
--	WHERE location = 'Canada'
	ORDER BY 1, 2

-- Countries with highest infection rate relative to population

SELECT location, population, MAX(CONVERT(DECIMAL, total_cases)) 'highestInfectionCount', MAX(total_cases/CONVERT(DECIMAL, population)*100) 'percentagePopulation'
	FROM PortfolioProject..CovidDeaths
	GROUP BY location, population
	ORDER BY 4 DESC

-- Deaths by continent
-- Showing continents with highest death count

SELECT continent, MAX(CONVERT(DECIMAL, total_deaths)) 'highestDeathCount'
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent
	ORDER BY 2 DESC

-- Deaths and death % by income

SELECT location, MAX(CONVERT(DECIMAL, total_deaths)) 'highestDeathCount', MAX(total_deaths/CONVERT(DECIMAL, population)*100) 'percentDeath'
	FROM PortfolioProject..CovidDeaths
	WHERE location LIKE '%income'
	GROUP BY location
	ORDER BY 3 DESC

-- Deaths by country
-- Showing the countries with highest death count

SELECT location, MAX(CONVERT(DECIMAL, total_deaths)) 'highestDeathCount'
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY location
	ORDER BY 2 DESC

-- Countries with highest death rates relative to population

SELECT location, MAX(total_deaths/CONVERT(DECIMAL, population)*100) 'percentDeath'
	FROM PortfolioProject..CovidDeaths
	GROUP BY location
	ORDER BY 2 DESC

-- Global Numbers
-- Shows number of covid cases, covid deaths, and death percent

SELECT date, SUM(new_cases) 'newCases', SUM(new_deaths) 'newDeaths', SUM(new_deaths)/SUM(new_cases)*100 'percentDeath'
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	AND new_cases <> 0
	GROUP BY date
	ORDER BY 1

-- Looking at Total Population vs. Vaccinations

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations
	FROM PortfolioProject..CovidDeaths deaths
		JOIN PortfolioProject..CovidVaccinations vax
			ON deaths.location = vax.location
				AND deaths.date = vax.date
	WHERE deaths.continent IS NOT NULL
	ORDER BY 2, 3

-- Looking at new vaccinations per day (rolling count)

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations
, SUM(CONVERT(DECIMAL, vax.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) 'rollingVaccinations'
	FROM PortfolioProject..CovidDeaths deaths
		JOIN PortfolioProject..CovidVaccinations vax
			ON deaths.location = vax.location
				AND deaths.date = vax.date
	WHERE deaths.location = 'Canada' -- Canada
--	WHERE deaths.continent IS NOT NULL -- worldwide
	ORDER BY 2, 3

-- Rolling vaccinations by percentage of population (using CTE)

WITH popVaxxed (Continent, Location, Date, Population, New_Vaccinations, rollingVaccinations) AS (
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations
	, SUM(CONVERT(DECIMAL, vax.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) 'rollingVaccinations'
		FROM PortfolioProject..CovidDeaths deaths
			JOIN PortfolioProject..CovidVaccinations vax
				ON deaths.location = vax.location
					AND deaths.date = vax.date
		WHERE deaths.location = 'Canada' -- Canada
	--	WHERE deaths.continent IS NOT NULL -- worldwide
) SELECT *, rollingVaccinations/population*100 'percentVaccinations'
	FROM popVaxxed

-- Rolling vaccinatoins by percentage of population (using temp table)

DROP TABLE IF EXISTS #percentVaccination
CREATE TABLE #percentVaccination (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rollingVaccinations numeric
) INSERT INTO #percentVaccination
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations
	, SUM(CONVERT(DECIMAL, vax.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) 'rollingVaccinations'
		FROM PortfolioProject..CovidDeaths deaths
			JOIN PortfolioProject..CovidVaccinations vax
				ON deaths.location = vax.location
					AND deaths.date = vax.date
		WHERE deaths.location = 'Canada' -- Canada
	--	WHERE deaths.continent IS NOT NULL -- worldwide
SELECT *, rollingVaccinations/population*100 'percentVaccinations'
	FROM #percentVaccination

------------------------------------------------------------------------------------------------------------------------
	
-- Views
-- Creating view to store data for later visualizations

CREATE VIEW percentVaccinated AS
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations
	, SUM(CONVERT(DECIMAL, vax.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) 'rollingVaccinations'
		FROM PortfolioProject..CovidDeaths deaths
			JOIN PortfolioProject..CovidVaccinations vax
				ON deaths.location = vax.location
					AND deaths.date = vax.date
		WHERE deaths.continent IS NOT NULL
