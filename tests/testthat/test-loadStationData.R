# ============================
# Test: loadStationData.R
# ============================

if (Sys.which("ncgen") != "") {
    # Loading outside of test_that to avoid 'invalid connection' error caused by 
    # excessive message output from the function, which breaks testthat reporters 

    # Station (station id given + units)
    station_path <- testthat::test_path("testdata", "test_station") 
    station_ids = c("000012", "000013")

    out_station_units <- loadStationData(
      dataset = station_path,
      var = "tmax",
      stationID = station_ids,
      units = "degC",
      season = 6:8,
      years = 1961:1962)

    # Station (station id given + lat/lon limits)
    out_station_latlon <- list(result = NULL, warning = NULL)

    withCallingHandlers(
      out_station_latlon$result <- tryCatch(
        loadStationData(
          dataset = station_path,
          var = "tmax",
          stationID = station_ids,
          lonLim = c(-20, 20),
          latLim = c(25, 55),
          season = 6:8,
          years = 1961:1962)),
      warning = function(w) {
        out_station_latlon$warning <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    )

    # Station (variable not found) 
    out_station_varnotfound <- list(result = NULL, error = NULL)

    withCallingHandlers(
      out_station_varnotfound$result <- tryCatch(
        loadStationData(
          dataset = station_path,
          var = "varnotfound",
          stationID = station_ids),
        error = function(e) {
          out_station_varnotfound$error <<- conditionMessage(e)
          NULL
        }
      )
    )

    # Grid (no station id given + lon limit) 
    temp_dir <- getOption("loadeR.tempdir")
    grid_path <- file.path(temp_dir, "test_timestation.ncml") 

    out_grid_lon <- loadStationData(
      dataset = grid_path,
      var = "tas",
      lonLim = c(-20, 20),
      season = 1:2,
      years = 2000:2000)

    # Grid (no station id given + lat limit)
    out_grid_lat <- loadStationData(
      dataset = grid_path,
      var = "tas",
      latLim = c(25, 55),
      season = 1:2,
      years = 2000:2000)

    # Grid (station id not found)
    out_grid_idnotfound <- list(result = NULL, error = NULL)

    withCallingHandlers(
      out_grid_idnotfound$result <- tryCatch(
        loadStationData(
          dataset = grid_path,
          var = "tas",
          stationID = c("3", "4")),
        error = function(e) {
          out_grid_idnotfound$error <<- conditionMessage(e)
          NULL
        }
      )
    )
}

test_that("loadStationData loads observations data from station datasets in standard ASCII format", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'loadStationData': 'ncgen' is not available on system")

  # Station (station id given + units)
  expect_type(out_station_units, "list") # The result should be a list
  expect_true(all(c("Variable", "Data", "xyCoords", "Dates", "Metadata") %in% names(out_station_units))) # The list should have specific names

  expect_true(is.list(out_station_units$Variable)) # Variable should be a list
  expect_true(all(c("varName", "level") %in% names(out_station_units$Variable))) # Variable should have specific names

  expect_true(is.matrix(out_station_units$Data)) # Data should be a matrix
  expect_equal(ncol(out_station_units$Data), length(station_ids))

  expect_true(is.data.frame(out_station_units$xyCoords)) # xyCoords should be a data frame
  expect_equal(nrow(out_station_units$xyCoords), length(station_ids)) # xyCoords should have one row per selected station

  expect_true(is.list(out_station_units$Metadata)) # Metadata should be a list
  expect_true("station_id" %in% names(out_station_units$Metadata)) # Metadata should include station ids
  expect_equal(out_station_units$Metadata$station_id, station_ids) # station ids in metadata should match the input station ids

  expect_true(is.list(out_station_units$Dates)) # Dates should be a list
  expect_true(all(c("start", "end") %in% names(out_station_units$Dates))) 

  # Station (station id given + lat/lon limits)
  expect_match(out_station_latlon$warning, "lonLim/latLim arguments ignored as Station Codes have been specified.")

  # Station (variable not found) 
  expect_match(out_station_varnotfound$error, "Variable requested not found")

  # Grid (no station id given + lon limit)
  expect_type(out_grid_lon, "list")

  # Grid (no station id given + lat limit)
  expect_type(out_grid_lat, "list")

  # Grid (station id not found)
  expect_match(out_grid_idnotfound$error, "stationID' values not found.")
})

test_that("string2date returns a POSIXlt vector of the same length of the input", {
  # Daily format YYYYMMDD
  dates_daily <- c("19810601", "19810602", "19810603")
  out_daily <- string2date(dates_daily, tz = "UTC")

  expect_s3_class(out_daily, "POSIXlt") # The result should be POSIXlt
  expect_length(out_daily, length(dates_daily)) # The result length should match the input length
  expect_equal(format(out_daily[1], "%Y-%m-%d"), "1981-06-01") # Check first date

  # Hourly format YYYYMMDDHH
  dates_hourly <- c("1981060100", "1981060112", "1981060123")
  out_hourly <- string2date(dates_hourly, tz = "UTC")

  expect_s3_class(out_hourly, "POSIXlt") # The result should be POSIXlt
  expect_length(out_hourly, length(dates_hourly)) # The result length should match the input length
  expect_equal(format(out_hourly[2], "%H"), "12") # Check hour part
})

test_that("timeBoundsValue returns a list with components start and end, of POSIXct dates", {
  dates <- string2date(c("19810601", "19810602", "19810603"), tz = "UTC")
  bounds <- timeBoundsValue(dates, tz = "UTC")

  expect_type(bounds, "list") # The result should be a list 
  expect_named(bounds, c("start", "end")) # The list should have specific names
  expect_length(bounds$start, length(dates)) # start should have one entry per date
  expect_length(bounds$end, length(dates)) # end should have one entry per date

  expect_equal(bounds$start[1], "1981-06-01 00:00:00 UTC")
  expect_equal(bounds$end[1], "1981-06-02 00:00:00 UTC") 
})

test_that("getTimeDomainStations returns a list with a vector of time index positions and the corresponding POSIXlt dates", {
  timeDates <- string2date(
    format(seq(as.Date("1981-01-01"), as.Date("1982-12-31"), by = "1 day"), "%Y%m%d"),
    tz = "UTC"
  ) # Sequence of daily dates from 1981 to 1982

  # Summer season in 1981
  out <- getTimeDomainStations(timeDates, season = 6:8, years = 1981)

  expect_type(out, "list") # The result should be a list
  expect_true(length(out) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out)))) # All elements should have names
  expect_true(all(c("timeInd", "timeDates") %in% names(out))) # The list should have specific names
  
  expect_type(out$timeInd, "integer") # timeInd should be integer
  expect_s3_class(out$timeDates, "POSIXlt") # timeDates should be POSIXlt
  expect_true(all(format(out$timeDates, "%Y") == "1981")) # All dates should be in 1981
  expect_true(all(as.integer(format(out$timeDates, "%m")) %in% 6:8)) # All months should be 6:8

  # Cross-year season
  out_cross <- getTimeDomainStations(timeDates, season = c(12, 1, 2), years = 1982)

  expect_type(out_cross, "list") # The result should be a list
  expect_true(length(out_cross) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out_cross)))) # All elements should have names
  expect_true(all(c("timeInd", "timeDates") %in% names(out_cross))) # The list should have specific names

  expect_type(out_cross$timeInd, "integer") # timeInd should be integer
  expect_s3_class(out_cross$timeDates, "POSIXlt") # timeDates should be POSIXlt
  expect_true(all(as.integer(format(out_cross$timeDates, "%m")) %in% c(12, 1, 2))) # All months should be 12,1,2

  # Full year 
  out_full <- getTimeDomainStations(timeDates, season = NULL, years = NULL)
  
  expect_equal(length(out_full$timeDates), length(timeDates)) # All dates should be returned
  expect_identical(out_full$timeInd, seq_along(timeDates)) # timeInd should be full sequence
})
