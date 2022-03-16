-- Total Cases vs Total Deaths
-- Shows mortality rate of COVID, by date, in the United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM COVIDExploration..CovidDeaths
WHERE location='United States'
ORDER BY date


-- Total Cases vs Population
-- Shows percentage of population that got COVID, by date, in the United States
SELECT location, date, population, total_cases, (total_cases/population)*100 as population_covid_percentage
FROM COVIDExploration..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2


-- Shows countries with highest infection rate as a percentage of population
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as population_covid_percentage
FROM COVIDExploration..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY population_covid_percentage desc


-- Shows countries with highest death count total
SELECT location, MAX(cast(total_deaths as int)) as total_coviddeaths
FROM COVIDExploration..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY total_coviddeaths desc


-- Shows countries with highest death count as a percentage of population
SELECT location, population, MAX(CAST(total_deaths as int)) as highest_death_count, MAX((CAST(total_deaths as int)/population))*100 as population_coviddeath_percentage
FROM COVIDExploration..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY population_coviddeath_percentage desc


-- Shows continents with highest death count total
SELECT location, MAX(cast(total_deaths as int)) as total_coviddeaths
FROM COVIDExploration..CovidDeaths
WHERE continent is NULL AND location !='Upper middle income' AND location !='High income' AND location !='Lower middle income' AND location !='Low income'
GROUP BY location
ORDER BY total_coviddeaths desc


-- Shows highest death count total by income bracket
SELECT location, MAX(cast(total_deaths as int)) as total_coviddeaths
FROM COVIDExploration..CovidDeaths
WHERE location ='Upper middle income' OR location ='High income' OR location ='Lower middle income' OR location ='Low income'
GROUP BY location
ORDER BY total_coviddeaths desc


-- Shows global death count totals | Method #1: Using 'World' location
SELECT location, date, total_deaths
FROM COVIDExploration..CovidDeaths
WHERE location='World'
ORDER BY date


-- Shows global cases and death count totals by date | Method #2: Using all data and aggregate functions
SELECT date, SUM(new_cases) as total_cases_calced, SUM(cast(new_deaths as int)) as total_deaths_calced
FROM COVIDExploration..CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2


-- Shows global death count totals as a percentage of population
SELECT date, SUM(new_cases) as total_cases_calced, SUM(cast(new_deaths as int)) as total_deaths_calced, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as population_coviddeath_percentage
FROM COVIDExploration..CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY population_coviddeath_percentage desc

-- Shows global death percentage
SELECT SUM(new_cases) as total_cases_calced, SUM(cast(new_deaths as int)) as total_deaths_calced, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as population_coviddeath_percentage
FROM COVIDExploration..CovidDeaths
WHERE continent is NOT NULL
ORDER BY population_coviddeath_percentage desc




-- Shows Total Population vs Vaccinations, by date
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
FROM COVIDExploration..CovidDeaths cd
Join COVIDExploration..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent is NOT NULL
ORDER BY location, date

-- Shows Total Population vs Vaccinations, and displays rolling count of vaccinations by date
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(float,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as vaccination_rolling_total
FROM COVIDExploration..CovidDeaths cd
Join COVIDExploration..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent is NOT NULL AND cv.new_vaccinations is NOT NULL
ORDER BY location, date


-- Shows Total Population vs Vaccinations, and display rolling count of vaccinations by date, including vaccination percentage vs. population
-- Method #1: CTE for using vaccination_rolling_total
With PopVac (Continent, Location, Date, Population, New_Vaccinations, VaccinationRollingTotal)
as
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(float,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as vaccination_rolling_total
FROM COVIDExploration..CovidDeaths cd
Join COVIDExploration..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent is NOT NULL AND cv.new_vaccinations is NOT NULL
)
SELECT *, (VaccinationRollingTotal/Population) *100 as VaccinationRollingTotalPercentage
FROM PopVac


-- Shows Total Population vs Vaccinations, and display rolling count of vaccinations by date, including vaccination percentage vs. population
-- Method #2: Temp Table for using vaccination_rolling_total
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
VaccinationRollingTotal numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(float,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as vaccination_rolling_total
FROM COVIDExploration..CovidDeaths cd
Join COVIDExploration..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent is NOT NULL AND cv.new_vaccinations is NOT NULL

SELECT *, (VaccinationRollingTotal/Population) *100 as VaccinationRollingTotalPercentage
FROM #PercentPopulationVaccinated



-- Creating views for Tableau Viz
CREATE VIEW PercentPopulationVaccinated as
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(float,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as vaccination_rolling_total
FROM COVIDExploration..CovidDeaths cd
Join COVIDExploration..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent is NOT NULL AND cv.new_vaccinations is NOT NULL

SELECT *
FROM PercentPopulationVaccinated


-- Tableau Viz #1: SUMMARY VIEW - total cases, deaths, and death percentage summary
SELECT SUM(new_cases) as 'Total Cases', SUM(CAST(new_deaths as bigint)) as 'Total Deaths', SUM(CAST(new_deaths as bigint))/SUM(new_cases )*100 as 'Death Percentage'
FROM COVIDExploration..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Tableau Viz #2: TOTAL DEATH COUNT - displayed by continent
SELECT location as 'Location', SUM(CAST(new_deaths as bigint)) as 'Total Death Count'
FROM COVIDExploration..CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('World', 'European Union', 'International','Upper middle income', 'High income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY 'Total Death Count' DESC

--Tableau Viz #3: INFECTION COUNT & COVID% - shows countries with highest infection rate as a percentage of population
SELECT location as 'Location', population as 'Population', MAX(total_cases) as 'Highest Infection Count', MAX((total_cases/population))*100 as 'Population % with COVID'
FROM COVIDExploration..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY 'Population % with COVID' DESC

--Tableau Viz#4: - PERCENT POPULATION INFECTED - displayed by date 
SELECT location as 'Location', population as 'Population', date as 'Date', MAX(total_cases) as 'Highest Infection Count', MAX((total_cases/population))*100 as 'Percent Population Infected'
FROM COVIDExploration..CovidDeaths
GROUP BY location, population, date
ORDER BY 'Percent Population Infected' DESC



-- TESTING my world Pop, seems too high.. total cases is higher than world pop
SELECT SUM(new_cases) as 'Total Cases', SUM(CAST(new_deaths as bigint)) as 'Total Deaths', SUM(CAST(new_deaths as bigint))/SUM(new_cases )*100 as 'Death Percentage'
FROM COVIDExploration..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- SUM should be of new cases, not total cases...
SELECT location, continent, population, SUM(new_cases) as TotalCaseSum
FROM COVIDExploration..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent, population
ORDER BY 4 DESC



-- This fails to get population summary because it includes a rolling population for every row
SELECT SUM(population)
FROM COVIDExploration..CovidDeaths
WHERE continent IS NOT NULL

--This succeeds in gietting population summary because a CTE is created with the correct GROUP BY rows of every valid location, and then a summary is drawn from these population entries
WITH PopSummer (MyLocation, MyContinent, MyPopulation, MyWorldPop)
AS
(
SELECT location, continent, population, FIRST_VALUE(population) OVER(PARTITION BY location ORDER BY location) 'Pop Summary'
FROM COVIDExploration..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent, population
)
SELECT SUM(MyPopulation) as MyWorldPop
FROM PopSummer