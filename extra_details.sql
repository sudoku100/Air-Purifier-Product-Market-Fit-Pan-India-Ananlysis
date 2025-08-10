/* 	Answer Critical Questions: */
-- 1.	Priority Cities: Which Tier 1/2 cities show irreversible AQI degradation? */
SELECT 
	CONCAT(YEAR(date), ' - ', LPAD(MONTH(date), 2, '0')) AS YearMonth, 
    DATE_FORMAT(date, '%M') AS Month, 
    area, 
    AVG(aqi_value) AS avg_aqi_value,
    ROW_NUMBER() OVER(PARTITION BY area ORDER BY CONCAT(YEAR(date), ' - ', LPAD(MONTH(date), 2, '0'))) AS Rnk,
    ROW_NUMBER() OVER(PARTITION BY area ORDER BY AVG(aqi_value) DESC) AS aqi_Rnk
FROM aqi
GROUP BY YearMonth, Month, area
ORDER BY area, YearMonth, Rnk;

-- Calculating standard deviation in aqi per area
WITH tble AS (
	  SELECT 
		YEAR(date) AS Year, 
		LPAD(MONTH(date), 2, '0') AS Month,
		state,
		area, 
		AVG(aqi_value) AS aqi_value
	  FROM aqi
	  WHERE aqi_value IS NOT NULL
	  GROUP BY Year, Month, state, area
	  ORDER BY state, Year, Month
),
mean_tble AS (
	  SELECT 
		state,
		area, 
		AVG(aqi_value) AS avg_aqi_value
	  FROM tble
	  GROUP BY state, area
),
stdv_tble AS (
	  SELECT 
		m.state,
		m.area,
		m.avg_aqi_value,
		COUNT(*) AS cnt_datapoint,
		ROUND
		(
			SQRT(SUM(POW(t.aqi_value - m.avg_aqi_value, 2)) / (COUNT(*))), 2
		) AS stdv
	  FROM tble t
	  JOIN mean_tble m ON m.area = t.area
	  GROUP BY m.state, m.area, m.avg_aqi_value
)
SELECT * FROM stdv_tble
ORDER BY state, area;

-- 2. Which are the top 5 pollutants from the aqi table?		

WITH RECURSIVE split_cte AS (
	  SELECT
		ROW_NUMBER() over() AS id,
		TRIM(SUBSTRING_INDEX(prominent_pollutants, ',', 1)) AS pollutant,
		SUBSTRING(prominent_pollutants, 
		LENGTH(SUBSTRING_INDEX(prominent_pollutants, ',', 1)) + 2) AS rest,
		1 AS part
	  FROM aqi

	  UNION ALL

	  SELECT
		id,
		TRIM(SUBSTRING_INDEX(rest, ',', 1)),
		SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2),
		part + 1
	  FROM split_cte
	  WHERE rest != ''
),
count_pollutants AS(
	SELECT id, pollutant
	FROM split_cte
),
ranking AS(
	SELECT 
		DISTINCT pollutant, 
		COUNT(*) AS pollutant_count, 
		ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS pollutant_rank
	FROM count_pollutants
	GROUP BY pollutant
)
SELECT * FROM ranking
WHERE pollutant_rank < 6;

-- 3. Health Burden: How do AQI spikes correlate with paediatric asthma admissions?

SELECT DISTINCT disease_or_illness FROM idsp			# 118 unique diseases
ORDER BY disease_or_illness; 			

# Which of the 118 diseases are respiratory diseases?
SELECT disease_or_illness AS respiratoy_disease, COUNT(*) AS count_resp_dis
FROM idsp
WHERE disease_or_illness IN (
	'Acute Respiratory Illness',
	'Adenovirus',
	'ARI (Acute Respiratory Infection) / Influenza-like Illness (ILI)',
	'Chickenpox',
	'Chickenpox and Measles',
	'Diphtheria',
	'Fever and Upper Respiratory Tract Infection (URTI)',
	'H3N2',
	'HMPV (Human Metapneumovirus)',
	'Influenza',
	'Influenza A',
	'Measles',
	'Measles and Rubella',
	'Monkeypox (Mpox)',
	'Mumps',
	'Pertussis (Whooping Cough)',
	'Rubella',
	'Seasonal Influenza',
	'Swine Flu (H1N1)'
)
GROUP BY disease_or_illness
ORDER BY count_resp_dis DESC;

•	Behaviour Shifts: Do pollution emergencies increase purifier searches/purchases? 

•	Feature Gap: What do existing products lack (e.g., smart AQI syncing, compact designs)?

2.	Deliverables: 
Market Prioritization Dashboard with:
•	City risk scores (AQI severity × population density × income)
 
-- Step 1: Pre-aggregate city counts
WITH CityCounts AS (
    SELECT city, COUNT(*) AS city_count
    FROM area_latest_population_2024
    GROUP BY city
),

-- Step 2: Apply logic to include either unique cities or multiple cities where Area_type = 'City'
FilteredCities AS (
    SELECT a.*
    FROM area_latest_population_2024 a
    JOIN CityCounts c ON a.city = c.city
    WHERE 
        (c.city_count = 1)
        OR (c.city_count > 1 AND a.area_type = 'City')
)

-- Step 3: Join with other tables and calculate risk score
SELECT 
    a.State,
    City_Or_District,
    2024_Population_Estimate,
    PerCapitaIncome_INR_2024_25_per_Annum,
    AVG(aqi_value) AS avg_aqi,
    DENSE_RANK() OVER (
        ORDER BY
            ROUND(
                log(2024_Population_Estimate) * 				# Normalizing Population
                log(PerCapitaIncome_INR_2024_25_per_Annum) *    # Normalizing Income
                AVG(aqi_value), 2							
            ) DESC
    ) AS City_Risk_Score,
    'ROUND(log(2024_Population_Estimate) * log(PerCapitaIncome_INR_2024_25_per_Annum) * AVG(aqi_value), 2)' AS CRS_Calculation
FROM citywise_percapita_income_2024_25 cpi
JOIN aqi a ON a.area = cpi.City_Or_District
JOIN FilteredCities f ON f.city = cpi.City_Or_District
GROUP BY 
    a.State,
    City_Or_District,
    2024_Population_Estimate,
    PerCapitaIncome_INR_2024_25_per_Annum
ORDER BY avg_aqi DESC;
-- ---------------------------------
•	Health cost impact projections 

•	Competitor feature gap matrix 

Product Requirements Document specifying: 
•	Must-have features (e.g., PM2.5/VOC sensors)

•	Tiered pricing models for target segments 

3.	Innovate: 
•	Integrate external data (e.g., Google Trends, crop-burning satellite imagery) 

•	Video must demonstrate dashboard functionality + city-specific entry simulations
