# ============================
# Test: getLatLonDomain.R
# ============================

test_that("getLatLonDomain determines the geo-location parameters of an arbitrary user selection", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'getLatLonDomain': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_multidim.nc")
  gds <- openDataset(nc_path)

  var <- "tas" # Select variable 
  grid <- gds$findGridByShortName(var) # Select grid for the variable (Java method)
  lonLim <- c(-10, 5) # Select geographic domain (longitude)
  latLim <- c(35, 45) # Select geographic domain (latitude)

  out <- getLatLonDomain(grid = grid, lonLim = lonLim, latLim = latLim, spatialTolerance = NULL)

  expect_type(out, "list") # The result should be a list
  expect_true(length(out) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out)))) # All elements should have names
  expect_true(all(c("llRanges", "llbbox", "pointXYindex", "xyCoords", "revLat", "ix") %in% names(out))) # The list should have specific names

  expect_type(out$xyCoords, "list") # xyCoords should be a list
  expect_true(all(c("x","y","resX","resY") %in% names(out$xyCoords))) # xyCoords should have specific names

  expect_type(out$pointXYindex, "integer") # pointXYindex should be integer vector
  expect_length(out$pointXYindex, 2) # pointXYindex should have length 2

  expect_type(out$llRanges, "list") # llRanges should be a list
  expect_true(all(sapply(out$llRanges, function(r) inherits(r, "jobjRef")))) # elements from llRanges should be java object references (jobjRef)

  expect_type(out$llbbox, "list") # llbbox should be a list
  expect_true(all(sapply(out$llbbox, function(b) is.null(b) || inherits(b, "jobjRef")))) # elements from llbbox should be java object references or jnull

  expect_type(out$revLat, "logical") # revLat should be logical

  # Spatial tolerance
  out <- getLatLonDomain(grid, lonLim = lonLim, latLim = latLim, spatialTolerance = 10)
  expect_type(out, "list")

  # Invalid geographical coordinates
  expect_error(getLatLonDomain(grid, c(-200, 10), c(30, 40)),
                "Invalid geographical coordinates")
  gds$close()

  # Reverse latitude selection 
  nc_path <- file.path(temp_dir, "test_reverselat.nc")
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")
  out <- getLatLonDomain(grid, lonLim = c(-3.6, -3.4), latLim = c(0.0, 2.0))
  expect_true(out$revLat)
  gds$close()

  # Dateline crossing  
  nc_path <- file.path(temp_dir, "test_crossdateline.nc")
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")
  out <- getLatLonDomain(grid, lonLim = c(175, -175), latLim = c(-10, 10))
  expect_length(out$llbbox, 2)
  expect_length(out$llRanges, 2)

  out <- getLatLonDomain(grid, lonLim = NULL, latLim = 0.0)
  expect_type(out, "list")
  expect_true(length(out$llbbox) >= 1)
  expect_true(all(sapply(out$llbbox, function(b) is.null(b) || inherits(b, "jobjRef"))))
  gds$close()

  # No resolution 
  nc_path <- file.path(temp_dir, "test_notime.nc")
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")
  out <- getLatLonDomain(grid, lonLim = -3.5, latLim = 40.0)
  expect_true(all(is.na(diff(out$xyCoords$x))))
  expect_true(all(is.na(diff(out$xyCoords$y))))
  
  # Latitude and longitude limits smaller than grid resolution
  expect_warning(getLatLonDomain(grid, lonLim = -3.5, latLim = c(30.0, 40.0)),
    "Requested latLim range is smaller than the grid resolution")
  gds$close()
})

test_that("adjustRCMgrid performs operations to adequately handle 2D XY axis (typically from RCMs))", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'adjustRCMgrid': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_rcmgrid.nc")
  gds <- openDataset(nc_path)

  var <- "tas"
  grid <- gds$findGridByShortName(var)
  lonLim <- c(0, 2)
  latLim <- c(40, 42)

  latLon <- getLatLonDomain(grid = grid, lonLim = lonLim, latLim = latLim)
  adjusted <- adjustRCMgrid(gds, latLon = latLon, lonLim = lonLim, latLim = latLim)

  expect_type(adjusted, "list")
  expect_true(length(adjusted) > 0)
  expect_true(all(nzchar(names(adjusted))))
  expect_true(all(c("xyCoords", "llRanges") %in% names(adjusted)))
  expect_true("lat" %in% names(adjusted$xyCoords))
  expect_true("lon" %in% names(adjusted$xyCoords))
  expect_true(all(dim(adjusted$xyCoords$lat) == dim(adjusted$xyCoords$lon)))
  expect_true(length(adjusted$llRanges) >= 1)
  expect_true(all(sapply(adjusted$llRanges, function(x) inherits(x, "jobjRef"))))

  # Point selection
  latLon <- getLatLonDomain(grid = grid, lonLim = 0.0, latLim = 40.0)
  adjusted <- adjustRCMgrid(gds, latLon = latLon, lonLim = 0.0, latLim = 40.0)

  expect_type(adjusted$xyCoords$lat, "double")
  expect_type(adjusted$xyCoords$lon, "double")
  expect_length(adjusted$xyCoords$x, 1)
  expect_length(adjusted$xyCoords$y, 1)
  expect_true(adjusted$pointXYindex[1] == -1L && adjusted$pointXYindex[2] == -1L)

  # Null limits
  lonLim <- NULL
  latLim <- NULL

  latLon <- getLatLonDomain(grid = grid, lonLim = lonLim, latLim = latLim)
  adjusted <- adjustRCMgrid(gds, latLon = latLon, lonLim = lonLim, latLim = latLim)

  expect_type(adjusted, "list")
  expect_true(all(c("xyCoords", "llRanges") %in% names(adjusted)))
  expect_true(is.list(adjusted$xyCoords))
  expect_true("lat" %in% names(adjusted$xyCoords))
  expect_true("lon" %in% names(adjusted$xyCoords))
  expect_true(all(dim(adjusted$xyCoords$lat) == dim(adjusted$xyCoords$lon)))
  expect_true(length(adjusted$llRanges) >= 1)
  expect_true(all(sapply(adjusted$llRanges, function(x) inherits(x, "jobjRef"))))

  # Fixed lonLim 
  lonLim <- 1  
  latLim <- c(40, 42) 

  latLon <- getLatLonDomain(grid = grid, lonLim = lonLim, latLim = latLim)
  adjusted <- adjustRCMgrid(gds, latLon = latLon, lonLim = lonLim, latLim = latLim)

  expect_type(adjusted, "list")
  expect_true(all(c("xyCoords", "llRanges") %in% names(adjusted)))
  expect_equal(dim(adjusted$xyCoords$lat), dim(adjusted$xyCoords$lon))
  expect_true(adjusted$pointXYindex[2] == -1L) 
  expect_true(all(sapply(adjusted$llRanges, function(x) inherits(x, "jobjRef"))))

  # Fixed latLim
  lonLim <- c(0, 2)  
  latLim <- 41  

  latLon <- getLatLonDomain(grid = grid, lonLim = lonLim, latLim = latLim)
  adjusted <- adjustRCMgrid(gds, latLon = latLon, lonLim = lonLim, latLim = latLim)

  expect_type(adjusted, "list")
  expect_true(all(c("xyCoords", "llRanges") %in% names(adjusted)))
  expect_equal(dim(adjusted$xyCoords$lat), dim(adjusted$xyCoords$lon))
  expect_true(adjusted$pointXYindex[1] == -1L)  # La dimensión Y (lat) no es punto
  expect_true(all(sapply(adjusted$llRanges, function(x) inherits(x, "jobjRef"))))

  gds$close()
})
