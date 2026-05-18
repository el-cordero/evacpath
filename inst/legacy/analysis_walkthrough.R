funcs <- c(
  "_scripts/00_evacuation_grid.R",
  "_scripts/01_region_area.R",
  "_scripts/02_escape_points.R",
  "_scripts/03_calc_lc_path.R",
  "_scripts/03_calc_min_distance.R",
  "_scripts/03_minimum_distance.R",
  "_scripts/04_distance_grid.R",
  "_scripts/05_pea.R"
)
for (i in funcs){
  source(i)
}

library(terra)
library(leastcostpath)

tez <- vect("_data/tez.gpkg")
inundation <- rast("_data/tsunami_inundation_zone.tif")
inundation <- as.polygons(inundation)
dem <- rast("_data/dem.tif")
land <- rast("_data/land.tif")
roads <- vect("_data/rds.gpkg")
road_locs <- vect("_data/rds_locs.gpkg")

crs_jak <- "EPSG:32748"
tez <- project(tez,crs_jak)
inundation <- project(inundation,crs_jak)
dem <- project(dem,crs_jak)
land <- project(land,crs_jak)
roads <- project(roads,crs_jak)
road_locs <- project(road_locs, crs_jak)

working_res <- res(dem)*5

evac_grid <- evacuation_grid(inundation,working_res)
writeVector(evac_grid,"_data/evac_grid.gpkg", overwrite=TRUE)

escape_locs <- escape_points(inundation,roads)

plot(evac_grid,col="gray")
plot(tez,col="blue",add=TRUE)
plot(roads,add=TRUE)
plot(escape_locs,col="red",add=TRUE)
writeVector(escape_locs,"_data/evac_points.gpkg", overwrite=TRUE)


# create escape areas within 5 meters of the escape points
escape_buffer <- buffer(escape_locs,5)
escape_buffer <- aggregate(escape_buffer)

roads_buffer <- buffer(roads, 2)
roads_buffer <- aggregate(roads_buffer)

roads_mask <- vect(c(roads_buffer,escape_buffer))
roads_mask <- aggregate(roads_mask)
writeVector(roads_mask,"_data/dem_roads_mask_lyr.gpkg",overwrite=TRUE)

# merge the escape area to the roads
dem_roads <- mask(dem,roads_mask)

# conductance matrix for least cost path analysis
cs <- create_slope_cs(dem_roads)

# create a grid evac zone
# convert the road network into points
road_points <- mask(evac_grid,roads_buffer)
road_points <- intersect(road_points, roads_buffer)
road_points <- as.points(as.lines(road_points))
writeVector(road_points,"_data/rds_locs_analysis.gpkg", overwrite=TRUE)

extract a random sample from the road points
fraction <- 2000
if(fraction < length(road_points)){
  set.seed(23401)
  road_points_ltd <- sample(road_points,fraction)
  print("Fraction used.")
}


# least cost path analysis
min_dist_points <- min_dist(cs, road_points_ltd, escape_locs)

# crop by the study area
# min_dist_points <- crop(min_dist_points,buffer(area.study,10))

municipality <- "Jakarta"
# voronai polygons
v <- voronoi(min_dist_points)
v$time <- as.numeric(v$distance) * (1/1.22) * (1/60)
v$muni <- municipality
v <- v[,c('muni','distance','time')]
names(v) <- c("Municipio","DistToSafety","EvacTimeAvg")

roads_inundation <- crop(buffer(roads_buffer,3),inundation)
roads_inundation <- vect(c(roads_inundation,tez))
roads_inundation <- aggregate(roads_inundation)
writeVector(roads_inundation, "_data/tsunami_inundation_zone_final.gpkg", overwrite=TRUE)

v <- crop(v,roads_inundation)

plot(v,"DistToSafety")
plot(v,"EvacTimeAvg")

writeVector(min_dist_points,"_data/jakartaPEAT_points.gpkg", overwrite=TRUE)
writeVector(v, "_data/jakartaPEAT_voronai.gpkg", overwrite=TRUE)


