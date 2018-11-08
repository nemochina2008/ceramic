fast_merge <- function(x) {
  ## about 3 times faster than reduce(, merge)
  out <- raster::raster(purrr::reduce(purrr::map(x, raster::extent), raster::union), crs = raster::projection(x[[1]]))
  raster::res(out) <- raster::res(x[[1]])
  cells <- unlist(purrr::map(x, ~raster::cellsFromExtent(out, .x)))
  vals <- do.call(rbind, purrr::map(x, ~values(readAll(.x))))
  setValues(brick(out, out, out), vals[order(cells), ])
}

#' Miscellaneous places
#'
#' Visit some nice locales with web tiles.
#'
#' * `cc_macquarie` Macquarie Island
#'
#' @param buffer with in metres to extend around the location
#' @param ...
#' @param debug optionally print out files that will be used
#'
#' @return RasterBrick, with RGB
#' @export
#' @name ceramic_locale
#' @examples
#' im <- cc_macquarie()
#' library(raster)
#' plotRGB(im)
cc_macquarie <- function(buffer = 5000, type = "mapbox.outdoors", ..., debug = FALSE) {
  loc <- cbind(158.93835,
               -54.49871)
  get_loc(loc, buffer)
}

#' @name ceramic_locale
#' @export
cc_davis <- function(buffer = 5000, type = "mapbox.outdoors", ..., debug = FALSE) {
#  68°34′36″S 77°58′03″E
  loc <- cbind(77 + 58/60 + 3/3600,
               -(68 + 34/60 + 36/3600))
  get_loc(loc, buffer, ..., debug = debug)

}
#' @name ceramic_locale
#' @export
cc_mawson <- function(buffer = 5000, type = "mapbox.outdoors", ..., debug = FALSE) {
  # 67°36′12″S 62°52′27″E
  loc <- cbind(62 + 52/60 + 27/3600,
               -(67 + 36/60 + 12/3600))
  get_loc(loc, buffer, ..., debug = debug)

}

#' @name ceramic_locale
#' @export
cc_casey <- function(buffer = 5000, type = "mapbox.outdoors", ..., debug = FALSE) {
  #66°16′57″S 110°31′36″E
  loc <- cbind(110 + 31/60 + 36/3600,
               -(66 + 16/60 + 57/3600))
  get_loc(loc, buffer, ..., debug = debug)

}
#' @name ceramic_locale
#' @export
cc_heard <- function(buffer = 5000, type = "mapbox.outdoors",..., debug = FALSE) {
#  53°S 73°30’E.
  loc <- cbind(73 + 30/60 + 30/3600,
               -(53 + 0 + 0/3600))
  get_loc(loc, buffer, ..., debug = debug)

}
#' @name ceramic_locale
#' @export
cc_kingston <- function(buffer = 5000, type = "mapbox.outdoors", ..., debug = FALSE) {
  loc <- cbind(-147.70837,
               -42.98682)
  get_loc(loc, buffer, type = type, ..., debug = debug)

}
get_loc <- function(loc, buffer, type = "mapbox.outdoors", ..., debug = debug) {
  if (length(buffer) == 1) buffer <- rep(buffer, 2)
  xp <- buffer[1] / (1852 * 60) / cos(loc[1, 2, drop = TRUE] * pi/180)
  yp <- buffer[2] / (1852 * 60)

  my_bbox <- structure(c(xmin = loc[1] - xp, ymin = loc[2] - yp,
              xmax = loc[1] + xp, ymax = loc[2] + yp), crs = structure(list(epsg = 4326,
                                                                              proj4string = "+proj=longlat +ellps=WGS84 +no_defs"), class = "crs"), class = "bbox")
  tile_grid <- slippymath:::bb_to_tg(my_bbox, max_tiles = 36)
  zoom <- tile_grid$zoom

  mapbox_query_string <-
    paste0(sprintf("https://api.mapbox.com/v4/%s/{zoom}/{x}/{y}.jpg90", type),
           "?access_token=",
           Sys.getenv("MAPBOX_API_KEY"))

  files <- down_loader(tile_grid, mapbox_query_string, debug = debug)
  br <- lapply(files, raster::brick)

  for (i in seq_along(br)) {
    br[[i]] <- raster::setExtent(br[[i]],
                         mercator_tile_extent(tile_grid$tiles$x[i], tile_grid$tiles$y[i], zoom = zoom))
  }

  fast_merge(br)
}