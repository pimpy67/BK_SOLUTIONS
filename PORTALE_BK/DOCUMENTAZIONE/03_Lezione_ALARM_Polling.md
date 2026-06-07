# 📚 LEZIONE 3: ALARM E POLLING - COME IL PORTALE RACCOGLIE EVENTI

**Autore:** Claude Code  
**Data:** Giugno 2026  
**Progetto:** Portale BK-Service - Autorizzazione Licenze Software  
**Livello:** Intermedio

---

## 📑 INDICE

1. [Il Problema](#parte-1-il-problema)
2. [Due Soluzioni: PUSH vs PULL](#parte-2-due-soluzioni-push-vs-pull)
3. [POLLING (PULL)](#parte-3-polling-pull)
4. [ALARM nel Progetto](#parte-4-alarm-nel-progetto-bk-service)
5. [Flusso ALARM Dettagliato](#parte-5-flusso-alarm-dettagliato)
6. [Configurazione ALARM](#parte-6-configurazione-alarm)
7. [Gestione Errori](#parte-7-gestione-errori)
8. [Vantaggi e Svantaggi](#parte-8-vantaggi-e-svantaggi)

---

## PARTE 1: IL PROBLEMA

### Scenario: Come comunica il Portale con l'ERP?

```
SITUAZIONE:
Cliente paga presso il Fornitore (ERP)
    ↓
ERP registra il pagamento
    ↓
Portale BK deve sapere del pagamento
    ↓
Come fa il Portale a scoprirlo?
```

### Due approcci possibili:

```
APPROCCIO 1: ERP manda messaggio al Portale (PUSH)
ERP → "Hey Portale, cliente ha pagato!"
      Portale riceve subito

APPROCCIO 2: Portale chiede periodicamente all'ERP (PULL)
Portale → "ERP, ci sono novità?"
ERP     → "Sì, cliente ha pagato"
Portale riceve dopo un po'
```

### Nel progetto BK-Service:

**Usiamo APPROACH 2 (PULL/POLLING)** perché:
- ✅ ERP non deve sapere dell'indirizzo del Portale
- ✅ ERP non deve aprire connessioni verso Portale
- ✅ Più semplice da implementare e gestire
- ✅ Più sicuro (Portale controlla il flusso)

---

## PARTE 2: DUE SOLUZIONI: PUSH vs PULL

### PUSH (Push Notification)

```
ERP ─── "Cliente ABC ha pagato!" ───→ Portale
   (ERP prende l'iniziativa)

Caratteristiche:
✅ Istantaneo (notizia arriva subito)
✅ Efficiente (non chiedi se non serve)
❌ Complesso (ERP deve conoscere Portale)
❌ Problemi di connessione = perdita notizie
❌ Come fa ERP a sapere indirizzo Portale?
```

### PULL (Polling)

```
Portale ← "Scusa, novità?" ← ERP
 (Portale chiede periodicamente)

Ogni 5 minuti:
Portale → "Ci sono nuovi pagamenti?"
ERP     → "Sì: ABC pagato, DEF pagato"
Portale → "Ok, salvato. Cancella lista"
ERP     → "Ok"

Caratteristiche:
✅ Semplice (Portale controlla tutto)
✅ Affidabile (se fallisce, riprova dopo)
✅ Sicuro (Portale decide quando)
❌ Non istantaneo (latenza fino a 5 minuti)
❌ Più richieste (anche se non serve)
```

### Nel progetto: POLLING ✅

```
Portale chiede all'ERP ogni N secondi (configurabile):

GET /erp/alarm?codice=XXX

ERP risponde:
[
  { tipo: "PAGAMENTO_CONFERMATO", cliente: "ABC", ... },
  { tipo: "PAGAMENTO_CONFERMATO", cliente: "DEF", ... },
  { tipo: "NEW_INVOICE", cliente: "ABC", ... }
]

Portale elabora, quindi chiede:
GET /erp/alarm/ack?eventi=[id1, id2, id3]
(Per dire: "Ho elaborato questi, elimina dalla coda")
```

---

## PARTE 3: POLLING (PULL)

### Cos'è il Polling?

```
POLLING = Fare domande ripetutamente finché non ricevi una risposta

ANALOGIA: Controllare la cassetta postale

Ogni mattina:
- Vai alla cassetta postale
- Apri: "C'è posta?"
- Sì: Raccogli le lettere, chiudi cassetta, vai
- No: Chiudi cassetta, vai
- Domani, ripeti

STESSO CONCETTO:
Ogni 5 minuti:
- Portale chiama ERP
- ERP: "Ecco gli eventi nuovi"
- Portale: "Ok, li elaboro"
- Attendi 5 minuti
- Ripeti
```

### Polling: Step-by-step

```
CICLO INFINITO:

╔═══════════════════════════════════╗
║ PASSO 1: Attendi intervallo       ║
║ (es. 5 minuti = 300 secondi)      ║
╚═══════════════════════════════════╝
         ↓
╔═══════════════════════════════════╗
║ PASSO 2: Fai richiesta            ║
║ GET /erp/alarm?codice=ABC123      ║
╚═══════════════════════════════════╝
         ↓
╔═══════════════════════════════════╗
║ PASSO 3: Ricevi risposta          ║
║ {                                 ║
║   "eventi": [                     ║
║     {...},  {...},  {...}         ║
║   ]                               ║
║ }                                 ║
╚═══════════════════════════════════╝
         ↓
╔═══════════════════════════════════╗
║ PASSO 4: Elabora eventi           ║
║ Per ogni evento:                  ║
║ - Leggi il tipo                   ║
║ - Esegui azione (crea licenza, ecc.) ║
║ - Registra come elaborato         ║
╚═══════════════════════════════════╝
         ↓
╔═══════════════════════════════════╗
║ PASSO 5: Conferma ricezione (ACK) ║
║ GET /erp/alarm/ack?events=[1,2,3] ║
╚═══════════════════════════════════╝
         ↓
╔═══════════════════════════════════╗
║ TORNA A PASSO 1                   ║
╚═══════════════════════════════════╝
```

---

## PARTE 4: ALARM NEL PROGETTO BK-SERVICE

### Cos'è ALARM?

```
ALARM = Il sistema di Polling del Portale BK-Service

È l'UNICA chiamata IN USCITA del Portale verso l'esterno.

Portale:
┌────────────────────────────┐
│ IN (riceve):               │
│ - POST /client/register    │
│ - POST /client/license/issue
│ - POST /client/heartbeat   │
│                            │
│ OUT (invia):               │
│ - GET /alarm ← UNICA!     │
└────────────────────────────┘
        ↕
       ERP
```

### Endpoint ALARM:

```
GET /{base}/{desinenza}/{erp}/alarm?codice=XXXX

Esempio reale:
GET https://erp.bksolution.it/api/licenze/alarm?codice=PORTALE_ABC

Parametri:
- {base} = https://erp.bksolution.it
- {desinenza} = /api
- {erp} = licenze
- codice = identificativo univoco del Portale presso ERP
          (come un numero cliente)
```

### Cosa aspetta il Portale?

```
Risposta da ERP:

{
  "eventi": [
    {
      "id_evento": 1,
      "tipo": "PAGAMENTO_CONFERMATO",
      "cliente": "ABC",
      "prodotto": "FATTURA",
      "piano": "ANNUALE",
      "durata": 365,
      "importo": 1200.00,
      "riferimento_pagamento": "PAG_20260607_001",
      "timestamp": "2026-06-07T10:30:00Z"
    },
    {
      "id_evento": 2,
      "tipo": "NEW_INVOICE",
      "cliente": "ABC",
      "numero_fattura": "F001/2026",
      "data_fattura": "2026-06-07",
      "timestamp": "2026-06-07T10:35:00Z"
    }
  ]
}
```

### Eventi principali nel Progetto:

| Tipo Evento | Origine | Azione Portale |
|---|---|---|
| **PAGAMENTO_CONFERMATO** | ERP | Attiva/Rinnova licenza |
| **NEW_INVOICE** | ERP | Completa riga Pagamenti |
| **NEW_CUSTOMER** | ERP | Crea nuovo cliente |
| **NEW_PRODUCT** | ERP | Aggiorna catalogo |
| **CMD_SOSPENDI** | ERP | Sospende licenza |
| **CMD_RIATTIVA** | ERP | Riattiva licenza |
| **CMD_REVOCA** | ERP | Revoca licenza |
| **CMD_PROROGA** | ERP | Estende licenza |

---

## PARTE 5: FLUSSO ALARM DETTAGLIATO

### Workflow B: Acquisto → Attivazione

```
FASE 1: CLIENTE PAGA
┌─────────────────────────┐
│ Cliente paga presso ERP │
└─────────────────────────┘
         ↓
FASE 2: ERP REGISTRA
┌──────────────────────────────┐
│ ERP crea record di pagamento │
│ Accoda evento in tabella:    │
│ {                            │
│   tipo: "PAGAMENTO_...",     │
│   cliente: "ABC",            │
│   rif_pagamento: "PAG_001"   │
│ }                            │
└──────────────────────────────┘
         ↓ (in attesa)
         ↓ (ERP tiene i record in coda)
         ↓
FASE 3: PORTALE CHIEDE ALARM
┌──────────────────────────────┐
│ GET /erp/alarm?codice=XYZ    │
│                              │
│ Portale chiede: "Novità?"    │
└──────────────────────────────┘
         ↓
FASE 4: ERP RISPONDE
┌──────────────────────────────┐
│ HTTP 200 OK                  │
│ {                            │
│   "eventi": [               │
│     {                        │
│       "id_evento": 1,       │
│       "tipo": "PAGAMENTO...",│
│       "cliente": "ABC",      │
│       ...                    │
│     }                        │
│   ]                          │
│ }                            │
└──────────────────────────────┘
         ↓
FASE 5: PORTALE ELABORA
┌──────────────────────────────┐
│ Portale riceve evento        │
│ 1. Legge: PAGAMENTO_CONFERMATO
│ 2. Cerca cliente ABC         │
│ 3. Trova licenza TRIAL       │
│ 4. La cambia a ACTIVE        │
│ 5. Setta data_scadenza       │
│ 6. Firma nuovo entitlement   │
│ 7. Salva tutto nel DB        │
│ 8. Crea evento: LICENZA_ATTIVATA
│ 9. Invia email di conferma   │
└──────────────────────────────┘
         ↓
FASE 6: PORTALE CONFERMA (ACK)
┌──────────────────────────────┐
│ GET /erp/alarm/ack?          │
│    events=[1]                │
│                              │
│ Portale dice: "Ho fatto"     │
└──────────────────────────────┘
         ↓
FASE 7: ERP CANCELLA
┌──────────────────────────────┐
│ ERP risponde: HTTP 200       │
│ ERP cancella evento dalla coda│
│                              │
│ Prossima volta che Portale   │
│ chiede: "Non c'è più"        │
└──────────────────────────────┘
         ↓
✅ DONE! Licenza attivata
```

---

## PARTE 6: CONFIGURAZIONE ALARM

### Cosa si configura?

```
TABELLA ConfigAlarm:

┌──────────────────┬─────────────────────────────┐
│ Campo            │ Valore Esempio              │
├──────────────────┼─────────────────────────────┤
│ indirizzo_base   │ https://erp.bksolution.it   │
│ desinenza        │ /api/licenze                │
│ erp_nome         │ BkSolution                  │
│ codice_controllo │ PORTALE_ABC123              │
│ intervallo_sec   │ 300 (5 minuti)              │
│ ultimo_polling   │ 2026-06-07T10:30:00Z        │
│ attivo           │ 1 (true)                    │
└──────────────────┴─────────────────────────────┘

Significato:
- indirizzo_base = Dove trobare l'ERP
- desinenza = Quale API dell'ERP
- erp_nome = Nome dell'ERP (per log)
- codice_controllo = ID che ERP riconosce
- intervallo_sec = Ogni quanto tempo fare richieste (CRITICO!)
- ultimo_polling = Timestamp dell'ultima richiesta
- attivo = Se il polling è acceso
```

### Intervallo_sec: Quanto spesso chiedere?

```
TRADE-OFF:

INTERVALLO BREVE (30 secondi):
✅ Latenza bassa (pagamenti attivati in 30 sec)
❌ Tanti request (288 al giorno)
❌ Carico ERP alto
❌ Costi rete

INTERVALLO LUNGO (1 ora):
✅ Pochi request (24 al giorno)
✅ Carico basso
❌ Latenza alta (pagamenti attivati in 1 ora!)
❌ Cliente aspetta

COMPROMESSO (5 minuti = 300 sec):
✅ Latenza ragionevole (~5 min)
✅ Pochi request (288 al giorno)
✅ Carico ERP accettabile
✅ Buon compromesso
```

### Configurazione del Portale:

```
Nel database BK-Service:

INSERT INTO ConfigAlarm (
  indirizzo_base,
  desinenza,
  erp_nome,
  codice_controllo,
  intervallo_sec,
  attivo
) VALUES (
  'https://erp.bksolution.it',
  '/api/licenze',
  'BkSolution',
  'PORTALE_ABC123',
  300,
  1
);

Ogni 5 minuti, il Portale esegue:
- Controlla `ConfigAlarm`
- Costruisce URL: 
  https://erp.bksolution.it/api/licenze/alarm?codice=PORTALE_ABC123
- Fa GET
- Elabora risposte
- Fa ACK
- Aggiorna `ultimo_polling`
```

---

## PARTE 7: GESTIONE ERRORI

### Cosa accade se il polling fallisce?

```
SCENARIO 1: ERP è down

Portale → GET /alarm?...
ERP ✗ (non risponde)
Portale → Ritenta dopo 30 secondi
ERP ✓ (torna online)
Portale riceve gli eventi
✅ Non perdi nulla

SCENARIO 2: Portale non conferma (ACK)

Portale → GET /alarm
ERP → Ecco gli eventi
Portale elabora...
(Portale crasha prima di fare ACK)

Prossima volta:
Portale → GET /alarm
ERP → Ecco gli eventi ANCORA (non foram cancellati)
Portale → Crea licenza... (ma esiste già!)
Portale → Errore: Licenza duplicata

PROTEZIONE: Idempotenza!
Portale controlla: "Esiste già questa licenza?"
Sì → Skip, non duplicare
No → Crea
```

### Strategie di retry:

```
Se polling fallisce:

TENTATIVO 1: Subito (1 sec dopo)
TENTATIVO 2: 30 secondi dopo
TENTATIVO 3: 1 minuto dopo
TENTATIVO 4: 5 minuti dopo
TENTATIVO 5: 10 minuti dopo

Se ancora fallisce: Log di errore e continua
(Riproverà al prossimo ciclo di polling)
```

---

## PARTE 8: VANTAGGI E SVANTAGGI

### Vantaggi del Polling (ALARM)

```
✅ SEMPLICE
   - ERP non deve sapere dell'indirizzo Portale
   - Portale controlla tutto
   
✅ AFFIDABILE
   - Se fallisce, riprova
   - Niente dati persi (ERP mantiene coda)
   
✅ SCALABILE
   - ERP non deve gestire connessioni in arrivo
   - Portale può aggiungere più copie senza problema
   
✅ IDEMPOTENTE
   - Se stessa richiesta arriva 2 volte → Nessun problema
   - La licenza non si duplica
   
✅ SICURO
   - Solo Portale apre connessioni (attivo)
   - ERP rimane passivo e protetto
```

### Svantaggi del Polling (ALARM)

```
❌ LATENZA
   - Non istantaneo
   - Cliente aspetta fino a 5 minuti
   
❌ RICHIESTE INUTILI
   - Anche se non c'è nulla, il Portale chiede comunque
   - Carico su ERP
   
❌ COMPLESSITÀ NELLA CODA
   - ERP deve mantenere una coda di eventi
   - Se ERP crasha, la coda potrebbe perdersi
   - (Soluzione: Persistere in DB, non in memoria)
```

### Alternative non usate:

```
WEBHOOK (PUSH):
POST https://portale.bk/api/webhook
Body: { evento: "PAGAMENTO_CONFERMATO", ... }

❌ Perché non lo usiamo:
- ERP deve sapere l'indirizzo del Portale (complesso)
- Se Portale è down, ERP perde l'evento (fragile)
- Difficile da testare (richiede ambienti pubblici)

WEBSOCKET (Real-time):
Connessione bidirezionale permanente

❌ Perché non lo usiamo:
- Overkill per 5 minuti di latenza
- Complesso per app remote
- Consuma memoria (connessioni aperte)

MESSAGE QUEUE (RabbitMQ, Kafka):
ERP → Queue ← Portale

❌ Perché non lo usiamo:
- Dipendenza da servizio esterno
- Più componenti = più complessità
- Per ora non necessario
```

---

## RIASSUNTO FINALE

| Concetto | Cos'è |
|----------|-------|
| **Polling** | Chiedere periodicamente se ci sono novità |
| **ALARM** | Sistema di polling del Portale BK-Service |
| **intervallo_sec** | Ogni quanti secondi il Portale chiede |
| **Evento** | Una novità dall'ERP (pagamento, fattura, ecc.) |
| **ACK** | Conferma di ricezione ("Ho elaborato l'evento") |
| **Coda** | ERP mantiene gli eventi finché non son ACKati |
| **Idempotenza** | Stessa richiesta 2 volte = Nessun problema |

---

## ✅ CONCETTI CHIAVE DA RICORDARE

1. **Polling = Chiedere ripetutamente** (Pull, non Push)
2. **ALARM è l'unica uscita del Portale** verso l'esterno
3. **intervallo_sec = Trade-off tra latenza e carico**
4. **ERP mantiene una coda** finché Portale non fa ACK
5. **Idempotenza = protezione da duplicati**
6. **Se fallisce, Portale riprova** - i dati non si perdono

---

**Fine della Lezione**
