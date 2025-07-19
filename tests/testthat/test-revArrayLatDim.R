# ============================
# Test: revArrayLatDim.R
# ============================

test_that("revArrayLatDim reverses latitude coordinates ordering", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'revArrayLatDim': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_levelxy.nc") 
  gds <- openDataset(nc_path)

  var <- "tas" # Select variable
  grid <- gds$findGridByShortName(var) # Select grid for the variable (Java method)

  level <- 850 # Select pressure level
  latLon <- getLatLonDomain(grid, lonLim = c(-10, 5), latLim = c(35, 45)) # Select geographic domain
  timePars <- getTimeDomain(
    grid = grid,
    dic = NULL,
    season = 6:8,
    years = 1981:1981,
    time = "none",
    aggr.d = "none",
    aggr.m = "none",
    threshold = NULL,
    condition = NULL
  ) # Select time domain
  levelPars <- getVerticalLevelPars(grid, level = level) # Select vertical level pars

  subset <- makeSubset(
    grid = grid,
    timePars = timePars,
    levelPars = levelPars,
    latLon = latLon,
    memberPars = NULL
  )

  mdArray <- subset$mdArray
  reversed <- revArrayLatDim(mdArray)

  # Check that dimensions and attributes are preserved
  expect_equal(dim(reversed), dim(mdArray))
  expect_equal(attr(reversed, "dimensions"), attr(mdArray, "dimensions"))

  # Check that the 'lat' axis was reversed
  lat_dim_index <- grep("lat", attr(mdArray, "dimensions"))
  expect_equal(reversed[, 1, ], mdArray[, dim(mdArray)[lat_dim_index], ])
  expect_equal(reversed[, dim(mdArray)[lat_dim_index], ], mdArray[, 1, ])

  gds$close()
})

test_that("revArrayLatDim correctly handles 'y' and 'latitude' dimension names", {
  # Case with "y" as latitude dimension name
  arr_y <- array(1:9, dim = c(3, 3))
  attr(arr_y, "dimensions") <- c("x", "y")
  res_y <- revArrayLatDim(arr_y)
  expect_equal(dim(res_y), dim(arr_y))
  expect_equal(attr(res_y, "dimensions"), attr(arr_y, "dimensions"))
  expect_equal(res_y[, 1], arr_y[, 3])
  expect_equal(res_y[, 3], arr_y[, 1])

  # Case with "latitude" as latitude dimension name
  arr_latitude <- array(1:9, dim = c(3, 3))
  attr(arr_latitude, "dimensions") <- c("x", "latitude")
  res_lat <- revArrayLatDim(arr_latitude)
  expect_equal(dim(res_lat), dim(arr_latitude))
  expect_equal(attr(res_lat, "dimensions"), attr(arr_latitude, "dimensions"))
  expect_equal(res_lat[, 1], arr_latitude[, 3])
  expect_equal(res_lat[, 3], arr_latitude[, 1])
})
