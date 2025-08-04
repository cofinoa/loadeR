# ============================
# Test: loadDecadalForecast.R
# ============================

test_that("loadDecadalForecast loads a grid from a decadal forecast", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'loadDecadalForecast': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_runtime.nc") 

  tmp <- tempfile(fileext = ".dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
tas,tas,24h,0,24,mean,-273.15,1,0",
    tmp
  )

  result <- loadDecadalForecast(dataset = nc_path, 
      var = "tas", dictionary = tmp, members = 1,
      lonLim = c(-10, 5), latLim = c(35, 45),
      season = 1:3, years = 1980:1981,
      time = "none", aggr.d = "none", aggr.m = "none")
  
  expect_type(result, "list")
  expect_true("Data" %in% names(result))
  expect_true(is.array(result$Data))
  expect_true("Dates" %in% names(result))
  expect_true("Variable" %in% names(result))
  expect_true(attr(result$Variable, "is_standard") == TRUE)

  # No dictionary
  result <- loadDecadalForecast(dataset = nc_path, 
      var = "tas", dictionary = FALSE, members = 1,
      lonLim = c(-10, 5), latLim = c(35, 45),
      season = 1:3, years = 1980:1981,
      time = "none", aggr.d = "none", aggr.m = "none")

  expect_true(attr(result$Variable, "is_standard") == FALSE)

  file.remove(tmp)
})