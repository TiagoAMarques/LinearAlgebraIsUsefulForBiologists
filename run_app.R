if (!requireNamespace("shiny", quietly = TRUE)) {
  stop(
    "The 'shiny' package is required. Install it with install.packages('shiny').",
    call. = FALSE
  )
}

shiny::runApp(appDir = ".", launch.browser = TRUE)
