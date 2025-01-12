-- Queries used for Tableau Project
-- Table 1
SELECT SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_Deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathRate
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY SUM(new_cases), SUM(new_deaths);

-- Table 2
SELECT location, SUM(new_deaths) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NULL AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY SUM(new_deaths) DESC;

-- Table 3
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentagePopulationInfected
FROM coviddeaths
GROUP BY location, population
ORDER BY MAX(total_cases/population)*100 DESC;

-- Table 4
SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentagePopulationInfected
FROM coviddeaths
GROUP BY location, population, date
ORDER BY MAX(total_cases/population)*100 DESC;