source(file.path("R", "model.R"))

A <- projection_matrix(2, .5, 1/3)
stopifnot(identical(dim(A), c(2L, 2L)))
stopifnot(isTRUE(all.equal(as.numeric(A %*% c(10, 20)), c(40, 35/3))))

p <- project_population(A, c(10, 20), 5)
stopifnot(nrow(p) == 6, all(p$total >= 0), p$year[1] == 0, p$year[6] == 5)

s <- matrix_summary(A)
stopifnot(s$lambda > 0, abs(sum(s$stable) - 1) < 1e-10)

case <- impact_projection(A, c(10, 20), 20, .3, .15, .35, 3, 12)
m <- injury_metrics(case$baseline, case$impacted)
stopifnot(all(case$impacted$total <= case$baseline$total + 1e-8))
stopifnot(m$lost_population_years > 0, m$max_proportional_decrease > 0)

E <- elasticity_matrix(A)
stopifnot(all(is.finite(E)), all(E >= 0), E[1, 1] == 0)

oil <- oil_spill_projection(20000, 40, .45, .85, .3, .15, .35, 3, 12, 1.5)
stopifnot(max(abs(oil$baseline$total - 20000)) < 1e-6)
stopifnot(min(oil$impacted$total) < 20000)
stopifnot(tail(oil$impacted$total, 1) > min(oil$impacted$total))

cat("All model tests passed.\n")
