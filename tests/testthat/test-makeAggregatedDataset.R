# ============================
# Test: makeAggregatedDataset.R
# ============================

test_that("makeAggregatedDataset handles joinExisting and union cases correctly", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'makeAggregatedDataset': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  source.dir <- file.path(temp_dir, "test_grid")  
  output_ncml <- file.path(temp_dir, "temp.ncml") 

  makeAggregatedDataset(
    source.dir = source.dir,
    ncml.file = output_ncml,
    file.ext = "nc",
    aggr.dim = "time",
    pattern = NULL,
    recursive = FALSE,
    verbose = FALSE,
    timeUnitsChange = TRUE
  )

  expect_true(file.exists(output_ncml))
  content <- suppressWarnings(readLines(output_ncml))
  
  # Expect union aggregation block
  expect_true(any(grepl("<aggregation type=\"union\">", content)))

  # Each variable block should have a joinExisting aggregation
  expect_true(any(grepl("joinExisting", content)))
  expect_true(any(grepl("<variableAgg name=\"pr\"", content)))
  expect_true(any(grepl("<variableAgg name=\"T\"", content)))
  expect_true(any(grepl("<variableAgg name=\"Z\"", content)))
  
  # ncoords must appear
  expect_true(any(grepl("ncoords=", content)))

  unlink(output_ncml)

  # Case with only one file per variable 
  output_ncml <- file.path(temp_dir, "temp.ncml") 

  makeAggregatedDataset(
    source.dir = source.dir,
    ncml.file = output_ncml,
    file.ext = "nc",
    aggr.dim = "time",
    pattern = "test_pr\\.nc$|test_T\\.nc$|test_Z\\.nc$",
    recursive = FALSE,
    verbose = FALSE,
    timeUnitsChange = TRUE
  )

  expect_true(file.exists(output_ncml))
  content <- suppressWarnings(readLines(output_ncml))

  expect_true(any(grepl("<aggregation type=\"union\">", content)))
  expect_true(any(grepl("test_pr.nc", content)))
  expect_true(any(grepl("test_T.nc", content)))
  expect_true(any(grepl("test_Z.nc", content)))
  expect_true(any(grepl("ncoords=", content)))
  
  unlink(output_ncml)
})
