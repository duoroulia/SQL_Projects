SELECT *
FROM coviddeaths
WHERE continent IS NOT NULL -- 清除了大约6000条数据
ORDER BY location, date;

-- Select data that we're going to use
-- We can see the highest deathrate was 25.94%, in Yemen. Top 10 country with highest death rate is Yemen, Mexico, Ecuador, Sudan, Syria, Egypt, Liberia, Bolivia, Chad, and China
SELECT location, SUM(total_cases) AS TotalCases, SUM(new_cases), SUM(total_deaths) AS TotalDeaths, (SUM(total_deaths)/SUM(total_cases)) AS DeathsRate
-- ??????/??????????这里怎么样把population也加上去
FROM coviddeaths
GROUP BY location
ORDER BY (SUM(total_deaths)/SUM(total_cases)) DESC;

-- Looking at total cases VS total deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathsPercentage
FROM coviddeaths
WHERE location LIKE '%China%'
ORDER BY location, date; -- the latest data showed the likelihood to die was around 4-5 percentage. Still growing

-- Looking at the total cases VS population
-- However, this dataset doesn't include data after 2021. I can't see the whole process of China.
SELECT location, date, total_cases, population, (total_cases/population)*100 AS AffectedPercentage
FROM coviddeaths
WHERE location LIKE '%Kingdom%'
ORDER BY location, date;

-- Looking at Countries with Highest Infection Rate compared to the Population
SELECT location,population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS AffectedPercentage
FROM coviddeaths
GROUP BY location, population -- 注意：写了函数就一定要加groupby
ORDER BY MAX((total_cases/population))*100 DESC;

-- Showing Countries with Highest Death Count per Population
-- SELECT location, population, MAX(total_deaths) AS HighestDeathsCount, MAX((total_deaths/population))*100 AS DeathRatewizPopulation
SELECT location, MAX(total_deaths) AS totaldeathscount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location-- , population -- 注意：写了函数就一定要加groupby
ORDER BY MAX(total_deaths) DESC;
-- cast()的作用：显式转换数据类型

-- Let's breaking things down by continent
-- The number is wrong. We'll change the query
SELECT continent, MAX(total_deaths) AS totaldeathscount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent-- , population -- 注意：写了函数就一定要加groupby
ORDER BY MAX(total_deaths) DESC;

SELECT location, MAX(total_deaths) AS totaldeathscount
FROM coviddeaths
WHERE continent IS NULL
GROUP BY location-- , population -- 注意：写了函数就一定要加groupby
ORDER BY MAX(total_deaths) DESC;

-- Showing continents with the highest death count per population
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_Deaths, SUM(new_deaths)/SUM(new_cases) AS deathPercentage -- 因为原表totalcases是每日总计，所以无法sum，就无法groupby
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Connect the 2 tables, looking at the total population VS vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(vac.new_vaccinations) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) AS vaccinationRollingCount
        -- 作用：按地区和时间累积newvaccination的人数
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- We want to see the vaccinationRollingCount VS population, but we can't use this new column name right now. There are 2 ways.
-- 1.USE cte
WITH PopulationVSVac (continent, location, date, population, new_vaccinations, vaccinationRollingCount) -- CTE中的列必须和引用中的列一致
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(vac.new_vaccinations) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) AS vaccinationRollingCount
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY dea.location, dea.date; 不能有排序语句
)
SELECT *, (vaccinationRollingCount/population) *100 AS vaccinationRate
FROM PopulationVSVac;

-- 2.USE TEMP TABLE
DROP TABLE IF EXISTS PopulationVSVac;
CREATE TEMPORARY TABLE PopulationVSVac AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(vac.new_vaccinations) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) AS vaccinationRollingCount
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Creating views to store data for later visualization
CREATE VIEW PopulationVSVac AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(vac.new_vaccinations) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) AS vaccinationRollingCount
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;
