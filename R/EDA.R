rm(list=ls()) #Za resetiranje okoline

library(DBI)
library(RPostgres)
library(dplyr)
library(ggplot2)
library(tidyr)
library(diptest)
library(readxl)
library(readr)
library(stringr)
library(stringi)
library(lmtest)
library(latex2exp)

#Pomoćna funkcija za temu grafova
tema_grafa <- function(){
  theme_minimal()+
  theme(
    #Naslov
    plot.title=element_text(size=16, face="bold", color="grey20", hjust=0.5),
    #Podnaslov
    plot.subtitle=element_text(size=11, color="grey20", margin=margin(b=15), hjust=0.5),
    #Nazivi osi
    axis.title=element_text(size=11, face="bold", color="grey20"),
    #Vrijednosti na osima
    axis.text=element_text(size=9, color="grey30"),
    #Grid
    panel.grid.minor=element_line(color="grey90", linewidth=0.1),
    panel.grid.major=element_line(color="grey75", linewidth=0.5),
    #Legenda
    legend.position="top",
    legend.title=element_blank(),
    #Izvor podataka
    plot.caption=element_text(size=9, color="grey30", hjust=0, margin=margin(t=12)),
    #Margine
    plot.margin = margin(t=20, r=20, b=20, l=20)
  )
}

#Povezivanje na PostgreSQL
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "Nekretnine",
  host = "localhost",
  port = 1402,
  user = "postgres",
  password = Sys.getenv("PGPASSWORD")
)

#Učitavanje podataka
jls <- dbReadTable(con, "jls")
transakcije <- dbReadTable(con, "transakcije")
priustivost <- dbReadTable(con, "priustivost")
cijene <- dbReadTable(con, "cijene")

#Koliko podataka nedostaje?
nrow(jls)
nrow(cijene)
nrow(transakcije)
nrow(priustivost)

transakcije %>%
  count(status)

priustivost %>%
  count(status)

cijene %>%
  count(status)



###############################################################################
################################# TRANSAKCIJE #################################
###############################################################################

godisnje_transakcije <- transakcije %>%
  group_by(godina) %>%
  summarise(broj_transakcija=sum(broj_transakcija, na.rm=T),
            opservirano=sum(status=="opservirano"),
            bez_transakcija=sum(status=="nema_transakcija"),
            potisnuto=sum(status=="potisnuto"),
            nedostaje=sum(status=="nedostaje"),
            broj_jls=n(),
            .groups="drop"
            )

#Prikaz godišnjeg broja transakcija, potisnutih jls i jls bez transakcija
godisnje_transakcije

#Grafa poznatih transakcija bez potisnutih vrijednosti
ggplot(godisnje_transakcije, aes(x=godina, y=broj_transakcija/1000))+
  geom_line(color="grey20", linewidth=0.7)+
  geom_point(color="grey20")+
  scale_x_continuous(breaks=2012:2025)+
  labs(title="Broj transakcija stanova i apartmana (u tisućama)", x="", y="",
       caption="Izvor: Ekonomski institut, Zagreb. Potisnute vrijednosti nisu uključene."
       )+
  tema_grafa()



###############################################################################
################################## CIJENE #####################################
###############################################################################

godisnje_cijene <- cijene %>%
  group_by(godina) %>%
  summarise(
    prosjek=mean(cijena_po_m2[status=="opservirano"], na.rm=T),
    medijan=median(cijena_po_m2[status=="opservirano"], na.rm=T),
    opservirano=sum(status=="opservirano"),
    bez_transakcija=sum(status=="nema_transakcija"),
    potisnuto=sum(status=="potisnuto"),
    nedostaje=sum(status=="nedostaje"),
    broj_jls=n(),
    .groups="drop"
  )

#Prikaz godišnjih medijalnih cijena, potisnutih jls i jls bez transakcija
godisnje_cijene

#Graf medijana i prosjeka medijalnih cijena bez potisnutih vrijednosti
ggplot(godisnje_cijene, aes(x=godina))+
  geom_line(aes(y=prosjek, color="prosjek"), linewidth=0.8)+
  geom_point(aes(y=prosjek, color="prosjek"), size=2)+
  geom_line(aes(y=medijan, color="medijan"), linewidth=0.8)+
  geom_point(aes(y=medijan, color="medijan"), size=2)+
  scale_x_continuous(breaks=2012:2025)+
  scale_y_continuous(labels=scales::label_number(big.mark=".", decimal.mark=","))+
  scale_color_manual(values=c("prosjek"="turquoise3","medijan"="coral"))+
  labs(title="Medijalne cijene po JLS", x="", y="cijena (EUR/m\u00B2)",
       caption="Izvor: Ekonomski institut, Zagreb. Potisnute vrijednosti nisu uključene."
       )+
  tema_grafa()

####################### MEDIJALNE CIJENE PO GODINAMA ##########################

#Graf medijalnih cijena po godinama
ggplot(cijene %>% filter(status=="opservirano"), aes(x=factor(godina), y=cijena_po_m2))+
  geom_boxplot(fill="turquoise3")+
  labs(title="Medijalne cijene po JLS",x="", y="cijena (EUR/m\u00B2)",
       caption="Izvor: Ekonomski institut, Zagreb. Potisnute vrijednosti nisu uključene."
       )+
  tema_grafa()

#Identifikacija outliera
outlieri_godine <- cijene %>%
  filter(status=="opservirano") %>%
  group_by(godina) %>%
  mutate(q1=quantile(cijena_po_m2, 0.25), q3=quantile(cijena_po_m2, 0.75),
         iqr=q3-q1, gornja_granica=q3+1.5*iqr
         ) %>%
  filter(cijena_po_m2>gornja_granica) %>%
  ungroup() %>%
  left_join(jls %>% select(sifra, jls, zupanija), by="sifra") %>%
  select(sifra, jls, zupanija, godina, cijena_po_m2) %>%
  arrange(sifra, godina)

outlieri_godine

#Dubrovnik je u zadoblju od 2012.-2020.g. bio outlier čak 7 puta. Opatija je
#bila outlier 2012. i 2013. godine, a u novije vrijeme su outlieri Bale-Valle u
#Istarskoj županiji te Kukljica u Zadarskoj.

####################### MEDIJALNE CIJENE PO ŽUPANIJAMA ########################

#Uzimamo cijene iz iste godine radi pravedne usporedbe bez inflacijskog učinka
#Uzimamo 2025. kao najrecentniju godinu

cijene_2025 <- cijene %>%
  filter(godina==2025, status=="opservirano") %>%
  left_join(jls %>% select(sifra, zupanija), by="sifra")

#Graf medijalnih cijena po županijama
ggplot(cijene_2025, aes(x=reorder(zupanija, cijena_po_m2, median), y=cijena_po_m2))+
  geom_boxplot(fill="turquoise3")+
  coord_flip()+
  labs(title="", x="", y="",
       caption="Izvor: Ekonomski institut, Zagreb. Potisnute vrijednosti nisu uključene."
       )+
  tema_grafa()+
  theme(plot.margin=margin(0, 5, 5, 0), axis.title.x=element_blank(),
        axis.text.x=element_text(face="bold"), axis.text.y=element_text(face="bold"),
        plot.caption=element_text(face="bold"))
ggsave("boxplot_po_zupanijama.png", plot=last_plot(), dpi=600)

outlieri_2025 <- cijene_2025 %>%
  left_join(jls %>% select(sifra, jls), by="sifra") %>%
  group_by(zupanija) %>%
  mutate(q1=quantile(cijena_po_m2, 0.25), q3=quantile(cijena_po_m2, 0.75),
         iqr=q3-q1, donja_granica=q1-1.5*iqr, gornja_granica=q3+1.5*iqr
         ) %>%
  filter(cijena_po_m2<donja_granica|cijena_po_m2>gornja_granica) %>%
  ungroup() %>%
  mutate(vrsta_outliera=if_else(cijena_po_m2<donja_granica, "Donji", "Gornji")) %>%
  select(sifra, jls, zupanija, cijena_po_m2, donja_granica, gornja_granica,
         vrsta_outliera) %>%
  arrange(zupanija, cijena_po_m2)

outlieri_2025

outlieri_2025 %>%
  arrange(vrsta_outliera, desc(cijena_po_m2))

#Spremamo csv outliera za Power BI
write.csv2(outlieri_2025, "outlieri_2025.csv", row.names=F, fileEncoding="UTF-8")

#Za razliku od podjele po godinama, u podjeli po županijama imamo i donje
#outliere. Donji outlieri (znatno jeftinije jls od ostalih U SVOJOJ ŽUPANIJI) su:
#Imotski, Dugi Rat, Sinj, Pašman, Benkovac i Knin. Gornji outlieri su: Split,
#Privlaka i Kukljica. Najjeftiniji outlier je Knin, a najskuplji Kukljica.

#Bitno je napomenuti da različite županije imaju različit broj jls-ova. Identifikacija
#outliera je pouzdanija u županijama s većim brojem jedinica lokalne samouprave.

#Broj jls po županijama
cijene_2025 %>%
  count(zupanija, name="broj_jls") %>%
  arrange(desc(broj_jls))

#Najskuplje jls
najskuplje_jls <- cijene_2025 %>%
  left_join(jls %>% select(sifra, jls), by="sifra") %>%
  arrange(desc(cijena_po_m2)) %>%
  select(jls, zupanija, cijena_po_m2) %>%
  slice_head(n=10)

ggplot(najskuplje_jls, aes(x=reorder(jls, cijena_po_m2), y=cijena_po_m2))+
  geom_col(fill="turquoise3", width=0.7)+
  coord_flip()+
  scale_y_continuous(labels=scales::label_number(big.mark=".", decimal.mark=",",
                                                 accuracy=1
                                                 )
                     )+
  labs(title="Najskuplje JLS u 2025.g.", x="", y="cijena (EUR/m\u00B2)",
       caption="Izvor: Ekonomski institut, Zagreb. Potisnute vrijednosti nisu uključene."
       )+
  tema_grafa()

#Najjeftinije jls
najjeftinije_jls <- cijene_2025 %>%
  left_join(jls %>% select(sifra, jls), by="sifra") %>%
  arrange(cijena_po_m2) %>%
  select(jls, zupanija, cijena_po_m2) %>%
  slice_head(n=10)

ggplot(najjeftinije_jls, aes(x=reorder(jls, cijena_po_m2), y=cijena_po_m2))+
  geom_col(fill="coral", width=0.7)+
  coord_flip()+
  scale_y_continuous(labels=scales::label_number(big.mark=".", decimal.mark=",",
                                                 accuracy=1
                                                 )
                     )+
  labs(title="Najjeftinije JLS u 2025.g.", x="", y="cijena (EUR/m\u00B2)",
       caption="Izvor: Ekonomski institut, Zagreb. Potisnute vrijednosti nisu uključene."
       )+
  tema_grafa()



###############################################################################
################################# PRIUŠTIVOST #################################
###############################################################################

#Definicija indeksa priuštivosti I:
#I=medijalna_cijena_po_m2/prosječna_godišnja_neto_plaća*100

#Manji indeks = veća priuštivost
#Veći indeks = manja priuštivost

priustivost %>%
  count(status)

priustivost %>%
  filter(status=="opservirano") %>%
  summarise(
    broj_jls=n(),
    prosjek=mean(indeks_priustivosti),
    medijan=median(indeks_priustivosti),
    st_dev=sd(indeks_priustivosti),
    minimum=min(indeks_priustivosti),
    q1=quantile(indeks_priustivosti, 0.25),
    q3=quantile(indeks_priustivosti, 0.75),
    maksimum=max(indeks_priustivosti)
  )

#Vidimo ogromno odstupanje prosjeka od medijana i ogromnu st.dev.

priustivost %>%
  filter(status=="opservirano") %>%
  left_join(jls %>% select(sifra, jls, zupanija), by="sifra") %>%
  arrange(desc(indeks_priustivosti)) %>%
  select(jls, zupanija, indeks_priustivosti) %>%
  slice_head(n=10)

#Zaprešić ima abnormalno velik indeks priuštivosti. Gledajući u originalnu
#Excel tablicu, vrijednost je bilježena kao 12936,0. Ovo je vrlo vjerojatno greška
#u decimalnom zapisu, ali ne možemo biti sigurni pa stavljamo vrijednost
#indeksa na NA.

#Ažuriramo početnu tablicu priuštivosti
zapresic_sifra <- jls$sifra[jls$jls=="ZAPREŠIĆ"]
priustivost$indeks_priustivosti[priustivost$sifra==zapresic_sifra] <- NA
priustivost$status[priustivost$sifra==zapresic_sifra] <- "greška_izvora"

#Ponovo računamo vrijednosti
priustivost %>%
  filter(status=="opservirano") %>%
  summarise(
    broj_jls=n(),
    prosjek=mean(indeks_priustivosti),
    medijan=median(indeks_priustivosti),
    st_dev=sd(indeks_priustivosti),
    minimum=min(indeks_priustivosti),
    q1=quantile(indeks_priustivosti, 0.25),
    q3=quantile(indeks_priustivosti, 0.75),
    maksimum=max(indeks_priustivosti)
  )

#Graf indeksa priuštivosti u 2024.g.
ggplot(priustivost %>% filter(status=="opservirano"), aes(x=indeks_priustivosti))+
  geom_histogram(bins=25, fill="turquoise3", color="coral")+
  scale_x_continuous(labels=scales::label_number(big.mark=".", decimal.mark=",",
                                                 accuracy=1
                                                 )
                     )+
  labs(title="Indeks priuštivosti po JLS (2024.g.)", x="indeks priuštivosti",
       y="frekvencija",
       caption="Izvor: Ekonomski institut, Zagreb. Zaprešić nije uključen zbog greške u izvoru."
       )+
  tema_grafa()

#Uočavamo bimodalnost distribucije pa ćemo ju provjeriti Hartiganovim testom
#H0: Distribucija je unimodalna
#H1: ne H0
indeksi <- priustivost %>%
  filter(status=="opservirano") %>%
  pull(indeks_priustivosti)
hartigan <- dip.test(indeksi)
hartigan$statistic
hartigan$p.value
#Ne možemo odbaciti unimodalnost na razini značajnosti 0.05.
#Dakle, multimodalnost nije statistički značajna.

#Vrlo je vjerojatno da desni vrh čine jls u obalnim i turističkim područjima,
#a lijevi ostala područja čije cijene nisu prilagođene stranoj potražnji.
#Međutim zbog rezultata testa ne smijemo slijepo prihvatiti ovaj zaključak.
#Za to bi nam bilo potrebno još podataka.

#Svejedno možemo analizirati podatke koje imamo.
#Granica indeksa 18 je uzeta na temelju grafa, a ne teorijskim izračunom.
#Nadalje jls s indeksima manjim od 18 zovemo PRIUŠTIVIM jls, a one s
#većim od 18 NEPRIUŠTIVIM.

priustivost %>%
  filter(status=="opservirano") %>%
  mutate(skupina=if_else(indeks_priustivosti<18, "Niži vrh", "Viši vrh")
  ) %>%
  count(skupina)

#Postotak pripadnosti jls-ova nižem i višem vrhu po županijama
priustivost %>%
  filter(status=="opservirano") %>%
  left_join(jls %>% select(sifra, zupanija), by="sifra") %>%
  mutate(skupina=if_else(indeks_priustivosti<18, "Niži vrh", "Viši vrh")) %>%
  count(zupanija, skupina, name="broj_jls") %>%
  group_by(zupanija) %>%
  mutate(udio=round(broj_jls/sum(broj_jls)*100, 1)) %>%
  ungroup() %>%
  arrange(skupina) %>%
  print(n=30)

udio_nizeg_vrha <- priustivost %>%
  filter(status=="opservirano") %>%
  left_join(jls %>% select(sifra, zupanija), by="sifra") %>%
  mutate(nizi_vrh=indeks_priustivosti<18) %>%
  group_by(zupanija) %>%
  summarise(broj_jls=n(), broj_nizeg_vrha=sum(nizi_vrh),
            udio_nizeg_vrha=round(mean(nizi_vrh)*100, 1), .groups="drop"
            ) %>%
  arrange(udio_nizeg_vrha) %>%
  mutate(zupanija_oznaka=paste0(zupanija," (", broj_jls, ")"))

ggplot(udio_nizeg_vrha, aes(x=reorder(zupanija_oznaka, udio_nizeg_vrha),
                            y=udio_nizeg_vrha
                            )
       )+
  geom_col(fill="turquoise3")+
  coord_flip()+
  scale_y_continuous(limits=c(0, 100), breaks=seq(0, 100, 20),
                     labels=scales::label_number(suffix="%")
                     )+
  labs(title="Udio priuštivih JLS (2024.g.)", x="", y="",
       caption="Izvor: Ekonomski institut, Zagreb. Broj uz županije označuje broj jls-ova."
       )+
  tema_grafa()



###############################################################################
########################## EKSPORT REZULTATA ##################################
###############################################################################

#Prikaz godišnjih cijena
DBI::dbWriteTable(
  con,
  "godisnje_cijene",
  godisnje_cijene,
  overwrite=T,
  row.names=F
)

#Prikaz godišnjih transakcija
DBI::dbWriteTable(
  con,
  "godisnje_transakcije",
  godisnje_transakcije,
  overwrite=T,
  row.names=F
)

#Prikaz formule za indeks priuštivosti
formula <- ggplot()+
  annotate("text", x=0, y=0,
           label=TeX(r"($I=\frac{medijalna\ cijena\ stana\ po\ m^2}{prosječna\ godišnja\ neto\ plaća}\cdot 100$)"),
           size=7, family="sans", color="white"
           )+
  xlim(-0.65,0.65)+
  ylim(-0.25,0.25)+
  theme_void()+
  theme(plot.background=element_rect(fill="transparent", color=NA),
        panel.background=element_rect(fill="transparent", colour=NA),
        plot.margin=margin(0, 0, 0, 0)
        )

ggsave("formula_priustivosti.png", plot=formula, width=12, height=1.8, dpi=600, bg="transparent")
