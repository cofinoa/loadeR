# ============================
# Test: adjustDates.forecast.R
# ============================

test_that("adjustDates.forecast adjusts dates in forecast data", {
  # Monthly aggregation
  dates_monthly <- seq(as.Date("1980-01-01"), by = "month", length.out = 3)
  forecastDates_month <- list(list(as.POSIXct(dates_monthly)))

  foreTimePars_month <- list(
    forecastDates = forecastDates_month,
    aggr.d = "none",
    aggr.m = "mean"
  )

  res_month <- adjustDates.forecast(foreTimePars_month)

  expect_type(res_month, "list")
  expect_named(res_month, c("start", "end"))
  expect_equal(length(res_month$start), 3)
  expect_true(all(grepl("^\\d{4}-\\d{2}-\\d{2}( [A-Z]+)?$", res_month$start)))
  expect_true(all(grepl("^\\d{4}-\\d{2}-\\d{2}( [A-Z]+)?$", res_month$end)))

  # Daily aggregation
  dates_daily <- seq(as.Date("1980-01-01"), by = "day", length.out = 3)
  forecastDates_day <- list(list(as.POSIXct(dates_daily)))

  foreTimePars_day <- list(
    forecastDates = forecastDates_day,
    aggr.d = "mean",
    aggr.m = "none"
  )

  res_day <- adjustDates.forecast(foreTimePars_day)

  expect_type(res_day, "list")
  expect_named(res_day, c("start", "end"))
  expect_equal(length(res_day$start), 3)
  expect_true(all(grepl("^\\d{4}-\\d{2}-\\d{2}( [A-Z]+)?$", res_day$start)))
  expect_true(all(grepl("^\\d{4}-\\d{2}-\\d{2}( [A-Z]+)?$", res_day$end)))

  # No aggregation
  dates_none <- c("1980-01-01 00:00:00", "1980-01-02 00:00:00", "1980-01-03 00:00:00")
  forecastDates_none <- list(list(as.POSIXct(dates_none, tz = "GMT")))

  foreTimePars_none <- list(
    forecastDates = forecastDates_none,
    aggr.d = "none",
    aggr.m = "none"
  )

  res_none <- adjustDates.forecast(foreTimePars_none)

  expect_type(res_none, "list")
  expect_named(res_none, c("start", "end"))
  expect_equal(length(res_none$start), 3)
  expect_true(all(grepl("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}( [A-Z]+)?$", res_none$start)))
  expect_true(all(grepl("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}( [A-Z]+)?$", res_none$end)))
})