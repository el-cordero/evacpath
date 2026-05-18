### Function: Evacuation Grid
### This function creates an evacuation grid from the evacuation zone

# requires:
# library: terra

### area.evac <- the evacuation zone (zono de desalojo)
### res <- the resoution of each evacuation grid

evacuation_grid <- function(area.evac, res){
  grid.r <- rast(ext=ext(area.evac),crs=crs(area.evac),resolution=res)
  grid.p <- as.polygons(grid.r)
  
  # municipalities <- sort(unique(area.evac$Municipio)) 
  # grid <- crop(grid.p, area.evac,ext=TRUE)
  grid <- mask(grid.p, area.evac)

  return(grid)
}

