# ============================
# Test: makeSubset.R
# ============================

test_that("makeSubset reads an arbitrary data slice", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'makeSubset': 'ncgen' is not available on system")

  # Fixed latitude and longitude limits with monthly aggregation
  nc_path <- testthat::test_path("testdata", "test_levelxy.nc") 
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")

  levelPars <- getVerticalLevelPars(grid, level = 850)
  timePars <- getTimeDomain(
    grid = grid,
    dic = NULL,
    season = 6:8,
    years = 1981:1981,
    time = "none",
    aggr.d = "none",
    aggr.m = "mean",
    threshold = 290,
    condition = "LE"
  )
  latLon <- getLatLonDomain(grid, lonLim = -3.5, latLim = 40.0) 
  expect_equal(latLon$pointXYindex[1] >= 0, TRUE)
  expect_equal(latLon$pointXYindex[2] >= 0, TRUE)

  out <- makeSubset(
    grid = grid,
    timePars = timePars,
    levelPars = levelPars,
    latLon = latLon,
    memberPars = NULL
  ) 
  expect_type(out, "list") # The result should be a list
  expect_true(length(out) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out)))) # All elements should have names
  expect_true(all(c("timePars", "mdArray") %in% names(out))) # The list should have specific names
  gds$close()

  # Fixed latitude and longitude limits with daily aggregation
  nc_path <- testthat::test_path("testdata", "test_levelxy_subdaily.nc") 
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")

  levelPars <- getVerticalLevelPars(grid, level = 850)
  timePars <- getTimeDomain(
    grid = grid,
    dic = NULL,
    season = 6:8,
    years = 1981:1981,
    time = "none",
    aggr.d = "mean",
    aggr.m = "none",
    threshold = NULL,
    condition = NULL
  )
  latLon <- getLatLonDomain(grid, lonLim = -3.5, latLim = 40.0)

  out <- makeSubset(
    grid = grid,
    timePars = timePars,
    levelPars = levelPars,
    latLon = latLon,
    memberPars = NULL
  )
  expect_type(out, "list") 
  gds$close()

  # Fixed latitude limit 
  nc_path <- testthat::test_path("testdata", "test_level.nc") 
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")

  levelPars <- getVerticalLevelPars(grid, level = 850)
  timePars <- getTimeDomain(
    grid = grid,
    dic = NULL,
    season = 6:8,
    years = 1981:1981,
    time = "none",
    aggr.d = "none",
    aggr.m = "none",
    threshold = NULL,
    condition = NULL
  )
  latLon <- getLatLonDomain(grid, lonLim = c(-3.5, -2.5), latLim = 40.0)
  expect_equal(latLon$pointXYindex[1] >= 0, FALSE)
  expect_equal(latLon$pointXYindex[2] >= 0, TRUE)

  out <- makeSubset(
    grid = grid,
    timePars = timePars,
    levelPars = levelPars,
    latLon = latLon,
    memberPars = NULL
  )
  expect_type(out, "list") 
  gds$close()
})
