select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations
--order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2


-- Суммарно зараженных - Суммарно смертей

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%kaz%'
order by 1,2


-- Доля зараженных к численности начеления

select location, date, total_cases, population, (total_cases/population)*100 as CasesPercentage
from PortfolioProject..CovidDeaths
--where location like '%kaz%'
order by 1,2


--Страны с наибольшей долей зараженных к численности начеления

select location, population, max(total_cases) HighestInfectionCount, max((total_cases/population))*100 PopulationInfectedPercentage
from PortfolioProject..CovidDeaths
--where location like '%kaz%'
group by location, population
order by 4 desc


--Страны с наибольшим количестовм смертей к численности начеления

select location, max(cast (total_deaths as int)) TotalDeathCount
from PortfolioProject..CovidDeaths
--where location like '%kaz%'
where continent is not null
group by location
order by 2 desc


-- По континентам

select continent, max(cast (total_deaths as int)) TotalDeathCount
from PortfolioProject..CovidDeaths
--where location like '%kaz%'
where continent is not null
group by continent
order by 2 desc


--Глобальные цифры

select sum(new_cases) total_cases, sum(cast (new_deaths as int)) total_deaths, sum(cast (new_deaths as int))/sum(new_cases)*100 DeathPercentage
from PortfolioProject..CovidDeaths
--where location like '%kaz%'
where continent is not null
--group by date
order by 1,2



-- Численность - Вакцинированные

select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(int, v.new_vaccinations)) over (partition by d.location order by d.date) PeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location=v.location
	and d.date=v.date
where d.continent is not null
order by 2,3


-- Используем CTE
with popvsvac
as
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(int, v.new_vaccinations)) over (partition by d.location order by d.date) PeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location=v.location
	and d.date=v.date
where d.continent is not null
)
select *, (PeopleVaccinated/population)*100 VaccinatedPercentage
from popvsvac


-- Создание представления

Create view PeopleVaccinatedPercentage
as
with popvsvac
as
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(int, v.new_vaccinations)) over (partition by d.location order by d.date) PeopleVaccinated
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
	on d.location=v.location
	and d.date=v.date
where d.continent is not null
)
select *, (PeopleVaccinated/population)*100 VaccinatedPercentage
from popvsvac