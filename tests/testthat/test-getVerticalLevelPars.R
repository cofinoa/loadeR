# ============================
# Test: getVerticalLevelPars.R 
# ============================

test_that("getVerticalLevelPars opens the grid and checks all possible level values", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'getVerticalLevelPars': 'ncgen' is not available on system")

  # Level specified and no vertical levels available 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_rcmgrid.nc")
  gds <- openDataset(nc_path)
  
  var <- "tas" # Select variable 
  grid <- gds$findGridByShortName(var) # Select grid for the variable (Java method)
  out <- getVerticalLevelPars(grid, level = 850)
  
  expect_equal(out$level, 850) # level should match the input level
  expect_true(identical(out$zRange, rJava::.jnull())) # zRange should be NULL (no vertical levels)
  gds$close()

  # Level specified and vertical levels available 
  nc_path <- file.path(temp_dir, "test_level.nc")
  gds <- openDataset(nc_path)
  
  var <- "tas" # Select variable 
  grid <- gds$findGridByShortName(var) # Select grid for the variable (Java method)
  out <- getVerticalLevelPars(grid, level = 850)

  expect_type(out, "list") # The result should be a list
  expect_true(length(out) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out)))) # All elements should have names
  expect_named(out, c("level", "zRange")) # The list should have specific names
  expect_equal(out$level, 850) # level should match the input level
  expect_s4_class(out$zRange, "jobjRef") # zRange should be a java object reference (jobjRef)

  # Non-existent level specified
  expect_error(getVerticalLevelPars(grid, level = 9999),
  "Vertical level not found")

  # Level not specified and multiple vertical levels available
  expect_error(getVerticalLevelPars(grid, level = NULL),
  "Variable with vertical levels: '@level' following the variable name is required")
  gds$close()
})
