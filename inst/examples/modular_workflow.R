# Modular evacpath workflow --------------------------------------------------
# Use this when you want full control over each geoprocessing step.

library(terra)
library(evacpath)

zones <- prepare_tsunami_zones(
  inundation = "_data/tsunami_inundation_depth.tif",
  dem = "_data/dem.tif",
  target_crs = "EPSG:32748"
)

roads <- clean_roads(
  "_data/rds.gpkg",
  exclude = list(field = "man_made", values = "pier"),
  target_crs = "EPSG:32748"
)

roads_for_escape <- crop_roads_to_inner_extent(
  roads = roads,
  zone = zones$escape_zone,
  inset_x_m = 250,
  inset_y_m = 250
)

escape_boundary_zone <- make_road_aware_escape_zone(
  escape_zone = zones$escape_zone,
  roads = roads_for_escape,
  road_buffer_m = 2,
  crop_buffer_m = 3
)

grid <- make_evac_grid(zones$hazard_zone, resolution = terra::res(zones$dem) * 50)

escape <- find_escape_points(escape_boundary_zone, roads_for_escape)

mask_parts <- make_road_mask(
  roads = roads,
  escape_points = escape,
  road_buffer_m = 2,
  escape_buffer_m = 5,
  return_components = TRUE
)

origins <- make_road_origins(
  evac_grid = grid,
  roads_buffer = mask_parts$roads_buffer,
  max_origins = 25,
  seed = 23401
)

cs <- make_conductance_surface(
  dem = zones$dem,
  road_mask = mask_parts$mask,
  resolution = terra::res(zones$dem) * 50
)

dist_pts <- calc_min_distance_to_safety(
  cs = cs,
  origins = origins,
  destinations = escape,
  progress = TRUE,
  progress_every = 1,
  check_locations = FALSE
)

polys <- make_evac_polygons(
  distance_points = dist_pts,
  clip_area = zones$hazard_zone,
  walking_speed_mps = 1.22,
  region_name = "Study area"
)
