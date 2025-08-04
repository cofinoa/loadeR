# ============================
# Test: conversion.R        
# ============================

test_that("hurs2huss derives specific humidity from relative humidity", {
    tas <- c(293.15, 295.15, 300.15) # Kelvin
    ps <- c(101325, 100000, 99000) # Pa
    hurs <- c(80, 60, 50) # %
    huss <- hurs2huss(tas, ps, hurs)

    expect_type(huss, "double")
    expect_equal(length(huss), length(tas))
    expect_true(all(huss > 0 & huss < 1))
})

test_that("mslp2ps does conversion of sea-level pressure to surface pressure", {
    tas <- c(293.15, 295.15, 290.15) # Kelvin
    zs <- c(0, 100, 500) # geopotential height (m^2/s^2)
    mslp <- c(101325, 101000, 100500) # Pa
    ps <- mslp2ps(tas, zs, mslp)

    expect_type(ps, "double")
    expect_equal(length(ps), length(tas))
    expect_true(all(ps <= mslp))
    expect_true(any(ps < mslp))
})

test_that("tdps2hurs does conversion of dew point to relative humidity", {
    tas <- c(293.15, 295.15, 300.15) # K
    tdps <- c(290.15, 290.15, 290.15) # K
    hurs <- tdps2hurs(tas, tdps)

    expect_type(hurs, "double")
    expect_equal(length(hurs), length(tas))
    expect_true(all(hurs >= 0 & hurs <= 100))
})

test_that("huss2hurs converts specific humidity to relative humidity", {
    huss <- c(0.01, 0.008, 0.005) # kg/kg
    tas_C <- c(20, 22, 25) # degrees C
    ps_mb <- c(1013.25, 1000, 990) # millibars
    hurs <- huss2hurs(huss, tas_C, ps_mb)

    expect_type(hurs, "double")
    expect_equal(length(hurs), length(huss))
    expect_true(all(hurs >= 0 & hurs <= 100))
})
