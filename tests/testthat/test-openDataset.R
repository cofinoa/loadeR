# ============================
# Test: openDataset.R        
# ============================

test_that("openDataset opens a local or remote grid dataset", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'openDataset': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_multidim.nc") 
  gds <- openDataset(nc_path)

  expect_false(is.null(gds)) 
  expect_true(rJava::.jinstanceof(gds, "ucar.nc2.dt.grid.GridDataset")) 
  gds$close()

  # URL: Forbidden (403)
  #url <- "http://httpstat.us/403"
  #expect_error(openDataset(url), regexp = "You don't have the necessary permissions to access the requested dataset")
  
  # URL: Not found (404)
  #url <- "http://httpstat.us/404"
  #expect_error(openDataset(url), regexp = "is not a valid URL")

  # URL: Not found 
  #url <- "http://httpstat.us/200"
  #expect_error(openDataset(url), regexp = "Requested URL not found\nThe problem may be momentary.")

  # URL: Service unavailable (503)
  #url <- "http://httpstat.us/503"
  #expect_error(openDataset(url), regexp = "The server is temporarily unable to service your request")
})
