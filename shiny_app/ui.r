
ui <- fluidPage(

  fluidRow(
    
    column(9,
             leafletOutput(outputId = 'map', height=820, width=1600)
    ),
    
    column(3,
           wellPanel(
             
             h3('Display Controls'),
             h6('These control the LSOAs which are shown on the map'),
             
             sliderInput('NO2_slider', label = h5('NO2 Level'), 20, 70,
                         value = c(40, 70), step = 1),
             
             checkboxGroupInput("london_area", label = h5("London Areas"), 
                                choices = list("Inner" = 'inner', "Outer" = 'outer'),
                                selected = c('inner','outer')),
             
             # selectInput('lad_selector', label = h5('Local Authority District'),
             #             choices = c('All', levels(sf$LAD17NM)), 
             #             selected = 'All'),
             
             h3('Data Controls'),
             h6('Use to change the deprivation domain shown on the map and charts, or show NO2 on the map'),
             
             selectInput('field_selector', label = h5('Select variable'), 
                         choices = list('Mean NO2' = 'NO2_men', 
                                        'Index of Multiple Deprivation (IMD)' = 'imd_dcl',
                                        'IMD - income' = 'incm_dc',
                                        'IMD - employment' = 'emplymnt_d',
                                        'IMD - education' = 'edctn_d',
                                        'IMD - health' = 'hlth_dc',
                                        'IMD - crime' = 'crm_dcl',
                                        'IMD - housing barriers' = 'hsng_dc',
                                        'IMD - living environment' = 'lvng_dc'), 
                         selected = 'NO2_men'),
             
             plotOutput('scatter', height = 150),
             plotOutput('barMD', height = 150)
           )))

  )

  
