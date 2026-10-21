# Contributing

Contributions that improve biological clarity, accessibility, teaching flow, or
model verification are welcome.

## Before opening a pull request

1. Create a focused branch from the default branch.
2. Keep the female-only assumptions explicit in interface text and documentation.
3. Do not present illustrative inputs as empirical species estimates.
4. Run both test scripts from the repository root:

   ```sh
   Rscript tests/test-model.R
   Rscript tests/test-server.R
   ```

5. Describe the teaching or technical reason for the change in the pull request.

For changes to the population model, add a numerical assertion to
`tests/test-model.R`. For changes to reactive outputs, extend
`tests/test-server.R` where practical.
