-- JLS
CREATE TABLE IF NOT EXISTS jls (
    sifra INTEGER PRIMARY KEY,
    jls VARCHAR(100) NOT NULL,
    zupanija VARCHAR(100) NOT NULL
);

-- TRANSAKCIJE
CREATE TABLE IF NOT EXISTS transakcije (
    sifra INTEGER NOT NULL,
    godina INTEGER NOT NULL,
    broj_transakcija INTEGER,
    status VARCHAR(30) NOT NULL,

    PRIMARY KEY (sifra, godina),

    FOREIGN KEY (sifra)
        REFERENCES jls(sifra),

    CHECK (godina BETWEEN 2012 AND 2025),
    CHECK (broj_transakcija IS NULL OR broj_transakcija>=0),

    CHECK (
        (status='opservirano' AND broj_transakcija IS NOT NULL)
        OR
        (status='nema_transakcija' AND broj_transakcija=0)
        OR
        (status IN ('potisnuto', 'nedostaje')
            AND broj_transakcija IS NULL)
    )
);

-- PRIUŠTIVOST
CREATE TABLE IF NOT EXISTS priustivost (
    sifra INTEGER NOT NULL,
    godina INTEGER NOT NULL,
    indeks_priustivosti NUMERIC,
    status VARCHAR(30) NOT NULL,

    PRIMARY KEY (sifra, godina),

    FOREIGN KEY (sifra)
        REFERENCES jls(sifra),

    CHECK (godina=2024),

    CHECK (
        (status='opservirano' AND indeks_priustivosti IS NOT NULL)
        OR
        (status IN ('nema_transakcija', 'potisnuto', 'nedostaje')
            AND indeks_priustivosti IS NULL)
    )
);

-- CIJENE
CREATE TABLE IF NOT EXISTS cijene (
    sifra INTEGER NOT NULL,
    godina INTEGER NOT NULL,
    cijena_po_m2 NUMERIC,
    status VARCHAR(30) NOT NULL,

    PRIMARY KEY (sifra, godina),

    FOREIGN KEY (sifra)
        REFERENCES jls(sifra),

    CHECK (godina BETWEEN 2012 AND 2025),
    CHECK (cijena_po_m2 IS NULL OR cijena_po_m2>=0)
);
