/*

Taking a summary of the F1 2021 Season

*/

-- Locations and Dates of Grand Prix

select r.raceId, c.lat, c.lng, convert(date, r.date) as date, r.name as GrandPrix
from races as r
join circuits as c
on r.circuitId = c.circuitId
where r.year = 2021
order by r.date

-- 2021 Constructors Points Recap

select *
from 
(select distinct(c.name) as Constructor, concat(races.year, ' ', races.name) as Race,
sum(r.points) over(partition by c.name order by races.date) as RunningTotal
from Results as r
join constructors as c
on r.constructorId = c.constructorId
join races 
on r.raceId = races.raceId
where races.year = 2021) as t
PIVOT
(
SUM(RunningTotal)
for Race in ([2021 Bahrain Grand Prix],	[2021 Emilia Romagna Grand Prix],	[2021 Portuguese Grand Prix],	
			 [2021 Spanish Grand Prix],	[2021 Monaco Grand Prix],	[2021 Azerbaijan Grand Prix],	
			 [2021 French Grand Prix],	[2021 Styrian Grand Prix],	[2021 Austrian Grand Prix],	
			 [2021 British Grand Prix],	[2021 Hungarian Grand Prix],	[2021 Belgian Grand Prix],	
			 [2021 Dutch Grand Prix],	[2021 Italian Grand Prix],	[2021 Russian Grand Prix],	
			 [2021 Turkish Grand Prix],	[2021 United States Grand Prix],	[2021 Mexico City Grand Prix],	
			 [2021 SÃ£o Paulo Grand Prix],	[2021 Qatar Grand Prix],	[2021 Saudi Arabian Grand Prix],	
			 [2021 Abu Dhabi Grand Prix])
) as Pt

-- 2021 Driver Points Recap

select *
from 
(select d.surname as Driver, concat(races.year, ' ', races.name) as Race,
sum(r.points) over(partition by d.surname order by races.date) as RunningTotal
from Results as r
join drivers as d
on r.driverId = d.driverId
join races 
on r.raceId = races.raceId
where races.year = 2021) as t
PIVOT
(
SUM(RunningTotal)
for Race in ([2021 Bahrain Grand Prix],	[2021 Emilia Romagna Grand Prix],	[2021 Portuguese Grand Prix],	
			 [2021 Spanish Grand Prix],	[2021 Monaco Grand Prix],	[2021 Azerbaijan Grand Prix],	
			 [2021 French Grand Prix],	[2021 Styrian Grand Prix],	[2021 Austrian Grand Prix],	
			 [2021 British Grand Prix],	[2021 Hungarian Grand Prix],	[2021 Belgian Grand Prix],	
			 [2021 Dutch Grand Prix],	[2021 Italian Grand Prix],	[2021 Russian Grand Prix],	
			 [2021 Turkish Grand Prix],	[2021 United States Grand Prix],	[2021 Mexico City Grand Prix],	
			 [2021 São Paulo Grand Prix],	[2021 Qatar Grand Prix],	[2021 Saudi Arabian Grand Prix],	
			 [2021 Abu Dhabi Grand Prix])
) as Pt

-- Queries for Race Summaries

-- 2021 Qualifying Times

select r.raceId, convert(date, r.date) as date, r.name as Race, d.surname as Driver, c.name, q.position
, convert(varchar,dateadd(ms,q.q1,0),114) as Q1
, convert(varchar,dateadd(ms,q.q2,0),114) as Q2
, convert(varchar,dateadd(ms,q.q3,0),114) as Q3
from qualifying2 as q
	join drivers as d
	on q.driverId = d.driverId
	join races as r
	on q.raceId = r.raceId
	join constructors as c
	on q.constructorId = c.constructorId
where r.raceID between 1051 and 1073
order by raceId, position


--Lap Times for 2021 Season
select Raceid, Date, Race, Driver, Lap, Position, convert(varchar,dateadd(ms,Laptime,0),114) as LapTime, 
convert(varchar,dateadd(ms,racetime,0),114) as RaceTime, (RaceTime-FastLap)/1000 as Delta
from(
	select *,
	min(RaceTime) over(Partition by Race, lap order by lap, position) as FastLap
	from(
		select *,
		sum(laptime) over(partition by Race, Driver order by lap) as RaceTime	
		from(
			select r.raceId, convert(date, r.date) as date, r.name as Race, d.surname as Driver, l.lap, l.position, l.milliseconds as Laptime
			from lap_times as l
			join drivers as d
			on l.driverId = d.driverId
			join races as r
			on l.raceId = r.raceId
			where r.year = '2021') x
			) t
	)s
order by Date, lap, position


--Full Race Summary 
select r.raceId, convert(date, races.date) as date, races.name, d.surname, c.name, r.positionOrder, r.points, 
sum(points) over(partition by d.surname order by races.date) as RunningPoints,
r.laps, s.status, convert(varchar,dateadd(ms,r.milliseconds,0),114) as TotalRaceTime
from results as r
	join status as s
	on r.statusId = s.statusId
	join drivers as d
	on r.driverId = d.driverId
	join constructors as c
	on r.constructorId = c.constructorId
	join races 
	on r.raceId = races.raceId
where r.raceId between 1051 and 1073
order by races.date, r.positionOrder

/*

Taking a look into the alltime data

*/

-- How many races have there been in each season of F1?

select year, count(distinct name) as GrandPrix
from races	
group by year

-- Who are the top 10 most experienced drivers (driven the most Grand Prix)?

select forename, surname, RacesEntered
from (
	select *, 
		rank() over(order by RacesEntered desc) as rnk
		from(
			select count(r.raceId) as RacesEntered, d.driverId, d.forename, d.surname
			from results as r
			join drivers as d
			on r.driverId = d.driverId
			group by d.driverId, d.forename, d.surname
			) as x
		) as Races
where Races.rnk < 11

-- What Countries have hosted a race and how many?

select  c.country, count(r.name) as GrandPrix
from races as r
join circuits as c
on r.circuitId = c.circuitId
group by c.country
order by GrandPrix desc	

-- Countries and their Teams/ Drivers/ Wins

with teams as(
	select Nationality, count(nationality) as Teams
	from constructors
	group by nationality),

Drive as(
	select nationality, count(nationality) as Drivers	
	from drivers
	group by nationality)

Select Drive.nationality as Country, Drive.Drivers, Teams.Teams
from Drive
left join Teams
on drive.nationality = teams.nationality
order by Teams desc	

-- How many times has each Grand Prix been run?

select name, count(circuitid) as RaceCount
from races
group by name
order by RaceCount desc	

-- What is the Fastest Lap Time for each Grand Prix and what Year (data only from 1996 to 2021)?

with t1 as (
select r.year, r.name, r.round, d.surname, laps.lap, laps.laptime,
	   rank () over(partition by r.raceid order by laptime) as rnk
from drivers as d
join (
	select *, convert(varchar,dateadd(ms,milliseconds,0),114) as laptime
	from lap_times) as laps
on laps.driverId =d.driverId
join races as r
on laps.raceId = r.raceId),

t2 as (
select * from t1
where rnk = 1),

t3 as (
select *,
rank() over(partition by name order by laptime) as fast
from t2)

select year, name, surname, lap, laptime 
from t3
where fast = 1

-- What Season has the most Grand Prix Winners?


-- creating a view selecting only winning drivers and their races
go
Create View WinningDrivers as
	(select r.year, re.raceid, r.name, re.driverid, re.position
	from results as re
	join races as r
	on re.raceId = r.raceId
	where position = 1)
go

select * 
from(
	select *, 
		rank() over(order by DistinctWinners desc) as rnk
	from(
		select year, count(distinct driverId) as DistinctWinners
		from WinningDrivers
		group by year) as Winners	
	) as Win
where rnk = 1

--All time Constructor Points and wins

with Points as (
	select *,
		   rank() over(order by allTimePoints desc) as PointsRank
	from(
		select c.name as Constructor, sum(r.points) as allTimePoints
		from results as r
		join constructors as c
		on r.constructorId = c.constructorId
		group by c.name) as x),

Wins as(
	select c.name as Constructor, count(c.name) as allTimeWins
	from results as r
	join constructors as c
	on r.constructorId = c.constructorId
	where r.position = 1
	group by c.name)

select points.Constructor, allTimePoints, allTimeWins
from points
left join wins 
on points.Constructor = wins.Constructor
where PointsRank <= 25
order by allTimePoints desc


-- Driver Alltime Stats
-- Finding Pole Positions
with Poles as (
select driverId, count(grid) as Poles
from results
where grid = 1
group by driverId),

--Finding Wins
Wins as (
select driverId, count(position) as Wins
from results
where position = 1
group by driverId),

--Finding Podiums
Podiums as (
select driverId, count(position) as Podiums
from results
where position <= 3
group by driverId),

--Joining stats
DriverStats as(
select Podiums.driverId, Wins.Wins, Podiums.Podiums, Poles.Poles 
from Podiums 
left join Poles on Podiums.driverId = poles.driverId
left join Wins on Podiums.driverId = Wins.driverId)

--Adding Names
Select Drivers.forename as firstName, Drivers.surname as lastName, ds.Wins, ds.Podiums, ds.Poles
from DriverStats as ds
join drivers
on ds.driverId = drivers.driverId
order by ds.Wins desc


-- Looking into Qualifying to Finish Position
select r.raceId, convert(date, races.date) as date, races.name, d.surname, c.name, r.grid, r.positionOrder, r.points
from results as r
join drivers as d
on r.driverId = d.driverId
join constructors as c
on r.constructorId = c.constructorId
join races 
on r.raceId = races.raceId

