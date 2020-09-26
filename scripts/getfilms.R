library(tidyverse)
library(rvest)
library(glue)

# retrieves all links from a meta page
getlinks <- function(rooturl){
  Sys.sleep(0.5) # avoid hammering
  
  print(paste0(rooturl, '\n'))
  read_html(rooturl) %>%
    html_node(xpath = '//*[@id="mw-pages"]/div/div') %>%
    html_nodes('li > a') %>%
    html_attr('href')
}

# retrieve a page with a timeout given the url
getpages <- function(pageurl){
  Sys.sleep(0.5) # avoid hammering
  print(paste0(pageurl, '\n'))
  read_html(pageurl)
}

# extract the plot from a page
getplots <- function(pagehtml){
  innerfunction <- function(pagehtml){
    
    headings <- pagehtml %>%
      html_node('#mw-content-text') %>%
      html_nodes('h2') %>%
      map(html_text) %>%
      map(str_extract, '^([^\\[])+')
    
    getsection <- function(sectionindex){
      par1 <- pagehtml %>%
        html_nodes(xpath = glue("//h2[contains(., '{headings[sectionindex]}')]/following-sibling::p")) %>%
        html_text()
      
      par2 <- pagehtml %>%
        html_nodes(xpath = glue("//h2[contains(., '{headings[sectionindex+1]}')]/preceding-sibling::p")) %>%
        html_text()
      
      par1[par1 %in% par2]    
    }
    
    1:length(headings) %>%
      map(getsection) %>%
      set_names(headings)
  }
  
  tryCatch(
    innerfunction(pagehtml),
    error = function(e) FALSE)
}

# extract synopsis from a page
getsinossijson <- function(pagehtml){
  innerfunction <- function(pagehtml){
    pagehtml %>%
      html_node(xpath = '//*[@id="mw-content-text"]/div[1]/table[1]') %>%
      html_table() %>%
      jsonlite::toJSON()
  }
  
  tryCatch(
    innerfunction(pagehtml),
    error = function(e) FALSE
  )
}

# grab the data
df <- tibble(anno = 1950:2020) %>%
  mutate(
    metaurl = paste0('https://it.wikipedia.org/wiki/Categoria:Film_italiani_del_', anno),
    filmroots = map(metaurl, getlinks)) %>%
  unnest(filmroots) %>%
  mutate(
    filmurl = paste0('https://it.wikipedia.org', filmroots),
    pages = map(filmurl, getpages))

# initial processing of scraped pages
df <- df %>%
  mutate(
    textpages = map(pages, getplots),
    sinossi = map(pages, getsinossijson))

# save the results for further use
# it would be a good idea to compress the values in an archive when done
for (i in 1:nrow(df)) {
  tempname <- str_replace(df$filmroots[i], '/wiki/', '') %>% str_remove('/')
  write_xml(df$pages[i][[1]], glue('./data/pages/{tempname}.html'))
  remove(tempname)
}

saveRDS(df, './data/rawdata.rds')
