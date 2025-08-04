# What is loadeR?

loadeR is an R package for climate data access building on the NetCDF-Java API. It allows user-friendly data access either from local or remote locations (e.g. OPeNDAP servers) and it is fully integrated with the User Data Gateway ([UDG](http://www.meteo.unican.es/udg-wiki)), a Climate Data Service deployed and maintained by the [Santander Meteorology Group](http://www.meteo.unican.es). loadeR has been conceived to work in the framework of both seasonal forecasting and climate change studies. Thus, it considers ensemble members as a basic dimension of its two main data structures (`grid` and `station`). Find out more about this package at the [loadeR wiki](https://github.com/SantanderMetGroup/loadeR/wiki).

This package is part of the [climate4R framework](http://www.meteo.unican.es/climate4r), formed by `loadeR`, `transformeR`, `downscaleR`, `visualizeR` and other packages dealing with climate data analysis and visualization.

The recommended installation procedure (for loader and the companion loadeR.java and climate4R.UDG packages) is to use the `install_github` command from the devtools R package (see the installation info in the wiki):

```r
devtools::install_github(c("SantanderMetGroup/loadeR.java", "SantanderMetGroup/climate4R.UDG", "SantanderMetGroup/loadeR"))
```
**IMPORTANT:** On OS X, be sure to execute this in R started from the Terminal, not the R App! (This is because the R app doesn’t honor $PATH changes in ~/.bash_profile)

**IMPORTANT:** The package requires Java version 1.7 or higher. Several _recommendations for known problems with R and Java_ are given in the [wiki installation info](https://github.com/SantanderMetGroup/loadeR/wiki/Installation)). 
 
**NOTE:** loadeR is enhanced by [loadeR.ECOMS](http://meteo.unican.es/udg-wiki/ecoms/RPackage) package which allows to remotely access harmonized data from several state-of-the-art seasonal forecasting databases stored at the ECOMS-UDG. 

# Testing loadeR

### Setting Up the Test Environment:

1. Create a Conda environment with R 3.6 and the packages that loadeR depends on:
```bash
conda create -n c4r-loader-tests -c conda-forge r-base=3.6 r-loader.java "r-climate4r.udg>=0.2.0" r-abind r-rcurl 
```

2. Install the packages needed for testing:
 ```bash
conda install -c conda-forge r-devtools r-covr libnetcdf
```
The r-devtools package is used to run the test suite, without requiring the package to be formally installed. The r-covr package allows you to compute test coverage. Finally, libnetcdf is needed to generate temporary .nc files from .cdl definitions included in the package. These NetCDF files are created and deleted dynamically during testing, and serve as input data for specific test cases. If you use R versions 4.3 or 4.4 on Windows, you may encounter compatibility issues with the r-devtools package. It is recommended to use R 3.6 for full compatibility. 

### Running the Tests:

1. Before running any tests, you need to clone the loadeR package repository locally:
```bash
git clone https://github.com/SantanderMetGroup/loadeR.git
cd loadeR
```
This puts you in the root directory of the package. 

2. Make sure to activate the environment you created earlier:
```bash
conda activate c4r-loader-tests
```

3. Once you're in the root directory of the cloned package and the environment is active, run the following command to execute the test suite:
```bash
Rscript -e "devtools::test()"
```
The test() function from the devtools package runs all tests located in the tests/testthat/ directory of the package without requiring the package to be installed. It is a shortcut for testthat::test_dir(), and automatically reloads the package code using devtools::load_all() before running the tests. This means that any changes made to the functions in the package are detected immediately when the tests are run.

4. Once you're in the root directory of the cloned package and the environment is active, run the following command to check the test coverage:
```bash
Rscript -e "covr::package_coverage()"
```
This command returns the coverage percentage for each R file in the package, indicating how much of the code is exercised by the test suite.

`Note:` you can also develop and use the package outside the test suite. To do so, start an R session from the root directory of the package (with the environment activated), and run:
```R
devtools::load_all()
```
This will simulate loading the package from the local source directory (where you're located) and make all its functions available in the R session. Any change you make to the R scripts will be picked up the next time you run devtools::load_all(). After that, you can call the functions normally from your R session, and they will reflect your latest changes without requiring installation.

---
Reference and further information: 

**[General description of the climate4R framework]** Iturbide et al. (2019) The R-based climate4R open framework for reproducible climate data access and post-processing. *Environmental Modelling and Software*, 111, 42-54. https://doi.org/10.1016/j.envsoft.2018.09.009
Check out the [companion notebooks](https://github.com/SantanderMetGroup/notebooks) with worked examples.

**[Statistical Downscaling]** Bedia et al. (2020). Statistical downscaling with the downscaleR package (v3.1.0): contribution to the VALUE intercomparison experiment. *Geoscientific Model Development*, 13, 1711–1735. https://doi.org/10.5194/gmd-13-1711-2020


**[Seasonal forecasting applications]** Cofiño et al. (2018) The ECOMS User Data Gateway: Towards seasonal forecast data provision and research reproducibility in the era of Climate Services. *Climate Services*, 9, 33-43. http://doi.org/10.1016/j.cliser.2017.07.001

**[Example of a sectoral application (fire danger)]** Bedia et al. (2018) Seasonal predictions of Fire Weather Index: Paving the way for their operational applicability in Mediterranean Europe. *Climate Services*, 9, 101-110. http://doi.org/10.1016/j.cliser.2017.04.001
