# ============================
# Test: dictionaryTransformForecast.R
# ============================

test_that("dictionaryTransformForecast performs variable transformation according to dictionary specifications", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'dictionaryTransformForecast': 'ncgen' is not available on system")

  nc_path <- testthat::test_path("testdata", "test_levelxy_subdaily.nc") 
  dic_path <- testthat::test_path("testdata", "test.dic") 

  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")

  dic_entry <- dictionaryLookup(dic_path, var = "tas", time = "DD")

  timePars <- getTimeDomain(
    grid = grid,
    dic = dic_entry,
    season = 6:8,
    years = 1981:1981,
    time = "DD",
    aggr.d = "none",
    aggr.m = "none",
    threshold = NULL,
    condition = NULL
  )
  levelPars <- getVerticalLevelPars(grid, level = 850)
  latLon <- getLatLonDomain(grid, lonLim = c(-10, 5), latLim = c(35, 45))
  memberPars <- rJava::.jnull() # No ensemble members

  # Get raw mdArray in Kelvin
  mdArray <- makeSubset(grid, timePars, levelPars, latLon, memberPars)$mdArray

  # Apply transformation using scale and offset (K -> °C)
  transformed <- dictionaryTransformForecast(dic_entry, mdArray)

  # Expected output
  expected <- mdArray * dic_entry$scale + dic_entry$offset

  # Check correctness
  expect_equal(dim(transformed), dim(mdArray))
  expect_equal(transformed, expected)

  gds$close()
})