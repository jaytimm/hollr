
.hollrEnv <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # Package initialization code (if any)
}

.onAttach <- function(libname, pkgname) {
  # Code to run when the package is attached (if any)
}

# Suppress warnings for global variables
utils::globalVariables(c("id", "annotator_id", "attempts", "success"))
