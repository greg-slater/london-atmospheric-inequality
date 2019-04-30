# read in data and transform to mapbox CRS
sf <- st_read('london_lsoa_NO2_gen/london_lsoa_NO2_gen.shp')
sf <- st_transform(sf, 4326)

mapbox_TOKEN <- 'INSERT-TOKEN-HERE'

# manual lookup lists for dynamic data fields
clr <- list(NO2_men = "YlOrRd", 
            imd_dcl = "PuBuGn",
            incm_dc = "Blues",
            emplymnt_d = "Greens",
            edctn_d = "Oranges",
            hlth_dc = "Purples",
            crm_dcl = "Reds",
            hsng_dc = "BuGn",
            lvng_dc = "RdPu")

scr <- list(NO2_men = "imd_scr", 
            imd_dcl = "imd_scr",
            incm_dc = "incm_sc",
            emplymnt_d = "emplymnt_s",
            edctn_d = "edctn_s",
            hlth_dc = "hlth_sc",
            crm_dcl = "crm_scr",
            hsng_dc = "hsng_sc",
            lvng_dc = "lvng_sc")


server <- function(input,output, session){

  # reactive function to update data based on inputs 
  filteredData <- reactive({
    filter(sf, NO2_men >= input$NO2_slider[1], NO2_men <= input$NO2_slider[2],
                  londn_r %in% input$london_area)
  })

  # base map object, mapbox layer, set start position and zoom level
  output$map <- renderLeaflet({
    
    leaflet() %>%
      # addPolygons(data = sf,
      #             stroke = FALSE,
      #             fillColor = ~colorBin('YlOrRd', sf$NO2_men)(sf$NO2_men),
      #             fillOpacity = 0.8) %>%
      addProviderTiles(provider = providers$MapBox, 
                       options = providerTileOptions(id = "mapbox.light",
                                                     accessToken = mapbox_TOKEN)) %>%
  
      setView(lng=-0.121, lat=51.512 , zoom=11)
  })
  
  
  # bar plot for population distribution of selected map areas
  output$barMD <- renderPlot({
    
    if (nrow(filteredData()) == 0)  # return null if no data selected, stops errors
      return(NULL)
    
    # set groupBy variable to IMD if NO2 is selected, else set to selected
    if (input$field_selector == 'NO2_men'){
      groupBy <- 'imd_dcl' 
    } else {
      groupBy <- input$field_selector
    }
    
    # data for chart, grouping by groupBy variable and summing population 
    chart_data <- filteredData() %>% st_set_geometry(NULL) %>% group_by_(groupBy) %>% summarise(sum = sum(X2013_pp))

    # get colours from correct palette for as many deciles are currently being displayed
    pal <- rev(brewer.pal(8, clr[[groupBy]]))
    pal <- colorRampPalette(pal)(length(chart_data$sum)) 
    
    # create chart
    ggplot(data=chart_data, aes_string(x=groupBy, y='sum', fill=factor(chart_data[[groupBy]])))  +
      geom_col() + scale_fill_manual(values = pal) +
      theme(legend.position='none') + 
      labs(title= 'Population by deprivation decile', x=paste(groupBy, '(1 = most deprived 10 = least deprived)'), y='population (thousands)') +
      scale_x_continuous(breaks = seq(1,10,1)) +
      scale_y_continuous(labels = scales::number_format(scale=.001, accuracy=1, suffix='K'))
  })
  
  
  # scatter plot for NO2 score against currently selected deprivation domain
  output$scatter <- renderPlot({
    
    var <- scr[[input$field_selector]]  # select correct score variable based on input
    
    ggplot(data=filteredData(), aes_string(y=var, x='NO2_men')) + geom_point(size=.1) + xlim(20,70) +
      labs(title='Mean NO2 and deprivation domain score', x='Mean NO2', y=var)
  })
  
  
  # observe function to update polygons based on data and NO2 range
  observe({
    
    # define variables
    colourBy <- input$field_selector
    df_live <- filteredData()
    
    # reverse colour palette for all variables other than NO2
    if(colourBy == 'NO2_men'){
      colour <- brewer.pal(9, clr[[colourBy]])
    } else{
      colour <- rev(brewer.pal(9, clr[[colourBy]]))
    }
    
    # create leaflet colour bin function using defined palette
    pal <- colorBin(colour, sf[[colourBy]], 9, pretty=FALSE)
    
    leafletProxy("map", data = df_live) %>%
      clearShapes() %>%
      clearControls() %>%
      addPolygons(stroke = TRUE,
                  color = '#919191',
                  weight = 1,
                  fillColor = pal(df_live[[colourBy]]),
                  fillOpacity = 0.5) %>%
      addLegend('bottomleft', pal = pal, values = sf[[colourBy]])
  })
  
}
