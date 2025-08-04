# ============================
# Test: getTimeDomain.R
# ============================

test_that("getTimeDomain performs the selection of time slices based on season and year specification", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'getTimeDomain': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_grid", "test_T.nc")
  gds <- openDataset(nc_path)

  var <- "T" # Variable name
  grid <- gds$findGridByShortName(var) # Select grid for the variable (Java method)

  out <- getTimeDomain(
    grid = grid,
    dic = NULL,                  
    season = 6:8,               
    years = 1981,           
    time = "none",               
    aggr.d = "none",      
    aggr.m = "none",           
    threshold = NULL,
    condition = NULL)

  expect_type(out, "list") # The result should be a list
  expect_true(length(out) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out)))) # All elements should have names
  expect_true(all(c("dateSliceList", "timeResInSeconds", "tRanges", "deaccumFromFirst", 
                    "aggr.d", "aggr.m", "threshold", "condition") %in% names(out))) # The list should have specific names

  expect_type(out$dateSliceList, "list") # dateSliceList should be a list
  expect_true(all(sapply(out$dateSliceList, function(x) inherits(x, "POSIXct")))) # elements from dateSliceList should be POSIXct vectors

  expect_type(out$tRanges, "list") # tRanges should be a list
  expect_true(all(sapply(out$tRanges, function(r) inherits(r, "jobjRef")))) # elements from tRanges should be java object references (jobjRef)

  expect_type(out$timeResInSeconds, "double") # timeResInSeconds should be double
  expect_true(is.null(out$deaccumFromFirst) || is.logical(out$deaccumFromFirst)) # deaccumFromFirst should be NULL or logical
  
  # Daily data with aggr.d = "mean" should trigger message and ignore aggr.d
  expect_message({
    out <- getTimeDomain(
      grid = grid,
      dic = NULL,
      season = 6:8,
      years = 1981,
      time = "none",
      aggr.d = "mean", 
      aggr.m = "none",
      threshold = NULL,
      condition = NULL)
  }, "NOTE: The original data is daily: argument 'aggr.d' ignored")

  expect_identical(out$aggr.d, "none") # Confirm it was internally set to "none"

  # Year selection out of boundaries
  expect_error(getTimeDomain(
    grid = grid, 
    dic = NULL, 
    season = 6:8, 
    years = 1983:1985,
    time = "none",
    aggr.d = "none", 
    aggr.m = "none",
    threshold = NULL,
    condition = NULL),
    "Year selection out of boundaries. Use function dataInventory to check available years.")

  # Year crossing
  out <- getTimeDomain(
    grid = grid,
    dic = NULL,
    season = c(12, 1, 2), 
    years = 1981:1982,
    time = "none",
    aggr.d = "none",
    aggr.m = "none",
    threshold = NULL,
    condition = NULL)

  all_months <- unique(unlist(lapply(out$dateSliceList, function(x) as.integer(format(x, "%m")))))
  expect_true(all(c(12, 1, 2) %in% all_months))

  gds$close()

  # Sub-daily case with no daily aggregation function 
  nc_path <- file.path(temp_dir, "test_grid", "test_T_subdaily.nc")
  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("T")

  expect_error(
    getTimeDomain(
      grid = grid, 
      dic = NULL, 
      season = 6:8, 
      years = NULL,
      time = "DD", 
      aggr.d = "none", 
      aggr.m = "none",
      threshold = NULL, 
      condition = NULL),
    "A daily aggregation function must be indicated to perform daily aggregation")

  # Sub-daily case with monthly aggregation function prior to daily aggregation
  expect_error(
    getTimeDomain(
      grid = grid, 
      dic = NULL, 
      season = 6:8, 
      years = NULL,
      time = "none", 
      aggr.d = "none", 
      aggr.m = "mean",
      threshold = NULL, 
      condition = NULL),
    "A daily aggregation function must be indicated prior to monthly aggregation")

  # Sub-daily case with condition and threshold with deaccumulation 
  tmp_dic <- tempfile(fileext = ".dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
tas,T,6h,0,6,mean,-273.15,1,1",tmp_dic)
  dic <- dictionaryLookup(tmp_dic, var = "tas", time = "06")

  out <- getTimeDomain(
    grid = grid, 
    dic = dic,
    season = NULL, 
    years = NULL,
    time = "06", 
    aggr.d = "mean", 
    aggr.m = "none",
    threshold = 290, 
    condition = "LE")

  expect_type(out, "list")
  expect_true(!is.null(out$deaccumFromFirst))
  expect_true(out$deaccumFromFirst %in% c(TRUE, FALSE))
  expect_true("condition" %in% names(out))
  expect_identical(out$condition, "<=")
  gds$close()

  # No time axis 
  nc_path <- file.path(temp_dir, "test_notime.nc")
  gds <- openDataset(nc_path)

  var <- "tas" # Variable name
  grid <- gds$findGridByShortName(var) # Select grid for the variable (Java method)

  messages <- capture_messages({
  out <- getTimeDomain(
    grid = grid,
    dic = NULL,                  
    season = 6:8,               
    years = 1981,           
    time = "none",               
    aggr.d = "none",      
    aggr.m = "none",           
    threshold = NULL,
    condition = NULL)
  })

  expect_true(any(grepl("Undefined Dataset Time Axis", messages)))

  file.remove(tmp_dic)
  gds$close()
})
 