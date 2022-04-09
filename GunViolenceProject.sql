-- Inspect tables (show only top 1000 rows) --
SELECT TOP 1000 *
FROM gun_violence

SELECT *
FROM us_cities
WHERE NAME like '%New York%'

-- Display participant gender --
WITH results AS( -- 1st WITH clause
	SELECT participant_gender
	FROM gun_violence
),
res AS( -- 2nd WITH clause
	SELECT STUFF(value, 1, pos + 1, '') AS gender
	FROM results
	CROSS APPLY STRING_SPLIT(REPLACE(participant_gender, '||', '|'), '|')
	CROSS APPLY (SELECT CHARINDEX('::', value)) AS t(pos)
)
SELECT gender, COUNT(*) AS total
FROM res
WHERE gender = 'Male' OR gender = 'Female'
GROUP BY gender
ORDER BY total DESC

-- Display participant status --
WITH results AS( -- 1st WITH clause
	SELECT participant_status
	FROM gun_violence
),
res AS( -- 2nd WITH clause
	SELECT STUFF(value, 1, pos + 1, '') AS status
	FROM results
	CROSS APPLY STRING_SPLIT(REPLACE(participant_status, '||', '|'), '|')
	CROSS APPLY (SELECT CHARINDEX('::', value)) AS t(pos)
)
SELECT status, COUNT(*) AS total
FROM res
WHERE status = 'Arrested' OR status = 'Unharmed' OR status = 'Injured' OR status = 'Killed'
GROUP BY status
ORDER BY total DESC

-- Display participant age group --
WITH results AS( -- 1st WITH clause
	SELECT participant_age_group
	FROM gun_violence
),
res AS( -- 2nd WITH clause
	SELECT STUFF(value, 1, pos + 1, '') AS age_group
	FROM results
	CROSS APPLY STRING_SPLIT(REPLACE(participant_age_group, '||', '|'), '|')
	CROSS APPLY (SELECT CHARINDEX('::', value)) AS t(pos)
)
SELECT age_group, COUNT(*) AS total
FROM res
WHERE age_group = 'Adult 18+' OR age_group = 'Teen 12-17' OR age_group = 'Child 0-11'
GROUP BY age_group
ORDER BY total DESC

-- Display participant type --
WITH results AS( -- 1st WITH clause
	SELECT participant_type
	FROM gun_violence
),
res AS( -- 2nd WITH clause
	SELECT STUFF(value, 1, pos + 1, '') AS type
	FROM results
	CROSS APPLY STRING_SPLIT(REPLACE(participant_type, '||', '|'), '|')
	CROSS APPLY (SELECT CHARINDEX('::', value)) AS t(pos)
)
SELECT type, COUNT(*) AS total
FROM res
WHERE type = 'Victim' OR type = 'Subject-Suspect'
GROUP BY type
ORDER BY total DESC

-- Display incident data for each state
SELECT
	state,
	COUNT(incident_id) AS total_incidents,
	SUM(n_killed) AS deaths,
	SUM(n_injured) AS injured,
	SUM(n_killed) + SUM(n_injured) AS total_casualties,
	SUM(CASE WHEN incident_characteristics LIKE '%armed robbery%' THEN 1 ELSE 0 END) AS armed_robbery,
	SUM(CASE WHEN incident_characteristics LIKE '%gang involvement%' THEN 1 ELSE 0 END) AS gang_involvement,
	SUM(CASE WHEN incident_characteristics LIKE '%home invasion%' THEN 1 ELSE 0 END) AS home_invasion,
	SUM(CASE WHEN incident_characteristics LIKE '%domestic violence%' THEN 1 ELSE 0 END) AS domestic_violence,
	SUM(CASE WHEN incident_characteristics LIKE '%road rage%' THEN 1 ELSE 0 END) AS road_rage,
	SUM(CASE WHEN incident_characteristics LIKE '%mass_shooting%' THEN 1 ELSE 0 END) AS mass_shooting,
	SUM(CASE WHEN notes LIKE '%teen%' THEN 1 ELSE 0 END) AS teen_incidents,
	SUM(CASE WHEN incident_characteristics LIKE '%raid%' AND incident_characteristics LIKE '%drug involvement%' THEN 1 ELSE 0 END) AS drug_raid,
	SUM(CASE WHEN incident_characteristics LIKE '%suicide^%' THEN 1 ELSE 0 END) AS suicide
FROM gun_violence
GROUP BY state
ORDER BY total_incidents DESC

-- Display incident data and city data a particular state (or all states) --
WITH results AS
(
	SELECT
		state_abbrev,
		city_or_county,
		COUNT(incident_id) AS total_incidents,
		SUM(n_killed) AS deaths,
		SUM(n_injured) AS injured,
		SUM(n_killed) + SUM(n_injured) AS total_casualties,
		SUM(CASE WHEN incident_characteristics LIKE '%armed robbery%' THEN 1 ELSE 0 END) AS armed_robbery,
		SUM(CASE WHEN incident_characteristics LIKE '%gang involvement%' THEN 1 ELSE 0 END) AS gang_involvement,
		SUM(CASE WHEN incident_characteristics LIKE '%home invasion%' THEN 1 ELSE 0 END) AS home_invasion,
		SUM(CASE WHEN incident_characteristics LIKE '%domestic violence%' THEN 1 ELSE 0 END) AS domestic_violence,
		SUM(CASE WHEN incident_characteristics LIKE '%road rage%' THEN 1 ELSE 0 END) AS road_rage,
		SUM(CASE WHEN incident_characteristics LIKE '%mass_shooting%' THEN 1 ELSE 0 END) AS mass_shooting,
		SUM(CASE WHEN notes LIKE '%teen%' THEN 1 ELSE 0 END) AS teen_incidents,
		SUM(CASE WHEN incident_characteristics LIKE '%raid%' AND incident_characteristics LIKE '%drug involvement%' THEN 1 ELSE 0 END) AS drug_raid,
		SUM(CASE WHEN incident_characteristics LIKE '%suicide^%' THEN 1 ELSE 0 END) AS suicide
	FROM gun_violence
	WHERE state_abbrev LIKE '%PA%' -- Optional query to filter by state (comment this line out to query all states)
	GROUP BY state_abbrev, city_or_county
)
SELECT
	state_abbrev,
	city_or_county AS city,
	total_incidents,
	deaths,
	injured,
	total_casualties,
	armed_robbery,
	gang_involvement,
	home_invasion,
	domestic_violence,
	road_rage,
	mass_shooting,
	teen_incidents,
	drug_raid,
	suicide
FROM results
WHERE total_incidents > 50
ORDER BY total_incidents DESC

-- Compute rolling statistics for PA (I just chose a lookback window of 377 because it is on the fib sequence)
WITH results AS(
	SELECT
		date AS datetime,
		state,
		city_or_county,
		SUM(n_killed) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_death_count,
		SUM(n_injured) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_injured_count,
		SUM(CASE WHEN incident_characteristics LIKE '%armed robbery%' THEN 1 ELSE 0 END) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_armed_robbery_count,
		SUM(CASE WHEN incident_characteristics LIKE '%gang involvement%' THEN 1 ELSE 0 END) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_gang_involvement_count,
		SUM(CASE WHEN incident_characteristics LIKE '%home invasion%' THEN 1 ELSE 0 END) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_home_invasion_count,
		SUM(CASE WHEN incident_characteristics LIKE '%domestic violence%' THEN 1 ELSE 0 END) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_domestic_violence_count,
		SUM(CASE WHEN incident_characteristics LIKE '%road rage%' THEN 1 ELSE 0 END) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_road_rage_count,
		SUM(CASE WHEN incident_characteristics LIKE '%mass_shooting%' THEN 1 ELSE 0 END) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_mass_shooting_count,
		SUM(CASE WHEN notes LIKE '%teen%' THEN 1 ELSE 0 END) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_teen_incident_count,
		SUM(CASE WHEN incident_characteristics LIKE '%raid%' AND incident_characteristics LIKE '%drug involvement%' THEN 1 ELSE 0 END) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_drug_raid_count,
		SUM(CASE WHEN incident_characteristics LIKE '%suicide^%' THEN 1 ELSE 0 END) OVER (ORDER BY date ROWS BETWEEN 377 PRECEDING AND CURRENT ROW) AS rolling_suicide_count
	FROM gun_violence
	WHERE state like 'pennsylvania'
)
SELECT *, CAST(datetime AS DATE) AS date
FROM results