# films-on-map
A quick look at the geographical settings of italian films

# What is in here

I got curious about the settings of italian films from the last 50-60 years, and asked myself: is there a noticeable geographical trend in there? (e.g. north to south, east to west, around the capitol)

This repository contains a small collection of scripts that generates a dataset to answer the question.

# Approach

I was not able to find a premade dataset, so I made my own. The information are obtained by scraping http://it.wikipedia.org.
Each page is parsed to extract the plot and / or the synopsys, their content is then tokenized looking for geographical references.

These references (towns and regions names) are assigned geographical coordinates by joining them with information retrieved from:

- ISTAT
- https://github.com/MatteoHenryChinaski/Comuni-Italiani-2018-Sql-Json-excel

For each film a unique point is calculated by taking the average of the coordinates of all unique geographical references.

# License

This repository is licensed under the Creative Commons Attribution-NonCommercial License. To view a copy of the license, visit https://creativecommons.org/licenses/by-nc/4.0/

![alt text](https://mirrors.creativecommons.org/presskit/buttons/88x31/svg/by-nc.eu.svg)

Feel free to use the included dataframe for your own projects.