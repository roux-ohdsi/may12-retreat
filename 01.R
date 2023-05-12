# to install all packages w/ correct versions:
# install.packages("renv")
# renv::restore() 

# if not using renv (USE RENV!), can install the packages individually
# install.packages("remotes)
# remotes::install_github("roux-ohdsi/ohdsilab")
# install.packages("pkgdepends")
# pd <- pkgdepends::pkg_download_proposal$new("roux-ohdsi/ohdsilab", config = list(dependencies = "Suggests"))
# pd$resolve()
# pkgs <- pd$get_resolution()
# install.packages(pkgs[pkgs$status == "OK", "ref"])
# remotes::install_github("OHDSI/ROhdsiWebAPI")
# remotes::install_github("OHDSI/Eunomia")
# install.packages("tidyverse")

# packages
library(ohdsilab)
library(Eunomia)
library(dplyr)

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

# access the person table
person_tbl <- tbl(con, inDatabaseSchema(cdm_schema, "person")) |> 
  select(-provider_id) # don't know why this is there but shouldn't be!

# sql code isn't run until you print the table or collect() it
person_tbl
tally(person_tbl)
# now is a regular dataframe in your R session
person <- collect(person_tbl)

# join with the procedure table
df <- person_tbl |> 
  left_join( # left join because we want to keep all the people even if they never had a procedure
    tbl(con, inDatabaseSchema(cdm_schema, "procedure_occurrence")),
    by = "person_id"
  ) |> 
  left_join(
    tbl(con, inDatabaseSchema(cdm_schema, "concept")),
        by = c("procedure_concept_id" = "concept_id")
  ) |> 
  collect() # make it local (don't do until you're sure!)

df |> 
  select(person_id, birth_datetime, procedure_date, procedure_concept_id, 
         concept_name, domain_id, vocabulary_id, concept_code)

# same table using ohdsilab function
df2 <- person_tbl |> 
  omop_join("procedure_occurrence", type = "left", by = "person_id") |> 
  omop_join("concept", type = "left", by = c("procedure_concept_id" = "concept_id")) |> 
  collect()
df2

person_tbl <- person_tbl |> 
  mutate(
  age_30 = dateAdd("year",  30, birth_datetime),
  age_40 = dateAdd("year", 40, birth_datetime)
)

person_tbl |> 
  select(person_id, birth_datetime, age_30, age_40)

some_procedures <- person_tbl |> 
  omop_join("procedure_occurrence", type = "left", 
            by = join_by(person_id, between(y$procedure_datetime, x$age_30, x$age_40))) |> 
  omop_join("concept", type = "left", by = c("procedure_concept_id" = "concept_id")) |> 
  select(person_id, birth_datetime, procedure_datetime, concept_name)

show_query(some_procedures)

some_procedures
# why some NAs in procedures?




# CHALLENGES

# replace the ethnicity_concept_id, race_concept_id, gender_concept_id 
# in the person_tbl with their actual values

# find the first procedure after someone's 18th birthday
# using a join_by specification
