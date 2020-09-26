library(tidyverse)
library(jsonlite)

`%!in%` <- function(a, b){!(a %in% b)}

# load previous step if you start from this file
# this do not reload automaticall the html pages in the pages column
# you will need to take care of that yourself
if (!is.data.frame(df)){
  df <- readRDS('./data/rawdata.rds')
}

# process synopsis to make nested dataframes
keptfields <- yaml::read_yaml('./settings/sinossi.yml')
process_sinossi <- function(jsonin){
  innerfunction <- function(jsonin){
    jsonin %>%
      fromJSON() %>%
      jsonlite::flatten() %>%
      as_tibble() %>%
      set_names(c('cols', 'values')) %>%
      filter(cols %in% keptfields) %>%
      spread(key = cols, value = values)
  }
  
  tryCatch(
    innerfunction(jsonin),
    error = function(e) tibble())
}

# process page sections to nested dataframe
process_text <- function(txtlist){
  innerfunction <- function(txtlist){
    tibble(cols = names(txtlist)) %>%
      rowwise() %>%
      mutate(content = list(text = txtlist[[cols]])) %>%
      spread(key = cols, value = content)
  }
  
  tryCatch(
    innerfunction(txtlist),
    error = function(e) tibble())
}

# drop unused values and process
df <- df %>%
  mutate(
    failedtext = map_lgl(textpages, isFALSE),
    failedsin = map_lgl(sinossi, isFALSE)) %>%
  filter(
    !failedtext,
    !failedsin) %>%
  select(anno, filmroots,textpages, sinossi) %>%
  mutate(
    textpages = map(textpages, process_text),
    sinossi = map(sinossi, process_sinossi),
    trama = map(textpages, function(x){x[['Trama']]}))

# get a list of italian geographical terms (this is real rough)
# I got the excel file with the list from here:
# https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&ved=2ahUKEwju7_GDrPXrAhUDzqQKHe4ACCAQFjABegQIARAB&url=https%3A%2F%2Fwww.istat.it%2Fstorage%2Fcodici-unita-amministrative%2FElenco-comuni-italiani.xls&usg=AOvVaw1grUzCb-YznlY1XTyzCUJE
# and the coordinates from here:
# https://github.com/MatteoHenryChinaski/Comuni-Italiani-2018-Sql-Json-excel/blob/master/italy_geo.json
istatdf <- readxl::read_excel('./data/istat_comuni.xls') %>%
  select(
    comune = `Denominazione in italiano`,
    provincia = `Sigla automobilistica`,
    macroarea = starts_with("Denominazione dell'Unità territoriale sovracomunale")) %>%
  left_join(fromJSON('./data/italy_geo.json')) %>%
  mutate(
    lat = as.numeric(lat),
    lng = as.numeric(lng)) %>%
  filter(comune %!in% yaml::read_yaml('./settings/comuni_da_rimuovere.yml'))

# add regions data
istatdf <- read_csv('./data/addon_regioni.csv') %>%
  rename(comune = capoluogo) %>%
  left_join(istatdf) %>%
  select(-comune) %>%
  rename(comune = regione) %>%
  bind_rows(istatdf)


# extract geographical terms from plots
link_words <- function(textlist){
  innerfunction <- function(textlist){
    list_to_plaintext <- function(a){
      a %>%
        purrr::flatten_chr() %>%
        str_remove_all('\\[(.*)\\]') %>%
        str_replace_all('\\n', ' ') %>%
        str_flatten('')
    }
    
    tokenize_text <- function(a){
      a <- a %>%
        str_replace_all('[\\",\\.;:]', '') %>%
        str_split(' ') %>%
        .[[1]]
      
      a[a %in% istatdf$comune]
    }
    
    a <- textlist %>% 
      list_to_plaintext %>%
      tokenize_text
    
    tibble(comune = unique(a)) %>% 
      left_join(istatdf)
    
  }
  
  tryCatch(
    innerfunction(textlist),
    error = function(e) tibble())
}

get_geo <- function(wordslist){
  innerfunction <- function(a){
    tibble(
      lat = mean(a$lat, na.rm = TRUE),
      lon = mean(a$lng, na.rm = TRUE))
  }
  
  tryCatch(
    innerfunction(wordslist),
    error = function(e) tibble()
  )
}

df <- df %>%
  mutate(
    usedwords = map(trama, function(x){suppressMessages(link_words(x))}),
    geopoints = map(usedwords, function(x){suppressMessages(get_geo(x))})) %>%
  unnest(geopoints)

# save data for further use
saveRDS(df, './data/cleandata.rds')

