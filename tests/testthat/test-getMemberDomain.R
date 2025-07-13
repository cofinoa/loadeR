# ============================
# Test: getMemberDomain.R
# ============================

test_that("getMemberDomain defines indices for member selection", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'getMemberDomain': 'ncgen' is not available on system")

  nc_path <- testthat::test_path("testdata", "test_multidim.nc") 
  gds <- openDataset(nc_path)

  var <- "tas" # Select variable 
  grid <- gds$findGridByShortName(var) # Select grid for the variable (Java method)
 
  # Default members (all)
  out_all <- getMemberDomain(grid = grid, members = NULL)

  expect_type(out_all, "list") # The result should be a list
  expect_true(length(out_all) > 0) # The list should not be empty
  expect_true(all(sapply(out_all, function(x) inherits(x, "jobjRef")))) # All elements should be java object references (jobjRef)

  # Non-continuous members 
  out_some <- getMemberDomain(grid = grid, members = c(1, 3, 5), continuous = FALSE)

  expect_type(out_some, "list") # The result should be a list
  expect_equal(length(out_some), 3) # The list should have 3 members
  expect_true(all(sapply(out_some, function(x) inherits(x, "jobjRef")))) # All elements should be java object references (jobjRef)

  # Continuous members
  out_cont <- getMemberDomain(grid = grid, members = 2:4, continuous = TRUE)
  
  expect_s4_class(out_cont, "jobjRef") # out_cont shoul be a java object reference (jobjRef)
  expect_error(
    getMemberDomain(grid = grid, members = c(1, 3), continuous = TRUE),
    "Non-continuous member selections are not allowed"
  ) # Check error on non-continuous with continuous = TRUE

  gds$close()
})
