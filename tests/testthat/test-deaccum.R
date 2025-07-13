# ============================
# Test: deaccum.R
# ============================

test_that("deaccum performs deaccumulation", {
  x <- c(1, 3, 6, 2, 5, 9) # season1: 1,3,6 / season2: 2,5,9
  t.ranges <- c(0, 3, 6)  # start/end indices of each season
  
  # Case 1: dff = TRUE (keep the first value of each season)
  out_with_first <- matrix(deaccum(x, t.ranges, dff = TRUE), nrow = 3)
  expect_equal(out_with_first[, 1], c(1, 2, 3)) # 1st season: keep first, then diffs
  expect_equal(out_with_first[, 2], c(2, 3, 4)) # 2nd season: same
 
  # Case 2: dff = FALSE (drop the first value of each season)
  out_without_first <- matrix(deaccum(x, t.ranges, dff = FALSE), nrow = 2)
  expect_equal(out_without_first[, 1], c(2, 3)) # 1st season: only diffs
  expect_equal(out_without_first[, 2], c(3, 4)) # 2nd season: same
})
