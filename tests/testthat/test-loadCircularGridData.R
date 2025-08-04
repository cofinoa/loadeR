# ============================
# Test: loadCircularGridData.R
# ============================

test_that("loadCircularGridData loads a grid from a circular gridded dataset", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'loadCircularGridData': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_multidimrlonrlat.nc")

  tmp <- tempfile(fileext = ".dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
tas,tas,24h,0,24,mean,-273.15,1,0",
    tmp
  )

  result <- loadCircularGridData(dataset = nc_path, 
    var = "tas", dictionary = tmp, 
    lonLim = c(-10, 5), latLim = c(35, 45),
    season = 1:2, years = 2000:2000, members = 1:2,
    time = "none", aggr.d = "none", aggr.m = "none",
    condition = NULL, threshold = NULL)
  
  expect_type(result, "list")
  expect_true("Data" %in% names(result))
  expect_equal(attr(result$Data, "dimensions")[1:2], c("member", "time"))

  # No dictionary
  result <- loadCircularGridData(dataset = nc_path, 
    var = "tas", dictionary = FALSE, 
    lonLim = c(-10, 5), latLim = c(35, 45),
    season = 1:2, years = 2000:2000, members = 1:2,
    time = "none", aggr.d = "none", aggr.m = "none",
    condition = NULL, threshold = NULL)
  
  expect_type(result, "list")
  expect_true("xyCoords" %in% names(result))
  expect_true(!is.null(attr(result$xyCoords, "projection")))

  # Condition and threshold
  expect_error(loadCircularGridData(dataset = nc_path, 
    var = "tas", dictionary = tmp, 
    lonLim = c(-10, 5), latLim = c(35, 45),
    season = 1:2, years = 2000:2000, members = 1:2,
    time = "none", aggr.d = "none", aggr.m = "none",
    condition = "LE", threshold = 290), "Invalid 'aggr.m' argument value given 'threshold' and 'condition'")
  
  expect_error(loadCircularGridData(dataset = nc_path, 
    var = "tas", dictionary = tmp, 
    lonLim = c(-10, 5), latLim = c(35, 45),
    season = 1:2, years = 2000:2000, members = 1:2,
    time = "none", aggr.d = "none", aggr.m = "none",
    condition = "LE", threshold = "nonumeric"), "Invalid non-numeric 'threshold' argument value")
  
  expect_error(loadCircularGridData(dataset = nc_path, 
    var = "tas", dictionary = tmp, 
    lonLim = c(-10, 5), latLim = c(35, 45),
    season = 1:2, years = 2000:2000, members = 1:2,
    time = "none", aggr.d = "none", aggr.m = "none",
    condition = "LE", threshold = NULL), "A 'threshold' argument value is required given 'condition', with no default")
  
  file.remove(tmp)
})