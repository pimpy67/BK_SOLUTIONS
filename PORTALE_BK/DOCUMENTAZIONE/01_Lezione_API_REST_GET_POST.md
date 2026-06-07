# 📚 LEZIONE TEORICA: API, REST, GET/POST, ENDPOINT

**Autore:** Claude Code  
**Data:** Giugno 2026  
**Progetto:** Portale BK-Service - Autorizzazione Licenze Software  
**Livello:** Principiante (spiegazione semplice e intuitiva)

---

## 📑 INDICE

1. [Cos'è un'API](#parte-1-cosè-unapi)
2. [Cos'è REST](#parte-2-cosè-rest)
3. [GET vs POST](#parte-3-get-vs-post---quando-usare-uno-o-laltro)
4. [Endpoint](#parte-4-cosè-un-endpoint)
5. [Richiesta e Risposta](#parte-5-richiesta-e-risposta)
6. [Formato Dati (JSON)](#parte-6-formato-dati-json)
7. [Status Code](#parte-7-status-code-i-codici-di-risposta)
8. [Applicazione al Progetto BK-Service](#parte-8-applicazione-al-tuo-progetto-bk-service)
9. [Riassunto Finale](#riassunto-finale)

---

## PARTE 1: COS'È UN'API?

### Analogia Reale (Restaurant)

Immagina un ristorante:
- **Tu** = cliente che vuole mangiare
- **Cameriere** = API
- **Cucina** = il sistema/server
- **Menu** = documentazione dell'API

```
TU (Cliente)
   |
   | "Vorrei un caffè, per favore"
   |
   v
CAMERIERE (API)
   |
   | Comunica alla cucina
   |
   v
CUCINA (Server)
   |
   | Prepara il caffè
   |
   v
CAMERIERE (API)
   |
   | Ti porta il caffè
   |
   v
TU (Cliente)
   |
   ✅ Hai il caffè!
```

### In Programmazione:

Un'**API** (Application Programming Interface) è un **"cameriere digitale"** che:
- ✅ Riceve richieste dal tuo programma/app
- ✅ Le comunica al server
- ✅ Ti restituisce il risultato

### Esempio reale del tuo progetto:

```
Libreria Client                    Portale BK-Service
      |                                  |
      | "Dammi una trial"                |
      |─────────────────────────────────>|
      |                                  |
      |  Ricerca nel database, crea     |
      |  licenza, firma documento       |
      |                                  |
      |<─────────────────────────────────|
      | Ecco l'entitlement firmato       |
      |                                  |
      ✅ App sbloccata!
```

---

## PARTE 2: COS'È REST?

### REST = "Architettura di comunicazione"

**REST** (Representational State Transfer) è un **insieme di regole** per comunicare tra sistemi.

Le regole principali:
1. ✅ **Usa Internet standard** (HTTP)
2. ✅ **Usa verbi chiari** (GET, POST, PUT, DELETE)
3. ✅ **Usa URL (endpoint) significativi**
4. ✅ **Restituisci dati strutturati** (solitamente JSON)

### I 4 Verbi REST principali:

| Verbo | Cosa fa | Esempio |
|-------|---------|---------|
| **GET** | Legge dati | Visualizza lo stato della licenza |
| **POST** | Crea/invia dati | Registra un nuovo cliente |
| **PUT** | Modifica dati | Aggiorna i dati di un cliente |
| **DELETE** | Cancella dati | Revoca una licenza |

---

## PARTE 3: GET vs POST - QUANDO USARE UNO O L'ALTRO

### GET = "Chiedere informazioni"

**Quando usarlo:**
- Vuoi **leggere/ricevere dati**
- NON vuoi modificare nulla
- I dati sono **pubblici** (non sensibili)

**Analogia:**
```
TU: "Cameriere, qual è il prezzo del caffè?"
CAMERIERE: "5 euro" ✅
```

**Esempio dal tuo progetto:**
```
GET /api/v1/client/license/status
↓
Portale risponde: "Status = TRIAL, giorni rimanenti = 28"
```

**Caratteristiche:**
- I dati **visibili nell'URL**: `GET /api/v1/license/status?cliente=123&prodotto=abc`
- Non è sicuro per **password/dati sensibili**
- **Più veloce**, cacheabile
- Usa **query parameters** (`?chiave=valore`)

---

### POST = "Inviare informazioni per creare/modificare qualcosa"

**Quando usarlo:**
- Vuoi **inviare dati** al server
- Vuoi **creare** qualcosa (nuova licenza, nuovo cliente)
- I dati sono **sensibili** (non vuoi vederli nell'URL)

**Analogia:**
```
TU: "Cameriere, voglio un caffè, un cornetto e una brioche"
CAMERIERE: Annota in un foglio (non nel menu!), lo passa in cucina
CUCINA: Prepara tutto
CAMERIERE: "Ecco, ordine completato"
```

**Esempio dal tuo progetto:**
```
POST /api/v1/client/register
Body: {
  "paese": "IT",
  "p_iva": "12345678901",
  "product_key": "FATTURA-2026",
  "fingerprint": "abc123xyz"
}
↓
Portale risponde: {
  "esito": "OK",
  "registration_token": "token_temporaneo_xyz"
}
```

**Caratteristiche:**
- I dati **nel "corpo" della richiesta** (invisibili nell'URL)
- ✅ **Sicuro per dati sensibili**
- **Più lento** di GET
- Serve per **creare, modificare, cancellare**

### Tabella Comparativa:

| Aspetto | GET | POST |
|---------|-----|------|
| **Uso** | Legge dati | Crea/modifica dati |
| **Sicurezza** | Bassa (visibile nell'URL) | Alta (nel corpo) |
| **Velocità** | Più veloce | Più lento |
| **Cache** | Sì | No |
| **Dati nel corpo** | No | Sì |
| **Idempotente** | Sì (ripetibile) | No |

---

## PARTE 4: COS'È UN ENDPOINT?

### Endpoint = "Indirizzo specifico dove mandare la richiesta"

È l'**URL completo** che indichi al server.

**Sintassi:**
```
{metodo} {base_url}{percorso}?{parametri}

Esempio:
GET https://api.portale.bk/api/v1/client/license/status?cliente_id=123
```

**Scomposizione:**
```
GET                           = Metodo (cosa fare)
https://api.portale.bk        = Base URL (dove)
/api/v1/client/license/status = Endpoint/Path (quale risorsa)
?cliente_id=123               = Query Parameter (filtri opzionali)
```

### Paragone reale:

```
GET     https://api.portale.bk/api/v1/client/license/status
 |         |                    |
Cosa fare  Ufficio postale       Sportello specifico, cassella specifica
```

### Endpoint del progetto BK-Service:

**Lato CLIENT:**
```
POST   /api/v1/client/register              → Registra dispositivo
POST   /api/v1/client/license/issue         → Richiedi trial
GET    /api/v1/client/license/status        → Visualizza stato
POST   /api/v1/client/heartbeat             → Invia heartbeat
POST   /api/v1/client/license/refresh       → Rinnova offline
POST   /api/v1/client/license/renew-request → Richiedi rinnovo
```

**Lato FORNITORE:**
```
POST   /api/v1/vendor/products              → Carica catalogo prodotti
POST   /api/v1/vendor/customers             → Carica clienti
GET    /{base}/{desinenza}/{erp}/alarm      → Polling ALARM (unica uscita)
```

---

## PARTE 5: RICHIESTA E RISPOSTA

### Come funziona una comunicazione API:

```
┌─────────────────────────────────────────────────────────┐
│                      CLIENTE (App)                       │
└─────────────────────────────────────────────────────────┘
                           |
                           | 1️⃣ RICHIESTA
                           |   POST /client/register
                           |   Body: { p_iva, product_key, fingerprint }
                           v
┌─────────────────────────────────────────────────────────┐
│                  PORTALE (Server)                        │
│  ✓ Riceve richiesta                                     │
│  ✓ Valida i dati                                        │
│  ✓ Cerca nel database                                   │
│  ✓ Genera token                                         │
│  ✓ Prepara risposta                                     │
└─────────────────────────────────────────────────────────┘
                           |
                           | 2️⃣ RISPOSTA
                           |   Status: 200 OK
                           |   Body: { registration_token, scadenza }
                           v
┌─────────────────────────────────────────────────────────┐
│                      CLIENTE (App)                       │
│  ✓ Riceve risposta                                      │
│  ✓ Salva il token                                       │
│  ✓ Procede con passo successivo                         │
└─────────────────────────────────────────────────────────┘
```

### Struttura di una richiesta:

```
┌─ RIGA DI RICHIESTA ─────────────────────────────┐
│ POST /api/v1/client/register HTTP/1.1           │
├─ HEADER (metadati) ────────────────────────────┤
│ Host: api.portale.bk                           │
│ Content-Type: application/json                 │
│ Content-Length: 256                            │
├─ CORPO (dati) ─────────────────────────────────┤
│ {                                               │
│   "paese": "IT",                               │
│   "p_iva": "12345678901",                      │
│   "product_key": "FATTURA-2026",               │
│   "fingerprint": "abc123xyz"                   │
│ }                                               │
└─────────────────────────────────────────────────┘
```

### Struttura di una risposta:

```
┌─ RIGA DI STATO ─────────────────────────────────┐
│ HTTP/1.1 200 OK                                 │
├─ HEADER (metadati) ────────────────────────────┤
│ Content-Type: application/json                 │
│ Content-Length: 512                            │
│ Date: Mon, 07 Jun 2026 10:00:00 GMT           │
├─ CORPO (dati) ─────────────────────────────────┤
│ {                                               │
│   "esito": "OK",                               │
│   "registration_token": "eyJhbGciOiJIUzI...",  │
│   "scadenza_token": "2026-06-07T12:30:00Z"     │
│ }                                               │
└─────────────────────────────────────────────────┘
```

---

## PARTE 6: FORMATO DATI (JSON)

Le API comunicano in **JSON** (JavaScript Object Notation).

### Esempio di richiesta POST:

```json
POST /api/v1/client/register

{
  "paese": "IT",
  "p_iva": "12345678901",
  "product_key": "FATTURA-ELETTRONICA-2026",
  "fingerprint": "a1b2c3d4e5f6g7h8"
}
```

### Esempio di risposta:

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "esito": "OK",
  "registration_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "scadenza_token": "2026-06-07T12:30:00Z",
  "messaggio": "Registrazione completata con successo"
}
```

**Cosa significa:**
- ✅ `esito: OK` = operazione riuscita
- ✅ `registration_token` = chiave temporanea per il prossimo step
- ✅ `scadenza_token` = quando scade il token

### Struttura JSON:

```json
{
  "campo_stringa": "valore",
  "campo_numero": 123,
  "campo_booleano": true,
  "campo_array": ["item1", "item2"],
  "campo_oggetto": {
    "sottocampo": "valore"
  }
}
```

---

## PARTE 7: STATUS CODE (I codici di risposta)

Il server risponde sempre con un **numero** che indica l'esito:

| Codice | Categoria | Significato | Esempio |
|--------|-----------|-------------|---------|
| **200** | ✅ 2xx Success | OK, tutto bene | Registrazione completata |
| **201** | ✅ 2xx Success | Creato | Nuova licenza creata |
| **204** | ✅ 2xx Success | No Content | Cancellazione completata |
| **400** | ❌ 4xx Client Error | Errore nel tuo input | P.IVA non valida |
| **401** | ❌ 4xx Client Error | Non autenticato | Token scaduto |
| **403** | ❌ 4xx Client Error | Non autorizzato | Non hai permessi |
| **404** | ❌ 4xx Client Error | Non trovato | Cliente non esiste |
| **500** | ❌ 5xx Server Error | Errore del server | Il server ha un problema |
| **503** | ❌ 5xx Server Error | Servizio non disponibile | Server in manutenzione |

### Esempio dal tuo progetto:

**Richiesta con errore:**
```
POST /api/v1/client/register
Body: { p_iva: "INVALIDA" }

Risposta:
HTTP 400 Bad Request
{
  "esito": "ERRORE",
  "codice_errore": "P_IVA_NON_VALIDA",
  "messaggio": "La P.IVA fornita non è valida"
}
```

**Richiesta riuscita:**
```
POST /api/v1/client/register
Body: { p_iva: "12345678901", ... }

Risposta:
HTTP 200 OK
{
  "esito": "OK",
  "registration_token": "xyz..."
}
```

---

## PARTE 8: APPLICAZIONE AL TUO PROGETTO BK-SERVICE

### Workflow A (Primo Avvio) in dettaglio:

```
┌────────────────────────────────────────────┐
│ 1. LIBRERIA GENERA FINGERPRINT             │
│    (no comunicazione, solo locale)         │
└────────────────────────────────────────────┘
                    |
                    v
┌────────────────────────────────────────────┐
│ 2. RICHIESTA POST /client/register         │
│    ─────────────────────────────────────→ │
│    {                                       │
│      paese: "IT",                          │
│      p_iva: "12345678901",                 │
│      product_key: "FATTURA-2026",          │
│      fingerprint: "abc123..."              │
│    }                                       │
└────────────────────────────────────────────┘
                    |
                    v
         ┌──────────────────┐
         │  PORTALE VALIDA  │
         │  I DATI          │
         └──────────────────┘
                    |
                    v
┌────────────────────────────────────────────┐
│ 3. RISPOSTA 200 OK                         │
│    ←─────────────────────────────────────  │
│    {                                       │
│      esito: "OK",                          │
│      registration_token: "token_xyz",      │
│      scadenza_token: "2026-06-07T12:00"    │
│    }                                       │
└────────────────────────────────────────────┘
                    |
                    v
┌────────────────────────────────────────────┐
│ 4. LIBRERIA RICEVE TOKEN                   │
│    (salva token in memoria)                │
└────────────────────────────────────────────┘
                    |
                    v
┌────────────────────────────────────────────┐
│ 5. RICHIESTA POST /client/license/issue    │
│    ─────────────────────────────────────→ │
│    {                                       │
│      registration_token: "token_xyz"       │
│    }                                       │
└────────────────────────────────────────────┘
                    |
                    v
         ┌──────────────────┐
         │  PORTALE CREA    │
         │  LICENZA TRIAL   │
         │  E LA FIRMA      │
         └──────────────────┘
                    |
                    v
┌────────────────────────────────────────────┐
│ 6. RISPOSTA 200 OK                         │
│    ←─────────────────────────────────────  │
│    {                                       │
│      status: "TRIAL",                      │
│      entitlement: "eyJ0eXAiOiJKV1QiLCJhbGc", │
│      data_scadenza: "2026-07-07"           │
│    }                                       │
└────────────────────────────────────────────┘
                    |
                    v
┌────────────────────────────────────────────┐
│ 7. LIBRERIA RICEVE ENTITLEMENT             │
│    ✅ SBLOCCA LA TRIAL!                    │
└────────────────────────────────────────────┘
```

### Workflow B (Acquisto) - Flusso semplificato:

```
CLIENTE PAGA
    |
    v
ERP GENERA EVENTO: FORN_PAGAMENTO_CONFERMATO
    |
    v (in coda)
    |
PORTALE ESEGUE ALARM (GET /alarm)
    |
    v
PORTALE ELABORA EVENTO
    |
    v
PORTALE CREA PAGAMENTO NEL DB
    |
    v
PORTALE PORTA LICENZA: TRIAL → ACTIVE
    |
    v
PORTALE FIRMA NUOVO ENTITLEMENT (ACTIVE)
    |
    v
LIBRERIA RICEVE ENTITLEMENT ACTIVE
    |
    v
✅ FUNZIONI COMPLETE SBLOCATE!
```

---

## RIASSUNTO FINALE

| Concetto | Cos'è | Analogia |
|----------|-------|----------|
| **API** | Cameriere digitale che comunica tra client e server | Cameriere al ristorante |
| **REST** | Architettura/regole per le API | Regole del ristorante |
| **GET** | Leggi/chiedi dati senza modificare | "Qual è il prezzo?" |
| **POST** | Invia dati per creare/modificare | "Voglio questo ordine" |
| **Endpoint** | Indirizzo specifico (URL) dove mandare la richiesta | Sportello del PEC |
| **Richiesta** | Quello che mandi al server | La tua domanda al cameriere |
| **Risposta** | Quello che il server ti restituisce | La risposta del cameriere |
| **Status Code** | Numero che indica se è andato tutto bene | "OK" o "Errore" |
| **JSON** | Formato per scambiare dati | Foglio con i dati ordinati |

---

## ✅ CONCETTI CHIAVE DA RICORDARE

1. **Un'API è un intermediario** tra la tua app e il server
2. **REST è un insieme di regole** per usare le API
3. **GET legge, POST crea/modifica**
4. **Endpoint = URL specifico** con metodo, percorso, parametri
5. **Ogni richiesta ha una risposta** con stato e dati
6. **JSON è il formato standard** per i dati
7. **Status Code (200, 400, 500) ti dice l'esito**

---

## 📝 NOTE FINALI

Questa lezione copre i **concetti base** necessari per comprendere il progetto BK-Service. 

**Prossime lezioni suggerite:**
- Autenticazione e Firma Digitale
- JWT (JSON Web Tokens)
- ALARM e Polling
- Gestione Errori e Validazione
- Sicurezza e Crittografia

---

**Fine della Lezione**
