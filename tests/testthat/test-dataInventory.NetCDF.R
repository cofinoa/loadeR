# ============================
# Test: dataInventory.NetCDF.R
# ============================

test_that("dataInventory.NetCDF returns a list with summary information about the variables stored in a gridded dataset", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'dataInventory.NetCDF': 'ncgen' is not available on system")

  nc_path <- testthat::test_path("testdata", "test_multidim.nc") 
  out <- dataInventory.NetCDF(nc_path)
  
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