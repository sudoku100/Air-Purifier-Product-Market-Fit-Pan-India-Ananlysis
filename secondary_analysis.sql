										-- SECONDARY ANALYSIS --

-- 1. Which age group is most affected by air pollution-related health outcomes — and how does this vary by city? 

-- ---------------------------------------------------

-- 2. Who are the major competitors in the Indian air purifier market, and what are their key 
--    differentiators (e.g., price, filtration stages, smart features)? 

-- ----------------------------------------------------

-- 3. What is the relationship between a city’s population size and its average AQI — do larger cities 
--    always suffer from worse air quality? (Consider 2024 population and AQI data for this) 

# Table data containg population v/s aqi for cities across India.
SELECT 
	al.state, area AS City, Area_Type,
    2024_Population_Estimate, 
    AVG(aqi_value) as avg_aqi_value
FROM aqi 
LEFT JOIN area_latest_population_2024 al ON area = city
GROUP BY al.state, area, Area_Type, 2024_Population_Estimate
ORDER BY 2024_Population_Estimate;

# Calculating the Pearson's correlation coefficient between Latest Population_Estimate and avg_aqi_value
WITH cte AS (
	SELECT 
		al.state, area AS City,
		AVG(2024_Population_Estimate) AS 2024_Population_Estimate, 
        AVG(aqi_value) as avg_aqi_value
	FROM aqi 
	LEFT JOIN area_latest_population_2024 al ON area = city
    WHERE YEAR(date) = 2024
	GROUP BY al.state, area
)
SELECT ROUND
	(
		(COUNT(*) * SUM(2024_Population_Estimate * avg_aqi_value) - SUM(2024_Population_Estimate) * SUM(avg_aqi_value)) /
		(SQRT(COUNT(*) * SUM(2024_Population_Estimate * 2024_Population_Estimate) - POWER(SUM(2024_Population_Estimate), 2)) *
		 SQRT(COUNT(*) * SUM(avg_aqi_value * avg_aqi_value) - POWER(SUM(avg_aqi_value), 2))
		), 2
	) AS correlation_coefficient
FROM cte;								# Almost no correaltion : 0.09
-- ----------------------------------------------------

-- 4. How aware are Indian citizens of what AQI (Air Quality Index) means — and do they understand its health implications?

-- ----------------------------------------------------

-- 5. Which pollution control policies introduced by the Indian government in the past 5 years have had the most 
--    measurable impact on improving air quality — and how have these impacts varied across regions or cities? 

-- ----------------------------------------------------