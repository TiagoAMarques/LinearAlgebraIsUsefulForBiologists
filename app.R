library(shiny)

source(file.path("R", "model.R"))

fmt <- function(x, digits = 2) formatC(x, format = "f", digits = digits, big.mark = ",")

matrix_html <- function(A, symbolic = FALSE) {
  values <- if (symbolic) c("0", "F", "S<sub>J</sub>", "S<sub>A</sub>") else sprintf("%.2f", as.numeric(t(A)))
  cells <- sprintf("<span class='matrix-cell'>%s</span>", values)
  HTML(paste0(
    "<div class='matrix-display'><strong>A</strong> = ",
    "<div class='matrix-layout'>",
    "<div class='matrix-column-labels'><span>Female juveniles now</span><span>Adult females now</span></div>",
    "<div class='matrix-row-labels'><span>Female juveniles<br>next year</span><span>Adult females<br>next year</span></div>",
    "<div class='matrix-grid'>", paste(cells, collapse = ""), "</div>",
    "</div>",
    "<div class='matrix-meaning'><strong>F</strong> = female offspring per adult female; ",
    "<strong>S<sub>J</sub></strong> = female juvenile survival to adulthood; ",
    "<strong>S<sub>A</sub></strong> = adult female survival.</div>",
    "<div>n<sub>t+1</sub> = A n<sub>t</sub></div></div>"
  ))
}

metric_box <- function(value, label) {
  div(class = "metric-card", div(class = "metric-number", value), div(class = "metric-label", label))
}

ui <- navbarPage(
  title = "Matrices for Biologists",
  id = "page",
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
  ),
  tabPanel(
    "Why matrices?",
    div(class = "why-page",
    fluidPage(
      div(class = "hero",
          h1("A population is a vector. Biology is the matrix."),
          p("Follow individuals through life stages, predict many generations with one rule, and see how eigenvalues turn a table of vital rates into a biological forecast.")),
      fluidRow(
        column(12, div(class = "matrix-card story-panel", h3("1. Describe the state"),
                      p("In this female-only model, put female juveniles and adult females into a column vector."),
                      div(class="matrix-display", HTML("n<sub>t</sub> = ( J<sub>female,t</sub>, A<sub>female,t</sub> )<sup>T</sup>")))),
        column(12, div(class = "matrix-card story-panel", h3("2. Encode transitions"),
                      p("Rows describe next year; columns describe this year. Every entry has a biological meaning."),
                      matrix_html(matrix(0, 2, 2), symbolic = TRUE))),
        column(12, div(class = "matrix-card story-panel", h3("3. Project and interpret"),
                      p("Multiplication advances one year. Powers of the matrix advance many years."),
                      div(class="matrix-display", HTML("n<sub>t+k</sub> = A<sup>k</sup> n<sub>t</sub>"))))
      ),
      br(),
      div(class = "teaching-note",
          strong("The key idea: "),
          "a matrix is not merely a rectangular calculation. It is a compact hypothesis about how a biological system changes."),
      div(class = "story-step", h3("Try the Matrix lab next"),
          p("Start with the values from the Mathematics for Biologists slides, interpreted here as a female-only model: each adult female produces 2 female juveniles, half the female juveniles mature, and one third of adult females survive."))
    ))
  ),
  tabPanel(
    "Matrix lab",
    sidebarLayout(
      sidebarPanel(
        h3("Build a female-only projection matrix"),
        div(class="teaching-note", "Only females are counted. Fecundity is female offspring per adult female; males are assumed not to limit reproduction."),
        br(),
        sliderInput("fecundity", "Fecundity F (female juveniles per adult female)", 0, 4, 2, .05),
        sliderInput("juvenile_survival", "Female juvenile survival to adulthood SJ", 0, 1, .5, .01),
        sliderInput("adult_survival", "Adult female survival SA", 0, 1, 1/3, .01),
        hr(),
        numericInput("initial_juveniles", "Initial female juveniles", 10, min = 0),
        numericInput("initial_adults", "Initial adult females", 20, min = 0),
        sliderInput("years", "Projection horizon (years)", 1, 50, 20, 1),
        actionButton("reset_slides", "Reset to slide example", class = "btn-primary")
      ),
      mainPanel(
        fluidRow(
          column(5, div(class = "matrix-card", uiOutput("matrix_display"))),
          column(7, fluidRow(
            column(4, uiOutput("lambda_box")),
            column(4, uiOutput("trend_box")),
            column(4, uiOutput("mix_box"))
          ))
        ),
        br(),
        div(class = "matrix-card", plotOutput("projection_plot", height = "390px")),
        br(),
        fluidRow(
          column(6, div(class = "explain-card", h3("Read the multiplication"), uiOutput("first_step"))),
          column(6, div(class = "explain-card", h3("Why the dominant eigenvalue matters"), uiOutput("eigen_explanation")))
        )
      )
    )
  ),
  tabPanel(
    "Oil-spill case study",
    sidebarLayout(
      sidebarPanel(
        h3("Set an impact scenario"),
        p(class="small-note", "This is a deliberately simplified teaching model inspired by the supplied cetacean study; it is not a reproduction of its fitted model or results."),
        numericInput("case_population", "Pre-spill female population", 20000, min = 100, step = 100),
        sliderInput("case_juvenile_survival", "Baseline female juvenile survival", .1, .9, .45, .01),
        sliderInput("case_adult_survival", "Baseline adult female survival", .5, .98, .85, .01),
        sliderInput("exposed", "Population exposed", 0, 1, .30, .01, post = ""),
        sliderInput("survival_reduction", "Survival reduction among exposed", 0, .5, .15, .01),
        sliderInput("fecundity_reduction", "Fecundity reduction among exposed", 0, .8, .35, .01),
        sliderInput("impact_years", "Years with maximum oil-related effects", 1, 10, 3, 1),
        p(class="small-note",
          "During these years, the selected survival and fecundity reductions remain fully in force. Afterward, those vital rates return gradually to their baseline values over the recovery period below."),
        sliderInput("recovery_years", "Additional years to recover vital rates", 0, 30, 12, 1),
        sliderInput("density_compensation", "Density-dependent reproductive compensation", 0, 3, 1.5, .1),
        sliderInput("case_horizon", "Projection horizon", 10, 75, 40, 1)
      ),
      mainPanel(
        fluidRow(
          column(4, uiOutput("lost_box")),
          column(4, uiOutput("mpd_box")),
          column(4, uiOutput("recovery_box"))
        ),
        br(),
        div(class="matrix-card",
            span(class="legend-chip baseline-chip", "Baseline"),
            span(class="legend-chip impact-chip", "Impacted"),
            plotOutput("case_plot", height="410px")),
        br(),
        div(class="teaching-note",
            strong("From algebra to evidence: "),
            "the pre-spill matrix is calibrated to λ = 1, so the baseline remains at carrying capacity. After a decline, lower density raises fecundity and permits recovery. The gap between trajectories is summarized as lost population-years, maximum proportional decrease, and time to recovery."),
        br(),
        div(class="matrix-card", h4("Case-study baseline"), uiOutput("case_baseline_text"))
      )
    )
  ),
  tabPanel(
    "Sensitivity",
    fluidPage(
      div(class="hero", h1("Which life-history rate matters most?"),
          p("Elasticity asks: if a matrix entry changes by 1%, by what percentage does long-run growth change? This makes rates measured on different scales comparable.")),
      fluidRow(
        column(12, div(class="matrix-card sensitivity-panel", plotOutput("elasticity_plot", height="500px"))),
        column(12, div(class="matrix-card sensitivity-panel", h3("Interpretation"), uiOutput("elasticity_text"),
                      hr(), h4("A useful conservation question"),
                      p("Should limited effort improve juvenile survival, adult survival, or reproduction? The answer depends on the whole matrix—not on a rate viewed in isolation.")))
      )
    )
  ),
  tabPanel(
    "Teaching notes",
    fluidPage(
      div(class="hero", h1("A 20-minute classroom sequence"),
          p("Use prediction, manipulation, and interpretation to make the algebra earn its biological meaning.")),
      fluidRow(
        column(4, div(class="matrix-card", h3("Predict · 3 min"),
                      p("Ask whether the slide-example population will grow or decline before revealing lambda. Ask which stage will dominate."))),
        column(4, div(class="matrix-card", h3("Experiment · 10 min"),
                      p("Students change one rate at a time, then compare equal proportional changes using the elasticity view."))),
        column(4, div(class="matrix-card", h3("Apply · 7 min"),
                      p("Create a hypothetical oil-impact scenario. Discuss the baseline counterfactual, recovery assumptions, and what the three injury metrics do—and do not—capture.")))
      ),
      br(),
      div(class="matrix-card", h3("Source grounding and scope"),
          p("The matrix example and notation follow the supplied Mathematics for Biologists slides. The case-study structure follows the supplied Deepwater Horizon cetacean paper: compare baseline and impacted population trajectories, vary survival and fecundity, allow recovery, and summarize population-level injury."),
          p(class="small-note", "The published study used a substantially richer sex- and age-structured model, exposure classes, density-dependent fecundity, parameter uncertainty, and Monte Carlo simulation. Values selected here are user-controlled pedagogical inputs and must not be interpreted as estimates for any species."))
    )
  )
)

server <- function(input, output, session) {
  observeEvent(input$reset_slides, {
    updateSliderInput(session, "fecundity", value = 2)
    updateSliderInput(session, "juvenile_survival", value = .5)
    updateSliderInput(session, "adult_survival", value = 1/3)
    updateNumericInput(session, "initial_juveniles", value = 10)
    updateNumericInput(session, "initial_adults", value = 20)
  })

  A <- reactive(projection_matrix(input$fecundity, input$juvenile_survival, input$adult_survival))
  initial <- reactive(c(input$initial_juveniles, input$initial_adults))
  summary_A <- reactive(matrix_summary(A()))
  projection <- reactive(project_population(A(), initial(), input$years))

  output$matrix_display <- renderUI(matrix_html(A()))
  output$lambda_box <- renderUI(metric_box(fmt(summary_A()$lambda, 3), "Dominant eigenvalue λ"))
  output$trend_box <- renderUI(metric_box(tools::toTitleCase(summary_A()$direction), "Long-run trend"))
  output$mix_box <- renderUI(metric_box(paste0(fmt(100 * summary_A()$stable["Adult females"], 0), "%"), "Stable adult-female share"))

  output$projection_plot <- renderPlot({
    dat <- projection()
    matplot(dat$year, dat[, c("Female juveniles", "Adult females")], type="l", lwd=3, lty=1,
            col=c("#087f8c", "#e76f51"), xlab="Year", ylab="Number of individuals",
            main="Stage-structured population projection")
    legend("topleft", c("Female juveniles", "Adult females"), col=c("#087f8c", "#e76f51"), lwd=3, bty="n")
    grid(col="#dce7e5")
  }, res = 110)

  output$first_step <- renderUI({
    first <- as.numeric(A() %*% initial())
    HTML(sprintf(
      "<p><strong>Female juveniles next year:</strong> 0 × %.1f female juveniles + %.2f × %.1f adult females = <strong>%.2f</strong></p><p><strong>Adult females next year:</strong> %.2f × %.1f female juveniles + %.2f × %.1f adult females = <strong>%.2f</strong></p>",
      initial()[1], A()[1,2], initial()[2], first[1], A()[2,1], initial()[1], A()[2,2], initial()[2], first[2]
    ))
  })

  output$eigen_explanation <- renderUI({
    s <- summary_A()
    time_text <- if (is.infinite(s$timescale)) "It neither doubles nor halves." else
      sprintf("At the long-run rate it takes about %.1f years to %s.", s$timescale,
              if (s$lambda > 1) "double" else "halve")
    p(sprintf("The dominant eigenvalue is %.3f: after transient stage effects fade, total abundance is multiplied by roughly this factor each year. %s", s$lambda, time_text))
  })

  case_data <- reactive(oil_spill_projection(
    input$case_population, input$case_horizon, input$case_juvenile_survival,
    input$case_adult_survival, input$exposed, input$survival_reduction,
    input$fecundity_reduction, input$impact_years, input$recovery_years,
    input$density_compensation
  ))
  metrics <- reactive(injury_metrics(case_data()$baseline, case_data()$impacted))

  output$lost_box <- renderUI(metric_box(fmt(metrics()$lost_population_years, 0), "Lost population-years"))
  output$mpd_box <- renderUI(metric_box(paste0(fmt(100 * metrics()$max_proportional_decrease, 1), "%"), "Maximum decrease"))
  output$recovery_box <- renderUI(metric_box(
    if (is.na(metrics()$year_to_recovery)) paste0(">", input$case_horizon) else fmt(metrics()$year_to_recovery, 0),
    "Year reaching 95% of baseline"
  ))

  output$case_baseline_text <- renderUI({
    x <- case_data()
    HTML(sprintf(
      "<p>The model begins with <strong>%s females</strong> at carrying capacity. Baseline fecundity is calibrated to <strong>%.3f female offspring per adult female</strong>, giving a dominant eigenvalue of exactly <strong>1.000</strong>.</p><p class='small-note'>This keeps the no-spill trajectory flat. Density-dependent reproduction operates only as the impacted population falls below carrying capacity.</p>",
      formatC(input$case_population, format="f", digits=0, big.mark=","),
      x$nominal_fecundity
    ))
  })

  output$case_plot <- renderPlot({
    x <- case_data()
    ymax <- max(x$baseline$total, x$impacted$total)
    plot(x$baseline$year, x$baseline$total, type="l", lwd=3, col="#087f8c",
         xlab="Years since impact", ylab="Total population", ylim=c(0, ymax * 1.04),
         main="Counterfactual population trajectories")
    lines(x$impacted$year, x$impacted$total, lwd=3, col="#e76f51")
    polygon(c(x$baseline$year, rev(x$impacted$year)),
            c(x$baseline$total, rev(x$impacted$total)), col=adjustcolor("#e9c46a", .35), border=NA)
    lines(x$baseline$year, x$baseline$total, lwd=3, col="#087f8c")
    lines(x$impacted$year, x$impacted$total, lwd=3, col="#e76f51")
    abline(v=input$impact_years, lty=3, col="#60748a")
    grid(col="#dce7e5")
  }, res=110)

  output$elasticity_plot <- renderPlot({
    E <- elasticity_matrix(A())
    old_par <- par(mar=c(6.5, 7.5, 4, 2) + .1)
    on.exit(par(old_par), add=TRUE)
    image(1:2, 1:2, t(E[2:1, ]), col=hcl.colors(20, "Teal"), axes=FALSE,
          xlab="", ylab="", main="Elasticity of λ")
    axis(1, at=1:2, labels=c("Female\njuveniles", "Adult\nfemales"), padj=.5)
    axis(2, at=1:2, labels=rev(c("Female juveniles", "Adult females")), las=1, hadj=1)
    mtext("Stage now (matrix columns)", side=1, line=4.5, font=2)
    mtext("Stage next year (matrix rows)", side=2, line=5.6, font=2)
    for (i in 1:2) for (j in 1:2) {
      val <- E[3-j, i]
      text(i, j, if (val == 0) "structural zero" else sprintf("%.3f", val), font=2, col=if(val > max(E)*.6) "white" else "#17324d")
    }
  }, res=110)

  output$elasticity_text <- renderUI({
    E <- elasticity_matrix(A())
    labels <- matrix(c("juvenile retention", "juvenile maturation", "fecundity", "adult survival"), 2, 2)
    idx <- arrayInd(which.max(E), dim(E))
    tagList(
      p(HTML(sprintf("For the current matrix, <strong>%s</strong> has the largest elasticity (%.3f). A 1%% increase in this rate produces approximately a %.2f%% increase in λ near the current values.",
                     labels[idx[1], idx[2]], E[idx[1], idx[2]], E[idx[1], idx[2]]))),
      div(class="teaching-note",
          strong("Why are the two off-diagonal values equal? "),
          HTML("Yes—this happens by construction in this two-stage model. Its dominant eigenvalue depends on fecundity and juvenile survival through their product, <em>F × S<sub>J</sub></em>. A 1% proportional change in either factor therefore produces the same proportional change in that product, and hence the same elasticity of λ. The equality need not hold in a richer age- or stage-structured matrix."))
    )
  })
}

shinyApp(ui, server)
