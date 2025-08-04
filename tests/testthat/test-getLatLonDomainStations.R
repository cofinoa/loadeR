# ============================
# Test: getLatLonDomainStations.R
# ============================

test_that("getLatLonDomainStations gets time index positions for loading ascii station data", {
  lons <- c(-6, -4, -2, 1, 3)
  lats <- c(37, 38, 39, 40, 41)

  # Point selection
  out_point <- getLatLonDomainStations(
    lonLim = -6, 
    latLim = 37, 
    lons = lons, 
    lats = lats
  )

  expect_type(out_point, "list") # The result should be a list
  expect_true(length(out_point) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out_point)))) # All elements should have names
  expect_true(all(c("stInd", "stCoords") %in% names(out_point))) # The list should have specific names

  expect_type(out_point$stInd, "integer") # stInd should be integer
  expect_true(is.matrix(out_point$stCoords)) # stCoords should be a matrix
  expect_equal(dim(out_point$stCoords), c(1, 2)) # stCoords should be a matrix of one row and two columns (lon, lat)

  # Bounding box selection
  out_box <- getLatLonDomainStations(
    lonLim = c(-5, 0), 
    latLim = c(36, 40), 
    lons = lons, 
    lats = lats
  )
  expect_type(out_box, "list")
  expect_true(length(out_box) > 0)
  expect_true(all(nzchar(names(out_box))))
  expect_true(all(c("stInd", "stCoords") %in% names(out_box)))
  expect_type(out_box$stInd, "integer")
  expect_equal(ncol(out_box$stCoords), 2)
  expect_equal(nrow(out_box$stCoords), length(out_box$stInd))

  # Different length lonLim (2) and latLim (1)
  expect_message({
    out_bb_lat1 <- getLatLonDomainStations(
      lonLim = c(-5, -4),
      latLim = 36,
      lons = lons,
      lats = lats
    )
  }, "Length of lonLim and latLim arguments are different")

  # Different length lonLim (1) and latLim (2)
  expect_message({
    out_bb_lon1 <- getLatLonDomainStations(
      lonLim = -5,
      latLim = c(36, 37),
      lons = lons,
      lats = lats
    )
  }, "Length of lonLim and latLim arguments are different")

  # Invalid definition: too long
  expect_error(getLatLonDomainStations(
    lonLim = c(-5, 0, 2),
    latLim = c(36, 37),
    lons = lons,
    lats = lats
  ), "Invalid definition of geographical position") 
})
