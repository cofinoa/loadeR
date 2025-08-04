# ============================
# Test: getForecastTimeDomain.R
# ============================

test_that("getForecastTimeDomain computes time parameters for forecast datasets", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'getForecastTimeDomain': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_runtime.nc") 
  dic_path <- file.path(temp_dir, "test.dic")
  
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")
  
  dic <- dictionaryLookup(dic_path, var = "tas", time = "DD")
  
  runTimePars <- getRunTimeDomain.seasonal(
    dataset = nc_path,
    grid = grid,
    members = NULL,
    season = 1:3,
    years = 1980:1982, 
    leadMonth = 0
  )
  
  out <- getForecastTimeDomain(
    grid = grid,
    dataset = nc_path,
    dic = dic,
    runTimePars = runTimePars,
    time = "none",
    aggr.d = "mean",
    aggr.m = "none"
  )
  
  expect_type(out, "list")
  expect_true(all(c("forecastDates", "ForeTimeRangesList", "deaccum", "aggr.d", "aggr.m") %in% names(out)))
  expect_true(is.list(out$forecastDates))
  expect_true(is.list(out$ForeTimeRangesList))
  expect_true(is.logical(out$deaccum))
  expect_equal(out$aggr.d, "mean")
  expect_equal(out$aggr.m, "none")
  
  gds$close()

  # Sub-daily with daily aggregation 
  nc_path_subdaily <- file.path(temp_dir, "test_runtime_subdaily.nc")
  gds <- openDataset(nc_path_subdaily)
  grid <- gds$findGridByShortName("tas")
  
  runTimePars <- getRunTimeDomain.seasonal(
    dataset = nc_path_subdaily,
    grid = grid,
    members = NULL,
    season = 1:3,
    years = 1980:1980, 
    leadMonth = 0
  )

  out <- getForecastTimeDomain(
    grid = grid,
    dataset = nc_path_subdaily,
    dic = dic,
    runTimePars = runTimePars,
    time = "DD",
    aggr.d = "mean",
    aggr.m = "none"
  )

  expect_type(out, "list")
  expect_true(out$aggr.d == "mean")

  # Sub-daily with sub-daily aggregation + monthly aggregation
  out <- getForecastTimeDomain(
    grid = grid,
    dataset = nc_path_subdaily,
    dic = dic,
    runTimePars = runTimePars,
    time = "DD",
    aggr.d = "mean",
    aggr.m = "mean"
  )

  expect_type(out, "list")
  expect_true(out$aggr.d == "mean")
  expect_true(out$aggr.m == "mean")
  
  # Error if sub-daily and no daily aggregation provided 
  expect_error(
    getForecastTimeDomain(
      grid = grid,
      dataset = nc_path_subdaily,
      dic = dic,
      runTimePars = runTimePars,
      time = "DD",
      aggr.d = "none",
      aggr.m = "mean"
    ),
    "A daily aggregation function must be indicated to perform daily aggregation"
  )
  
  # Hourly verification time 
  out <- getForecastTimeDomain(
    grid = grid,
    dataset = nc_path_subdaily,
    dic = dic,
    runTimePars = runTimePars,
    time = "06",
    aggr.d = "none",
    aggr.m = "none"
  )

  expect_true(all(sapply(out$forecastDates, function(x) all(x$hour == 6))))

  gds$close()
})
