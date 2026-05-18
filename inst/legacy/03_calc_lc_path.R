### Function: Calculate Least Cost Path
### This function calculates the least cost path if the destination can be
### reached from the origin via the conductance surface 

# requires:
# library: terra, leastcostpath

# cs <- leastcostpath conductance matrix
# origin <- origin point
# destination <- destination point

calculate_lc_path <- function(cs, origin, destination){
    lc_path <- tryCatch(
        {
        create_lcp(x = cs, origin = origin,
        destination = destination,check_locations = TRUE)
    },  error = function(e) {return(NULL)}
    )
    if (is.null(lc_path) == FALSE){
        return(lc_path)
    }
}



