
library(sf)
library(tmap)
library(rgdal)
library(tidyverse)


NO2 <- read_csv('DATA/inputs/PostLAEI2013_2013_NO2.csv')
NO2_sf <- st_as_sf(NO2, coords=c('x', 'y'), crs=st_crs(27700)$proj4string) 


oa_ref <- read_csv('DATA/inputs/Output_Area_to_Lower_Layer_Super_Output_Area_to_Middle_Layer_Super_Output_Area_to_Local_Authority_District_December_2017_Lookup_in_Great_Britain__Classification_Version_2.csv')
lsoa_lon <- filter(oa_ref, RGN11NM == 'London') %>% select(LSOA11CD, LAD17CD, LAD17NM) %>% distinct()


lsoa <- st_read('DATA/inputs/LSOA/Lower_Layer_Super_Output_Areas_December_2011_Generalised_Clipped__Boundaries_in_England_and_Wales.shp')
lsoa <- inner_join(lsoa, lsoa_lon, by=c('lsoa11cd'='LSOA11CD'))
lsoa <- st_transform(lsoa, 27700)

lsoa_gen <- st_read('DATA/inputs/LSOA_gen/Lower_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped__Boundaries_in_England_and_Wales.shp')
lsoa_gen <- inner_join(lsoa_gen, lsoa_lon, by=c('lsoa11cd'='LSOA11CD'))
lsoa_gen <- st_transform(lsoa_gen, 27700)



# LOOP INPUTS
LADs <- distinct(filter(oa_ref, RGN11NM == 'London'), LAD17NM) # distinct list of all LADs in London, to loop through
final_output_df <- data.frame() # empty frame to load data into

# loop through LADs
for (lad in seq(1, nrow(LADs))) {

  print(paste('PROCESSING DATA FOR: ', LADs$LAD17NM[lad]))
  
  # filter LSOA sf to just current LAD
  working_lsoa_sf <- (filter(lsoa, LAD17NM == LADs$LAD17NM[lad]))
  
  print('- creating subset of NO2 data')
  # create temporary sf of just NO2 points in current LAD, for faster processing
  working_NO2_index <- st_contains(st_union(working_lsoa_sf), NO2_sf, sparse = T)
  working_NO2_sf <-  NO2_sf[working_NO2_index[[1]],]
  
  # create matrix to store output for each LAD
  out_matrix <- matrix(ncol=6, nrow=nrow(working_lsoa_sf))
  
  # 
  LAD17NM <- working_lsoa_sf$LAD17NM[[1]]
  
  # loop through lsoas in the current LAD and work out NO2 scores
  for (i in seq(1, nrow(working_lsoa_sf))){  #nrow(working_lsoa_sf)
    
    index <- st_contains(working_lsoa_sf[i,1], working_NO2_sf, sparse=T)
    points <- working_NO2_sf[index[[1]],] %>% st_set_geometry(NULL)
    
    lsoa11cd <- working_lsoa_sf$lsoa11cd[[i]]
    NO2_count <- nrow(points)
    NO2_mean <- mean(points[['conct']])
    NO2_max  <- max(points[['conct']])
    NO2_min  <- min(points[['conct']])
    
    try(
      out_matrix[i,] <- c(LAD17NM, lsoa11cd, NO2_count, NO2_mean, NO2_max, NO2_min)
    )
    
    # if (i %% 50 == 0 ){
    # print(paste('-- loaded result no.', i, 'out of', nrow(working_lsoa_sf), ' - ', round(i/nrow(working_lsoa_sf)*100), '% complete'))
    # }
  }
  
  print(paste('- NO2 calculations complete for: ', LADs$LAD17NM[lad]))
  
  # load LAD output into a dataframe and name columns
  output_df <- data.frame(out_matrix)
  names(output_df) <- c('LAD17NM', 'lsoa11cd', 'NO2_count', 'NO2_mean', 'NO2_max', 'NO2_min')
  
  # write LAD output to its own file
  filename <- paste('DATA/outputs/', LADs$LAD17NM[lad], '_output.csv', sep='')
  write_csv(output_df, filename)
  
  # if it's the first LAD turn into to final_output, else join to existing final_output
  if (lad == 1){
    final_output_df <- output_df
  } else {
    final_output_df <- rbind(final_output_df, output_df)
  }
  
  # write final_output table to csv
  write_csv(final_output_df, 'DATA/outputs/LAD_all_output.csv')
  print('- all data loaded to output table')
}


# read in existing output data and all other files 
# (comment out first line if running for the first time)
final_output_in <- read_csv('DATA/outputs/LAD_all_output.csv')
imd_data <- read_csv('DATA/inputs/ID_2015_london.csv')
pop_data <- read_csv('DATA/inputs/london-atlas-data-formatted.csv')
london_area <- read_csv('DATA/inputs/LAD17NM_inner_outer.csv')

# names(final_output_in)



lsoa_NO2 <- left_join(lsoa_gen, select(final_output_in, -LAD17NM), by='lsoa11cd') %>%
  left_join(imd_data, by='lsoa11cd') %>%
  left_join(select(pop_data, -Names), by='lsoa11cd') %>%
  left_join(london_area, by='LAD17NM')

st_write(lsoa_NO2, 'DATA/outputs/london_lsoa_NO2_gen/london_lsoa_NO2_gen.shp')
