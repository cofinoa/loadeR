# ============================
# Test: dictionaryTransformGrid.R
# ============================

test_that("dictionaryTransformGrid performs transformation and deaccumulation as expected", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'dictionaryTransformGrid': 'ncgen' is not available on system")
 
  temp_dir <- getOption("loadeR.tempdir")
  nc_path <- file.path(temp_dir, "test_levelxy_subdaily.nc") 
  dic_path <- file.path(temp_dir, "test.dic")

  gds <- openDataset(nc_path)
  grid <- gds$findGridByShortName("tas")

  dic_entry <- dictionaryLookup(dic_path, var = "tas", time = "DD")

  timePars <- getTimeDomain(
    grid = grid,
    dic = dic_entry,
    season = 6:8,
    years = 1981:1981,
    time = "DD",
    aggr.d = "mean",
    aggr.m = "none",
    threshold = NULL,
    condition = NULL
  )

  levelPars <- getVerticalLevelPars(grid, level = 850)
  latLon <- getLatLonDomain(grid, lonLim = c(-10, 5), latLim = c(35, 45))
  memberPars <- rJava::.jnull() # No ensemble members

  mdArray <- makeSubset(grid, timePars, levelPars, latLon, memberPars)$mdArray
  transformed <- dictionaryTransformGrid(dic_entry, timePars, mdArray)

  # Expected result: mdArray * scale + offset
  expected <- mdArray * dic_entry$scale + dic_entry$offset

  expect_equal(dim(transformed), dim(expected))
  expect_equal(transformed, expected)

  # Deaccumulation 
  tmp_dic <- tempfile(fileext = ".dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
tas,T,6h,0,6,mean,-273.15,1,1",tmp_dic)
  dic_entry <- dictionaryLookup(tmp_dic, var = "tas", time = "06")

  timePars <- getTimeDomain(
    grid = grid, 
    dic = dic_entry,
    season = NULL, 
    years = NULL,
    time = "06", 
    aggr.d = "mean", 
    aggr.m = "none",
    threshold = NULL, 
    condition = NULL)
  
  # Get raw mdArray in Kelvin
  mdArray <- makeSubset(grid, timePars, levelPars, latLon, memberPars)$mdArray

  # Apply transformation using scale and offset (K -> °C)
  transformed <- dictionaryTransformGrid(dic_entry, timePars, mdArray)

  # Apply transformation converting mdArray (K -> °C)
  mdArrayCelsius <- mdArray - 273.15

  expected <- array(NA, dim = dim(mdArrayCelsius))
  expected[1, , ] <- mdArrayCelsius[1, , ] # First time step
  expected[2, , ] <- mdArrayCelsius[2, , ] - mdArrayCelsius[1, , ] # Second time step is the difference from the first

  # Check transformation: temperature - 273.15
  expect_equal(as.vector(transformed), as.vector(expected))

  file.remove(tmp_dic) 
  gds$close()
})