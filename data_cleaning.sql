USE airpurifier;

desc aqi;
select date from aqi;

update aqi
set date = str_to_date(date, '%d-%m-%Y');

alter table aqi
modify date date;

select * from aqi;
-- ------------------------

desc idsp;
select reporting_date from idsp where reporting_date = '';

update idsp
set reporting_date = str_to_date(reporting_date, '%d-%m-%Y')
where reporting_date IS NOT NULL AND reporting_date != '';

update idsp
set reporting_date = NULL
where reporting_date = '';
  
update idsp
set outbreak_starting_date = str_to_date(outbreak_starting_date, '%d-%m-%Y');

update idsp
set disease_or_illness = TRIM(disease_or_illness);

alter table idsp
modify outbreak_starting_date date,
modify reporting_date date;

with cte as(
	select state, district, count(*) from idsp 
	where district like "%,%"
	group by 1,2
	order by 1,2 	# 1+1+2+1 = 5 values
)
update idsp
set district = substring_index(district,",",1)
where district in (select district from cte);
-- -------------------------------------------------

-- From Area-wise Population table
SHOW COLUMNS FROM area_latest_population_2024;
SELECT 
	`2024 Population Estimate`,
    `source(s)`,
    `Area Type`
FROM area_latest_population_2024;

-- Modify Column Names by removing space and special characters
ALTER TABLE area_latest_population_2024
CHANGE COLUMN `2024 Population Estimate` 2024_Population_Estimate TEXT,
CHANGE COLUMN `Area Type` Area_Type TEXT,
CHANGE COLUMN `source(s)` Source TEXT;

-- Remove comma from integer values AND change DATATYPE from text to int
UPDATE area_latest_population_2024
SET 2024_Population_Estimate = REPLACE(2024_Population_Estimate, ',', ''),
State = TRIM(State), City = TRIM(City), Area_Type = TRIM(Area_Type);

ALTER TABLE area_latest_population_2024
MODIFY 2024_Population_Estimate INT;

SELECT * FROM area_latest_population_2024;
-- ------------------------------------------------------

-- delete the empty 'note' column from the population_projection table
ALTER TABLE population_projection
DROP COLUMN note ;
-- -------------------------------------------------------

-- Clean column names of citywise_percapita_income_2024_25 table
ALTER TABLE citywise_percapita_income_2024_25
RENAME COLUMN `City/District` TO City_Or_District,
RENAME COLUMN `Per Capita Income (?, 2024–25) per Annum` TO PerCapitaIncome_INR_2024_25_per_Annum;