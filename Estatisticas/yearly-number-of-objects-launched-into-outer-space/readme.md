# Annual number of objects launched into space - Data package

This data package contains the data that powers the chart ["Annual number of objects launched into space"](https://ourworldindata.org/grapher/yearly-number-of-objects-launched-into-outer-space?v=1&csvType=full&useColumnShortNames=false) on the Our World in Data website. It was downloaded on May 02, 2025.

### Active Filters

A filtered subset of the full data was downloaded. The following filters were applied:

## CSV Structure

The high level structure of the CSV file is that each row is an observation for an entity (usually a country or region) and a timepoint (usually a year).

The first two columns in the CSV file are "Entity" and "Code". "Entity" is the name of the entity (e.g. "United States"). "Code" is the OWID internal entity code that we use if the entity is a country or region. For normal countries, this is the same as the [iso alpha-3](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) code of the entity (e.g. "USA") - for non-standard countries like historical countries these are custom codes.

The third column is either "Year" or "Day". If the data is annual, this is "Year" and contains only the year as an integer. If the column is "Day", the column contains a date string in the form "YYYY-MM-DD".

The final column is the data column, which is the time series that powers the chart. If the CSV data is downloaded using the "full data" option, then the column corresponds to the time series below. If the CSV data is downloaded using the "only selected data visible in the chart" option then the data column is transformed depending on the chart type and thus the association with the time series might not be as straightforward.

## Metadata.json structure

The .metadata.json file contains metadata about the data package. The "charts" key contains information to recreate the chart, like the title, subtitle etc.. The "columns" key contains information about each of the columns in the csv, like the unit, timespan covered, citation for the data etc..

## About the data

Our World in Data is almost never the original producer of the data - almost all of the data we use has been compiled by others. If you want to re-use data, it is your responsibility to ensure that you adhere to the sources' license and to credit them correctly. Please note that a single time series may have more than one source - e.g. when we stich together data from different time periods by different producers or when we calculate per capita metrics using population data from a second source.

## Detailed information about the data


## Annual number of objects launched into outer space
Annual number of satellites, probes, landers, crewed spacecrafts, and space station flight elements, launched into Earth orbit or beyond.
Last updated: March 4, 2025  
Next update: March 2026  
Date range: 1957–2024  
Unit: objects  


### How to cite this data

#### In-line citation
If you have limited space (e.g. in data visualizations), you can use this abbreviated in-line citation:  
United Nations Office for Outer Space Affairs (2025) – with major processing by Our World in Data

#### Full citation
United Nations Office for Outer Space Affairs (2025) – with major processing by Our World in Data. “Annual number of objects launched into outer space – UNOOSA” [dataset]. United Nations Office for Outer Space Affairs, “Online Index of Objects Launched into Outer Space” [original data].
Source: United Nations Office for Outer Space Affairs (2025) – with major processing by Our World In Data

### What you should know about this data
* Objects are defined here as satellites, probes, landers, crewed spacecrafts, and space station flight elements launched into Earth orbit or beyond.
* This data is based on national registers of launches submitted to the UN by participating nations. According to UN estimates, the data captures around 88% of all objects launched.
* When an object is marked by the source as launched by a country on behalf of another one, the launch is attributed to the latter country.
* When a launch is made jointly by several countries, it is recorded in each of these countries' time series but only once in the 'World' series.

### Source

#### United Nations Office for Outer Space Affairs – Online Index of Objects Launched into Outer Space
Retrieved on: 2025-03-04  
Retrieved from: https://www.unoosa.org/oosa/osoindex/search-ng.jspx  

#### Notes on our processing step for this indicator
- We scrape the data from the source by iterating through all objects in the online index.
- We harmonize the names of countries. When an object is marked by the source as launched by a country on behalf of another one, we attribute the launch to the latter country.
- We aggregate launches by country and year. When a launch is made jointly by several countries, it is recorded in each of these countries' time series.
- We calculate the total number of launches globally. This is available as 'World' in the data. When a launch is made jointly by several countries, it is only recorded once in the 'World' series.
- We also calculate the cumulative number of launches over time.


    