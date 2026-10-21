# Matrices for Biologists

An interactive R Shiny app for teaching why linear algebra matters in biology.
Students can build a stage-structured projection matrix, follow a population
through time, interpret its dominant eigenvalue and stable stage structure,
explore elasticity, and compare baseline and oil-impact scenarios.

## Learning goals

After using the app, students should be able to:

- interpret rows, columns, and entries of a population projection matrix;
- calculate one projection step conceptually as `n(t + 1) = A n(t)`;
- connect repeated matrix multiplication with long-term population change;
- interpret the dominant eigenvalue and stable stage distribution;
- use elasticity to compare proportional effects of demographic rates; and
- explain how counterfactual population trajectories support impact assessment.

## Teaching model

The Matrix Lab uses a female-only, two-stage model:

```text
                         stage at time t
                  female juvenile   adult female
female juvenile        [  0              F  ]
adult female            [  SJ             SA ]
```

`F` is female offspring per adult female, `SJ` is female juvenile survival to
adulthood, and `SA` is adult female survival. Males are not tracked and are
assumed not to limit reproduction.

The default values reproduce the supplied Mathematics for Biologists example:
`F = 2`, `SJ = 1/2`, `SA = 1/3`, and initial state `(10, 20)`.

The oil-spill section is a simplified conceptual model inspired by a published
Deepwater Horizon cetacean population assessment. It has a controllable initial
abundance, a stable pre-impact population (`lambda = 1`), reduced survival and
fecundity after exposure, gradual recovery of vital rates, and a simple
density-dependent fecundity response. It is not a reproduction of the paper's
fitted model, parameters, uncertainty analysis, or species-specific results.

## Requirements

- R 4.2 or later
- The [`shiny`](https://cran.r-project.org/package=shiny) package

Install the dependency once from an R console:

```r
install.packages("shiny")
```

## Run locally

Clone the repository, open an R session in its root directory, and run:

```r
shiny::runApp()
```

Alternatively, use the platform-neutral launcher:

```sh
Rscript run_app.R
```

The app opens in the default browser. Stop it with `Ctrl+C` in the terminal or
the Stop button in RStudio.

## Repository structure

```text
.
|-- app.R                 # Shiny interface and server logic
|-- R/
|   `-- model.R           # Matrix projections and impact calculations
|-- tests/
|   |-- test-model.R      # Numerical model checks
|   `-- test-server.R     # Reactive Shiny smoke test
|-- www/
|   `-- styles.css        # App styling
|-- run_app.R             # Cross-platform launcher
`-- .github/workflows/    # Continuous integration
```

## Run the tests

From the repository root:

```sh
Rscript tests/test-model.R
Rscript tests/test-server.R
```

The tests use base R assertions and Shiny's built-in server testing support, so
no additional testing package is required.

## Suggested classroom sequence

1. Ask students to predict whether the default population grows or declines.
2. Use the Matrix Lab to connect each matrix entry to a biological process.
3. Change one demographic rate at a time and compare short- and long-term effects.
4. Use the Sensitivity tab to discuss equal elasticities of fecundity and juvenile
   survival in this particular two-stage construction.
5. Build an oil-impact scenario and discuss counterfactuals, recovery assumptions,
   and the interpretation of population-level injury metrics.

## Scientific scope

This is an educational application, not a tool for wildlife-management decisions.
Its parameter values are user-controlled illustrations and should not be interpreted
as estimates for any species or population.

The case study was inspired by:

> Marques, T. A., Thomas, L., Booth, C. G., Garrison, L. P., Rosel, P. E.,
> Takeshita, R., Mullin, K. D., & Schwacke, L. H. (2023). Population consequences
> of the Deepwater Horizon oil spill on pelagic cetaceans. *Marine Ecology Progress
> Series, 714*, 1-14.

## Contributing

Bug reports and teaching suggestions are welcome. Please read
[`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request.

## License

No open-source license has yet been selected. Add a `LICENSE` file before public
release if you want others to be legally permitted to reuse or modify the project.
