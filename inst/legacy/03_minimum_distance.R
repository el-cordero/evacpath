### Function: Minimum Distance
### This function calculates the minimum 'distance to safety'

# requires:
# library: terra, leastcostpath

# cs <- leastcostpath conductance matrix
# origins <- road points
# destinations <- escape points/locations


min_dist <- function(cs, origins, destinations){
  
  # first, make sure that the origin and destination are location within the same extent
  # as the conductance surface
  cs_rast <- rasterise(cs) # cs raster
  
  # the cs projection is the same, but changes format from the original dem projection
  # to avoid issues, reproject to the newly formatted cs crs
  origins <- project(origins,crs(cs_rast)) 
  destinations <- project(destinations,crs(cs_rast)) 
  
  # crop to cs extent
  destinations <- crop(destinations, cs_rast, ext=TRUE) 
  
  # loop through origins to get minimum distance from any destinations
  minDist <- data.frame() # empty df
  for (i in 1:length(origins)){
    # run the lcp analysis
      lc.paths <- create_lcp(cs,origin=origins[i],destinations)
      lc.paths <- perim(lc.paths) # return vector of distance
      lc.paths <- lc.paths[lc.paths != 0] # remove zero values
      lc.paths <- min(lc.paths) # calculate the minimum distance
      # add the results to minDist
      if (lc.paths != Inf){
        minDist[i,1:3] <- c(geom(origins[i])[,c('x','y')],lc.paths)
      }
  }

  # data cleaning
  minDist <- na.omit(minDist) # remove NA rows
  names(minDist) <- c('x','y','distance')
  minDist$type <- 'road'
  
  # add destinations to minDist (distance = 0)
  escapeDist <- data.frame(geom(destinations)[,c('x','y')],
                            distance = 0, type = 'escape')
  minDist <- rbind(minDist, escapeDist)
  
  # return a spatvector object
  minDist <- vect(minDist, geom=c("x", "y"), crs=crs(origins))
  
  return(minDist)
}

