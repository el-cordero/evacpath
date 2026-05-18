### Function: Distance Grid
### This function calculates a 'distance to safety' grid

# requires:
# library: terra, fields

# rds <- rds
# escape.pnts <- escape points/locations
# area.study <- study area
# area.region <- greater area
# res.1 <- low resolution (default = 100)
# res.2 <- high resolution (default = 1)
# crs <- coordinate reference system

distance_grid <- function(minDist.pnts,area.region,area.study,res.1,res.2){
  # crop roads to region area
  # rasterize the road points, using the distance attribute
  r.1 <- rast(resolution=res.1,crs=crs(minDist.pnts),extent=ext(area.region))
  dist.grid <- rasterize(minDist.pnts,r.1,'distance')

  # thin plate spline regression for kriging/interpolation
  xy <- data.frame(xyFromCell(dist.grid, 1:ncell(dist.grid)))
  v <- values(dist.grid)
  i <- !is.na(v)
  xy <- xy[i,]
  v <- v[i]
  tps <- Tps(xy, v)

  # needs to convert to default filetype (again)
  # this is required
  dist.grid <- rast(dist.grid)
  dist.grid <- terra::project(dist.grid,crs(minDist.pnts))

  # use model to predict values at all locations
  dist.grid <- interpolate(dist.grid, tps)
  
  # remove the values lower than 0, which are outside the study area
  dist.grid[dist.grid < 0] <- 0## Not run:
  
  # resample the dataset to project resolution
  r.2 <- rast(resolution=res.2,crs=crs(minDist.pnts),extent=ext(area.region))
  dist.grid <- resample(dist.grid,r.2)
  
  dist.grid <- crop(dist.grid,area.study)
  dist.grid <- mask(dist.grid,area.study)

  return(dist.grid)
}
