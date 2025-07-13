# ============================
# Test: dictionaryTransform.R
# ============================

test_that("dictionaryTransform performs variable transformation according to dictionary specifications", {
  skip_if(Sys.which("ncgen") == "", "Skipping test 'dictionaryTransform': 'ncgen' is not available on system")

  nc_path <- testthat::test_path("testdata", "test_levelxy_subdaily.nc") 
  dic_path <- testthat::test_path("testdata", "test.dic") 

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
  levelPars <- getVerticalLevelPars(grid, 850)
  latLon <- getLatLonDomain(grid, lonLim = c(-10, 5), latLim = c(35, 45))
  memberPars <- rJava::.jnull() # No ensemble members

  # Get raw mdArray in Kelvin
  mdArray <- makeSubset(grid, timePars, levelPars, latLon, memberPars)$mdArray

  # Apply transformation using scale and offset (K -> °C)
  transformed <- dictionaryTransform(dic_entry, grid, timePars, mdArray)

  # Check transformation: temperature - 273.15
  expect_equal(transformed, mdArray - 273.15)

  # Deaccumulation 
  tmp_dic <- file.path(testthat::test_path("testdata"), "temp.dic")
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
  transformed <- dictionaryTransform(dic_entry, grid, timePars, mdArray)

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