-- ============================================================================
-- CREAZIONE DATABASE - GESTIONE CORSI E FORMAZIONE
-- ============================================================================

CREATE DATABASE gestione_corsi;

-- ============================================================================
-- TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION verifica_min_docenti_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stato_edizione = 'Corrente' THEN
        IF NOT EXISTS (
            SELECT 1 FROM insegnamento
            WHERE codice_corso = NEW.codice_corso AND num_edizione = NEW.numero
        ) 
        
        THEN
            RAISE EXCEPTION
                'Vincolo 1,N violato: l''edizione % del corso % (Corrente) '
                'deve avere almeno un docente assegnato.',
                NEW.numero, NEW.codice_corso;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trig_edizione_insert_verifica_docente
AFTER INSERT ON edizione
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verifica_min_docenti_insert();

-- =========================================================

CREATE OR REPLACE FUNCTION verifica_min_docenti_update()
RETURNS TRIGGER AS $$
DECLARE
    stato_attuale VARCHAR(50);
BEGIN
    IF OLD.codice_corso = NEW.codice_corso AND OLD.num_edizione = NEW.num_edizione THEN
        RETURN NULL;
    END IF;
    
    SELECT stato_edizione INTO stato_attuale FROM edizione 
    WHERE codice_corso = OLD.codice_corso AND numero = OLD.num_edizione;
    
    IF stato_attuale = 'Corrente' THEN
        IF NOT EXISTS (
            SELECT 1 FROM insegnamento
            WHERE codice_corso = OLD.codice_corso AND num_edizione = OLD.num_edizione
        ) 
        
        THEN
            RAISE EXCEPTION
                'Vincolo 1,N violato: impossibile spostare il docente (cf: %) '
                'in quanto e'' l''unico assegnato all''edizione % del corso %.',
                OLD.cf_docente, OLD.num_edizione, OLD.codice_corso;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trig_insegnamento_update_min_docenti
AFTER UPDATE ON insegnamento
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verifica_min_docenti_update();

-- =========================================================

CREATE OR REPLACE FUNCTION verifica_min_docenti_delete()
RETURNS TRIGGER AS $$
DECLARE
    stato_attuale VARCHAR(50);
BEGIN
    SELECT stato_edizione INTO stato_attuale FROM edizione 
    WHERE codice_corso = OLD.codice_corso AND numero = OLD.num_edizione;

    IF stato_attuale = 'Corrente' THEN
        IF NOT EXISTS (
            SELECT 1 FROM insegnamento
            WHERE codice_corso  = OLD.codice_corso AND num_edizione  = OLD.num_edizione
        ) 
        
        THEN
            RAISE EXCEPTION
                'Vincolo 1,N violato: impossibile eliminare il docente (cf: %) '
                'in quanto e'' l''unico assegnato all''edizione % del corso %.',
                OLD.cf_docente, OLD.num_edizione, OLD.codice_corso;
        END IF;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trig_insegnamento_delete_min_docenti
AFTER DELETE ON insegnamento
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verifica_min_docenti_delete();

-- ===============================================================

CREATE OR REPLACE FUNCTION verifica_min_abilitazioni_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tipo_persona <> 'Docente' THEN
        RETURN NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM abilitazione
        WHERE cf_docente = NEW.cf
    ) THEN
        RAISE EXCEPTION
            'Vincolo 1,N violato: il docente (cf: %) '
            'non ha nessuna abilitazione assegnata.',
            NEW.cf;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trig_docente_insert_verifica_min_abilitazioni
AFTER INSERT ON persona
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verifica_min_abilitazioni_insert();

-- ===================================================================

CREATE OR REPLACE FUNCTION verifica_min_abilitazioni_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.cf_docente = NEW.cf_docente THEN
        RETURN NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM abilitazione
        WHERE cf_docente = OLD.cf_docente
    ) THEN
        RAISE EXCEPTION
            'Vincolo 1,N violato: impossibile spostare l''abilitazione '
            'del docente (cf: %) in quanto e'' l''unica che possiede.',
            OLD.cf_docente;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trig_abilitazione_min_update
AFTER UPDATE ON abilitazione
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verifica_min_abilitazioni_update();

-- =====================================================================

CREATE OR REPLACE FUNCTION verifica_min_abilitazioni_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM abilitazione
        WHERE cf_docente = OLD.cf_docente
    ) THEN
        RAISE EXCEPTION
            'Vincolo 1,N violato: impossibile eliminare l''abilitazione '
            'del docente (cf: %) in quanto e'' l''unica che possiede.',
            OLD.cf_docente;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trig_abilitazione_min_delete
AFTER DELETE ON abilitazione
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verifica_min_abilitazioni_delete();

-- =======================================================================

CREATE OR REPLACE FUNCTION cancella_lezioni_edizione_passata()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.stato_edizione = 'Corrente' AND NEW.stato_edizione = 'Passata' THEN
        DELETE FROM lezione
        WHERE codice_corso  = NEW.codice_corso
          AND num_edizione  = NEW.numero;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trig_edizione_passata_cancella_lezioni
BEFORE UPDATE ON edizione
FOR EACH ROW
EXECUTE FUNCTION cancella_lezioni_edizione_passata();