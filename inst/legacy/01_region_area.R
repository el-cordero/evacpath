### Function: Region Area
### This function creates a buffer around the evacuation zone
### in order to include evacuation points outside the municipality
### for a more accurate distance analysis.

# requires:
# library: terra

### area.evac <- the entire evacuation zone (zono de desalojo)
### area.study <- the evacuation zone for the municipality

region_area <- function(area.evac, area.study){
  area.region <- aggregate(area.evac,dissolve=TRUE)
  buff <- buffer(area.study, 5000)
  buff <- aggregate(buff,dissolve=TRUE)
  area.region <- crop(area.region,buff)
  area.region <- erase(area.region)
  return(area.region)
}

