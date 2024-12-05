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