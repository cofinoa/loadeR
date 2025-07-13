# ============================
# Test: loadGridData.R
# ============================

test_that("loadGridData loads a grid from a gridded dataset", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'loadGridData': 'ncgen' is not available on system")

  nc_path <- testthat::test_path("testdata", "test_rcmgrid.nc") 

  out <- loadGridData(
    dataset = nc_path,
    var = "tas",
    lonLim = c(0, 2),
    latLim = c(40, 42),
    years = 2000:2000
  ) 
  expect_type(out, "list") # The result should be a list
  expect_true(length(out) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out)))) # All elements should have names
  expect_true(all(c("Variable", "Data", "xyCoords", "Dates") %in% names(out))) # The list should have specific names 
  expect_type(out$Variable, "list") # Variable should be a list
  expect_true(all(c("varName", "level") %in% names(out$Variable))) # Variable should have specific names 
  expect_type(out$xyCoords, "list") # xyCoords should be a list
  expect_true(all(c("x","y") %in% names(out$xyCoords))) # xyCoords should have specific names 
  expect_true(is.array(out$Data)) # Data should be an array 

  nc_path <- testthat::test_path("testdata", "test_grid", "test_T.nc") 
  
  out <- loadGridData(
    dataset = nc_path,
    var = "T",
    lonLim = -3.5,
    latLim = 40,
    years = 1980:1980
  )
  expect_type(out, "list")

  # Variable not found 
  nc_path <- testthat::test_path("testdata", "test_levelxy_subdaily.nc") 

  expect_error(loadGridData(
    dataset = nc_path,
    var = "pr@850"), "Variable requested not found\nCheck 'dataInventory' output and/or dictionary 'identifier'.")

  # Daily aggregation 
  out <- loadGridData(
    dataset = nc_path,
    var = "tas@850",
    dictionary = TRUE,
    lonLim = c(-10, 5),
    latLim = c(35, 45),
    season = 6:8,
    years = 1981:1981,
    time = "DD",
    aggr.d = "mean",
    aggr.m = "none")
  expect_type(out, "list")
  expect_equal(out$Variable$level, 850) 
 
  # Daily aggregation ignored
  expect_message({loadGridData(
    dataset = nc_path,
    var = "tas@850",
    lonLim = c(-10, 5),
    latLim = c(35, 45),
    season = 6:8,
    years = 1981:1981,
    time = "none", 
    aggr.d = "mean",
    aggr.m = "none")},"NOTE: Argument 'aggr.d' ignored")

  # Conditon no threshold
  expect_error(loadGridData(
    dataset = nc_path,
    var = "tas@850", 
    lonLim = c(-10, 5),
    latLim = c(35, 45),
    season = 6:8,
    years = 1981:1981,
    condition = "LE"),"A 'threshold' argument value is required given 'condition', with no default")

  # Condition no numeric threshold
  expect_error(loadGridData(
    dataset = nc_path,
    var = "tas@850", 
    lonLim = c(-10, 5),
    latLim = c(35, 45),
    season = 6:8,
    years = 1981:1981,
    condition = "LE",
    threshold = "290"),"Invalid non-numeric 'threshold' argument value")
  
  # Condition no aggr
  expect_error(loadGridData(
    dataset = nc_path,
    var = "tas@850", 
    lonLim = c(-10, 5),
    latLim = c(35, 45),
    season = 6:8,
    years = 1981:1981,
    condition = "LE",
    threshold = 290),"Invalid 'aggr.m' argument value given 'threshold' and 'condition'")
  
  # Invalid season
  expect_error(loadGridData(
    dataset = nc_path,
    var = "tas@850",
    lonLim = c(-10, 5),
    latLim = c(35, 45),
    season = 13,
    years = 1981:1981),"Invalid season definition")
  
  # Ensemble axis
  nc_path <- testthat::test_path("testdata", "test_multidim.nc") 

  out <- loadGridData(
    dataset = nc_path,
    var = "tas@850", 
    lonLim = c(-10, 5),
    latLim = c(35, 45),
    season = 1:3,
    years = 2000:2000,
    members = 1:2)
  expect_type(out, "list")
  expect_true("Members" %in% names(out))  

  # Sorting longitudes
  nc_path <- testthat::test_path("testdata", "test_levelyx_subdaily.nc") 

  out <- loadGridData(
    dataset = nc_path,
    var = "tas@850",
    lonLim = c(-10, 5),
    latLim = c(35, 45),
    season = 6:8,
    years = 1981:1981,
    time = "DD",
    aggr.d = "mean",
    aggr.m = "none")
  expect_true("lon" %in% attr(out$Data, "dimensions"))
})

test_that("loadGridDataset loads a subset from a gridded data", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'loadGridDataset': 'ncgen' is not available on system")

  # No ensemble axis, members = NULL
  nc_path <- testthat::test_path("testdata", "test_levelyx_subdaily.nc") 
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")
  latLon <- getLatLonDomain(grid, lonLim = c(-10, 5), latLim = c(35, 45))

  out <- loadGridDataset("tas", grid, NULL, 850, 6:8, 1981, NULL, "none", latLon, "none", "none", 290, "LE")
  expect_type(out, "list")
  expect_null(out$Members)

  # No ensemble axis, members = 1  
  expect_warning({
    out <- loadGridDataset("tas", grid, NULL, 850, 6:8, 1981, 1, "none", latLon, "none", "none", NULL, NULL)
    expect_type(out, "list")
    expect_null(out$Members)}, "NOTE: The grid does not contain an Ensemble Axis: 'member' argument was ignored")
  gds$close()

  # Ensemble axis, valid members 
  nc_path <- testthat::test_path("testdata", "test_multidim.nc") 
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")
  latLon <- getLatLonDomain(grid, lonLim = c(-10, 5), latLim = c(35, 45))

  out <- loadGridDataset("tas", grid, NULL, 850, 1:3, 2000, 1, "none", latLon, "none", "none", NULL, NULL)
  expect_type(out, "list")
  expect_true("Members" %in% names(out))

  # Ensemble axis, invalid members 
  expect_error({
    loadGridDataset("tas", grid, NULL, 850, 1:3, 2000, 7, "none", latLon, "none", "none", NULL, NULL)
  }, regexp = "Invalid member selection")
  gds$close()
})

test_that("adjustDates adjust time/start dates of a loaded object", {
  # Monthly aggregation 
  timePars_month <- list(
    dateSliceList = as.Date(c("1981-06-01", "1981-07-01", "1981-08-01")),
    aggr.m = "mean",
    aggr.d = "none"
  )
  result_month <- adjustDates(timePars_month)
  expect_type(result_month, "list")
  expected_start_month <- c("1981-06-01", "1981-07-01", "1981-08-01")
  expected_end_month <- c("1981-07-01", "1981-08-01", "1981-09-01")
  expect_true(all(mapply(grepl, expected_start_month, result_month$start)))
  expect_true(all(mapply(grepl, expected_end_month, result_month$end)))

  # Daily aggregation 
  timePars_day <- list(
    dateSliceList = c("1981-06-01 00:00:00", "1981-06-02 00:00:00"),
    aggr.m = "none",
    aggr.d = "mean"
  )
  result_day <- adjustDates(timePars_day)
  expect_type(result_day, "list")
  expected_start_day <- c("1981-06-01", "1981-06-02")
  expected_end_day <- c("1981-06-02", "1981-06-03")
  expect_true(all(mapply(grepl, expected_start_day, result_day$start)))
  expect_true(all(mapply(grepl, expected_end_day, result_day$end)))

  # No aggregation 
  timePars_none <- list(
    dateSliceList = c("1981-06-01 00:00:00"),
    aggr.m = "none",
    aggr.d = "none"
  )
  result_none <- adjustDates(timePars_none)
  expect_type(result_none, "list")
  expect_true(grepl("1981-06-01 00:00:00", result_none$start))
  expect_true(grepl("1981-06-01 00:00:00", result_none$end))

  # NULL dateSliceList
  timePars_null <- list(
    dateSliceList = NULL,
    aggr.m = "none",
    aggr.d = "none"
  )
  result_null <- adjustDates(timePars_null)
  expect_type(result_null, "list")
  expect_null(result_null$start)
  expect_null(result_null$end)
})

test_that("ndays and timeUnits work correctly", {
  # Tests for ndays
  expect_equal(ndays("2023-02-15"), as.difftime(28, units = "days")) # Common February
  expect_equal(ndays("2024-02-15"), as.difftime(29, units = "days")) # Leap year February
  expect_equal(ndays("2023-04-15"), as.difftime(30, units = "days")) # April (30 days)
  expect_equal(ndays("2023-01-15"), as.difftime(31, units = "days")) # January (31 days)

  # Tests for timeUnits
  expect_equal(timeUnits(1), "1h")
  expect_equal(timeUnits(3), "3h")
  expect_equal(timeUnits(6), "6h")
  expect_equal(timeUnits(12), "12h")
  expect_equal(timeUnits(24), "days")
  expect_equal(timeUnits(720), "months") # 30 days * 24 h
  expect_equal(timeUnits(8760), "years") # 365 days * 24 h
  expect_equal(timeUnits(10000), "undefined") # Not matched by any condition
})
