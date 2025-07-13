# Run before any test

if (Sys.which("ncgen") != "") {
    # Get cdl files
    cdl_files <- list.files(test_path("testdata"), pattern = "\\.cdl$", 
                            recursive = TRUE, full.names = TRUE)

    # Generate nc files
    message("Starting .nc generation from .cdl files...")
    nc_files <- character(length(cdl_files))
    for (i in seq_along(cdl_files)) {
      cdl <- cdl_files[i]
      nc  <- sub("\\.cdl$", ".nc", cdl)
      system2("ncgen", args = c("-7", "-o", nc, cdl))
      nc_files[i] <- nc
    }

    # Generate ncml files
    message("Starting .ncml generation...")

    ncml1 <- '<?xml version="1.0" encoding="UTF-8"?>
    <netcdf xmlns="http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2">
      <aggregation type="union">
        <netcdf location="test_timestation.nc"/>
      </aggregation>
      <attribute name="timeSeries" value="true"/>
    </netcdf>'
    writeLines(ncml1, file.path(test_path("testdata"), "test_timestation.ncml"))

    ncml2 <- '<?xml version="1.0" encoding="UTF-8"?>
    <netcdf xmlns="http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2">
      <aggregation type="union">
        <netcdf location="test_timestationlatlon.nc"/>
      </aggregation>
      <attribute name="timeSeries" value="true"/>
    </netcdf>'
    writeLines(ncml2, file.path(test_path("testdata"), "test_timestationlatlon.ncml"))

    ncml_grid <- '<?xml version="1.0" encoding="UTF-8"?>
    <netcdf xmlns="http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2">
      <aggregation type="union">

        <!-- Aggregation of variable \'pr\' across multiple files -->
        <netcdf>
          <aggregation dimName="time" type="joinExisting" timeUnitsChange="true">
            <variableAgg name="pr"/>
            <netcdf location="test_pr.nc" ncoords="1"/> 
          </aggregation>
        </netcdf>

        <!-- Aggregation of variable \'T\' across daily and sub-daily data -->
        <netcdf>
          <aggregation dimName="time" type="joinExisting" timeUnitsChange="true">
            <variableAgg name="T"/>
            <netcdf location="test_T.nc" ncoords="1096"/>
            <netcdf location="test_T_subdaily.nc" ncoords="8"/>
          </aggregation>
        </netcdf>

        <!-- Aggregation of variable \'Z\' from a single source -->
        <netcdf>
          <aggregation dimName="time" type="joinExisting" timeUnitsChange="true">
            <variableAgg name="Z"/>
            <netcdf location="test_Z.nc" ncoords="2"/>
          </aggregation>
        </netcdf>

      </aggregation>
    </netcdf>'
    writeLines(ncml_grid, file.path(test_path("testdata", "test_grid"), "test_grid.ncml"))
} 

# Generate dic files
message("Starting .dic generation...")

dic1 <- file.path(testthat::test_path("testdata"), "test.dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
tas,T,24h,0,24,mean,-273.15,1,0
pr,pr,24h,0,24,sum,0,1000,0",
    dic1)

dic2 <- file.path(testthat::test_path("testdata"), "test_levelxy_subdaily.dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
tas@850,tas,24h,0,24,mean,-273.15,1,0",
    dic2)

dic_grid <- file.path(testthat::test_path("testdata", "test_grid"), "test_grid.dic")
  writeLines(
    "identifier,short_name,time_step,lower_time_bound,upper_time_bound,aggr_fun,offset,scale,deaccum
T,T,24h,0,24,mean,-273.15,1,0
Z,Z,24h,0,24,mean,0,0.1020408,0
pr,pr,24h,0,24,sum,0,1000,0",
    dic_grid)

# Run after all tests

withr::defer({ 
  if ("rJava" %in% loadedNamespaces()) try(rJava::.jgc(), silent = TRUE)

  message("Starting cleanup of generated .nc files after all tests...")
  nc_files <- list.files(testthat::test_path("testdata"), pattern = "\\.nc$", 
                         recursive = TRUE, full.names = TRUE)
  unlink(nc_files)

  message("Starting cleanup of generated .ncml files after all tests...")
  ncml_files <- list.files(testthat::test_path("testdata"), pattern = "\\.ncml$", 
                           recursive = TRUE, full.names = TRUE)
  unlink(ncml_files)

  message("Starting cleanup of generated .dic files after all tests...")
  dic_files <- list.files(testthat::test_path("testdata"), pattern = "\\.dic$", 
                          recursive = TRUE, full.names = TRUE)
  unlink(dic_files)
}, teardown_env())
