# ============================
# Test: getRunTimeDomain.seasonal.R
# ============================

test_that("getRunTimeDomain.seasonal returns correct seasonal runtime parameters", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'getRunTimeDomain.seasonal': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_runtime.nc")
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas") 

  # Standard case: January to March (no year-crossing)
  out <- getRunTimeDomain.seasonal(
    dataset = nc_path,
    grid = grid,
    members = NULL,
    season = 1:3,
    years = 1980:1982, 
    leadMonth = 0
  )

  expect_type(out, "list")
  expect_true(all(c("validMonth", "years", "season", "year.cross", "runDates", "runTimeRanges") %in% names(out)))

  expect_type(out$validMonth, "double")
  expect_type(out$years, "integer")
  expect_type(out$season, "integer")
  expect_true(is.null(out$year.cross) || is.integer(out$year.cross))
  expect_s3_class(out$runDates, "POSIXlt")
  expect_true(is.list(out$runTimeRanges))
  expect_true(all(sapply(out$runTimeRanges, function(x) inherits(x, "jobjRef"))))

  # Year-crossing season: November to February
  result_cross <- getRunTimeDomain.decadal(
    dataset = nc_path,
    grid = grid,
    members = NULL,
    season = c(11, 12, 1, 2),
    years = 1981:1982
  )

  expect_type(result_cross$year.cross, "integer")
  expect_true(result_cross$years[1] <= 1982L)
  expect_true(all(result_cross$season %in% c(11,12,1,2)))

  # Expect error for invalid leadMonth
  expect_error(
    getRunTimeDomain.seasonal(
      dataset = nc_path,
      grid = grid,
      members = NULL,
      season = c(4, 5, 6), 
      years = 1981:1982,
      leadMonth = 7 
    ),
    regexp = "Incompatible 'leadMonth' and 'season' argument values"
  )

  # Null season and years
  out <- getRunTimeDomain.seasonal(
    dataset = nc_path,
    grid = grid,
    members = NULL,
    season = NULL,
    years = NULL,
    leadMonth = 0
  )

  expect_type(out$season, "double")
  expect_gt(length(out$season), 0)
  expect_type(out$years, "integer")
  expect_true(length(out$years) > 0)
  expect_true(min(out$years) >= 1980)

  # Years outside of range
  expect_warning(
    out <- getRunTimeDomain.seasonal(
      dataset = nc_path,
      grid = grid,
      members = NULL,
      season = 1:3,
      years = 1970:1999,
      leadMonth = 0
    ),
    regexp = "Year selection out of dataset range"
  )
  
  expect_true(all(out$years >= 1980 & out$years <= 1982))
  
  gds$close()
})