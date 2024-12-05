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

--Daniel's Queries
--Query with CUBE:
/*This query allows us to look at the time dimension of greenhouse gases and how they have evolved over time. 
The query aggregates emissions data using the CUBE operator, providing a comprehensive summary of emissions across the dimensions: start time, sector, and gas.
The CUBE function generates totals for all combinations of these dimensions, as well as overall totals across each dimension individually and combined.

Interpretation
The results provide insights into emissions grouped by time periods (start_time_id), sector (sector_name), and gas (gas_name). For example, in one row where start_date is 2021,
sector is 'agriculture', and gas is 'CO2', the total emissions are calculated as 279569928.87575805 tonnes. In another row where the sector and start_date are the same and all
gases are included, 19656478684.733253 tons were calculated. 

Implications
The results enable policymakers to identify high-emission periods, sectors, or gases and target these areas for intervention. 
For example, if emissions from the "Energy" sector during start_time_id = 2021 show a significant spike, it could signal the need for stricter 
regulations or policies in that sector. Additionally, the overall totals provide a comprehensive view of emissions, helping track progress toward global emission reduction goals.
*/

WITH TimeSectorCube AS (
    SELECT 
        COALESCE(CAST(dst.start_time AS NVARCHAR), 'ALL') AS start_date, -- Use dates for grouping
        COALESCE(s.sector_name, 'ALL') AS sector,
        COALESCE(g.gas_name, 'ALL') AS gas,
        SUM(ISNULL(e.quantity, 0)) AS total_emissions,
        COUNT(e.emission_id) AS entries_count
    FROM emissions e
    JOIN dim_start_times dst ON e.start_time_id = dst.start_time_id
    JOIN dim_sectors s ON e.sector_id = s.sector_id
    JOIN dim_gases g ON e.gas_id = g.gas_id
    GROUP BY CUBE (dst.start_time, s.sector_name, g.gas_name)
)
SELECT 
    start_date,
    sector,
    gas,
    total_emissions,
    entries_count
FROM TimeSectorCube
ORDER BY start_date, sector, gas;

/*
This query ranks sectors by their total emissions for each gas type using the RANK() window function. 
The query partitions the emissions data by gas_name, ensuring each gas type has its own ranking of sectors based on their contribution. 
The total emissions for each sector and gas combination are calculated using SUM, and the RANK() function assigns a rank to each sector within its gas category.

Interpretation
The results show which sectors contribute the most emissions for each specific gas. For example, the fossil_fuel_operations sector is ranked 1st for Ch4 emissions 
with 1014838435.6569908 tonnes, while Agriculture ranks 2nd for Methane with 1001224381.5754291 tonnes. 
This breakdown provides gas-specific sectoral insights, enabling targeted interventions.

Implications
This analysis helps policymakers focus on the most impactful sectors for each gas.
By identifying the top contributors for each gas type, policymakers can design sector-specific strategies to reduce emissions effectively.
*/

WITH SectorRankings AS (
    SELECT 
        s.sector_name AS sector,
        g.gas_name AS gas,
        SUM(ISNULL(e.quantity, 0)) AS total_emissions,
        RANK() OVER (PARTITION BY g.gas_name ORDER BY SUM(ISNULL(e.quantity, 0)) DESC) AS rank
    FROM emissions e
    JOIN dim_sectors s ON e.sector_id = s.sector_id
    JOIN dim_gases g ON e.gas_id = g.gas_id
    GROUP BY s.sector_name, g.gas_name
)
SELECT 
    rank,
    sector,
    gas,
    total_emissions
FROM SectorRankings
ORDER BY gas, rank;

--query 3
/*
This query calculates the cumulative emissions by sector and their respective percentage contributions to the global total. 
It uses window functions to compute cumulative totals and percentages for emissions across all sectors, ordered by descending total emissions. 
The query also calculates the overall total emissions across all sectors.

The SectorEmissions calculates the total emissions for each sector by summing the quantity of emissions.
The CumulativeEmissions computes:
global_total_emissions: The total emissions across all sectors.
cumulative_emissions: The running total of emissions as sectors are ranked in descending order by emissions.
Interpretation
The results display emissions for each sector, their cumulative totals, and the cumulative percentage of the global total. For example:
The power sector contributes 28.69% of the global total emissions, followed by fossil_fuel_operations which raises the cumulative percentage to 50.58%. 
This provides a clear picture of how emissions are distributed among sectors.
The cumulative_percentage column helps identify key contributors to global emissions. Sectors at the top of the list are responsible for the largest shares of emissions.

Implications
This analysis allows policymakers to:
Identify sectors that are the largest contributors to emissions and prioritize them for interventions.
Focus efforts on reducing emissions in sectors with the highest cumulative percentages to achieve the greatest impact.
Use cumulative percentages to assess the relative importance of each sector in global emissions reduction strategies.
*/

WITH SectorEmissions AS (
    SELECT 
        s.sector_name AS sector,
        SUM(ISNULL(e.quantity, 0)) AS total_emissions
    FROM emissions e
    JOIN dim_sectors s ON e.sector_id = s.sector_id
    GROUP BY s.sector_name
),
CumulativeEmissions AS (
    SELECT 
        sector,
        total_emissions,
        SUM(total_emissions) OVER () AS global_total_emissions,
        SUM(total_emissions) OVER (ORDER BY total_emissions DESC ROWS UNBOUNDED PRECEDING) AS cumulative_emissions
    FROM SectorEmissions
)
SELECT 
    sector,
    total_emissions,
    cumulative_emissions,
    cumulative_emissions * 1.0 / (SELECT MAX(global_total_emissions) FROM CumulativeEmissions) AS cumulative_percentage
FROM CumulativeEmissions
ORDER BY total_emissions DESC;

/*

This query calculates a 5-year moving average of emissions for each country and sector. The moving average smooths out fluctuations 
by considering the current year and the emissions from the four preceding years. This allows for a broader view of trends in emissions over time.

The query aggregates emissions data by country, sector, and end_time, then uses the AVG() window function with the ROWS BETWEEN 4 PRECEDING 
AND CURRENT ROW clause to compute the moving average for each group.

Interpretation
The results show the total emissions for each country and sector in a given year alongside their 5-year moving average. For example:

For the fossil_fuel_operations sector in AGO, the moving average for 2021 reflects emissions from 2017 to 2021.
This helps identify whether emissions in a given year are consistent with long-term trends or represent a significant deviation.
The longer window of 5 years reduces noise caused by short-term anomalies, making it easier to observe broader patterns.

Implications
Trend Identification:
This moving average highlights stable trends and smooths out year-over-year fluctuations, enabling policymakers to focus on long-term changes in emissions.
By identifying sectors with steadily increasing emissions, targeted policies can be developed to curb growth in those areas.
Conversely, sectors with decreasing emissions can serve as models for successful interventions.
Resources can be directed toward sectors with the most significant long-term increases in emissions, as identified by deviations from the moving average.
*/


WITH CountrySectorEmissions AS (
    SELECT 
        c.iso_country_code AS country,
        s.sector_name AS sector,
        et.end_time AS period,
        SUM(ISNULL(e.quantity, 0)) AS total_emissions
    FROM emissions e
    JOIN dim_countries c ON e.country_id = c.country_id
    JOIN dim_sectors s ON e.sector_id = s.sector_id
    JOIN dim_end_times et ON e.end_time_id = et.end_time_id
    GROUP BY c.iso_country_code, s.sector_name, et.end_time
)
SELECT 
    country,
    sector,
    period,
    total_emissions,
    AVG(total_emissions) OVER (
        PARTITION BY country, sector 
        ORDER BY period 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS moving_average
FROM CountrySectorEmissions
ORDER BY country, sector, period;
