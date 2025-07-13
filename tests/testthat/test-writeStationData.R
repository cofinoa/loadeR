# ============================
# Test: writeStationData.R        
# ============================

# Loading outside of test_that to avoid 'invalid connection' error caused by 
# excessive message output from the function, which breaks testthat reporters
out <- loadStationData(
  dataset = testthat::test_path("testdata", "test_station"), 
  var = "tmax",
  stationID = c("000012", "000013"),
  units = "degC",
  season = 6:8,
  years = 1961:1962)

test_that("writeStationData writes a station object to value format", {
  # Temporary output file
  output_file <- file.path(testthat::test_path("testdata"), "temp.csv")
  suppressWarnings(writeStationData(out, path = output_file))
  written_data <- read.csv(output_file, check.names = FALSE)

  expect_equal(colnames(written_data), c("YYYYMMDD", out$Metadata$station_id)) # Check column names: one for date + one per station ID

  expected_dates <- as.integer(format(as.Date(out$Dates$start), "%Y%m%d"))
  expect_equal(written_data$YYYYMMDD, expected_dates)  # Check that the date column is correctly formatted as YYYYMMDD

  # Check the number of rows and columns
  expect_equal(nrow(written_data), length(out$Dates$start))
  expect_equal(ncol(written_data), length(out$Metadata$station_id) + 1) # +1 for the date column

  # Clean up
  file.remove(output_file)
})

test_that("writeStationData writes a station object with NA to value format", {
  # Create a copy of 'out' with one NA introduced
  out_with_na <- out
  out_with_na$Data[1, 1] <- NA

  # Temporary output file
  output_file <- file.path(testthat::test_path("testdata"), "temp.csv")
  suppressWarnings(writeStationData(out_with_na, path = output_file))
  written_data <- read.csv(output_file, stringsAsFactors = FALSE, check.names = FALSE)

  # Check that the NA was written 
  expect_true(is.na(written_data[1, 2])) # First row, first station column

  # Clean up
  file.remove(output_file)
})
