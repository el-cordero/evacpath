### Function: Calculate Minimum Distance
### This function calculates the minimum distance from a list of line-type vectors
### generated from calculate_lc_path

# requires:
# library: terra, leastcostpath

# lc_paths_list <- list of line vectors 

calculate_min_dist <- function(lc_paths_list){
    lc_paths <- vect(lc_paths_list)
    lc_paths_perim <- perim(lc_paths) # return vector of distance
    lc_paths_perim <- lc_paths_perim[!is.infinite(lc_paths_perim)]
    lc_paths_perim <- lc_paths_perim[lc_paths_perim != 0]
    min_dist <- min(lc_paths_perim) 
    return(min_dist)
}