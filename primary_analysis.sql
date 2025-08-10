													-- PRIMARY ANALYSIS --
	USE airpurifier;
	-- -----------------------------

	-- 1. List the top 5 and bottom 5 areas with highest average AQI. (Consider areas which contains data from last 6 months: 
	--    December 2024 to May 2025)

	# top 5 areas with highest average AQI
	SELECT 
	  state, 
	  area,
	  AVG(aqi_value) AS avg_aqi_value
	FROM aqi
	WHERE date BETWEEN '2024-12-01' AND '2025-05-31' AND aqi_value IS NOT NULL
	GROUP BY state, area
	ORDER BY avg_aqi_value DESC
	LIMIT 5;

	# bottom 5 areas with lowest average AQI
	SELECT 
	  state, 
	  area, 
	  AVG(aqi_value) AS avg_aqi_value
	FROM aqi
	WHERE date BETWEEN '2024-12-01' AND '2025-05-31' AND aqi_value IS NOT NULL
	GROUP BY state, area
	ORDER BY avg_aqi_value
	LIMIT 5;
	-- -------------------------------------------------------

	-- 2. List out top 2 and bottom 2 prominent pollutants for each state of southern India. 
	-- 	  (Consider data post covid: 2022 onwards) 

	WITH RECURSIVE split_cte AS (
		  SELECT
			ROW_NUMBER() over() AS id,
			state,
			TRIM(SUBSTRING_INDEX(prominent_pollutants, ',', 1)) AS pollutant,
			SUBSTRING(prominent_pollutants, 
			LENGTH(SUBSTRING_INDEX(prominent_pollutants, ',', 1)) + 2) AS rest,
			1 AS part
		  FROM aqi
			WHERE state IN (
				'Andhra Pradesh', 'Andaman and Nicobar Islands', 'Karnataka', 
				'Kerala', 'Tamil Nadu', 'Telangana', 'Puducherry','Lakshadweep'	)		# Southern Indian States
				AND date >= '2022-01-01'  									# Filter for post-COVID data
				
		  UNION ALL

		  SELECT
			id, state,
			TRIM(SUBSTRING_INDEX(rest, ',', 1)),
			SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2),
			part + 1
		  FROM split_cte
		  WHERE rest != ''
	),
	count_pollutants AS(
		SELECT id, state, pollutant 
		FROM split_cte
	),
	cte as(
		SELECT 
			state, pollutant , 
			COUNT(*) AS pollutant_count, 
			DENSE_RANK() OVER(PARTITION BY state ORDER BY COUNT(*) DESC) AS top_rnk,
			DENSE_RANK() OVER(PARTITION BY state ORDER BY COUNT(*)) AS bottom_rnk
		FROM count_pollutants
		GROUP BY state, pollutant
	)
	SELECT
		state, pollutant, pollutant_count, 
		CASE 
			WHEN top_rnk <= 2 THEN CONCAT('Top ', top_rnk)
			WHEN bottom_rnk <= 2 THEN CONCAT('Bottom ', bottom_rnk)
		END AS rank_type
	FROM cte
	WHERE top_rnk <= 2 OR bottom_rnk <= 2
	ORDER BY state, pollutant_count DESC;

	select distinct state from aqi order by 1; # 32 states
	-- -----------------------------------------
	-- Get an understanding of different week-day functions
	SELECT 
		date, 
		WEEK(date) as Week_Number,
		DAYNAME(date) AS Day_Name, 
		DAYOFWEEK(date) AS Day_of_Week, 
		WEEKDAY(date) AS Week_Day
	FROM airpurifier.aqi
	WHERE DAYNAME(date) = 'Monday';
	-- -----------------------------------------

	-- 3. Does AQI improve on weekends vs weekdays in Indian metro cities (Delhi, Mumbai, Chennai, Kolkata, Bengaluru, 
	--    Hyderabad, Ahmedabad, Pune)? (Consider data from last 1 year)
	SELECT 
	  area,
	  AVG(CASE WHEN DAYOFWEEK(date) NOT IN (1, 7) THEN aqi_value END) AS avg_aqi_value_on_weekdays,
	  AVG(CASE WHEN DAYOFWEEK(date) IN (1, 7) THEN aqi_value END) AS avg_aqi_value_on_weekends
	FROM aqi
	WHERE 
	  date BETWEEN 
		(SELECT DATE_ADD(MAX(date), INTERVAL -1 YEAR) FROM aqi)  -- 1 year ago from the latest date
		AND
		(SELECT MAX(date) FROM aqi)                              -- Latest date
	  AND area IN ('Delhi', 'Mumbai', 'Chennai', 'Kolkata', 'Bengaluru', 'Hyderabad', 'Ahmedabad', 'Pune')
	GROUP BY area;
	-- -----------------------------------------------

	-- 4. Which months consistently show the worst air quality across Indian states — 
	--    (Consider top 10 states with high distinct areas)
	WITH cte AS(
		 SELECT state
		 FROM aqi
		 GROUP BY state
		 ORDER BY COUNT(DISTINCT area) DESC		# Rajasthan,Maharashtra,Karnataka,Tamil Nadu,Bihar,Haryana,Uttar Pradesh,Odisha,Madhya Pradesh,Andhra Pradesh
		 LIMIT 10)
	SELECT month(date) as month, avg(aqi_value) avg_aqi
	FROM aqi
	WHERE state IN 
		(SELECT state FROM cte)
	GROUP BY month
	ORDER BY avg_aqi DESC;
    
    -- FOR Year-Month
	WITH top_10_states AS (
		SELECT state
		FROM aqi
		GROUP BY state
		ORDER BY COUNT(DISTINCT area) DESC		# Rajasthan,Maharashtra,Karnataka,Tamil Nadu,Bihar,Haryana,Uttar Pradesh,Odisha,Madhya Pradesh,Andhra Pradesh
		LIMIT 10
	)
	SELECT CONCAT(YEAR(date), '–', LPAD(MONTH(date), 2, '0')) AS YearMonth, AVG(aqi_value) AS avg_aqi_value
	FROM aqi
	WHERE state IN (SELECT * FROM top_10_states)
	GROUP BY yearmonth
	ORDER BY avg_aqi_value DESC;

	-- Answer: Nov, Dec and Jan (Festive seasons)
	-- Note: From Nov-2024 to Jan-2025 a consistent drop in AQI has been observed even though its festive season.
	-- -----------------------------------------

	-- 5. For the city of Bengaluru, how many days fell under each air quality category (e.g., Good, Moderate, Poor, etc.) 
	--    between March and May 2025?
	SELECT DISTINCT air_quality_status FROM aqi;	 # 6 VALUES - Satisfactory, Moderate, Good, Poor, Very Poor, Severe

	SELECT 
		SUM(CASE WHEN air_quality_status = 'Good' THEN 1 ELSE 0 END) AS Good,
		SUM(CASE WHEN air_quality_status = 'Moderate' THEN 1 ELSE 0 END) AS Moderate,
		SUM(CASE WHEN air_quality_status = 'Satisfactory' THEN 1 ELSE 0 END) AS Satisfactory,
		SUM(CASE WHEN air_quality_status = 'Poor' THEN 1 ELSE 0 END) AS Poor,
		SUM(CASE WHEN air_quality_status = 'Very Poor' THEN 1 ELSE 0 END) AS Very_Poor,
		SUM(CASE WHEN air_quality_status = 'Severe' THEN 1 ELSE 0 END) AS Severe
	FROM aqi
	WHERE 
		area = 'Bengaluru' 
		AND 
		date BETWEEN '2025-03-01' AND '2025-05-31';			# 3 MONTHS DATA FOR 2025
	-- ------------------------------------

	-- 6. List the top two most reported disease or illnesses in each state over the past three years, along with the 
	--    corresponding average Air Quality Index (AQI) for that period.
	WITH report_idsp AS (
		SELECT 
			state,
			disease_or_illness, 
			COUNT(*) AS cnt_disease,
			DENSE_RANK() OVER (
				PARTITION BY state
				ORDER BY COUNT(*) DESC
			) AS rnk
		FROM idsp
		WHERE year > (SELECT MAX(year) - 3 FROM idsp)
		GROUP BY state, disease_or_illness
        ORDER BY state
	),
	report_aqi AS (
		SELECT 
			state, 
			AVG(aqi_value) AS avg_aqi_value
		FROM aqi
        WHERE YEAR(date) > (SELECT MAX(YEAR(date)) - 3 FROM aqi)
		GROUP BY state
	)
	SELECT 
		"2023-25" AS period,
		ri.state,
		GROUP_CONCAT(ri.disease_or_illness ORDER BY rnk SEPARATOR ', ') AS top_2_ranking_diseases,
		ra.avg_aqi_value
	FROM report_idsp ri
	JOIN report_aqi ra 
	  ON ri.state = ra.state
	WHERE ri.rnk <= 2
	GROUP BY period, ri.state, ra.avg_aqi_value
	ORDER BY ri.state;
	-- ------------------------------------------------------

	-- 7. List the top 5 states with high EV adoption and analyse if their average AQI is significantly better 
	--    compared to states with lower EV adoption

	# top 5 states with high EV adoption
	WITH top_5_ev_states AS(
		SELECT state, fuel, IFNULL(SUM(value), 0) AS EV_cnt
		FROM vahan 
		WHERE LEFT(fuel, 8) = 'ELECTRIC'
		GROUP BY  state, fuel
		ORDER BY EV_cnt DESC
		LIMIT 5
	),
	state_aqi AS (
		SELECT state, AVG(aqi_value) AS avg_aqi_value
		FROM aqi 
		GROUP BY state
	)
	SELECT v.state, v.EV_cnt, a.avg_aqi_value
	FROM top_5_ev_states AS v
	INNER JOIN state_aqi a ON a.state = v.state
	ORDER BY v.EV_cnt DESC;

	# Comparing with the states with lower EV adoption
	WITH ev_count AS (
		SELECT 
			state, 
			IFNULL(SUM(value), 0) AS ev_count
		FROM vahan 
		WHERE LEFT(fuel, 8) = 'ELECTRIC'
		GROUP BY state
	),
	state_aqi AS (
		SELECT 
			state, 
			AVG(aqi_value) AS avg_aqi_value
		FROM aqi 
		GROUP BY state
	),
	ranked_states AS (
		SELECT 
			s.state,
			e.ev_count,
			s.avg_aqi_value,
			DENSE_RANK() OVER (ORDER BY e.ev_count DESC) AS ev_rank
		FROM ev_count e
		RIGHT JOIN state_aqi s ON e.state = s.state
	),
	labelled AS (
		SELECT 
			state, ev_count, avg_aqi_value,
			CASE WHEN ev_rank <= 5 THEN 'High EV' ELSE 'Low EV' END AS ev_category
		FROM ranked_states
	)
	SELECT 
		ev_category,
		COUNT(*) AS num_states,
		ROUND(AVG(avg_aqi_value), 2) AS avg_aqi_per_category
	FROM labelled
	GROUP BY ev_category;
	-- ---------------------------------------------

	-- Finding out the correlation between a average aqi and no of EVs in a state in a year; 
	-- Expecting a negative correaltion because more the adoption of EVs should result in lesser emmision.
	WITH cte AS(
    
		WITH aqi_avg as
		(
			SELECT 
				year(date) AS year, DATE_FORMAT(date, '%M') AS month, state, AVG(aqi_value) AS avg_aqi_value 
			FROM aqi
			GROUP BY year, state, month
			ORDER BY year, month, state
		),
		EV AS(
			SELECT year, month, state, IFNULL(SUM(value), 0) AS EV_Count
			FROM vahan
			WHERE fuel = 'ELECTRIC(BOV)'
			GROUP BY year, state, month
			ORDER BY year, month, state
		)
		SELECT 
			# a.year, 
			# a.month,
			a.state,
			AVG(avg_aqi_value) AS avg_aqi_value, 
			SUM(EV_Count) AS EV_Count
		FROM EV v
		INNER JOIN aqi_avg a
			ON v.year= a.year 
			AND v.month = a.month 
			AND v.state = a.state
		GROUP BY a.state
		ORDER BY a.state, avg_aqi_value DESC
)
	SELECT 
		ROUND
		(	
			(
				(COUNT(*) * SUM(avg_aqi_value * EV_Count)) - (SUM(avg_aqi_value) * SUM(EV_Count))
			) / 
			(
				SQRT
				(
					(COUNT(*) * SUM(POWER(avg_aqi_value, 2)) - POWER(SUM(avg_aqi_value), 2))
					* 
					(COUNT(*) * SUM(POWER(EV_Count, 2)) - POWER(SUM(EV_Count), 2))
				)
			), 2
		) AS pearson_correlation_coefficient
	FROM cte;										# 0.11

	/*
	A Pearson correlation coefficient of 0.11 indicates a weak positive linear relationship between average AQI values 
	and electric vehicle (EV) counts, not a negative one. This means that as the EV count increases, 
	the AQI value tends to increase slightly as well, although the association is very weak.

	It is a common misconception to expect a negative correlation here because one might intuitively 
	think that more EVs should reduce pollution (and thus AQI). However, the correlation coefficient simply 
	measures the linear association present in your data. A positive correlation does not necessarily imply 
	causation or even a meaningful relationship; it just shows the direction of co-movement between variables.
	*/

