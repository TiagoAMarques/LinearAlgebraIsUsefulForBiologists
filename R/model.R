projection_matrix <- function(fecundity, juvenile_survival, adult_survival) {
  matrix(
    c(0, fecundity, juvenile_survival, adult_survival),
    nrow = 2,
    byrow = TRUE,
    dimnames = list(c("Female juveniles next", "Adult females next"),
                    c("Female juveniles now", "Adult females now"))
  )
}

project_population <- function(A, initial, years) {
  stopifnot(is.matrix(A), all(dim(A) == c(2, 2)), length(initial) == 2, years >= 0)
  out <- matrix(0, nrow = years + 1, ncol = 2,
                dimnames = list(NULL, c("Female juveniles", "Adult females")))
  out[1, ] <- initial
  if (years > 0) {
    for (year in seq_len(years)) out[year + 1, ] <- as.numeric(A %*% out[year, ])
  }
  data.frame(year = 0:years, out, total = rowSums(out), check.names = FALSE)
}

matrix_summary <- function(A) {
  eig <- eigen(A)
  idx <- which.max(Re(eig$values))
  lambda <- Re(eig$values[idx])
  stable <- abs(Re(eig$vectors[, idx]))
  stable <- stable / sum(stable)
  list(
    lambda = lambda,
    stable = setNames(stable, c("Female juveniles", "Adult females")),
    timescale = if (abs(lambda - 1) < 1e-8) Inf else log(2) / abs(log(lambda)),
    direction = if (lambda > 1 + 1e-8) "growing" else if (lambda < 1 - 1e-8) "declining" else "stable"
  )
}

impact_projection <- function(A, initial, years, exposed, survival_reduction,
                              fecundity_reduction, impact_years, recovery_years) {
  baseline <- project_population(A, initial, years)
  impacted <- matrix(0, nrow = years + 1, ncol = 2)
  impacted[1, ] <- initial

  multipliers <- data.frame(year = 0:years, survival = 1, fecundity = 1)
  if (years > 0) {
    for (year in seq_len(years)) {
      if (year <= impact_years) {
        progress <- 0
      } else if (recovery_years > 0 && year <= impact_years + recovery_years) {
        progress <- (year - impact_years) / recovery_years
      } else {
        progress <- 1
      }
      s_mult <- 1 - exposed * survival_reduction * (1 - progress)
      f_mult <- 1 - exposed * fecundity_reduction * (1 - progress)
      At <- A
      At[1, 2] <- A[1, 2] * f_mult
      At[2, ] <- A[2, ] * s_mult
      impacted[year + 1, ] <- as.numeric(At %*% impacted[year, ])
      multipliers$survival[year + 1] <- s_mult
      multipliers$fecundity[year + 1] <- f_mult
    }
  }
  impacted <- data.frame(year = 0:years, `Female juveniles` = impacted[, 1],
                         `Adult females` = impacted[, 2],
                         total = rowSums(impacted), check.names = FALSE)
  list(baseline = baseline, impacted = impacted, multipliers = multipliers)
}

oil_spill_projection <- function(initial_total, years, juvenile_survival,
                                 adult_survival, exposed, survival_reduction,
                                 fecundity_reduction, impact_years,
                                 recovery_years, density_compensation) {
  stopifnot(initial_total > 0, juvenile_survival > 0,
            adult_survival >= 0, adult_survival < 1)

  # Choose nominal fecundity so the dominant eigenvalue is exactly one.
  # The pre-impact population is therefore at carrying capacity and stable.
  nominal_fecundity <- (1 - adult_survival) / juvenile_survival
  A <- projection_matrix(nominal_fecundity, juvenile_survival, adult_survival)
  stable <- matrix_summary(A)$stable
  initial <- initial_total * stable
  baseline <- project_population(A, initial, years)

  impacted <- matrix(0, nrow = years + 1, ncol = 2)
  impacted[1, ] <- initial
  multipliers <- data.frame(year = 0:years, survival = 1, fecundity = 1,
                            density_boost = 1)

  if (years > 0) {
    for (year in seq_len(years)) {
      if (year <= impact_years) {
        progress <- 0
      } else if (recovery_years > 0 && year <= impact_years + recovery_years) {
        progress <- (year - impact_years) / recovery_years
      } else {
        progress <- 1
      }

      abundance_ratio <- sum(impacted[year, ]) / initial_total
      density_boost <- 1 + density_compensation * max(0, 1 - abundance_ratio)
      s_mult <- 1 - exposed * survival_reduction * (1 - progress)
      f_mult <- 1 - exposed * fecundity_reduction * (1 - progress)

      At <- A
      At[1, 2] <- A[1, 2] * f_mult * density_boost
      At[2, ] <- A[2, ] * s_mult
      impacted[year + 1, ] <- as.numeric(At %*% impacted[year, ])
      multipliers[year + 1, c("survival", "fecundity", "density_boost")] <-
        c(s_mult, f_mult, density_boost)
    }
  }

  impacted <- data.frame(
    year = 0:years, `Female juveniles` = impacted[, 1],
    `Adult females` = impacted[, 2], total = rowSums(impacted),
    check.names = FALSE
  )
  list(baseline = baseline, impacted = impacted, multipliers = multipliers,
       matrix = A, nominal_fecundity = nominal_fecundity)
}

injury_metrics <- function(baseline, impacted, recovery_threshold = 0.95) {
  difference <- pmax(0, baseline$total - impacted$total)
  ratio <- ifelse(baseline$total > 0, impacted$total / baseline$total, 1)
  below <- which(ratio < recovery_threshold)
  ytr <- if (!length(below)) 0 else {
    after_min <- seq.int(which.min(ratio), length(ratio))
    recovered <- after_min[ratio[after_min] >= recovery_threshold]
    if (length(recovered)) baseline$year[recovered[1]] else NA_real_
  }
  list(
    lost_population_years = sum(difference),
    max_proportional_decrease = max(1 - ratio),
    year_to_recovery = ytr
  )
}

elasticity_matrix <- function(A, epsilon = 1e-5) {
  base <- matrix_summary(A)$lambda
  out <- matrix(NA_real_, nrow = nrow(A), ncol = ncol(A), dimnames = dimnames(A))
  for (i in seq_len(nrow(A))) {
    for (j in seq_len(ncol(A))) {
      if (A[i, j] == 0) {
        out[i, j] <- 0
      } else {
        perturbed <- A
        perturbed[i, j] <- A[i, j] * (1 + epsilon)
        out[i, j] <- ((matrix_summary(perturbed)$lambda - base) / base) / epsilon
      }
    }
  }
  out
}
