--GENERALNI PREGLED PROJEKTA--

Ovo je osobni projekt izrađen u svrhu poboljšanja vlastitih vještina u SQL-u i Power BI-ju
te za stjecanje generalnih informacija o tržištu stanova i apartmana u RH.

Neka od glavnih pitanja koja sam nastojao odgovoriti su:
1. Kako su se vremenski kretale cijene stanova i apartmana u RH?
2. Kako se vremenski kretao broj kupoprodajnih transakcija stanova i apartmana u RH?
3. Kako se cijene stanova i apartmana razlikuju geografski po županijama i jedinicama lokalne samouprave (jls)?
4. Koje su županije imale najviše priuštive, a koje najmanje priuštive stanove i apartmane u 2024.g?

Podaci koji su korišteni nalaze se na stranici Ekonomskog instituta u Zagrebu:
https://eizg.hr/publikacije-i-proizvodi/publikacije/serijske-publikacije/pregled-trzista-nekretnina-republike-hrvatske/4273

Uzete tablice su:
- medijalne cijene nekretnina po jls od 2012.-2025.g.
- priuštivost stanova ili apartmana u 2024.g.
- broj kupoprodajnih transakcija od 2012.-2025.g.

Tablice su kodom u R-u pročitane i pročišćene te pohranjene u bazu podataka u PostgreSQL-u.
Izvršen je EDA na podacima u R-u i kreirani su grafički prikazi podataka.
Kreiran je izvještaj najbitnijih podataka u Power BI-ju.


--METODOLOGIJA I REZULTATI--
Medijalne cijene po jls i broj transakcija po jls su jasni.
Indeks priuštivosti je u tablicama izračunat kao omjer medijalne cijene po m2 i
prosječne godišnje neto plaće pomnožen sa 100.
Dakle, što je manji indeks priuštivosti, to su stanovi i apartmani priuštiviji.

Neki podaci su potisnuti radi zaštite privatnosti i podataka u manjim sredinama.
Ako je unutar jls izvršeno manje od 10 kupoprodajnih transakcija, onda su podaci potisnuti.
Unutar Excel tablica znak "." označava 0 transakcija, a znak "z" označava barem jednu, ali manje od 10 transakcija.
Također, izbacio sam jls Zaprešić iz analize podataka o priuštivosti zbog sumnjivo velikog indeksa od 12936.
Ovo je najvjerojatnije greška u decimalnom zapisu, ali je nemoguće biti siguran pa sam ga izbacio.

Godišnji brojevi transakcija prilično dobro prate sinusoidnu krivulju.
U 2013.g. vidimo najniži broj transakcija.
Od 2013.g. do 2020.g. vidimo rast i nagli pad u 2020.g. vrlo vjerojatno uzrokovan pandemijom COVID-a 19.
2021.g. se broj transakcija vraća na originalnu putanju i doseže vrh u 2022.g.
Nakon 2022.g. vidimo pad sve do 2025.g.
Ekonomsko objašnjenje za sinusoidni oblik je konstantna fluktuacija cijena i potražnje:
niske cijene --> visoka potražnja --> visoke cijene --> niska potražnja --> niske cijene...

U zadnjih nekoliko godina je medijan medijalnih cijena blago veći od njihova prosjeka.
Dakle, naslućujemo blagu negativnu asimetriju. Prije toga su medijan i prosjek bili otprilike isti.

U 2025.g. je najjeftinija jls bila Vrbovsko s medijalnom cijenom od samo €715 po m2.
Najskuplja je bila Split s €4.07k po m2.
Generalni trend je takav da su obalna područja i Grad Zagreb daleko skuplji od ostalih
područja u unutrašnjosti RH.

Medijalne cijene po županijama za 2025.g. pokazuju da je Grad Zagreb najskuplji, ali
isključivo iz razloga što ima samo jednu jls. Ruralna područja obalnih županija vuku njihove
medijalne cijene prema dolje. To vidimo po činjenici da Grad Zagreb kao jls nije uspio ući u
10 najskupljih jls u RH. Prilagodba turističkih destinacija stranoj potražnji ima jači učinak.

Outlieri po medijalnim cijenama unutar vlastitih županija su:
Split, Dubrovnik, Primošten i Rogoznica kao skupi outlieri te
Vrbovsko, Benkovac, Drniš i Knin kao jeftini outlieri.

Distribucija indeksa priuštivosti po jls naizgled djeluje bimodalno.
Provedenim Hartiganovim testom za multimodalnost nismo mogli ustanoviti
statistički značajnu prisutnost multimodalne distribucije.
Međutim, granica između dva prividna vrha nam služi kao dobra granica za određivanje
priuštivih i nepriuštivih jls. Odabrali smo da je ta granica indeks priuštivosti 18.
Dakle, indeks manji od 18 znači priuštivost, a indeks veći od 18 nepriuštivost.
Najmanje priuštive županije su upravo Grad Zagreb i obalne županije, dok u nekim županijama u
unutrašnjosti sve jls pripadaju priuštivim jls (npr. Varaždinska, Međimurska, Požeško-slavonska itd.).


--ZAKLJUČAK--
U vrijeme provedbe ovog projekta (studeni 2026.g.) student sam zadnje godine fakulteta i ohrabrujuće je vidjeti
da broj transakcija stanova i apartmana pada. Vjerujem da nisam jedini od svojih kolega koji
već razmišlja o budućim planovima za stanovanje, a vjerujem da smo svi svijesni da su cijene
nekretnina (relativno) teško priuštive zadnjih nekoliko godina.

Osim osobne motivacije, ovaj projekt je dobar uvid u to da kupnja nekretnina u
obalnim područjima više nije priuštiva za prosječnog državljana Republike Hrvatske.
Čak i unutar samih obalnih županija neke se urbane obalne jls smatraju nepriuštivima
(kao što to pokazuje indeks priuštivosti), a kamo li za nekoga iz jls s manjim primanjima.
