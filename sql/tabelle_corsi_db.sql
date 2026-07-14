-- ============================================================================
-- SCHEMA DATABASE - GESTIONE CORSI E FORMAZIONE
-- ============================================================================

-- CORSO
-- ============================================================================
CREATE TABLE corso (
	codice VARCHAR(20) PRIMARY KEY,
	nome VARCHAR(100) NOT NULL UNIQUE
);


-- PERSONA
-- ============================================================================
CREATE DOMAIN dmn_titolo_studio AS VARCHAR(50)
    CHECK (VALUE IN ('Diploma', 'Laurea Triennale', 'Laurea Magistrale', 'Dottorato', 'Master'));

CREATE TABLE persona (
	cf CHAR(16) PRIMARY KEY,
	nome VARCHAR(50) NOT NULL,
	cognome VARCHAR(50) NOT NULL,
	data_nascita DATE NOT NULL,
	luogo_nascita VARCHAR(50) NOT NULL,
	indirizzo VARCHAR(100) NOT NULL,
	sesso CHAR(1) NOT NULL CHECK (sesso IN ('F', 'M')),
	titolo_studio dmn_titolo_studio,
	tipo_persona VARCHAR(50) NOT NULL CHECK (tipo_persona IN ('Partecipante', 'Docente')),
	
	CONSTRAINT cf_formato CHECK (length(cf) = 16)
);


-- FASCIA_ORARIA
-- ============================================================================
CREATE TABLE fascia_oraria (
	id_fascia INTEGER PRIMARY KEY,
	ora_inizio TIME NOT NULL,
	ora_fine TIME NOT NULL,

	CONSTRAINT orario_logico CHECK (ora_inizio < ora_fine),
    CONSTRAINT fascia_duplicata UNIQUE (ora_inizio, ora_fine),
    CONSTRAINT id_fascia_valido CHECK (id_fascia BETWEEN 1 AND 4)
);


-- EDIZIONE
-- ============================================================================
CREATE TABLE edizione (
	codice_corso VARCHAR(20),
	numero INT NOT NULL,
	data_inizio DATE NOT NULL,
	data_fine DATE NOT NULL,
	ore_totali NUMERIC(6, 2) NOT NULL,
	num_iscritti INT DEFAULT 0,
	stato_edizione VARCHAR(50) NOT NULL,

	CONSTRAINT pk_edizione PRIMARY KEY(codice_corso, numero),
	
	CONSTRAINT fk_codice_corso 
		FOREIGN KEY (codice_corso) REFERENCES corso(codice)
			ON DELETE NO ACTION
			ON UPDATE CASCADE,
		
	CONSTRAINT stato_valido 
	        CHECK (stato_edizione IN ('Corrente', 'Passata')),
	
	CONSTRAINT ore_positive CHECK (ore_totali > 0),
	CONSTRAINT iscritti_positivi CHECK (num_iscritti >= 0),
	
	CONSTRAINT data_logica CHECK (data_inizio <= data_fine)
);


-- LEZIONE
-- ============================================================================
CREATE TABLE lezione (
	codice_corso VARCHAR(20),
	num_edizione INT,
	id_fascia INT,
	giorno VARCHAR(15) NOT NULL,
	aula VARCHAR(30) NOT NULL,
	
	CONSTRAINT pk_lezione PRIMARY KEY(codice_corso, num_edizione, id_fascia, giorno),
	
	CONSTRAINT fk_corso_edizione
		FOREIGN KEY(codice_corso, num_edizione) REFERENCES edizione(codice_corso, numero)
		ON DELETE NO ACTION
		ON UPDATE CASCADE,
		
	CONSTRAINT fk_fascia 
		FOREIGN KEY(id_fascia) REFERENCES fascia_oraria(id_fascia)
			ON DELETE NO ACTION
			ON UPDATE CASCADE,
			
	CONSTRAINT giorno_valido 
		CHECK (giorno IN ('Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato'))
);


-- TELEFONO
-- ============================================================================
CREATE TABLE telefono (
	numero_tel VARCHAR(20) PRIMARY KEY,
	cf_proprietario CHAR(16) NOT NULL,

	CONSTRAINT fk_proprietario_tel
	        FOREIGN KEY(cf_proprietario) REFERENCES persona(cf)
	        ON DELETE CASCADE
	        ON UPDATE CASCADE,
	
	CONSTRAINT formato_numero CHECK (length(numero_tel) >= 8)
);


-- DIPENDENTE (specializzazione di PERSONA)
-- ============================================================================
CREATE DOMAIN dmn_liv_contratto AS INTEGER
    CONSTRAINT liv_valido CHECK (VALUE BETWEEN 1 AND 7);

CREATE TABLE dipendente (
	cf_dipendente CHAR(16) PRIMARY KEY,
	data_assunzione DATE NOT NULL,
	livello_contratto dmn_liv_contratto NOT NULL,
	
	CONSTRAINT fk_dipendente
	        FOREIGN KEY(cf_dipendente) REFERENCES persona(cf)
	        ON DELETE CASCADE
	        ON UPDATE CASCADE
);


-- COLLABORATORE (specializzazione di PERSONA)
-- ============================================================================
CREATE TABLE collaboratore (
    cf_collaboratore CHAR(16) PRIMARY KEY,
    p_iva CHAR(11) NOT NULL UNIQUE,
    tariffa_oraria NUMERIC(10, 2) NOT NULL,

    CONSTRAINT fk_collaboratore
        FOREIGN KEY (cf_collaboratore) REFERENCES persona(cf)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
        
    CONSTRAINT p_iva_formato CHECK (length(p_iva) = 11),
    CONSTRAINT tariffa_valida CHECK (tariffa_oraria > 0)
);


-- ABILITAZIONE (Docenti abilitati a insegnare corsi)
-- ============================================================================
CREATE TABLE abilitazione (
    cf_docente CHAR(16),
    codice_corso VARCHAR(20),
    
    CONSTRAINT pk_abilitazione PRIMARY KEY (cf_docente, codice_corso),
    
    CONSTRAINT fk_docente_abilitato
        FOREIGN KEY (cf_docente) REFERENCES persona(cf)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,

    CONSTRAINT fk_corso_abilitato
        FOREIGN KEY (codice_corso) REFERENCES corso(codice)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- INSEGNAMENTO (Docenti che insegnano in una specifica edizione)
-- ============================================================================
CREATE TABLE insegnamento (
    cf_docente CHAR(16),
    codice_corso VARCHAR(20),
    num_edizione INT,

    CONSTRAINT pk_insegnamento 
        PRIMARY KEY (cf_docente, codice_corso, num_edizione),

    CONSTRAINT fk_docente_insegnante
        FOREIGN KEY (cf_docente) REFERENCES persona(cf)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    CONSTRAINT fk_edizione_insegnata
        FOREIGN KEY (codice_corso, num_edizione) 
        REFERENCES edizione(codice_corso, numero)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);


-- FREQUENZA (Partecipanti che frequentano un corso)
-- ============================================================================
CREATE TABLE frequenza (
    cf_partecipante CHAR(16),
    codice_corso VARCHAR(20),
    num_edizione INT,
    voto_finale INT, 

    CONSTRAINT pk_frequenza 
        PRIMARY KEY (cf_partecipante, codice_corso, num_edizione),

    CONSTRAINT fk_persona_frequenza
        FOREIGN KEY (cf_partecipante) REFERENCES persona(cf)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    CONSTRAINT fk_edizione_frequenza
        FOREIGN KEY (codice_corso, num_edizione) 
        REFERENCES edizione(codice_corso, numero)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    CONSTRAINT voto_valido 
        CHECK (voto_finale IS NULL OR (voto_finale BETWEEN 1 AND 10))
);
