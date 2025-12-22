# Generating a Report

## Context

The [CCAS report generator](../../CCAS_report_generator.Rmd)
creates a report for one facility. However, this file should
not be called directly by the user, and should generally remain
untouched aside from report format updates. If a user wants
to generate a report manually, they should instead
call the `generate_one_report` function in
[this file](../../libraries/generate_report.R). Documentation
for this function can be found [here](../references/generate_report_ref.md).