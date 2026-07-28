# Centro di formazione – Basi di dati

Il seguente database fa riferimento a un progetto di gruppo per il corso di Basi di Dati presso l'Università di Udine. Il sistema gestisce le informazioni e la logistica di un centro di formazione.

## Cosa gestisce il sistema

Il sistema informativo prevede:

- l'**anagrafica** di docenti e studenti;
- la programmazione oraria;
- la **logistica** delle lezioni nelle aule;
- lo **stato di avanzamento** delle edizioni dei corsi.

## Dettagli del progetto

Il progetto si è focalizzato sullo sviluppo dei seguenti punti:

- creazione di un **primo schema E-R** focalizzato sulla semantica dei requisiti;
- successiva **ristrutturazione** dello schema E-R volta alla semplificazione di alcune entità e alla normalizzazione;
- sviluppo di **vincoli d'integrità** e **analisi di attributi derivati**;
- definizione dello **schema relazionale**;
- sviluppo dello **schema fisico** (DDL);
- implementazione di **operazioni** (DML): inserimento, aggiornamento, query esaustive e viste;
- implementazione dei principali **trigger**;
- **popolamento** del database tramite **script in Python** (usando Faker per generare dati realistici).

## Tecnologie utilizzate

- **DBMS:** PostgreSQL
- **Linguaggi:** SQL, Python
- **Librerie Python:** Faker, psycopg2
- **Strumenti di modellazione:** Draw.io

## Come avviare il progetto

### 1. Prerequisiti

- **PostgreSQL:** versione 17.10+
- **Python:** versione 3.13.5+

### 2. Creazione e configurazione del database

1. Accedi a PostgreSQL (tramite interfaccia grafica o linea di comando) e crea un nuovo database vuoto.
2. Esegui lo script `tabelle_corsi_db.sql` per creare lo schema fisico (le tabelle).
3. Esegui lo script `creazione_db_trigger.sql` per impostare i trigger sulle tabelle appena create.

Esempio di esecuzione da riga di comando:

```bash
psql -U utente -d nome_db -f tabelle_corsi_db.sql
psql -U utente -d nome_db -f creazione_db_trigger.sql
```

### 3. Configurazione ambiente Python

```bash
python -m venv venv

# Su Windows:
venv\Scripts\activate

# Su macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 4. Popolamento del database

Prima di avviare lo script di popolamento, bisogna inserire le credenziali corrette per la connessione al database locale.

```bash
python popolamento_db.py
```
