--Creating Table athelete_events:
/*  Point to be noted here:
                  In athelete_events dataset, columns:age,height,weight along with numeric values also have 'NA' values.
				  Therefore instead of (integer) I assign (varchar) constraint to following columns.Whenever, necessary I 
				  change it to (integer) */
				  
              
create table athelete_events(id int,name varchar,sex char(1),age varchar,height varchar,weight varchar
							,team varchar,noc char(3),games varchar,year int,season varchar,city varchar
							,sport varchar,event varchar,medal varchar)

copy athelete_events from 'D:\DATA SCIENCE\PostgreSql\Olympic games\athlete_events.csv'	with csv header		
select * from athelete_events

--Creating Table noc_region:

create table noc_region(noc char(3),region varchar)
copy noc_region from 'D:\DATA SCIENCE\PostgreSql\Olympic games\noc_regions.csv' with csv header
select * from noc_region	

/*Q1. How many olympics games have been held? */
select count(distinct games)as total_olympic_games from athelete_events

/*Q2. List down all Olympics games held so far.*/
select distinct games from athelete_events order by games

/*Q3. Mention the total no of nations who participated in each olympics game?*/
select games,count(distinct noc)as countries from athelete_events group by games 

/*Q4. Which year saw the highest and lowest no of countries participating in olympics?*/
                                               
with t as (select games,count(distinct noc)as countries from athelete_events group by games)
select * from t where countries=(select min(countries) from t) or countries=(select max(countries) from t)

/*Q5. Which nation has participated in all of the olympic games?*/

select region,total_participated_games from (select a.noc country,count(a.noc) total_participated_games 
from(select distinct noc,games from athelete_events order by noc)
as a group by country)as t inner join noc_region as u
on t.country=u.noc where total_participated_games=51 order by total_participated_games desc,region 

/*Q6. Identify the sport which was played in all summer olympics.*/

with t as (select sport,count(sport) as  no_of_games from (select distinct sport,games from athelete_events where season='Summer') as a 
group by sport
order by no_of_games desc)
select * from t where no_of_games=(select count(distinct games) as total_games from athelete_events where season='Summer')

/*Q7. Which Sports were just played only once in the olympics?*/
with t1 as(select sport,count(sport) as  no_of_games from (select distinct sport,games from athelete_events where season='Summer') as a 
group by sport
order by no_of_games )
select distinct t1.sport ,no_of_games,games from t1 inner join athelete_events using(sport) where no_of_games=1 order by sport

/*Q8. Fetch the total no of sports played in each olympic games.*/

select count(distinct sport) as num_of_sports_played ,games 
from athelete_events group by games order by num_of_sports_played  desc

/*Q9. Fetch details of the oldest athletes to win a gold medal.*/

select * from athelete_events where age!='NA' and medal='Gold' order by age desc limit 2

/*Q10.Find the Ratio of male and female athletes participated in all olympic games.*/ 

--Overall ratio:
with t as (select games,
sum(case when sex='M' then 1 else 0 end) as male,
sum(case when sex='F'then 1 else 0 end)as female
from athelete_events
group by games)

select concat('1:', round(sum(male)/sum(female),2))as ratio from t

--Ratio of female to male in each olympic games:

/*NOTE:we have to cast the ratio to numeric(or float) because default value is integer therefore for 
        values like 0.33,0.43,0.12,0.92 it reduces to zero */
with t as (select games,
sum(case when sex='M' then 1 else 0 end) as male,
sum(case when sex='F'then 1 else 0 end)as female
from athelete_events
group by games)
select *,concat('1:',round((male/nullif(female,0)::numeric),2)) as ratio_f_m from t


/*Q11.Fetch the top 5 athletes who have won the most gold medals.*/

select distinct name,team,medal,count(medal) over(partition by name) 
from athelete_events where medal='Gold' order by count desc limit 5

/*Q12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).*/

select distinct name,count(medal) over(partition by name) as total_medals,team
from athelete_events where medal!='NA' order by total_medals desc

/*Q13.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.*/
select distinct region,count(medal) over(partition by region) as total_medals from athelete_events 
inner join noc_region using(noc) where medal != 'NA' 
order by total_medals desc

/*Q14.List down total gold, silver and broze medals won by each country.*/
select region,
sum(case when medal='Gold' then 1 else 0 end) as Gold,
sum(case when medal='Silver' then 1 else 0 end) as Silver,
sum(case when medal='Bronze' then 1 else 0 end) as Bronze
from athelete_events inner join  noc_region using(noc)
group by region order by Gold desc,Silver desc,Bronze desc

/*Q15.List down total gold, silver and broze medals won by each country corresponding to each olympic games.*/
select region,games,
sum(case when medal='Gold' then 1 else 0 end) as Gold,
sum(case when medal='Silver' then 1 else 0 end) as Silver,
sum(case when medal='Bronze' then 1 else 0 end) as Bronze
from athelete_events inner join  noc_region using(noc)
group by region,games order by games,region

/*Q16.Identify which country won the most gold, most silver and most bronze medals in each olympic games.*/
with t as (select region,games,
sum(case when medal='Gold' then 1 else 0 end) as Gold,
sum(case when medal='Silver' then 1 else 0 end) as Silver,
sum(case when medal='Bronze' then 1 else 0 end) as Bronze
from athelete_events inner join  noc_region using(noc)
group by region,games order by games,region)
 ,t1 as (select region,games,Gold,dense_rank() over(partition by games order by Gold desc)as rnk from t)
 ,t2 as (select region,games,Silver,dense_rank() over(partition by games order by Silver desc)as rnk from t)
 ,t3 as (select region,games,Bronze,dense_rank() over(partition by games order by Bronze desc)as rnk from t)
,t4 as (select games,concat(region,'-',Gold) as max_gold from t1 where rnk=1)
,t5 as (select games,concat(region,'-',Silver)as max_silver from t2 where rnk=1)
,t6 as (select games,concat(region,'-',Bronze) as max_bronze from t3 where rnk=1)
,t7 as (select games,max_gold,max_silver from t4 inner join t5 using(games))
select  t7.games ,max_gold,max_silver,max_bronze from t6 inner join t7 using(games)
/*Q17.Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.*/
with t as (select region,games,
sum(case when medal='Gold' then 1 else 0 end) as Gold,
sum(case when medal='Silver' then 1 else 0 end) as Silver,
sum(case when medal='Bronze' then 1 else 0 end) as Bronze
from athelete_events inner join  noc_region using(noc)
group by region,games order by games,region)
 ,t1 as (select region,games,Gold,dense_rank() over(partition by games order by Gold desc)as rnk from t)
 ,t2 as (select region,games,Silver,dense_rank() over(partition by games order by Silver desc)as rnk from t)
 ,t3 as (select region,games,Bronze,dense_rank() over(partition by games order by Bronze desc)as rnk from t)
,t4 as (select games,concat(region,'-',Gold) as max_gold from t1 where rnk=1)
,t5 as (select games,concat(region,'-',Silver)as max_silver from t2 where rnk=1)
,t6 as (select games,concat(region,'-',Bronze) as max_bronze from t3 where rnk=1)
,t7 as (select games,max_gold,max_silver from t4 inner join t5 using(games))
, t8 as (select games,count(medal)over(partition by games,region) as total_medal
,region from athelete_events inner join noc_region using(noc) where medal != 'NA')
,t9 as (select * from (select distinct *,dense_rank() over(partition by games order by total_medal desc) as rnk from t8 order by games,rnk)as a
where a.rnk=1)
,t10 as (select games,concat(region,'-',total_medal) as G_T_medal from t9)
select z.*,G_T_medal from (select  t7.games ,max_gold,max_silver,max_bronze from t6 inner join t7 using(games))as z inner join t10
using(games)

/*Q18.Which countries have never won gold medal but have won silver/bronze medals?*/

with s as (select medal,region from athelete_events inner join noc_region using(noc) where  medal != 'NA' order by region)
select s1.* from (select region,
sum(case when medal ='Gold' then 1 else 0 end)as gold,
sum(case when medal ='Silver' then 1 else 0 end)as silver,
sum(case when medal ='Bronze' then 1 else 0 end)as bronze
from s group by region order by gold,bronze,silver ) s1 where gold =0

/*Q19.In which Sport/event, India has won highest medals.*/
with i as (select sport, region,medal from athelete_events inner join noc_region using(noc) where medal !='NA')
select i1.* from (select sport ,count(medal) as total_medal,region from i  group by sport,region) i1 where region='India'
order by total_medal desc limit 1

/*Q20.Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.*/

with h as (select games,sport,region,medal from athelete_events inner join noc_region using(noc)
where medal!='NA' and sport= 'Hockey' and region ='India')
select distinct *,count(medal) over(partition by games) from h order by count desc


