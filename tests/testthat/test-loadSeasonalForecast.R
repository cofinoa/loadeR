# ============================
# Test: loadSeasonalForecast.R
# ============================

test_that("loadSeasonalForecast Loads a user-defined spatio-temporal slice from a seasonal forecast", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'loadSeasonalForecast': 'ncgen' is not available on system")

  nc_path <- testthat::test_path("testdata", "test_runtime.nc") 

  tmp <- file.path(testthat::test_path("testdata"), "temp.dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
tas,tas,24h,0,24,mean,-273.15,1,0",
    tmp
  )

  result <- loadSeasonalForecast(dataset = nc_path, 
      var = "tas", dictionary = tmp, members = 1,
      lonLim = c(-10, 5), latLim = c(35, 45),
      leadMonth = 0, season = 1:3, years = 1980:1981,
      time = "none", aggr.d = "none", aggr.m = "none")
  
  expect_type(result, "list")
  expect_true("Data" %in% names(result))
  expect_true("Variable" %in% names(result))
  expect_true("Dates" %in% names(result))
  expect_true("xyCoords" %in% names(result))
  expect_true(attr(result$Variable, "use_dictionary"))

  # No dictionary
  result <- loadSeasonalForecast(dataset = nc_path, 
      var = "tas", dictionary = FALSE, members = 1,
      lonLim = c(-10, 5), latLim = c(35, 45),
      leadMonth = 0, season = 1:3, years = 1980:1981,
      time = "none", aggr.d = "none", aggr.m = "none")
      
  expect_false(attr(result$Variable, "use_dictionary"))

  # Variable not found
  expect_error(loadSeasonalForecast(dataset = nc_path, 
      var = "varnotfound", dictionary = FALSE, members = 1,
      lonLim = c(-10, 5), latLim = c(35, 45),
      leadMonth = 0, season = 1:3, years = 1980:1981,
      time = "none", aggr.d = "none", aggr.m = "none"), "Variable requested not found")
      
  # Invalid season
  expect_error(loadSeasonalForecast(dataset = nc_path,
    var = "tas", dictionary = FALSE, members = 1,
    lonLim = c(-10, 5), latLim = c(35, 45),
    leadMonth = 0, season = 0, years = 1980:1981,
    time = "none", aggr.d = "none", aggr.m = "none"), "Invalid season definition")

  # Missing season
  expect_error(loadSeasonalForecast(dataset = nc_path,
    var = "tas", dictionary = FALSE, members = 1,
    lonLim = c(-10, 5), latLim = c(35, 45),
    leadMonth = 0, season = NULL, years = 1980:1981,
    time = "none", aggr.d = "none", aggr.m = "none"), "Argument 'season' must be provided")

  file.remove(tmp)
})