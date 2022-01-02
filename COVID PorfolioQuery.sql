select * from CovidDeaths
order by 3,4
select * from CovidVaccinations
order by 3,4


--Selecting Data we are using

Select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1,2


-- Looking at total cases vs total deaths

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathPercentage
from CovidDeaths
Where location like '%States%'
order by 1,2

--Looking at Countries with Highest Infection Rates compared to Population

Select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population)*100) as CasesPercentage
from CovidDeaths
--Where location like '%States%'
Group By location, population 
order by CasesPercentage desc

--showing countries with the highest death count

Select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is null 
Group By location
order by TotalDeathCount desc	


--showing the continents with the highest death count per population

Select location, max(cast(total_deaths as int)) as TotalDeathCount, max((total_deaths/population)*100) as DeathPercentage
from CovidDeaths
where continent is not null 
Group By location
order by DeathPercentage desc	

-- Global Numbers	

select  sum(new_cases) as totalCases, sum(cast(new_deaths as int)) as totalDeaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from CovidDeaths
where continent is not null
--Group by date
order by 1,2


--looking at total Population v Vaccinations


select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, sum(convert(bigint,CV.new_vaccinations )) over (partition by CD.location order by cd.location, cd.date) as RollingVaccinationCount
from CovidDeaths as CD
join CovidVaccinations as CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null
order by 2,3

--Creating a CTE

with PopvVax (Continent, Location, Date, Population, new_vaccinations, RollingVaccinationCount)
as 
(
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, sum(convert(bigint,CV.new_vaccinations )) over (partition by CD.location order by cd.location, cd.date) as RollingVaccinationCount
from CovidDeaths as CD
join CovidVaccinations as CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null
)


select *, (RollingVaccinationCount/Population)*100 as RollingVaxPercentage
from PopvVax
order by 2,3

--Temp Table

drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population bigint,
New_vaccinations numeric,
RollingVaccinationCount numeric
)

Insert into #PercentPopulationVaccinated
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, sum(convert(bigint,CV.new_vaccinations )) over (partition by CD.location order by cd.location, cd.date) as RollingVaccinationCount
from CovidDeaths as CD
join CovidVaccinations as CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null

select *, (RollingVaccinationCount/Population)*100 as RollingVaxPercentage
from #PercentPopulationVaccinated
order by 2,3

go
--Creating View

Create View PercentPopulationVaccinated as
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, sum(convert(bigint,CV.new_vaccinations )) over (partition by CD.location order by cd.location, cd.date) as RollingVaccinationCount
from CovidDeaths as CD
join CovidVaccinations as CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null

select *
from PercentPopulationVaccinated