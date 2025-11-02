-- UEFA SQL Project

-- Tables Creation

--1) Goals Table

Create Table Goals(
	GOAL_ID varchar,
	MATCH_ID varchar,
	PID varchar,
	DURATION int,
	ASSIST varchar,
	GOAL_DESC varchar
);

-- 2)Matches Table

Create Table Matches(
	MATCH_ID varchar,
	SEASON varchar,
	DATE varchar,
	HOME_TEAM varchar,
	AWAY_TEAM varchar,
	STADIUM varchar,
	HOME_TEAM_SCORE int,
	AWAY_TEAM_SCORE int,
	PENALTY_SHOOT_OUT int,
	ATTENDANCE int
);


--3) Players Table
Create Table Players(
	PLAYER_ID varchar,
	FIRST_NAME varchar,
	LAST_NAME varchar,
	NATIONALITY varchar,
	DOB date,
	TEAM varchar,
	JERSEY_NUMBER float,
	POSITION varchar,
	HEIGHT float,
	WEIGHT float,
	FOOT varchar
);

-- 4) Teams Table

create Table Teams(
	TEAM_NAME varchar,
	COUNTRY varchar,
	HOME_STADIUM varchar
);

-- 5) Stadium Table

create Table Stadium(
	NAME varchar,
	CITY varchar,
	COUNTRY varchar,
	CAPACITY int
);


-- Importing tables data

copy goals from 'D:\PostgreSQL\Sql\SQL_Project\Data_Files\goals.csv' Delimiter ',' CSV Header;
copy matches from 'D:\PostgreSQL\Sql\SQL_Project\Data_Files\Matches.csv' Delimiter ',' CSV Header;
copy Players from 'D:\PostgreSQL\Sql\SQL_Project\Data_Files\Players.csv' Delimiter ',' CSV Header;
copy Stadium from 'D:\PostgreSQL\Sql\SQL_Project\Data_Files\Stadiums.csv' Delimiter ',' CSV Header;
copy Teams from 'D:\PostgreSQL\Sql\SQL_Project\Data_Files\Teams.csv' Delimiter ',' CSV Header;


-- Data in Tables 

select * from goals;
select * from matches;
select * from players;
select * from teams;
select * from stadium;

-- 1) Count the total number of teams
select count(*) as Total_Teams from teams;

--2)Find the Number of Teams per Country
select count(team_name) as total_number_of_teams from teams;

--3)Calculate the Average Team Name Length
select avg(length(team_name)) as avg_team_name_length from teams;

--4)Calculate the Average Stadium Capacity in Each Country round it off and sort by the total stadiums in the country
select country,Round(avg(capacity)) as avg_capacity,count('Name') as Total_stadiums from stadium group by 
country order by total_stadiums;

--5)Calculate the Total Goals Scored
select count(goal_id) as total_goals from goals;

--6)Find the total teams that have city in their names
select team_name from teams where team_name like '%City%';

--7) Use Text Functions to Concatenate the Team's Name and Country
select Team_name || ',' || country as Team_name_and_Country from teams;

--8) What is the highest attendance recorded in the dataset, and which match (including home and away teams, and date) does it correspond to?
select max(attendance) as Highest_Attendace , Date, Home_Team , Away_Team from 
Matches group by Date, Home_Team, Away_Team order by Highest_Attendace desc limit 1;

--9)What is the lowest attendance recorded in the dataset, and which match (including home and away teams, and date) does it correspond 
-- to set the criteria as greater than 1 as some matches had 0 attendance because of covid.
select max(attendance) as Lowest_Attendance,Date,Home_Team, Away_Team from matches 
group by date,home_team, Away_team Having min(attendance) > 1 order by Lowest_Attendance limit 1;

--10) Identify the match with the highest total score (sum of home and away team scores) 
-- in the dataset. Include the match ID, home and away teams, and the total score.
select match_id,home_team,away_team,home_team_score + away_team_score as Highest_total_score
from matches order by Highest_total_score desc limit 1;

--11)Find the total goals scored by each team, distinguishing between home and away goals. 
--Use a CASE WHEN statement to differentiate home and away goals within the subquery
select 
	teams,
	sum(case when is_goal = 1 then goals else 0 end) as home_goals,
	sum(case when is_goal = 0 then goals else 0 end) as away_goals
from (
	select
		a.home_team as teams,
		count(b.goal_id) as goals,
		1 as is_goal
	from matches as a
	join goals as b
	on a.match_id = b.match_id
	group by a.home_team
	union all 
	select 
		a.away_team as teams,
		count(b.goal_id) as goals,
		0 as is_goal
	from matches as a
	join goals as b
	on a.match_id = b.match_id
	group by a.away_team
)
group by teams;

--12) windows function - Rank teams based on their total scored goals (home and away combined) 
--using a window function.In the stadium Old Trafford.
select  
	team,
	sum(goals) as total_goals,
	dense_rank() over(order by sum(goals) desc) as goal_rank
from (
	select 
		a.home_team as team,
		count(b.goal_id) as goals
	from matches as a
	join goals as b
	on a.match_id=b.match_id
	where a.stadium='Old Trafford'
	group by a.home_team
	union all
	select 
		a.away_team as team,
		count(b.goal_id) as goals
	from matches as a
	join goals as b
	on a.match_id = b.match_id
	where stadium='Old Trafford'
	group by a.away_team
)
group by team
order by goal_rank;

--13) TOP 5 l players who scored the most goals in Old Trafford, ensuring null 
--values are not included in the result (especially pertinent for cases where a player might not have scored any goals).
select 
	a.first_name || ' ' || a.last_name as player_name,
	count(goal_id) as goals_scored
	from players as a
	join goals as b
	on a.player_id = b.pid
group by a.player_id,a.first_name,a.last_name
having a.first_name is not null and a.last_name is not null and count(goal_id) > 0
order by goals_scored desc limit 5;

--14)Write a query to list all players along with the total number of goals they have scored. 
--Order the results by the number of goals scored in descending order to easily identify the top 6 scorers
select 
	a.player_id,
	coalesce (a.first_name,'') || ' ' || a.last_name as player_name,
	count(goal_id) as goals_scored
	from players as a
	join goals as b
	on a.player_id = b.pid
group by a.player_id,a.first_name,a.last_name
order by goals_scored desc;

--15)Identify the Top Scorer for Each Team - Find the player from each team who has scored the most goals in all matches combined. 
--This question requires joining the Players, Goals, and possibly the Matches tables, and then using a subquery to aggregate goals by players and teams.
with team as(
	select 
		m.home_team as team,
		m.match_id,
		p.player_id,
		count(g.goal_id) as total_goals
	from players as p
	join goals as g on p.player_id = g.pid
	join matches as m on g.match_id = m.match_id
	group by m.home_team, p.player_id,m.match_id
	union all
	select
		m.match_id,
		m.away_team as team,
		p.player_id,
	count(g.goal_id) as total_goals
	from players as p
	join goals as g on p.player_id = g.pid
	join matches as m on g.match_id = m.match_id
	group by m.away_team , p.player_id, m.match_id
)
select 
	distinct t.team,
	p.player_id,
	coalesce(p.first_name,'')|| ' ' || p.last_name as player_name,
	count(g.goal_id) as total_goals
from players as p
join goals as g on p.player_id = g.pid
join matches as m on m.match_id = g.match_id
join team as T on m.match_id = t.match_id
group by p.player_id,player_name,m.match_id,t.team
having count(g.goal_id) = (
	select max(total_goals)
	from (
		select m.match_id,p.player_id,count(g.goal_id) as total_goals
		from players as p
		join goals as g on p.player_id = g.pid
		join matches as m on g.match_id = m.match_id
		group by m.match_id , p.player_id
	) as team_goals
	where team_goals.match_id = m.match_id
)
order by total_goals desc;

--16)Find the Total Number of Goals Scored in the Latest Season - Calculate the total number of goals
--scored in the latest season available in the dataset. This question involves using a subquery to first 
--identify the latest season from the Matches table, then summing the goals from the Goals table that 
--occurred in matches from that season.
select 
	count(g.goal_id) as total_goals_scored_2021_2022
from goals as g
where g.match_id in(
		select 
			m.match_id
		from matches as m
		where season = '2021-2022'
);

--17)Find Matches with Above Average Attendance - Retrieve a list of matches that had an attendance
--higher than the average attendance across all matches. This question requires a subquery to 
--calculate the average attendance first, then use it to filter matches
select match_id,home_team ,away_team , attendance
from matches
where attendance > (select avg(attendance) from matches);

--18)Find the Number of Matches Played Each Month - Count how many matches were played in each
--month across all seasons. This question requires extracting the month from the match dates and
--grouping the results by this value. as January Feb march
select 
	to_char(to_date(date,'dd mm yyyy'),'month') as month,
	count(match_id) as total_matches_played
from matches
group by month;