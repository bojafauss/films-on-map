# This is quick interactive visualizer for the structured data

library(shiny)
library(tidyverse)
library(RSQLite)
library(cowplot)

# preload, for performance
setwd('../')
db <- dbConnect(SQLite(), './outputs/database.db')
df <- dbReadTable(db, 'films_locations') %>%
    left_join(dbReadTable(db, 'meta_data')) %>%
    as_tibble()
dbDisconnect(db)

df <- df %>%
    mutate(
        genere = str_split(Genere, ','),
        runtime = Durata %>% str_remove(' min') %>% as.numeric(),
        decade = 10 * floor(anno / 10),
        fromrome = sqrt((lat-41.9)^2 + (lon-12.5)^2))

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Quickviz"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            sliderInput("range", "Select the years to keep",
                        min = min(df$anno), max = max(df$anno),
                        value = c(min(df$anno), max(df$anno)),
                        step = 1
                        ),
            selectInput("types", "Select the genres you want to visualize",
                        choices = c('all', df$genere %>% unlist() %>% str_remove_all(' ') %>% unique() %>% sort())
                        )
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("multiplot", height = "800px")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$multiplot <- renderPlot({
        localdf <- df %>%
            filter(anno %in% input$range[1]:input$range[2])
        
        if(input$types != 'all'){
            localdf <- localdf %>%
                mutate(keep_me = map_lgl(genere, function(f) any(input$types %in% f))) %>%
                filter(keep_me)
        }

        #plot1
        plot1 <- ggplot(localdf, aes(lon, lat)) +
            geom_polygon(data = map_data('italy'), aes(x=long, y = lat, group = group), fill = 'cyan', alpha = 0.4) +
            geom_density_2d() +
            ggtitle('Density map of locations')
        
        #plot2
        plot2 <- ggplot(localdf, aes(as.character(decade), runtime)) +
            geom_boxplot() +
            ggtitle('Boxplot of duration in minutes')
        
        #plot3
        plot3 <- ggplot(localdf, aes(lon, lat)) +
            geom_polygon(data = map_data('italy'), aes(x=long, y = lat, group = group), fill = 'cyan', alpha = 0.4) +
            geom_point(aes(color = as.character(decade))) +
            ggtitle('Points for locations')
        
        #plot4
        plot4 <- ggplot(localdf, aes(anno, fromrome)) +
            geom_point() +
            geom_smooth() +
            ggtitle('Distance from Rome, arbitrary unit')
            
        
        #makegrid
        plot_grid(plot1, plot2, plot3, plot4, nrow = 2)
        
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
