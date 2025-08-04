# ============================
# Test: makeSubset.decadal.R
# ============================

test_that("makeSubset.decadal makes a logical subset of a System4 GeoGrid", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'makeSubset.decadal': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_runtime.nc")  
  dic_path <- file.path(temp_dir, "test.dic") 

  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")

  # Dictionary entry for the variable
  dic <- dictionaryLookup(dic_path, var = "tas", time = "DD")

  # Runtime parameters (seasonal forecast)
  runTimePars <- getRunTimeDomain.seasonal(
    dataset = nc_path, grid = grid, season = 1:3, years = 1980:1980, leadMonth = 0
  )

  # Forecast time parameters
  foreTimePars <- getForecastTimeDomain(
    grid = grid, dataset = nc_path, dic = dic,
    runTimePars = runTimePars, time = "DD", aggr.d = "mean", aggr.m = "mean"
  )

  # Spatial domain
  latLon <- getLatLonDomain(grid, lonLim = c(-10, 5), latLim = c(35, 45))

  # Ensemble members
  memberRangeList <- getMemberDomain(grid, members = 1, continuous = FALSE)

  # Vertical level
  verticalPars <- getVerticalLevelPars(grid, level = NULL)

  result <- makeSubset.decadal(
    grid = grid,
    latLon = latLon,
    runTimePars = runTimePars,
    memberRangeList = memberRangeList,
    foreTimePars = foreTimePars,
    verticalPars = verticalPars
  )

  expect_type(result, "list")
  expect_true(all(c("mdArray", "foreTimePars") %in% names(result)))

  expect_true(is.array(result$mdArray))
  expect_true(!is.null(attr(result$mdArray, "dimensions")))
  expect_true("time" %in% attr(result$mdArray, "dimensions"))

  expect_true("forecastDates" %in% names(result$foreTimePars))
  expect_true(is.list(result$foreTimePars$forecastDates))

  gds$close()
})