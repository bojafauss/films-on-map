# extract synopsis and metadata and loads them on a SQLite DB
# for people that prefer to use SQL and do not need the whole
# page text and plot.
# the resulting DB in NOT indexed

library(tidyverse)
library(RSQLite)

# retrieve cleaned data and adds unique ids
df <- readRDS('./data/cleandata.rds') %>%
  mutate(uid = 1:nrow(df))

# save a main table ----
db <- dbConnect(SQLite(), './outputs/database.db')

df %>%
  select(uid, anno, filmroots, lat, lon) %>%
  {dbWriteTable(db, 'films_locations', .)}

dbDisconnect(db)

# save geographical references ----
db <- dbConnect(SQLite(), './outputs/database.db')

df %>%
  select(uid, usedwords) %>%
  unnest(usedwords) %>%
  {dbWriteTable(db, 'geo_references', .)}

dbDisconnect(db)

# save metadata from synopsis ----
db <- dbConnect(SQLite(), './outputs/database.db')

df %>%
  select(uid, sinossi) %>%
  unnest(sinossi) %>%
  select(-Anno) %>%
  {dbWriteTable(db, 'meta_data', .)}

dbDisconnect(db)


