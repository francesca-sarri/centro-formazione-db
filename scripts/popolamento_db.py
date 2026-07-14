# ============================================================================
# SCRIPT DI POPOLAMENTO - Genera dati realistici per il database corsi
# ============================================================================

import psycopg2
from faker import Faker
from datetime import datetime, timedelta
import random
import string

# ============================================================================
# CONFIGURAZIONE CONNESSIONE
# ============================================================================
DB_URL = ""

fake = Faker('it_IT')
conn = None
cursor = None


def connessione_db():
    # Connessione al database
    global conn, cursor
    try:
        conn = psycopg2.connect(DB_URL)
        cursor = conn.cursor()

        cursor.execute("SELECT current_database();")
        print(f"Collegato al database: {cursor.fetchone()[0]}")
        print("Connessione al database stabilita...")

    except Exception as e:
        print(f"Errore connessione: {e}.")
        exit(1)


def disconnessione_db():
    # Chiusura della connessione
    if cursor:
        cursor.close()
    if conn:
        conn.close()
    print("Connessione chiusa.")


def esecuzione_query(query, params=None):
    # Esegue una query MA NON FA IL COMMIT
    try:
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        return True
    except Exception as e:
        print(f"\nERRORE NELLA QUERY: {e}")
        print(f"Dati: {params}")
        raise e


def genera_cf():
    while True:
        cf = fake.ssn()
        cf = cf.replace(" ", "").upper()
        if len(cf) == 16:
            return cf


def genera_piva():
    cifre = [random.randint(0, 9) for _ in range(10)]
    s = 0
    for i in range(10):
        if i % 2 == 0:
            s += cifre[i]
        else:
            doppio = cifre[i] * 2
            if doppio > 9:
                doppio -= 9
            s += doppio

    controllo = (10 - (s % 10)) % 10
    cifre.append(controllo)

    return "".join(map(str, cifre))


# ============================================================================
# POPOLAMENTO TABELLE
# ============================================================================

def popola_corsi(num_corsi=10):
    print(f"\nGenerando {num_corsi} CORSI...")
    corsi_nomi = ['Python Basics', 'Advanced SQL', 'Web Development', 'Data Science',
                  'Machine Learning', 'Cloud Computing', 'Cybersecurity', 'DevOps',
                  'Java Enterprise', 'React & Frontend', 'Database Design', 'API REST']

    corsi_usati = []
    for i in range(num_corsi):
        codice = f"C{str(i + 1).zfill(3)}"  # Creazione del codice: es. "C001"
        nome = corsi_nomi[i % len(corsi_nomi)] + (f" - {i + 1}" if i >= len(corsi_nomi) else "")

        # Creazione query + Inserimento
        query = "INSERT INTO corso (codice, nome) VALUES (%s, %s)"
        esecuzione_query(query, (codice, nome))
        corsi_usati.append(codice)
    print(f"SUCCESSO: {len(corsi_usati)} corsi creati.")

    return corsi_usati


def popola_persone_e_docenti(num_docenti, num_partecipanti, corsi):
    print(f"\nGenerazione {num_docenti} DOCENTI (con abilitazioni) e {num_partecipanti} PARTECIPANTI...")
    persone = []
    titoli = ['Diploma', 'Laurea Triennale', 'Laurea Magistrale', 'Dottorato', 'Master']

    # 1. Creazione DOCENTI (con vincoli soddisfatti)
    for i in range(num_docenti):
        cf = genera_cf()
        nome = fake.first_name().replace("'", "''")
        cognome = fake.last_name().replace("'", "''")
        data_nascita = fake.date_of_birth(minimum_age=30, maximum_age=70).isoformat()
        luogo_nascita = fake.city().replace("'", "''")
        indirizzo = fake.address().replace('\n', ' ').replace("'", "''")
        sesso = random.choice(['M', 'F'])
        titolo = random.choice(titoli)
        tipo = 'Docente'

        # Inserimento in Persona
        query_persona = """INSERT INTO persona (cf, nome, cognome, data_nascita, luogo_nascita, 
                   indirizzo, sesso, titolo_studio, tipo_persona) 
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)"""
        esecuzione_query(query_persona,
                         (cf, nome, cognome, data_nascita, luogo_nascita, indirizzo, sesso, titolo, tipo))

        # Specializzazione (Metà dipendenti, Metà collaboratori)
        if i % 2 == 0:
            data_assunzione = fake.date_between(start_date='-5y').isoformat()
            livello = random.randint(1, 7)
            esecuzione_query(
                "INSERT INTO dipendente (cf_dipendente, data_assunzione, livello_contratto) VALUES (%s, %s, %s)",
                (cf, data_assunzione, livello))
        else:
            p_iva = genera_piva()
            tariffa = round(random.uniform(25.0, 100.0), 2)
            esecuzione_query("INSERT INTO collaboratore (cf_collaboratore, p_iva, tariffa_oraria) VALUES (%s, %s, %s)",
                             (cf, p_iva, tariffa))

        # ABILITAZIONE (soddisfa il trigger di cardinalità minima)
        num_corsi_abilitati = random.randint(1, 3)
        corsi_abilitati = random.sample(corsi, min(num_corsi_abilitati, len(corsi)))
        for corso in corsi_abilitati:
            esecuzione_query("INSERT INTO abilitazione (cf_docente, codice_corso) VALUES (%s, %s)", (cf, corso))

        persone.append({'cf': cf, 'nome': nome, 'cognome': cognome, 'tipo': 'Docente', 'abilitazioni': corsi_abilitati})

    # 2. Creazione PARTECIPANTI
    for _ in range(num_partecipanti):
        cf = genera_cf()
        nome = fake.first_name().replace("'", "''")
        cognome = fake.last_name().replace("'", "''")
        data_nascita = fake.date_of_birth(minimum_age=18, maximum_age=65).isoformat()
        luogo_nascita = fake.city().replace("'", "''")
        indirizzo = fake.address().replace('\n', ' ').replace("'", "''")
        sesso = random.choice(['M', 'F'])
        titolo = random.choice(titoli)
        tipo = 'Partecipante'

        query_persona = """INSERT INTO persona (cf, nome, cognome, data_nascita, luogo_nascita, 
                   indirizzo, sesso, titolo_studio, tipo_persona) 
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)"""
        esecuzione_query(query_persona,
                         (cf, nome, cognome, data_nascita, luogo_nascita, indirizzo, sesso, titolo, tipo))
        persone.append({'cf': cf, 'nome': nome, 'cognome': cognome, 'tipo': 'Partecipante'})

    print(f"SUCCESSO: {num_docenti} docenti e {num_partecipanti} partecipanti creati con rispettivi vincoli.")
    return persone


def popola_fasce_orarie():
    print(f"\nCreazione FASCE ORARIE...")
    fasce = [(1, '09:00', '11:00'), (2, '11:15', '13:15'), (3, '14:00', '16:00'), (4, '16:15', '18:15')]

    # Creazione delle fasce orarie + Inserimento
    for id_fascia, ora_inizio, ora_fine in fasce:
        query = "INSERT INTO fascia_oraria (id_fascia, ora_inizio, ora_fine) VALUES (%s, %s, %s)"
        query += " ON CONFLICT (id_fascia) DO NOTHING"
        esecuzione_query(query, (id_fascia, ora_inizio, ora_fine))

    print(f"SUCCESSSO: Create {len(fasce)} fasce orarie.")


def popola_edizioni_e_insegnamenti(corsi, persone, num_edizioni_per_corso=3):
    print(f"\nCreando EDIZIONI e assegnando INSEGNAMENTI...")
    count_edizioni = 0
    count_insegnamenti = 0
    anno_corrente = 2026

    # Filtro solo i docenti
    docenti = [p for p in persone if p['tipo'] == 'Docente']

    for corso in corsi:
        for num in range(1, num_edizioni_per_corso + 1):
            anno = anno_corrente - (3 - num)
            stato = 'Corrente' if anno == anno_corrente else 'Passata'
            mese_inizio = random.choice([2, 9])
            giorno = random.randint(1, 15)
            data_inizio = datetime(anno, mese_inizio, giorno).date()
            data_fine = data_inizio + timedelta(weeks=20)
            ore_totali = 120
            num_partecipanti = random.randint(1, 150)

            # Inserimento EDIZIONE
            query_edizione = """INSERT INTO edizione (codice_corso, numero, data_inizio, data_fine, 
                       ore_totali, num_iscritti, stato_edizione) 
                       VALUES (%s, %s, %s, %s, %s, %s, %s)"""
            esecuzione_query(query_edizione,
                             (corso, num, data_inizio.isoformat(), data_fine.isoformat(), ore_totali, num_partecipanti,
                              stato))
            count_edizioni += 1

            # Assegnazione INSEGNAMENTO
            docenti_abilitati = [d for d in docenti if corso in d['abilitazioni']]
            docenti_scelti = random.sample(docenti_abilitati, 1) if docenti_abilitati else random.sample(docenti, 1)

            for docente in docenti_scelti:
                query_inseg = "INSERT INTO insegnamento (cf_docente, codice_corso, num_edizione) VALUES (%s, %s, %s)"
                esecuzione_query(query_inseg, (docente['cf'], corso, num))
                count_insegnamenti += 1

    print(f"SUCCESSO: {count_edizioni} edizioni e {count_insegnamenti} insegnamenti creati.")


def popola_lezioni(corsi):
    print(f"\nCreando LEZIONI...")
    count = 0
    query_edizioni = "SELECT codice_corso, numero FROM edizione WHERE stato_edizione = 'Corrente'"
    cursor.execute(query_edizioni)
    edizioni = cursor.fetchall()

    giorni_validi = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì']

    for codice_corso, numero in edizioni:
        # Scelgo casualmente da 2 a 3 giorni a settimana per x corso
        giorni_scelti = random.sample(giorni_validi, random.randint(2, 3))

        for giorno in giorni_scelti:
            id_fascia = random.randint(1, 4)
            piano = random.randint(1, 3)
            aula_lettera = random.choice('ABCDE')
            aula = f"Aula {aula_lettera}{piano}"

            query = """INSERT INTO lezione (codice_corso, num_edizione, id_fascia, giorno, aula) 
                       VALUES (%s, %s, %s, %s, %s) ON CONFLICT DO NOTHING"""
            esecuzione_query(query, (codice_corso, numero, id_fascia, giorno, aula))
            count += 1

    print(f"SUCCESSO: {count} lezioni create.")


def popola_telefoni(persone):
    print(f"\nCreando NUMERI DI TELEFONO...")

    count = 0
    for persona in persone:
        # Scelta casuale se questa persona ha 1 o 2 numeri di telefono
        num_numeri = random.randint(1, 2)

        for _ in range(num_numeri):
            numero = f"3{random.randint(100000000, 999999999)}"  # Genera un numero italiano fittizio

            query = "INSERT INTO telefono (numero_tel, cf_proprietario) VALUES (%s, %s)"

            try:
                esecuzione_query(query, (numero, persona['cf']))
                count += 1
            except Exception as e:
                # Se il numero è duplicato, lo salto
                continue

    print(f"{count} numeri di telefono inseriti.")


def popola_frequenze(persone, corsi):
    print(f"\nCreando FREQUENZE...")
    partecipanti = [p for p in persone if p['tipo'] == 'Partecipante']
    count = 0

    # Estraggo stato_edizione per non mettere voti ai corsi correnti
    query_edizioni = "SELECT codice_corso, numero, stato_edizione FROM edizione"
    cursor.execute(query_edizioni)
    edizioni = cursor.fetchall()

    for corso, numero, stato in edizioni:
        partecipanti_edizione = random.sample(partecipanti, min(random.randint(5, 15), len(partecipanti)))
        for partecipante in partecipanti_edizione:

            # Assegna il voto SOLO se l'edizione è passata
            voto = None
            if stato == 'Passata':
                voto = random.randint(6, 10) if random.random() < 0.8 else None

            query = "INSERT INTO frequenza (cf_partecipante, codice_corso, num_edizione, voto_finale) VALUES (%s, %s, %s, %s)"
            esecuzione_query(query, (partecipante['cf'], corso, numero, voto))
            count += 1
    print(f"SUCCESSO: {count} frequenze create.")


# ============================================================================
# MAIN
# ============================================================================

def main():
    print("=" * 70)
    print("SCRIPT DI POPOLAMENTO DATABASE - Corsi e Formazione")
    print("=" * 70)

    connessione_db()

    try:
        # BLOCCO 1: Dati Base
        corsi = popola_corsi(12)
        popola_fasce_orarie()
        conn.commit()
        print(">>> Commit 1 (Corsi e Fasce) effettuato.")

        # BLOCCO 2: Persone, Abilitazioni e Specializzazioni
        persone = popola_persone_e_docenti(6, 25, corsi)
        conn.commit()
        print(">>> Commit 2 (Persone e Abilitazioni) effettuato.")

        # BLOCCO 3: Edizioni e Insegnamenti
        popola_edizioni_e_insegnamenti(corsi, persone, 3)
        conn.commit()
        print(">>> Commit 3 (Edizioni e Insegnamenti) effettuato.")

        # BLOCCO 4: Dati accessori (Lezioni, Frequenze, Telefoni)
        popola_lezioni(corsi)
        popola_telefoni(persone)
        popola_frequenze(persone, corsi)
        conn.commit()
        print(">>> Commit 4 (Lezioni, Telefoni, Frequenze) effettuato.")

        print("\n" + "=" * 70)
        print("POPOLAMENTO COMPLETATO CON SUCCESSO E SALVATO NEL DB.")
        print("=" * 70)

    except Exception as e:
        conn.rollback()
        print(f"\nROLLBACK effettuato. Errore: {e}")

    finally:
        disconnessione_db()


if __name__ == '__main__':
    main()