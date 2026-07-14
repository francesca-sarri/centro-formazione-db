-- ============================================================================
-- VISTA: Lezioni per settimana per ciascun corso
-- ============================================================================

CREATE VIEW lezioni_per_settimana AS
SELECT codice_corso, num_edizione, COUNT(*) AS lezioni_settimana
FROM lezione
GROUP BY codice_corso, num_edizione;

-- ============================================================================
-- QUERY: Media generale di partecipanti nelle edizioni correnti
-- con almeno 3 lezioni a settimana
-- ============================================================================

WITH edizioni_almeno_3_lezioni AS (
    SELECT codice_corso, num_edizione
    FROM lezioni_per_settimana
    WHERE lezioni_settimana >= 3
)
 
-- Calcola la media
SELECT AVG(e.num_iscritti) AS media_partecipanti_globale
FROM edizione e
JOIN edizioni_almeno_3_lezioni e3 
    ON e.codice_corso = e3.codice_corso AND e.numero = e3.num_edizione

WHERE e.stato_edizione = 'Corrente';


-- ============================================================================
-- QUERY: Numero di partecipanti per ogni corso con almeno 2 lezioni a settimana
-- ============================================================================

SELECT c.codice, c.nome, e.num_iscritti AS num_partecipanti
FROM corso c
JOIN edizione e ON c.codice = e.codice_corso
JOIN lezioni_per_settimana lps 
    ON e.codice_corso = lps.codice_corso AND e.numero = lps.num_edizione

WHERE lps.lezioni_settimana >= 2 AND e.stato_edizione = 'Corrente'
ORDER BY e.num_iscritti DESC;

-- ============================================================================
-- QUERY: Numero di docenti Dipendenti abilitati ad almeno 2 corsi 
-- tenuti in edizioni (Corrente o Passata) con almeno 10 partecipanti
-- ============================================================================

-- Edizioni con almeno 10 partecipanti
WITH edizioni_sufficienti AS (
    SELECT codice_corso, numero
    FROM edizione
    WHERE num_iscritti >= 10
),
 
docenti_dipendenti AS (
    SELECT p.cf, p.nome, p.cognome
    FROM persona p
    JOIN dipendente d ON p.cf = d.cf_dipendente
    JOIN abilitazione a ON d.cf_dipendente = a.cf_docente
    JOIN edizioni_sufficienti es ON a.codice_corso = es.codice_corso
    WHERE p.tipo_persona = 'Docente'
    GROUP BY p.cf, p.nome, p.cognome
    HAVING COUNT(DISTINCT es.codice_corso) >= 2
)

-- Conta docenti con almeno 2 corsi validi
SELECT COUNT(*) AS num_docenti_dipendenti
FROM docenti_dipendenti;
 
-- ============================================================================
-- QUERY: Partecipanti con valutazione media dei corsi >= 8
-- ============================================================================

-- Media voti per ogni partecipante
WITH media_voti_partecipanti AS (
    SELECT cf_partecipante, COUNT(DISTINCT codice_corso) AS num_corsi,
		   ROUND(AVG(voto_finale), 2) AS media_voti
    FROM frequenza
	WHERE voto_finale IS NOT NULL
    GROUP BY cf_partecipante
    HAVING AVG(voto_finale) >= 8
)
 
SELECT p.cf, p.nome, p.cognome, p.data_nascita, p.titolo_studio, mvp.num_corsi, mvp.media_voti
FROM media_voti_partecipanti mvp
JOIN persona p ON mvp.cf_partecipante = p.cf
ORDER BY mvp.media_voti DESC, p.cognome, p.nome;

-- ============================================================================
-- QUERY: Inserire un nuovo docente di tipo collaboratore.
-- ============================================================================

INSERT INTO persona (
    cf, nome, cognome, data_nascita, luogo_nascita, 
    indirizzo, sesso, titolo_studio, tipo_persona
) VALUES (
    'RSSMRA80A01H501U', 'Mario', 'Rossi', '1980-05-15', 'Roma', 
    'Via Roma 1', 'M', 'Laurea Magistrale', 'Docente'
);

INSERT INTO collaboratore (
    cf_collaboratore, p_iva, tariffa_oraria
) VALUES (
    'RSSMRA80A01H501U', '12345678901', 50.00
);

INSERT INTO abilitazione (cf_docente, codice_corso) VALUES ('RSSMRA80A01H501U', 'C001');

-- ============================================================================
-- QUERY: Aggiornare il numero di ore totali e cambiare lo stato di edizione
--		  per un’edizione che è appena terminata.
-- ============================================================================

UPDATE edizione
SET ore_totali = 120, stato_edizione = 'Passata'
WHERE codice_corso = 'INF-01' AND numero = 2;

-- ============================================================================
-- QUERY: Stampa tutti i corsi che hanno avuto almeno 3 edizioni passate.
-- ============================================================================

SELECT c.nome
FROM corso c
JOIN edizione e ON c.codice = e.codice_corso
WHERE e.stato_edizione = 'Passata'
GROUP BY c.codice, c.nome
HAVING COUNT(*) >= 3;

-- ============================================================================
-- QUERY: Numero delle edizioni passate offerte almeno due volte
-- ============================================================================

WITH edizioni_passate_per_corso AS (
    SELECT codice_corso, COUNT(*) AS num_edizioni_passate
    FROM edizione
    WHERE stato_edizione = 'Passata'
    GROUP BY codice_corso
    HAVING COUNT(*) >= 2
)
 
SELECT c.codice, c.nome, eppc.num_edizioni_passate
FROM edizioni_passate_per_corso eppc
JOIN corso c ON eppc.codice_corso = c.codice
ORDER BY eppc.num_edizioni_passate DESC;




