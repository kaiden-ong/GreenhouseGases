USE GreenhouseGasesDB

-- Kaiden's Queries

-- CUBE Query
/*
This query aggregates emissions data using the CUBE operator, providing a comprehensive
summary of emissions across multiple dimensions: country, sector, and gas. The CUBE function calculates
total emissions and the number of entries for each combination of these dimensions, as well as
their overall totals.

Interpretation:
The results provide insights into total emissions by country, sector, and gas, with aggregated
totals highlighting key contributors and overall emissions across all dimensions. For example, ABW
or Aruba, has 21843694.77865 tonnes of total emissions, as shown in row 7 since sector and gas are both
'ALL', meaning that all the sectors and gases are aggregated and summed in this row.


Implications:
This analysis can help policymakers see where the high-emission sectors, countries, or gases are and
target those, with policies or some other intervention method.
*/

WITH EmissionsCube AS (
    SELECT 
        COALESCE(c.iso_country_code, 'ALL') AS country,
        COALESCE(s.sector_name, 'ALL') AS sector,
        COALESCE(g.gas_name, 'ALL') AS gas,
        SUM(ISNULL(e.quantity, 0)) AS total_emissions,
        COUNT(e.emission_id) AS entries_count
    FROM emissions e
    JOIN dim_countries c ON e.country_id = c.country_id
    JOIN dim_sectors s ON e.sector_id = s.sector_id
    JOIN dim_gases g ON e.gas_id = g.gas_id
    GROUP BY CUBE (c.iso_country_code, s.sector_name, g.gas_name)
)
SELECT * 
FROM EmissionsCube
ORDER BY country, sector, gas;

-- Ranking Window Query

/*
This query ranks countries based on their total emissions using the RANK() window function.
The SUM() function calculates the total emissions for each country (including all sectors and gases).
The RANK() function assigns ranks to countries based on their total emissions, with the highest
emissions ranked first.

Interpretation:
The results are quite easy to interpret, the countries that emit the most gases are ranked the highest,
and the amount is shown in the row as well. China has the most, followed by the US, India, and Russia.


Implications:
These results are helpful for countries to see how they stack against other countries and also work with
the higher ranked countries to try to lower emissions. Organizations and international comittees can also
use this data to enforce policies that all countries must follow to lower emissions for the top countries.

*/

WITH CountryRanks AS (
	SELECT 
		c.iso_country_code as country,
		SUM(ISNULL(e.quantity, 0)) AS total_emissions,
		RANK() OVER (ORDER BY SUM(ISNULL(e.quantity, 0)) DESC) AS emissions_rank
	FROM emissions e
    JOIN dim_countries c ON e.country_id = c.country_id
    JOIN dim_sectors s ON e.sector_id = s.sector_id
    JOIN dim_gases g ON e.gas_id = g.gas_id
    GROUP BY c.iso_country_code
)
SELECT *
FROM CountryRanks
ORDER BY emissions_rank;

--VALUE Window Query

/*
This query is great for seeing the trends of carbon emissions in each country based on gas.
All the end times are shown (end of each year) and the amount of emissions correlating to 
that set of country, gas, and year. Then we have the latest years emission value and a column
comparing each year to the latest year.

Intepretation:
We can see for ABW (Aruba), ch4 emissions are increasing, however co2 emissions are decreasing.
Additionally, n20 is decreasing, and ch4 for afg is also increasing. There are thousands of columns
but each is easy to understand.

Implications:
This is very helpful to see the trends and possibly predict future increases or changes. Based on these 
results policy makers and help limit the increase in certain countries with certain gases, and aid in those
that are already descreasing.
*/

WITH EmissionTimeData AS (
    SELECT 
        c.iso_country_code AS country,
        g.gas_name AS gas,
        et.end_time,
        SUM(ISNULL(e.quantity, 0)) AS total_emissions
    FROM emissions e
    JOIN dim_countries c ON e.country_id = c.country_id
    JOIN dim_gases g ON e.gas_id = g.gas_id
    JOIN dim_end_times et ON e.end_time_id = et.end_time_id
    GROUP BY c.iso_country_code, g.gas_name, et.end_time
)
SELECT 
    country,
    gas,
    total_emissions,
    end_time,
    LAST_VALUE(total_emissions) OVER (
        PARTITION BY country, gas 
        ORDER BY end_time 
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    ) AS last_emission_value,
	CASE 
        WHEN total_emissions > 
            LAST_VALUE(total_emissions) OVER (
                PARTITION BY country, gas 
                ORDER BY end_time 
                ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
            ) THEN 'More'
        WHEN total_emissions < 
            LAST_VALUE(total_emissions) OVER (
                PARTITION BY country, gas 
                ORDER BY end_time 
                ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
            ) THEN 'Less'
        ELSE 'Latest'
    END AS comparison_to_latest
FROM EmissionTimeData
WHERE total_emissions > 0
ORDER BY country, gas, end_time;

--Time series analytic query
/*
This query looks at the two years before and calculates a 3 year moving average for each country
and sector. For example, for ABW and agriculture in 2017, it would take 2015 + 2016 + 2017 totals
and divide by 3 to find the moving average.

Interpretation:
Taking a look at ABW again, we can see that for buildings and fossil fuels, the moving average 
is generally increasing, however, manufacturing emissions are going down. These are easy to see 
as the results are ordered by country and sector so you can see how the quanity of emissions in 
each sector changes each year.

Implications:
This moving average is very helpful as it let's us understand trends for each sector. As a policy
maker for any of these countries this is important information as we can see which sectors are producing
the most emissions and which ones are continuing to rise.


*/

WITH AverageEmissions AS (
    SELECT 
        c.iso_country_code AS country,
        s.sector_name AS sector,
        YEAR(st.start_time) AS period,
        SUM(ISNULL(e.quantity, 0)) AS total_emissions,
        AVG(SUM(ISNULL(e.quantity, 0))) 
            OVER (PARTITION BY c.iso_country_code, s.sector_name
                  ORDER BY YEAR(st.start_time)
                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_years
    FROM emissions e
    JOIN dim_countries c ON e.country_id = c.country_id
    JOIN dim_sectors s ON e.sector_id = s.sector_id
    JOIN dim_start_times st ON e.start_time_id = st.start_time_id
    GROUP BY c.iso_country_code, s.sector_name, YEAR(st.start_time)
)
SELECT 
    country,
    sector,
    period,
    total_emissions,
    moving_avg_3_years
FROM AverageEmissions
ORDER BY country, sector, period;

