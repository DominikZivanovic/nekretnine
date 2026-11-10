rm(list=ls()) #Reset za čistu okolinu bez prijašnjih varijabli

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(usethis)

#Spremanje tablica u R
transakcije_original <- read_excel(file.choose(), sheet="Stanovi i apartmani",
                                   .name_repair="minimal"
                                   )
priustivost_original <- read_excel(file.choose(), sheet=1,
                                   .name_repair="minimal"
                                   )
cijene_original <- read_excel(file.choose(), sheet="Stanovi_apartmani EUR",
                              .name_repair="minimal"
                              )

#Pomoćne funkcije za čišćenje podataka
odredi_status <- function(x){
  x <- str_trim(as.character(x))
  case_when(is.na(x)|x==""~"nedostaje", x=="."~"nema_transakcija",
            x=="z"~"potisnuto", TRUE~"opservirano")
}
pretvori_broj <- function(x){
  x <- str_trim(as.character(x))
  x[x %in% c("", ".", "z")] <- NA_character_
  parse_number(x, locale=locale(decimal_mark="."))
}


###############################################################################
########################### ČIŠĆENJE PODATAKA #################################
###############################################################################

############################## TRANSAKCIJE ####################################

transakcije_original <- transakcije_original[!is.na(transakcije_original[[1]]),1:17]
names(transakcije_original)[1:3] <- c("sifra", "zupanija", "jls")
godine <- names(transakcije_original)[4:17]

#PIPELINE
#Početak
transakcije <- transakcije_original %>%
  pivot_longer(cols=all_of(godine), names_to="godina_original",
               values_to="vrijednost_original"
               ) %>%
  mutate(sifra=as.integer(sifra), godina=as.integer(str_extract(godina_original, "\\d{4}")),
         status=odredi_status(vrijednost_original),
         broj_transakcija = case_when(status=="nema_transakcija"~0,
                                      status=="opservirano"~pretvori_broj(vrijednost_original),
                                      TRUE~NA_real_
                                      )
         ) %>%
  select(sifra, jls, zupanija, godina, broj_transakcija, status)
#Kraj

############################# PRIUŠTIVOST #####################################

priustivost_original <- priustivost_original[!is.na(priustivost_original[[4]]), 1:5]
names(priustivost_original) <- c("jls", "zupanija", "tip_jls", "sifra",
                                 "indeks_original"
                                 )

#PIPELINE
#Početak
priustivost <- priustivost_original %>%
  mutate(sifra=as.integer(sifra), godina=2024, status=odredi_status(indeks_original),
         indeks_priustivosti=pretvori_broj(indeks_original)
         ) %>%
  select(sifra, jls, zupanija, tip_jls, godina, indeks_priustivosti, status)
#Kraj

################################## CIJENE #####################################

cijene_original <- cijene_original[!is.na(cijene_original[[1]]), 1:18]
names(cijene_original)[1:4] <- c("sifra", "zupanija", "jls", "tip_jls")
godine <- names(cijene_original)[5:18]

#PIPELINE
#Početak
cijene <- cijene_original %>%
  pivot_longer(cols=all_of(godine), names_to="godina_original",
               values_to="vrijednost_original"
  ) %>%
  mutate(sifra=as.integer(sifra), godina=as.integer(str_extract(godina_original, "\\d{4}")),
         status=odredi_status(vrijednost_original),
         cijena_po_m2 = case_when(status=="opservirano"~pretvori_broj(vrijednost_original),
                                  TRUE~NA_real_
         )
  ) %>%
  select(sifra, jls, zupanija, godina, cijena_po_m2, status)
#Kraj

############################ PROVJERA ČIŠĆENJA ################################

nrow(transakcije)
nrow(priustivost)
nrow(cijene)

n_distinct(transakcije$sifra)
n_distinct(priustivost$sifra)
n_distinct(cijene$sifra)

#Provjera duplih vrijednosti
transakcije %>%
  count(sifra, godina) %>%
  filter(n>1)

priustivost %>%
  count(sifra, godina) %>%
  filter(n>1)

cijene %>%
  count(sifra, godina) %>%
  filter(n>1)

#Provjera statusa
transakcije %>%
  count(godina, status)

priustivost %>%
  count(status)

cijene %>%
  count(status)

########################## SPREMANJE ČISTIH DATOTEKA ##########################

write_csv(transakcije, "Podaci/Cisto/transakcije.csv")
write_csv(priustivost, "Podaci/Cisto/priustivost.csv")
write_csv(cijene, "Podaci/Cisto/cijene.csv")



###############################################################################
####################### POVEZIVANJE NA POSTGRESQL #############################
###############################################################################

library(DBI)
library(RPostgres)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "Nekretnine",
  host = "localhost",
  port = 1402,
  user = "postgres",
  password = Sys.getenv("PGPASSWORD")
)

jls <- transakcije %>%
  distinct(sifra, jls, zupanija)
stopifnot(nrow(jls)==n_distinct(jls$sifra))

dbWriteTable(con, "stg_jls", jls, temporary=T, overwrite=T)
dbExecute(con, "
  INSERT INTO jls
    (sifra, jls, zupanija)
  SELECT sifra, jls, zupanija
  FROM stg_jls
  ON CONFLICT (sifra)
  DO UPDATE SET
    jls = EXCLUDED.jls,
    zupanija = EXCLUDED.zupanija;
")

dbWriteTable(con, "stg_transakcije", transakcije, temporary=T, overwrite=T)
dbExecute(con, "
  INSERT INTO transakcije
    (sifra, godina, broj_transakcija, status)
  SELECT sifra, godina, broj_transakcija, status
  FROM stg_transakcije
  ON CONFLICT (sifra, godina)
  DO UPDATE SET
    broj_transakcija = EXCLUDED.broj_transakcija,
    status = EXCLUDED.status;
")

dbWriteTable(con, "stg_priustivost", priustivost, temporary=T, overwrite=T)
dbExecute(con, "
  INSERT INTO priustivost
    (sifra, godina, indeks_priustivosti, status)
  SELECT sifra, godina, indeks_priustivosti, status
  FROM stg_priustivost
  ON CONFLICT (sifra, godina)
  DO UPDATE SET
    indeks_priustivosti = EXCLUDED.indeks_priustivosti,
    status = EXCLUDED.status;
")

dbWriteTable(con, "stg_cijene", cijene, temporary=T, overwrite=T)
dbExecute(con, "
  INSERT INTO cijene
    (sifra, godina, cijena_po_m2, status)
  SELECT sifra, godina, cijena_po_m2, status
  FROM stg_cijene
  ON CONFLICT (sifra, godina)
  DO UPDATE SET
    cijena_po_m2 = EXCLUDED.cijena_po_m2,
    status = EXCLUDED.status;
")

dbDisconnect(con)