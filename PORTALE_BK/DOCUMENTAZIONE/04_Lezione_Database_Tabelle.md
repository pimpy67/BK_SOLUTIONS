# 📚 LEZIONE 4: DATABASE E TABELLE - COME SONO ORGANIZZATI I DATI

**Autore:** Claude Code  
**Data:** Giugno 2026  
**Progetto:** Portale BK-Service - Autorizzazione Licenze Software  
**Livello:** Intermedio

---

## 📑 INDICE

1. [Cos'è un Database](#parte-1-cosè-un-database)
2. [Concetti Base: Tabelle e Righe](#parte-2-concetti-base-tabelle-e-righe)
3. [I 4 Gruppi di Tabelle](#parte-3-i-4-gruppi-di-tabelle)
4. [Relazioni tra Tabelle](#parte-4-relazioni-tra-tabelle)
5. [Chiavi Primarie e Straniere](#parte-5-chiavi-primarie-e-straniere)
6. [Esempio Pratico: Workflow Acquisto](#parte-6-esempio-pratico-workflow-acquisto)
7. [Query SQL Base](#parte-7-query-sql-base)
8. [Backup e Consistenza](#parte-8-backup-e-consistenza)

---

## PARTE 1: COS'È UN DATABASE?

### Definizione semplice:

```
DATABASE = Insieme organizzato di dati
           salvati in modo permanente
           che si possono cercare e modificare velocemente
```

### Analogia: Archivio di un'azienda

```
ARCHIVIO FISICO (vecchio):
Cassettone 1: Fatture (F001, F002, F003, ...)
Cassettone 2: Clienti (ABC, DEF, GHI, ...)
Cassettone 3: Fornitori (Fornitore A, B, C, ...)
Cassettone 4: Ordini (O001, O002, ...)

Vuoi cercare tutte le fatture del cliente ABC?
- Vado al cassettone 1 (fatture)
- Sfoglio una per una fino a trovarle
- Lento! ⏱️

DATABASE (digitale):
SELECT * FROM Fatture WHERE cliente = 'ABC'
↓
Risultato istantaneo ⚡
```

### Nel progetto BK-Service:

```
Il Portale ha UN UNICO database con:
- Clienti (anagrafica, contatti, lingue)
- Prodotti (catalogo, moduli, versioni)
- Licenze (stato, scadenza, limiti)
- Pagamenti (incassi, fatture)
- Dispositivi (fingerprint, heartbeat)
- Eventi (storia di cosa è accaduto)
- Notifiche (email, messaggi in-app)

Tutto salvato fisicamente su disco
in SQL Server (database relazionale)
```

---

## PARTE 2: CONCETTI BASE: TABELLE E RIGHE

### Tabella = Foglio Excel con dati omogenei

```
TABELLA: Clienti

┌────────┬──────────┬─────────┬──────────────────────┐
│ ID     │ P.IVA    │ Nome    │ Email                │
├────────┼──────────┼─────────┼──────────────────────┤
│ 1      │ 12345678 │ ABC SRL │ info@abc.it          │
│ 2      │ 87654321 │ DEF SPA │ contatti@def.com     │
│ 3      │ 11223344 │ GHI Ltd │ support@ghi.co.uk    │
└────────┴──────────┴─────────┴──────────────────────┘

Colonne (campi):
- ID: numero univoco
- P.IVA: codice fiscale
- Nome: ragione sociale
- Email: contatto

Righe (record):
- Riga 1: Dati di ABC SRL
- Riga 2: Dati di DEF SPA
- Riga 3: Dati di GHI Ltd
```

### Tipi di Colonne (Dati):

```
Testo (VARCHAR):
- P.IVA: "12345678"
- Email: "info@abc.it"
- Nome: "ABC SRL"

Numero (INT, BIGINT, DECIMAL):
- ID: 1, 2, 3
- Importo: 1200.50
- Numero Dispositivi: 5

Data/Ora (DATE, DATETIME):
- Data Creazione: 2026-06-07
- Scadenza: 2026-07-07T23:59:59

Booleano (BIT):
- Attivo: 1 (vero) oppure 0 (falso)
```

### Vincoli (Constraints):

```
PRIMARY KEY:
- Ogni riga ha un ID univoco
- ID non può ripetersi
- ID non può essere NULL

UNIQUE:
- Alcuni campi devono essere univoci
- Es: P.IVA di ogni cliente è unica (non 2 clienti hanno stessa P.IVA)

NOT NULL:
- Il campo è obbligatorio
- Non puoi lasciarlo vuoto

FOREIGN KEY:
- Riferimento ad altra tabella
- Es: licenza_cliente → ID del cliente (deve esistere in tabella Clienti)
```

---

## PARTE 3: I 4 GRUPPI DI TABELLE

### GRUPPO 1: Catalogo e Anagrafica

```
TABELLA: Prodotti
┌─────────────┬──────────┬──────────────────┐
│ ID_Prodotto │ Nome     │ Versione_Min     │
├─────────────┼──────────┼──────────────────┤
│ 1           │ Fattura  │ 2.0              │
│ 2           │ Spesometro│ 1.5             │
└─────────────┴──────────┴──────────────────┘

TABELLA: Moduli
┌─────────────┬──────────────────┬─────────────────┐
│ ID_Modulo   │ Nome             │ ID_Prodotto     │
├─────────────┼──────────────────┼─────────────────┤
│ 1           │ Gestione         │ 1 (Fattura)     │
│ 2           │ Notifiche        │ 1 (Fattura)     │
│ 3           │ Esportazione     │ 2 (Spesometro) │
└─────────────┴──────────────────┴─────────────────┘

TABELLA: Clienti
┌─────────────┬──────────┬────────────┬─────────┐
│ ID_Cliente  │ P.IVA    │ Nome       │ Lingua  │
├─────────────┼──────────┼────────────┼─────────┤
│ 1           │ 12345678 │ ABC SRL    │ it      │
│ 2           │ 87654321 │ DEF SPA    │ en      │
└─────────────┴──────────┴────────────┴─────────┘

TABELLA: PianiCatalogo
┌──────────┬──────────────┬─────────┬──────────────┐
│ ID_Piano │ Tipo         │ Durata  │ Max_Moduli   │
├──────────┼──────────────┼─────────┼──────────────┤
│ 1        │ TRIAL        │ 30      │ 2            │
│ 2        │ STANDARD     │ 365     │ 5            │
└──────────┴──────────────┴─────────┴──────────────┘

COSA CONTIENE:
✅ Informazioni statiche
✅ Configurazioni di catalogo
✅ Dati di clienti e fornitori
```

### GRUPPO 2: Licenze

```
TABELLA: Licenze
┌─────────────┬──────────────┬──────────┬──────────┐
│ ID_Licenza  │ ID_Cliente   │ Status   │ Scadenza │
├─────────────┼──────────────┼──────────┼──────────┤
│ 1           │ 1            │ TRIAL    │ 2026-07-07│
│ 2           │ 1            │ ACTIVE   │ 2027-06-07│
│ 3           │ 2            │ EXPIRED  │ 2026-05-01│
└─────────────┴──────────────┴──────────┴──────────┘

TABELLA: Dispositivi
┌──────────────┬──────────────┬──────────────┐
│ ID_Dispositivo│ ID_Licenza   │ Fingerprint  │
├──────────────┼──────────────┼──────────────┤
│ 1            │ 1            │ abc123xyz    │
│ 2            │ 1            │ def456uvw    │
│ 3            │ 2            │ ghi789rst    │
└──────────────┴──────────────┴──────────────┘

TABELLA: DocumentiLicenza
┌──────────────┬──────────────┬───────────┐
│ ID_Documento │ ID_Licenza   │ Entitlement│
├──────────────┼──────────────┼───────────┤
│ 1            │ 1            │ eyJhbGc...│
│ 2            │ 2            │ eyJhbGc...│
└──────────────┴──────────────┴───────────┘

COSA CONTIENE:
✅ Stato delle licenze
✅ Dispositivi registrati
✅ Entitlement firmati
✅ Informazioni di validità
```

### GRUPPO 3: Integrazione Fornitore

```
TABELLA: ConfigAlarm
┌──────────┬────────────────────┬──────────────┐
│ ID_Config│ Indirizzo_Base     │ Intervallo_Sec│
├──────────┼────────────────────┼──────────────┤
│ 1        │ https://erp.bk.it  │ 300          │
└──────────┴────────────────────┴──────────────┘

TABELLA: Eventi
┌──────────┬─────────────┬──────────────┬──────────┐
│ ID_Evento│ Tipo_Evento │ Origine      │ Payload  │
├──────────┼─────────────┼──────────────┼──────────┤
│ 1        │ PAGAMENTO_  │ FORNITORE    │ {json}   │
│ 2        │ NEW_INVOICE │ FORNITORE    │ {json}   │
│ 3        │ TRIAL_..    │ PORTALE      │ {json}   │
└──────────┴─────────────┴──────────────┴──────────┘

TABELLA: Pagamenti
┌──────────┬──────────────┬──────────────┬───────────┐
│ ID_Pagam │ ID_Cliente   │ Data_Pagam   │ Importo   │
├──────────┼──────────────┼──────────────┼───────────┤
│ 1        │ 1            │ 2026-06-07   │ 1200.00   │
│ 2        │ 2            │ 2026-06-06   │ 600.00    │
└──────────┴──────────────┴──────────────┴───────────┘

COSA CONTIENE:
✅ Configurazione ALARM
✅ Cronologia di eventi ricevuti
✅ Cronologia di pagamenti
```

### GRUPPO 4: Notifiche

```
TABELLA: ModelliNotifica
┌────────────┬───────────────┬──────────┐
│ ID_Modello │ Codice_Evento │ Corpo    │
├────────────┼───────────────┼──────────┤
│ 1          │ PORT_TRIAL... │ Ciao ... │
│ 2          │ PORT_LICENZA..│ La tua..│
└────────────┴───────────────┴──────────┘

TABELLA: Mail
┌──────────┬──────────────┬──────────┬──────────┐
│ ID_Mail  │ ID_Cliente   │ Oggetto  │ Stato    │
├──────────┼──────────────┼──────────┼──────────┤
│ 1        │ 1            │ Benvenuto│ INVIATA  │
│ 2        │ 1            │ Rinnovo  │ DA_INVI. │
└──────────┴──────────────┴──────────┴──────────┘

TABELLA: Messaggi
┌──────────┬──────────────┬──────────┬──────────┐
│ ID_Msg   │ ID_Cliente   │ Testo    │ Letto    │
├──────────┼──────────────┼──────────┼──────────┤
│ 1        │ 1            │ Trial ..│ 0        │
│ 2        │ 1            │ Attiva..│ 1        │
└──────────┴──────────────┴──────────┴──────────┘

COSA CONTIENE:
✅ Template email
✅ Cronologia email inviate
✅ Messaggi in-app per clienti
```

---

## PARTE 4: RELAZIONI TRA TABELLE

### Relazioni 1:N (Uno a Molti)

```
Un cliente ha MOLTE licenze

Clienti                  Licenze
┌────────────┐          ┌────────────┐
│ ID=1       │  1:N     │ ID=1       │
│ ABC SRL    │ ◀────────│ ABC-FATTURA│
│            │          │            │
└────────────┘          │ ID=2       │
                        │ ABC-SPESO  │
                        │            │
                        │ ID=3       │
                        │ ABC-ALTRO  │
                        └────────────┘

Significato:
Cliente ABC (ID=1) ha 3 licenze (IDs 1,2,3)
Ogni licenza sa chi è il suo cliente
```

### Relazioni N:M (Molti a Molti)

```
Una licenza ha MOLTI moduli
Un modulo è in MOLTE licenze

Licenze                    Moduli
┌────────────┐    N:M     ┌────────────┐
│ ID=1       │ ◀─────────▶│ ID=1       │
│ ABC-FATTURA│            │ Gestione   │
│            │            │            │
└────────────┘            │ ID=2       │
       ▲                   │ Notifiche  │
       │                   │            │
       │                   └────────────┘
       │
(Tabella di join: Licenze_Moduli)
┌──────────────────┐
│ ID_Licenza│ID_Mod│
├──────────┼──────┤
│ 1        │ 1    │
│ 1        │ 2    │
└──────────┴──────┘

Significato:
Licenza 1 ha moduli 1 e 2
```

---

## PARTE 5: CHIAVI PRIMARIE E STRANIERE

### Primary Key (Chiave Primaria)

```
PRIMARY KEY = ID univoco di una riga

TABELLA: Clienti
┌─────────────┬──────────┬────────────┐
│ ID_Cliente* │ P.IVA    │ Nome       │
├─────────────┼──────────┼────────────┤
│ 1           │ 12345678 │ ABC SRL    │
│ 2           │ 87654321 │ DEF SPA    │
│ 3           │ 11223344 │ GHI Ltd    │
└─────────────┴──────────┴────────────┘
  ↑
  Chiave Primaria (*)

Proprietà:
✅ Univoco (non si ripete)
✅ NOT NULL (non può essere vuoto)
✅ Uno per tabella
✅ Identifica una riga
```

### Foreign Key (Chiave Straniera)

```
FOREIGN KEY = Riferimento a Primary Key di un'altra tabella

TABELLA: Licenze
┌─────────────┬──────────────┬──────────┐
│ ID_Licenza* │ ID_Cliente→  │ Status   │
├─────────────┼──────────────┼──────────┤
│ 1           │ 1            │ TRIAL    │
│ 2           │ 1            │ ACTIVE   │
│ 3           │ 2            │ EXPIRED  │
└─────────────┴──────────────┴──────────┘
                ↑
          Foreign Key
          (riferisce Clienti.ID_Cliente)

Significato:
- Licenza 1 appartiene a Cliente 1 (ABC SRL)
- Licenza 2 appartiene a Cliente 1 (ABC SRL)
- Licenza 3 appartiene a Cliente 2 (DEF SPA)

Proprietà:
✅ Collega due tabelle
✅ Il valore deve esistere nell'altra tabella
✅ Se cancelli Cliente 1, cancelli anche licenze 1 e 2
   (integrità referenziale)
```

---

## PARTE 6: ESEMPIO PRATICO: WORKFLOW ACQUISTO

### Step 1: Cliente arriva nel DB

```
POST /api/v1/vendor/customers
Body: {
  "p_iva": "12345678",
  "nome": "ABC SRL",
  "email": "info@abc.it"
}

INSERT INTO Clienti (P.IVA, Nome, Email)
VALUES ('12345678', 'ABC SRL', 'info@abc.it');

Risultato:
┌─────────────┬──────────┬─────────────┐
│ ID_Cliente* │ P.IVA    │ Nome        │
├─────────────┼──────────┼─────────────┤
│ 1           │ 12345678 │ ABC SRL     │
└─────────────┴──────────┴─────────────┘
```

### Step 2: Libreria richiede trial

```
POST /api/v1/client/license/issue
(con registration_token che contiene cliente_id=1)

Portale esegue:
INSERT INTO Licenze (
  ID_Cliente,
  ID_Prodotto,
  Status,
  Data_Scadenza
) VALUES (1, 1, 'TRIAL', DATE_ADD(NOW(), INTERVAL 30 DAY));

Risultato:
┌─────────────┬──────────────┬──────────┬────────────┐
│ ID_Licenza* │ ID_Cliente→  │ Status   │ Scadenza   │
├─────────────┼──────────────┼──────────┼────────────┤
│ 1           │ 1            │ TRIAL    │ 2026-07-07 │
└─────────────┴──────────────┴──────────┴────────────┘
```

### Step 3: Cliente paga

```
ALARM riceve evento: PAGAMENTO_CONFERMATO
Payload: {
  "cliente_id": 1,
  "importo": 1200.00,
  "rif_pagamento": "PAG_001"
}

Portale esegue:
INSERT INTO Pagamenti (
  ID_Cliente,
  ID_Licenza,
  Data_Pagamento,
  Riferimento_Pagamento,
  Importo
) VALUES (1, 1, NOW(), 'PAG_001', 1200.00);

Risultato:
┌─────────────┬──────────────┬──────────────┬───────────┐
│ ID_Pagamento│ ID_Cliente→  │ Data_Pagam   │ Importo   │
├─────────────┼──────────────┼──────────────┼───────────┤
│ 1           │ 1            │ 2026-06-07   │ 1200.00   │
└─────────────┴──────────────┴──────────────┴───────────┘
```

### Step 4: Portale attiva licenza

```
UPDATE Licenze
SET Status = 'ACTIVE',
    Data_Scadenza = DATE_ADD(NOW(), INTERVAL 1 YEAR)
WHERE ID_Licenza = 1;

Risultato:
┌─────────────┬──────────────┬──────────┬────────────┐
│ ID_Licenza* │ ID_Cliente→  │ Status   │ Scadenza   │
├─────────────┼──────────────┼──────────┼────────────┤
│ 1           │ 1            │ ACTIVE   │ 2027-06-07 │ ← CAMBIATO!
└─────────────┴──────────────┴──────────┴────────────┘
```

### Step 5: Portale crea entitlement

```
INSERT INTO DocumentiLicenza (
  ID_Licenza,
  Entitlement,
  Firma
) VALUES (
  1,
  "eyJhbGc...",  ← JSON firmato
  "a1b2c3d..."   ← Firma del Portale
);

Risultato:
┌──────────────┬──────────────┬──────────────┐
│ ID_Documento │ ID_Licenza→  │ Entitlement  │
├──────────────┼──────────────┼──────────────┤
│ 1            │ 1            │ eyJhbGc...   │
└──────────────┴──────────────┴──────────────┘
```

---

## PARTE 7: QUERY SQL BASE

### SELECT (Leggi dati)

```
Mostra tutti i clienti:
SELECT * FROM Clienti;

Mostra solo nome e email di ABC:
SELECT Nome, Email FROM Clienti WHERE Nome = 'ABC SRL';

Mostra tutte le licenze attive:
SELECT * FROM Licenze WHERE Status = 'ACTIVE';

Mostra licenze in scadenza tra 7 giorni:
SELECT * FROM Licenze 
WHERE Data_Scadenza BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY);

Mostra tutte le licenze di cliente 1:
SELECT * FROM Licenze WHERE ID_Cliente = 1;
```

### INSERT (Aggiungi dati)

```
Aggiungi nuovo cliente:
INSERT INTO Clienti (P.IVA, Nome, Email)
VALUES ('99999999', 'XYZ Ltd', 'info@xyz.com');

Aggiungi nuova licenza:
INSERT INTO Licenze (ID_Cliente, ID_Prodotto, Status, Data_Scadenza)
VALUES (1, 1, 'TRIAL', '2026-07-07');
```

### UPDATE (Modifica dati)

```
Attiva una licenza:
UPDATE Licenze
SET Status = 'ACTIVE'
WHERE ID_Licenza = 1;

Aggiorna data scadenza:
UPDATE Licenze
SET Data_Scadenza = '2027-06-07'
WHERE ID_Licenza = 1;

Sospendi tutte le licenze di cliente 2:
UPDATE Licenze
SET Status = 'SUSPENDED'
WHERE ID_Cliente = 2;
```

### DELETE (Cancella dati)

```
ATTENZIONE: pericoloso!

Cancella un pagamento:
DELETE FROM Pagamenti WHERE ID_Pagamento = 1;

Nel progetto BK-Service:
- Usiamo soft delete (marcare come deleted, non cancellare)
- Raramente cancelliamo davvero
```

### JOIN (Combina dati da tabelle diverse)

```
Mostra nome cliente e status licenza:
SELECT c.Nome, l.Status
FROM Clienti c
JOIN Licenze l ON c.ID_Cliente = l.ID_Cliente
WHERE c.ID_Cliente = 1;

Risultato:
┌─────────┬────────┐
│ Nome    │ Status │
├─────────┼────────┤
│ ABC SRL │ TRIAL  │
│ ABC SRL │ ACTIVE │
└─────────┴────────┘

Mostra pagamenti dei clienti con nomi:
SELECT c.Nome, p.Importo, p.Data_Pagamento
FROM Clienti c
JOIN Pagamenti p ON c.ID_Cliente = p.ID_Cliente;
```

---

## PARTE 8: BACKUP E CONSISTENZA

### Backup

```
PERCHÉ è importante:
- Il disco potrebbe guastarsi
- Malware potrebbe cancellare dati
- Errore umano potrebbe fare guai

STRATEGIA nel Progetto:
- Backup completo ogni notte
- Backup incrementale ogni ora
- Backup geograficamente distribuito (su server remoti)
- Test di ripristino mensile
```

### Integrità Referenziale

```
Se cancelli un Cliente:
- Cosa succede alle sue Licenze?

OPZIONE 1: CASCADE
Cancella Cliente → Cancella tutte le sue Licenze
⚠️ Pericoloso!

OPZIONE 2: RESTRICT
Non permettere di cancellare Cliente se ha Licenze
✅ Sicuro (non perdi dati)

OPZIONE 3: SOFT DELETE
Non cancellare davvero, marcare come cancellato
UPDATE Clienti SET deleted_at = NOW()
✅ Sicuro + puoi ripristinare
```

### Transazioni

```
Una transazione = Serie di operazioni atomic

Scenario: Aggiorna licenza E crea pagamento
Se uno fallisce, l'altro non succede

BEGIN TRANSACTION
  UPDATE Licenze SET Status = 'ACTIVE' WHERE ID = 1;
  INSERT INTO Pagamenti (...) VALUES (...);
COMMIT;  ← Se arriva qui, entrambi confermati
         Se fallisce, niente è salvato (rollback)

Cosa protegge:
✅ Inconsistenze
✅ Duplicati parziali
✅ Stato incoerente del DB
```

---

## RIASSUNTO FINALE

| Concetto | Cos'è |
|----------|-------|
| **Database** | Insieme organizzato di dati |
| **Tabella** | Foglio con dati omogenei (righe + colonne) |
| **Riga** | Un record (es. un cliente) |
| **Colonna** | Un campo (es. nome, email) |
| **Primary Key** | ID univoco di una riga |
| **Foreign Key** | Riferimento a PK di un'altra tabella |
| **Relazione 1:N** | Un cliente → molte licenze |
| **Relazione N:M** | Molti moduli ← → molte licenze |
| **JOIN** | Combina dati da tabelle diverse |
| **Transazione** | Serie di operazioni atomic |

---

## ✅ CONCETTI CHIAVE DA RICORDARE

1. **Un database ha tabelle organizzate per argomento**
2. **Ogni riga ha un ID univoco (Primary Key)**
3. **Le tabelle sono collegate via Foreign Key**
4. **SQL SELECT/INSERT/UPDATE sono i comandi base**
5. **JOIN combina dati da tabelle diverse**
6. **Integrità referenziale = niente dati orfani**
7. **Transazioni = coerenza garantita**

---

**Fine della Lezione**
