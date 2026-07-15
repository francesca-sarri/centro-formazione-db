# Centro di formazione – Basi di dati

Il seguente database fa riferimento a un progetto di gruppo per il corso di Basi di Dati presso l'Università di Udine. Il sistema gestisce le informazioni e la logistica di un centro di formazione.

## Cosa gestisce il sistema

Il sistema informativo prevede:
* l'**anagrafica** di docenti e studenti;
* la programmazione oraria;
* la **logistica** delle lezioni nelle aule;
* lo **stato di avanzamento** delle edizioni dei corsi.

## Dettagli del progetto
Il progetto si è focalizzato sullo sviluppo dei seguenti punti:

* creazione di un **primo schema E-R** focalizzato sulla semantica dei requisiti;
* successiva **ristrutturazione** dello schema E-R volta alla semplificazione di alcune entità e alla normalizzazione;
* sviluppo di **vincoli d'integrità** e **analisi di attributi derivati**;
* definizione dello **schema relazionale**;
* sviluppo dello **schema fisico** (DDL);
* implementazione di **operazioni** (DML): inserimento, aggiornamento, query esaustive e viste;
* implementazione dei principali **trigger**;
* **popolamento** del database tramite **script in Python** (usando Faker per generare dati massivi realistici).

## Tecnologie utilizzate
- **DBMS:** PostgreSQL
- **Linguaggi:** SQL, Python
- **Librerie Python:** Faker, psycopg2
- **Strumenti di modellazione:** Draw.io

## Come avviare il progetto
