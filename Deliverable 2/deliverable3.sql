CREATE DATABASE GreenhouseGasesDB
GO
USE GreenhouseGasesDB

CREATE TABLE dim_countries
(
	country_id INT NOT NULL,
	iso_country_code VARCHAR(10) NOT NULL,
	PRIMARY KEY (country_id)
)

CREATE TABLE dim_start_times
(
	start_time_id INT NOT NULL,
	start_time DATE NOT NULL,
	PRIMARY KEY (start_time_id)
)

CREATE TABLE dim_end_times
(
	end_time_id INT NOT NULL,
	end_time DATE NOT NULL,
	PRIMARY KEY (end_time_id)
)

CREATE TABLE dim_gases
(
	gas_id INT NOT NULL,
	gas_name VARCHAR(10) NOT NULL,
	PRIMARY KEY (gas_id)
)

CREATE TABLE dim_sectors
(
	sector_id INT NOT NULL,
	sector_name VARCHAR(25) NOT NULL,
	PRIMARY KEY (sector_id)
)

CREATE TABLE dim_subsectors
(
	subsector_id INT NOT NULL,
	subsector_name VARCHAR(50) NOT NULL,
	PRIMARY KEY (subsector_id)
)

CREATE TABLE emissions
(
	emission_id INT NOT NULL,
	country_id INT,
	start_time_id INT,
	end_time_id INT,
	sector_id INT,
	subsector_id INT,
	gas_id INT,
	quantity FLOAT,
	PRIMARY KEY (emission_id)
)

DROP TABLE dim_countries
DROP TABLE dim_start_times
DROP TABLE dim_end_times
DROP TABLE dim_gases
DROP TABLE dim_sectors
DROP TABLE dim_subsectors
DROP TABLE emissions

BULK INSERT dim_countries
FROM 'C:\Users\mrpi3\OneDrive\Documents\UW Files\UW Fall 2024\INFO 430\GreenhouseGases\output\countries.csv'
WITH
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',  
	ROWTERMINATOR = '\n',   
	TABLOCK
)

BULK INSERT dim_start_times
FROM 'C:\Users\mrpi3\OneDrive\Documents\UW Files\UW Fall 2024\INFO 430\GreenhouseGases\output\starts.csv'
WITH
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',  
	ROWTERMINATOR = '\n',   
	TABLOCK
)

BULK INSERT dim_end_times
FROM 'C:\Users\mrpi3\OneDrive\Documents\UW Files\UW Fall 2024\INFO 430\GreenhouseGases\output\ends.csv'
WITH
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',  
	ROWTERMINATOR = '\n',   
	TABLOCK
)

BULK INSERT dim_gases
FROM 'C:\Users\mrpi3\OneDrive\Documents\UW Files\UW Fall 2024\INFO 430\GreenhouseGases\output\gases.csv'
WITH
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',  
	ROWTERMINATOR = '\n',   
	TABLOCK
)

BULK INSERT dim_sectors
FROM 'C:\Users\mrpi3\OneDrive\Documents\UW Files\UW Fall 2024\INFO 430\GreenhouseGases\output\sectors.csv'
WITH
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',  
	ROWTERMINATOR = '\n',   
	TABLOCK
)

BULK INSERT dim_subsectors
FROM 'C:\Users\mrpi3\OneDrive\Documents\UW Files\UW Fall 2024\INFO 430\GreenhouseGases\output\subsectors.csv'
WITH
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',  
	ROWTERMINATOR = '\n',   
	TABLOCK
)

BULK INSERT emissions
FROM 'C:\Users\mrpi3\OneDrive\Documents\UW Files\UW Fall 2024\INFO 430\GreenhouseGases\output\fact_table.csv'
WITH
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',  
	ROWTERMINATOR = '\n',   
	TABLOCK
)