# ============================
# Test: getRunTimeDomain.decadal.R
# ============================

test_that("getRunTimeDomain.decadal computes correct runtime parameters", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'getRunTimeDomain.decadal': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_runtime.nc")
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")

  # Standard case: June to August (no year-crossing)
  result <- getRunTimeDomain.decadal(
    dataset = nc_path,
    grid = grid,
    members = NULL,
    season = 6:8,
    years = 1981:1981
  )

  expect_type(result, "list")
  expect_named(result, c("validMonth", "years", "season", "year.cross", "runDates", "runTimeRanges"), ignore.order = TRUE)

  expect_type(result$validMonth, "double")
  expect_equal(result$validMonth, 1)
  expect_type(result$years, "integer")
  expect_equal(result$years, 1981L)
  expect_type(result$season, "integer")
  expect_equal(result$season, 6:8)
  expect_true(is.null(result$year.cross))
  expect_s3_class(result$runDates, "POSIXlt")
  expect_true(length(result$runDates) >= 1)
  expect_true(is.list(result$runTimeRanges))
  expect_true(all(sapply(result$runTimeRanges, function(x) inherits(x, "jobjRef"))))

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

  # Null season and years
  out <- getRunTimeDomain.decadal(
    dataset = nc_path,
    grid = grid,
    members = NULL,
    season = NULL,
    years = NULL
  )

  expect_type(out$season, "double")
  expect_gt(length(out$season), 0)
  expect_type(out$years, "integer")
  expect_true(length(out$years) > 0)
  expect_true(min(out$years) >= 1980)

  # Years outside of range
  expect_warning(
    out <- getRunTimeDomain.decadal(
      dataset = nc_path,
      grid = grid,
      members = NULL,
      season = 1:3,
      years = 1970:1999
    ),
    regexp = "Year selection out of dataset range"
  )
  
  expect_true(all(out$years >= 1980 & out$years <= 1982))

  gds$close()
})