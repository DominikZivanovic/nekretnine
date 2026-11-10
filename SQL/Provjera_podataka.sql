-- Generalna provjera
SELECT
    'cijene' AS tablica,
    COUNT(*) AS broj_redaka,
    COUNT(DISTINCT sifra) AS broj_jls,
    COUNT(DISTINCT godina) AS broj_godina,
    MIN(godina) AS prva_godina,
    MAX(godina) AS zadnja_godina
FROM cijene

UNION ALL

SELECT
    'transakcije',
    COUNT(*),
    COUNT(DISTINCT sifra),
    COUNT(DISTINCT godina),
    MIN(godina),
    MAX(godina)
FROM transakcije

UNION ALL

SELECT
    'priustivost',
    COUNT(*),
    COUNT(DISTINCT sifra),
    COUNT(DISTINCT godina),
    MIN(godina),
    MAX(godina)
FROM priustivost;

-- Provjera vrste unosa
SELECT
    'cijene' AS tablica,
    status,
    COUNT(*) AS broj_redaka
FROM cijene
GROUP BY status

UNION ALL

SELECT
    'transakcije',
    status,
    COUNT(*)
FROM transakcije
GROUP BY status

UNION ALL

SELECT
    'priustivost',
    status,
    COUNT(*)
FROM priustivost

GROUP BY status
ORDER BY tablica, status;

-- Provjera duplih vrijednosti
SELECT
    'cijene' AS tablica,
    sifra,
    godina,
    COUNT(*) AS broj_pojavljivanja
FROM cijene
GROUP BY sifra, godina
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'transakcije',
    sifra,
    godina,
    COUNT(*)
FROM transakcije
GROUP BY sifra, godina
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'priustivost',
    sifra,
    godina,
    COUNT(*)
FROM priustivost
GROUP BY sifra, godina
HAVING COUNT(*) > 1;