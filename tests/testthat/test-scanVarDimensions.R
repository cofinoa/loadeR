# ============================
# Test: scanVarDimensions.R
# ============================

test_that("scanVarDimensions retrieves dimension information for a gridded variable", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'scanVarDimensions': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_multidim.nc") 
  gds <- openDataset(nc_path)

  var <- "tas" # Select variable
  grid <- gds$findGridByShortName(var) # Select grid for the variable (Java method)

  out <- scanVarDimensions(grid)

  expect_type(out, "list") # The result should be a list
  expect_true(length(out) >= 2) # The list should have at least 2 dimensions

  expected_dim_names <- c("runtime", "member", "time", "level", "lat", "lon", "x", "y")
  expect_true(any(names(out) %in% expected_dim_names)) # The list should have specific names

  dim_name_to_check <- if ("lon" %in% names(out)) "lon" else if ("x" %in% names(dims)) "x" else NULL
  if (!is.null(dim_name_to_check)) {
    expect_true(all(c("Type", "Units", "Values") %in% names(out[[dim_name_to_check]])))
  }  # Check one dimension has required structure

  gds$close()
})
