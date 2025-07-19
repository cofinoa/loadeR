# ============================
# Test: findPointXYindex.R
# ============================

test_that("findPointXYindex finds the XY index position", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'findPointXYindex': 'ncgen' is not available on system")
  
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_levelxy.nc")
  gds <- openDataset(nc_path)

  var <- "tas"
  grid <- gds$findGridByShortName(var)
  gcs <- grid$getCoordinateSystem()

  # Null lonLim
  out <- findPointXYindex(lonLim = NULL, latLim = 40.0, gcs = gcs, spatialTolerance = NULL)
  expect_true(out$pointXYindex[2] >= 0)
  expect_equal(out$pointXYindex[1], -1)

  # Null latLim
  out <- findPointXYindex(lonLim = -3.5, latLim = NULL, gcs = gcs, spatialTolerance = NULL)
  expect_true(out$pointXYindex[1] >= 0)
  expect_equal(out$pointXYindex[2], -1)

  # Non-existent longitude
  expect_error(
    findPointXYindex(lonLim = -10, latLim = 40.0, gcs = gcs, spatialTolerance = NULL),
    "Selected X point coordinate is out of range"
  )

  # Non-existent latitude
  expect_error(
    findPointXYindex(lonLim = -3.5, latLim = 50, gcs = gcs, spatialTolerance = NULL),
    "Selected Y point coordinate is out of range"
  )

  # Spatial tolerance: adjust to lat max
  out <- findPointXYindex(lonLim = -3.5, latLim = 41.4, gcs = gcs, spatialTolerance = 0.5)
  expect_equal(out$pointXYindex, c(0L, 1L))

  # Spatial tolerance: adjust to lat min
  out <- findPointXYindex(lonLim = -3.5, latLim = 39.6, gcs = gcs, spatialTolerance = 0.5)
  expect_equal(out$pointXYindex, c(0L, 0L))

  # Spatial tolerance: adjust to lon max
  out <- findPointXYindex(lonLim = -3.3, latLim = 40.0, gcs = gcs, spatialTolerance = 0.2)
  expect_equal(out$pointXYindex, c(1L, 0L))

  # Spatial tolerance: adjust to lon min
  out <- findPointXYindex(lonLim = -4.0, latLim = 40.0, gcs = gcs, spatialTolerance = 0.6)
  expect_equal(out$pointXYindex, c(0L, 0L))

  # Spatial tolerance: adjust to lon max with length > 1
  out <- findPointXYindex(lonLim = c(-3.3, -3.4), latLim = 40.0, gcs = gcs, spatialTolerance = 0.2)
  expect_equal(out$pointXYindex[2], 0L)

  # Spatial tolerance: adjust to lon min with length > 1
  out <- findPointXYindex(lonLim = c(-4.0, -4.1), latLim = 40.0, gcs = gcs, spatialTolerance = 0.6)
  expect_equal(out$pointXYindex[2], 0L)

  gds$close()
})