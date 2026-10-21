library(shiny)
source("app.R", local = TRUE)

testServer(server, {
  session$setInputs(
    fecundity = 2, juvenile_survival = .5, adult_survival = 1/3,
    initial_juveniles = 10, initial_adults = 20, years = 20,
    case_population = 20000, case_juvenile_survival = .45,
    case_adult_survival = .85, case_horizon = 40, exposed = .3,
    survival_reduction = .15, fecundity_reduction = .35,
    impact_years = 3, recovery_years = 12, density_compensation = 1.5
  )
  session$flushReact()
  stopifnot(grepl("1.180", output$lambda_box$html, fixed = TRUE))
  stopifnot(grepl("Lost population-years", output$lost_box$html, fixed = TRUE))
  stopifnot(grepl("20,000 females", output$case_baseline_text$html, fixed = TRUE))
  stopifnot(!is.null(output$projection_plot), !is.null(output$case_plot))
})

cat("Reactive server smoke test passed.\n")
