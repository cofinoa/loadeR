# ============================
# Test: dataInventory.R
# ============================

test_that("stationInfo returns a quick overview of the stations contained in a stations dataset", {
  station_path <- testthat::test_path("testdata", "test_station") 
  df <- stationInfo(station_path, plot = FALSE)

  expect_s3_class(df, "data.frame") # The result should be a data frame
  expect_gt(nrow(df), 0) # The data frame should not be empty
  expect_true(all(nzchar(names(df)))) # All columns should have names
  expect_true(all(c("stationID", "longitude", "latitude") %in% names(df))) # The data frame should have specific columns 
  expect_type(df$longitude, "double") # longitude should be double
  expect_type(df$latitude, "double") # latitude should be double
})

test_that("dataInventory.ASCII returns data inventory from a station dataset in standard ASCII format", {
  station_path <- testthat::test_path("testdata", "test_station") 
  out <- dataInventory.ASCII(station_path, rs = FALSE)

  expect_type(out, "list") # The result should be a list
  expect_true(length(out) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out)))) # All elements should have names
  expect_named(out, c("Stations", "Variables", "Summary.stats")) # The list should have specific names
  expect_type(out$Stations, "list") # Stations should be a list
  expect_s3_class(out$Variables, "data.frame") # Variables should be a data frame
  expect_null(out$Summary.stats) # Summary.stats should be NULL (rs = FALSE)

  out <- dataInventory.ASCII(station_path, rs = TRUE)
  expect_false(is.null(out$Summary.stats)) # Summary.stats should not be NULL (rs = FALSE)
})

test_that("dataInventory.NetCDF.ts returns a list with summary information about the variables stored in a time series dataset", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'dataInventory.NetCDF.ts': 'ncgen' is not available on system")

  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_timestationlatlon.nc")
  out <- dataInventory.NetCDF.ts(nc_path)

  expect_type(out, "list") # The result should be a list
  expect_true(length(out) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out)))) # All elements should have names

  # Expected fields for each variable
  expectedFields <- c("Description", "DataType", "Shape", "Units", "DataSizeMb", "Version", "Dimensions") 
  for (var in out) {
    expect_type(var, "list") # Each variable information should be a list
    expect_true(all(expectedFields %in% names(var))) # Check for expected fields
  }
})

test_that("dataInventory returns expected structure for station dataset", {
  station_path <- testthat::test_path("testdata", "test_station") 
  out <- dataInventory(station_path, return.stats = FALSE)
  out2 <- dataInventory.ASCII(station_path, rs = FALSE)
  expect_equal(out, out2)
})
test_that("dataInventory returns expected structure for gridded dataset", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'dataInventory': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_grid", "test_grid.ncml")
  out <- dataInventory(nc_path, return.stats = FALSE)
  out2 <- dataInventory.NetCDF(nc_path)
  expect_equal(out, out2)
 
  nc_path <- file.path(temp_dir, "test_timestationlatlon.ncml")
  out <- dataInventory(nc_path, return.stats = FALSE)
  out2 <- dataInventory.NetCDF.ts(nc_path)
  expect_equal(out, out2)
})