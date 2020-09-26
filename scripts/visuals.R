library(tidyverse)
library(plotly)

df <- readRDS('./data/cleandata.rds')

# interactive, with plotly
plot_geo(df, x = ~lon, y = ~lat, frame = ~anno) %>% add_markers(text = ~filmroots)

# saved images
fig <- ggplot(df %>% mutate(decade = floor(anno/10)*10), aes(lon, lat)) +
  geom_polygon(data = map_data('italy'), aes(x=long, y = lat, group = group), fill = 'cyan', alpha = 0.4) +
  geom_hex() +
  facet_wrap(~decade)
ggsave('./outputs/hexes_by_decade.png')

fig <- ggplot(df %>% mutate(decade = floor(anno/10)*10), aes(lon, lat)) +
  geom_polygon(data = map_data('italy'), aes(x=long, y = lat, group = group), fill = 'cyan', alpha = 0.4) +
  geom_density_2d() +
  facet_wrap(~decade)
ggsave('./outputs/density_by_decade.png')

fig <- ggplot(df, aes(lon, lat)) +
  geom_polygon(data = map_data('italy'), aes(x=long, y = lat, group = group), fill = 'cyan', alpha = 0.4) +
  geom_density_2d() +
  facet_wrap(~anno)
ggsave('./outputs/density_by_year.png')

# look by genre
f <- function(df){
  if(nrow(df) == 0){return(NA)}
  if('Genere' %!in% names(df)){return(NA)}
  
  tryCatch(
    df$Genere[1] %>% str_extract('[^,]*'),
    error = function(e) NA)
}

df <- df %>%
  mutate(genere = map_chr(sinossi, f))

fig <- ggplot(df, aes(lon, lat)) +
  geom_polygon(data = map_data('italy'), aes(x=long, y = lat, group = group), fill = 'cyan', alpha = 0.4) +
  geom_density_2d() +
  facet_wrap(~genere)
ggsave('./outputs/density_by_genre.png')

df %>%
  group_by(anno, genere) %>%
  summarise(lat = mean(lat, na.rm = TRUE), lon = mean(lon, na.rm = TRUE)) %>%
  drop_na() %>%
  plot_geo(x = ~lon, y = ~lat, frame = ~anno) %>%
  add_markers(text = ~genere, color = ~genere)

