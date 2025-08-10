drop database if exists airpurifier;
create database airpurifier;
use airpurifier;

drop table if exists aqi;
create table aqi(
  date text	
, state	text
, area text
, number_of_monitoring_stations int
, prominent_pollutants text
, aqi_value int
, air_quality_status text
, unit text
);

SET GLOBAL LOCAL_INFILE = ON;

LOAD DATA LOCAL INFILE 'D:/CN/Hackathons/Code Basics/aqi.csv' INTO TABLE aqi
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

select count(*) from aqi; # 235785 rows
select * from aqi;
-- -----------------------------------------

drop table if exists idsp;
create table idsp(
  year int
, week int
, outbreak_starting_date text
, reporting_date text
, state	text
, district text
, disease_or_illness text
, status text
, cases int
, deaths int
, unit text
);

SET GLOBAL LOCAL_INFILE = ON;

LOAD DATA LOCAL INFILE 'D:/CN/Hackathons/Code Basics/idsp.csv' INTO TABLE idsp
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

select count(*) from idsp; # 6474 rows
select * from idsp;
-- ---------------------------------------

drop table if exists vahan;
create table vahan(
  year int
, month text
, state text
, rto text
, vehicle_class text
, fuel text
, value int
, unit text
);

LOAD DATA LOCAL INFILE 'D:/CN/Hackathons/Code Basics/vahan.csv' INTO TABLE vahan
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

select count(*) from vahan; # 64841 rows
select * from vahan;
-- -----------------------------


