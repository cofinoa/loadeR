# ============================
# Test: findVerticalLevel.R
# ============================

test_that("findVerticalLevel finds vertical level from variable definition", {
  var_level <- "ta@850" # Select variable with vertical level
  out1 <- findVerticalLevel(var_level)

  expect_type(out1, "list") # The result should be a list
  expect_true(length(out1) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out1)))) # All elements should have names
  expect_named(out1, c("var", "level")) # The list should have specific names

  expect_equal(out1$var, "ta") # var should should match the input variable
  expect_equal(out1$level, 850) # level should match the input level

  var_nolevel <- "tas" # Select variable with no vertical level
  out2 <- findVerticalLevel(var_nolevel)

  expect_type(out2, "list") # The result should be a list
  expect_true(length(out2) > 0) # The list should not be empty
  expect_true(all(nzchar(names(out2)))) # All elements should have names
  expect_named(out2, c("var", "level")) # The list should have specific names

  expect_equal(out2$var, "tas") # var should should match the input variable
  expect_null(out2$level) # level should be NULL 
})
