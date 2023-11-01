--create table where we will insert merged data

CREATE TABLE cyclisticData(
	ride_id nvarchar(MAX),
	rideable_type nvarchar(MAX),
	started_at datetime,
	ended_at datetime,
	start_station_name nvarchar(MAX),
	start_station_id nvarchar(MAX),
	end_station_name nvarchar(MAX),
	end_station_id nvarchar(MAX),
	start_lat float,
	start_lng float,
	end_lat float,
	end_lng float,
	member_casual nvarchar(MAX)

);


--insert merged data into new table; cyclistic data using unions


INSERT INTO cyclisticData
SELECT *
FROM [dbo].[202201-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202202-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202203-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202204-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202205-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202206-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202207-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202208-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202209-divvy-publictripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202210-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202211-divvy-tripdata]
UNION ALL 
SELECT * 
FROM [dbo].[202212-divvy-tripdata]


--check for null values 
select * from cyclisticData
where member_casual IS NULL 

--check for station null values
SELECT start_lat,start_lng, end_lat, end_lng, end_station_name, start_station_name, start_station_id, end_station_id
FROM cyclisticData
WHERE end_lat IS NULL OR end_lng IS NULL OR start_lat IS NULL OR start_lng IS NULL --nulls present , but have coresspondong lat and long columns so won't delete

--check for duplicate entries

SELECT ride_id, member_casual, start_station_name, end_station_name, COUNT(*) as duplicate_count
FROM cyclisticData
GROUP  BY ride_id, member_casual, start_station_name, end_station_name
HAVING COUNT(*) > 1 --no duplicate entries


--change data types

ALTER TABLE cyclisticData
ALTER COLUMN started_at DATETIME

ALTER TABLE cyclisticData
ALTER COLUMN ended_at DATETIME

--create duration columns 

ALTER TABLE cyclisticData
ADD hours_duration int,
 days_duration int,
 minutes_duration int;


--populate just created columns; hour_duration, days_duration

UPDATE cyclisticData
SET hours_duration = ABS(DATEDIFF(HH, started_at,ended_at)),
days_duration =  ABS(DATEDIFF(WEEKDAY, started_at,ended_at)),
minutes_duration = ABS(DATEDIFF(MINUTE, started_at, ended_at));

--adding month and weekday to data
ALTER TABLE cyclisticData
ADD month nvarchar(20),
weekday nvarchar(20)

--populating data into created columns

UPDATE cyclisticData
SET month = DATENAME(MONTH, started_at),
weekday = DATENAME(WEEKDAY, started_at)


--most popular bike type(casual)
SELECT rideable_type, count(ride_id) number_of_users
FROM cyclisticData
WHERE member_casual = 'casual'
GROUP BY rideable_type
ORDER BY 2 desc -- electric bike more popular

--most popular bike type(member)

SELECT rideable_type, count(ride_id) number_of_users
FROM cyclisticData
WHERE member_casual = 'member'
GROUP BY rideable_type
ORDER BY 2 desc -- more members use the classic bike compared compared to the electric bike and none of the members use docked bike

--member(subscription) vs casual member; more suscription members that casual members
SELECT member_casual, count(ride_id)
FROM cyclisticData
GROUP BY member_casual
ORDER BY 2 desc


--most popular month (members)
SELECT count(ride_id), month
FROM cyclisticData
WHERE member_casual = 'member'
GROUP BY month
ORDER BY 1 desc

-- most popular month is july

SELECT count(ride_id), month
FROM cyclisticData
WHERE member_casual = 'casual'
GROUP BY month
ORDER BY 1 desc -- most popular month is July

--popular weekday(members)

SELECT count(ride_id), weekday
FROM cyclisticData
WHERE member_casual = 'member'
GROUP BY weekday
ORDER BY 1 desc -- most popular day is Saturday

--popular day (casual)
SELECT count(ride_id), weekday
FROM cyclisticData
WHERE member_casual = 'casual'
GROUP BY weekday
ORDER BY 1 desc

-- count by station

SELECT count(ride_id), start_station_name, member_casual, start_lat,start_lng,end_lat,end_lng
FROM cyclisticData
GROUP BY start_station_name, member_casual, start_lat,start_lng,end_lat,end_lng
ORDER BY 1 desc, 3

--average ride duration casual members

SELECT weekday, AVG(minutes_duration) 
FROM cyclisticData
WHERE member_casual = 'casual'
GROUP BY weekday
ORDER BY 2 desc -- longest ride day is sundays

--average ride duration for members

SELECT weekday, AVG(minutes_duration) 
FROM cyclisticData
WHERE member_casual = 'member'
GROUP BY weekday
ORDER BY 2 desc 

--peak ride time(members)
SELECT DATEPART(HH, started_at), COUNT(ride_id)
FROM cyclisticData
WHERE member_casual = 'member'
GROUP BY DATEPART(HH, started_at)
ORDER BY 2 desc

--peak ride time (casual)
SELECT DATEPART(HH, started_at), COUNT(ride_id)
FROM cyclisticData
WHERE member_casual = 'casual'
GROUP BY DATEPART(HH, started_at)
ORDER BY 2 desc

--It seems Casual members ride bikes for longer in general compared to subscription members, paying monthly subscriptions would actually prove to be cheaper 
--Bike usage peaks in between June and September for both casual riders and members
-- Casual riders tend to ride bikes more during the weekend with the peak day being Saturday while members ride  more during the week (most likely for work commutes) with peak day being Thursday
-- ride time peaks for both casual riders and members at 17hrs