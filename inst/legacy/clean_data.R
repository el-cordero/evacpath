library(terra)
tsunami <- rast("_data/raw/inundation.nc")
dem <- rast("_data/raw/topo.nc")
roads <- vect("_data/raw/road.shp")


dem <- -dem
land <- ifel(dem > 0, 1, NA)
water <- ifel(dem < 0, 1, NA)
tsunami <- resample(tsunami, land)
tsunami <- mask(tsunami, land)
tez <- ifel(tsunami > 0, 1, NA)
tez_vector <- as.polygons(tez)

tez <- mosaic(tez,water)

plot(water, col = "lightblue", legend=FALSE,box=FALSE,axes=FALSE)
plot(land, col="darkgreen",add=TRUE, legend=FALSE)
plot(tez_vector, col="red", add=TRUE, legend=FALSE)
plot(roads,add=TRUE)

roads <- roads[!(roads$man_made %in% "pier"),]
# roads_locs <- as.points(roads)

writeRaster(tsunami, "_data/tsunami_inundation_depth.tif", overwrite=TRUE)
writeRaster(tez, "_data/tsunami_inundation_zone.tif", overwrite=TRUE)
writeRaster(dem,"_data/dem.tif", overwrite=TRUE)
writeRaster(land,"_data/land.tif", overwrite=TRUE)
writeVector(roads,"_data/rds.gpkg", overwrite=TRUE)
# writeVector(roads_locs,"_data/rds_locs.gpkg", overwrite=TRUE)
writeVector(tez_vector,"_data/tez.gpkg",overwrite=TRUE)
