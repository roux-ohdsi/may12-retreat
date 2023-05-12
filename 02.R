# packages
library(ohdsilab)
library(ROhdsiWebApi)
library(Eunomia)
library(tidyverse)

# Credentials
usr <- keyring::key_get("lab_user")
pw <- keyring::key_get("lab_password")

# DB Connections
connectionDetails <- getEunomiaConnectionDetails()
con <- connect(connectionDetails)

cdm_schema <- "main"
options(con.default.value = con)
options(schema.default.value = cdm_schema)
options(write_schema.default.value = cdm_schema)

atlas_url <- "https://atlas.roux-ohdsi-prod.aws.northeastern.edu/WebAPI"
options(atlas_url.default.value = atlas_url)

authorizeWebApi(
  atlas_url,
  authMethod = "db",
  webApiUsername = usr,
  webApiPassword = pw
)

# create fake cohorts
my_cohort <- "cohort"
createCohorts(connectionDetails)


# use the snippet


cohort <- tbl(con, paste("main", my_cohort, sep = ".")) |>
  select(person_id = subject_id, cohort_start_date, cohort_end_date) |>
  mutate(
    covariate_start_date = dateAdd("year", -1, cohort_start_date),
    txt_end_date = dateAdd("day", 4 * 30.25, cohort_start_date)
  )

ART <- pull_concept_set(cohort,
                        concept_set_id = 1125, concept_set_name = "ART", 
                        start_date = cohort_start_date, end_date = txt_end_date, 
                        keep_all = TRUE
)
IUI <- pull_concept_set(cohort,
                        concept_set_id = 1124, concept_set_name = "IUI",
                        start_date = cohort_start_date, end_date = txt_end_date
)

# Pull a concept set you create... (hopefully some matching concepts!)
