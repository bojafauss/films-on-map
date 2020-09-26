# this file simply executes the proper scripts in order

# scrape wikipedia and process data, do not clean the environment in between the two scripts if you value your time
source('./scripts/getfilms.R')
source('./scripts/cleandata.R')

# make some basic visuals
source('./scripts/visuals.R')
