# ============================
# Test: dictionaryLookup.R
# ============================

test_that("dictionaryLookup searches variable string in the dictionary", {
  # Use real dictionary for standard case
  dic_path <- testthat::test_path("testdata", "test.dic") 
  out <- dictionaryLookup(dic_path, var = "tas", time = "DD") # Dictionary file

  expect_s3_class(out, "data.frame") # The result should be a data frame
  expect_equal(nrow(out), 1) # The data frame should have one row (matching entry)
  expect_true(all(nzchar(names(out)))) # All columns should have names
  expect_true(all(c("identifier", "short_name", "time_step", "lower_time_bound", "upper_time_bound", "aggr_fun", "offset", "scale", "deaccum") %in% names(out))) # The data frame should have specific columns
  
  expect_equal(out$identifier, "tas") # identifier should match the input variable
  expect_equal(out$short_name, "T") # short_name for ta in in test.dic should be T
  expect_equal(out$time_step, "24h") # time_step for ta in test.dic should be daily (24h)
  expect_equal(out$lower_time_bound, 0) # lower_time_bound for ta in in test.dic should be 0
  expect_equal(out$upper_time_bound, 24) # upper_time_bound for ta in in test.dic should be 24
  expect_equal(out$aggr_fun, "mean") # aggr_fun for ta in in test.dic should be mean
  expect_equal(out$offset, -273.15) # offset for ta in in test.dic should be -273.15
  expect_equal(out$scale, 1) # scale for ta in in test.dic should be 1
  expect_equal(out$deaccum, 0) # deaccum for ta in in test.dic should be 0

  # Variable not in dictionary
  expect_error(dictionaryLookup(dic_path, var = "nonexistent", time = "DD"),
               "Variable requested does not match any identifier")

  # File not found
  expect_error(suppressWarnings(dictionaryLookup("non_existent_path.dic", var = "ta", time = "DD")),
               "Dictionary not found")

  # Duplicate rows simulation: 24h and 6h for same variable
  tmp <- file.path(testthat::test_path("testdata"), "temp.dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
tas,2T,24h,0,24,mean,-273.15,1,0
tas,2T,6h,0,6,mean,-273.15,1,0",
    tmp
  )

  # Should prefer 24h when time = "DD"
  out_dd <- dictionaryLookup(tmp, var = "tas", time = "DD")
  expect_equal(nrow(out_dd), 1)
  expect_equal(out_dd$time_step, "24h")

  # Should prefer 6h when time = "06"
  out_06 <- dictionaryLookup(tmp, var = "tas", time = "06")
  expect_equal(nrow(out_06), 1)
  expect_equal(out_06$time_step, "6h")

  # Time = "DD" with only 12h data → error
  tmp12 <- file.path(testthat::test_path("testdata"), "temp12.dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
temp12,T12,12h,0,12,mean,0,1,0",
    tmp12
  )
  expect_error(dictionaryLookup(tmp12, var = "temp12", time = "DD"),
               "Cannot compute daily mean from 12-h data")

  # Time = "06" with 12h data → error
  expect_error(dictionaryLookup(tmp12, var = "temp12", time = "06"),
               "Requested 'time' value")

  # Time = "06" with 24h data → error
  tmp24 <- file.path(testthat::test_path("testdata"), "temp24.dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
pr24,PR,24h,0,24,sum,0,1,0",
    tmp24
  )
  expect_error(dictionaryLookup(tmp24, var = "pr24", time = "06"),
               "Subdaily data not available for variable")

  # Time = "DD" with 24h data → accepted and time is set to "none"
  out_final <- dictionaryLookup(tmp24, var = "pr24", time = "DD")
  expect_equal(out_final$time_step, "24h")
  
  # Clean up temporary files
  unlink(c(tmp, tmp12, tmp24))
})

test_that("check.dictionary checks for dictionary options", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'check.dictionary': 'ncgen' is not available on system")

  nc_path <- testthat::test_path("testdata", "test_grid", "test_grid.ncml") 
  out <- check.dictionary(dataset = nc_path, var = "T", dictionary = TRUE, time = "DD")

  expect_type(out, "list") # The result should be a list
  expect_true(length(out) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out)))) # All elements should have names
  expect_true(all(c("shortName", "dic") %in% names(out))) # The list should have specific names
  
  expect_equal(out$shortName, "T") # shortName for ta in in test_grid.dic should be T
  expect_s3_class(out$dic, "data.frame") # dic should be a data.frame

  expect_equal(out$dic$identifier, "T") # identifier should match the input variable
  expect_equal(out$dic$short_name, "T") # short_name for ta in in test_grid.dic should be T
  expect_equal(out$dic$time_step, "24h") # time_step for ta in test_grid.dic should be daily (24h)
  expect_equal(out$dic$lower_time_bound, 0) # lower_time_bound for ta in in test_grid.dic should be 0
  expect_equal(out$dic$upper_time_bound, 24) # upper_time_bound for ta in in test_grid.dic should be 24
  expect_equal(out$dic$aggr_fun, "mean") # aggr_fun for ta in in test_grid.dic should be mean
  expect_equal(out$dic$offset, -273.15) # offset for ta in in test_grid.dic should be -273.15
  expect_equal(out$dic$scale, 1) # scale for ta in in test_grid.dic should be 1
  expect_equal(out$dic$deaccum, 0) # deaccum for ta in in test_grid.dic should be 0
})
