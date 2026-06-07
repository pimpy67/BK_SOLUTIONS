# 📚 LEZIONE 2: AUTENTICAZIONE, FIRMA DIGITALE E JWT

**Autore:** Claude Code  
**Data:** Giugno 2026  
**Progetto:** Portale BK-Service - Autorizzazione Licenze Software  
**Livello:** Intermedio

---

## 📑 INDICE

1. [Cos'è l'Autenticazione](#parte-1-cosè-laautenticazione)
2. [Firma Digitale vs Cifratura](#parte-2-firma-digitale-vs-cifratura)
3. [Chiavi Pubbliche e Private](#parte-3-chiavi-pubbliche-e-private)
4. [Cos'è JWT](#parte-4-cosè-jwt-json-web-token)
5. [Come Funziona JWT](#parte-5-come-funziona-jwt)
6. [JWT nel Progetto BK-Service](#parte-6-jwt-nel-progetto-bk-service)
7. [Token Temporanei](#parte-7-token-temporanei-scadenza)
8. [Sicurezza della Firma](#parte-8-sicurezza-della-firma)

---

## PARTE 1: COS'È L'AUTENTICAZIONE?

### Definizione semplice:

**Autenticazione** = "Provare che sei veramente tu"

### Analogia reale:

```
SITUAZIONE: Vuoi ritirare soldi dal bancomat

1. Inserisci la CARTA (identità)
2. Inserisci il PIN (autenticazione)
3. Bancomat verifica: "Sì, sei veramente te"
4. ✅ Puoi ritirare soldi
```

### Nel progetto BK-Service:

```
SITUAZIONE: Libreria Client vuole una licenza

1. Libreria invia: "Sono io, APP_FATTURA_2026"
2. Portale verifica: "Chi mi lo dice?"
3. Libreria mostra: "Ecco il mio token di registrazione"
4. Portale controlla: "Sì, token valido e non scaduto"
5. ✅ Portale concede la licenza
```

### Autenticazione vs Autorizzazione:

```
AUTENTICAZIONE = "Chi sei?" (verifica identità)
AUTORIZZAZIONE = "Cosa puoi fare?" (verifica permessi)

Esempio:
- Autenticazione: "Sei veramente Andrea?" ✓ Sì
- Autorizzazione: "Puoi creare utenti?" ✗ No, sei uno stagista
```

---

## PARTE 2: FIRMA DIGITALE vs CIFRATURA

### Differenze fondamentali:

| Aspetto | Firma Digitale | Cifratura |
|---------|---|---|
| **Scopo** | Provare autenticità | Nascondere il contenuto |
| **Legibilità** | Il messaggio rimane leggibile | Il messaggio diventa illeggibile |
| **Chi verifica** | Chiunque (con chiave pubblica) | Solo chi ha la chiave privata |
| **Caso d'uso** | Certificare che è autentico | Mantenere segreto |

### Analogia: Firma digitale

```
FIRMA SU UN ASSEGNO (analogia reale):

1. Tu scrivi un assegno
2. Lo firmi con la TUA firma
3. La banca vede:
   - L'assegno è leggibile (non segreto)
   - Ma è firmato da TE (è autentico)
   - Se qualcuno lo modifica, la firma non corrisponde più

FIRMA DIGITALE funziona così:
1. Server crea un documento (entitlement)
2. Lo firma con la SUA chiave privata
3. Libreria vede:
   - L'entitlement è leggibile
   - Ma è firmato dal Portale (è autentico)
   - Se qualcuno lo modifica, la firma non corrisponde più
```

### Analogia: Cifratura

```
LETTERA IN UNA CASSAFORTE (analogia reale):

1. Tu scrivi una lettera (leggibile)
2. La metti in una cassaforte (illeggibile senza chiave)
3. Solo chi ha la CHIAVE della cassaforte può leggerla

CIFRATURA funziona così:
1. Dati originali (leggibili)
2. Applicare cifratura (illeggibili senza chiave)
3. Solo chi ha la chiave di decifratura può leggerli
```

### Nel progetto BK-Service:

**Usiamo FIRMA, non CIFRATURA:**

```
Entitlement:
{
  "cliente": "ABC",
  "prodotto": "FATTURA",
  "scadenza": "2026-07-07",
  "firma": "a1b2c3d4e5f6g7h8i9j0"
}

✅ È LEGGIBILE (non è cifrato)
✅ È FIRMATO (è autentico)
✗ Non è segreto (ok, perché la firma lo certifica)
```

---

## PARTE 3: CHIAVI PUBBLICHE E PRIVATE

### Il concetto di coppia di chiavi:

Immagina due cassette postali:
- **Cassetta PUBBLICA** (rossa) = Chiunque può mettere lettere dentro
- **Cassetta PRIVATA** (blu) = Solo tu hai la chiave per aprirla

```
CASSETTE POSTALI (analogia):

Cassetta ROSSA (pubblica)
  ↑ Chiunque inserisce lettere
  |
  | Solo TU hai la chiave blu per aprire
  |
  ↓
Cassetta BLU (privata) con la tua chiave
```

### Nel progetto BK-Service:

**Firma Digitale con coppia di chiavi:**

```
PORTALE BK-SERVICE:
┌─────────────────────────────────────┐
│ Ha DUE chiavi:                      │
│  1. Chiave PRIVATA (segreta)        │
│  2. Chiave PUBBLICA (da condividere)│
└─────────────────────────────────────┘

FLUSSO:

1. PORTALE crea un entitlement
2. PORTALE firma con CHIAVE PRIVATA
   → Genera: "firma_a1b2c3d4..."
3. PORTALE invia a Libreria:
   {
     "entitlement": "{ cliente, prodotto, scadenza }",
     "firma": "a1b2c3d4...",
     "chiave_pubblica": "xyz789..." ← Per verificare
   }

4. LIBRERIA riceve
5. LIBRERIA verifica con CHIAVE PUBBLICA
   → Se la firma è valida: ✅ È autentico
   → Se la firma non corrisponde: ❌ È falso
```

### Come funziona la firma:

```
FIRMA DIGITALE - Step by step:

1. PORTALE ha un messaggio:
   "Cliente ABC, Prodotto FATTURA, Scade 2026-07-07"

2. PORTALE applica una FORMULA MATEMATICA
   + la CHIAVE PRIVATA (segreta)
   = Risultato: "a1b2c3d4e5f6g7h8"
   (questa è la FIRMA)

3. Se QUALCUNO modifica il messaggio in:
   "Cliente ABC, Prodotto FATTURA, Scade 2030-07-07"

4. E applica la stessa formula + chiave privata:
   ≠ "a1b2c3d4e5f6g7h8"
   (la firma NON corrisponde!)

5. La LIBRERIA lo sa subito: "È FALSIFICATO!"
```

---

## PARTE 4: COS'È JWT (JSON Web Token)?

### Definizione:

**JWT** (JSON Web Token) è un **modo standardizzato** di creare e verificare token firmati.

È un **formato** per organizzare:
- Dati
- Firma
- Metadati

### Struttura JWT:

```
JWT = parte1.parte2.parte3

Esempio reale:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

Scomposizione:
┌─ HEADER ──────────────────────┐
│ eyJhbGciOiJIUzI1NiIsInR5cCI6Ikp... │ Metadati
├─ PAYLOAD ────────────────────┤
│ eyJzdWIiOiIxMjM0NTY3ODkwIiwibmF... │ I dati
├─ FIRMA ──────────────────────┤
│ SflKxwRJSMeKKF2QT4fwpMeJf36POk6... │ La firma
└────────────────────────────────┘
```

### Decodifica JWT:

**Header (decodificato):**
```json
{
  "alg": "HS256",        ← Algoritmo di firma
  "typ": "JWT"           ← Tipo token
}
```

**Payload (decodificato):**
```json
{
  "sub": "1234567890",   ← Subject (chi è)
  "name": "John Doe",    ← Nome
  "iat": 1516239022      ← Emesso a (timestamp)
}
```

**Firma:**
```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret
)
```

---

## PARTE 5: COME FUNZIONA JWT

### Step-by-step nel tuo progetto:

```
STEP 1: LIBRERIA CHIEDE REGISTRAZIONE
POST /api/v1/client/register
Body: { paese, p_iva, product_key, fingerprint }

↓

STEP 2: PORTALE CREA JWT (registration_token)
Payload:
{
  "cliente_id": 123,
  "product_key": "FATTURA-2026",
  "iat": 1717754400,              ← Ora di emissione
  "exp": 1717754500               ← Scadenza (100 secondi dopo)
}

Firma: HMACSHA256(payload, chiave_privata)
       = a1b2c3d4e5f6g7h8i9j0...

JWT Completo:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjbGllbnRlX2lkIjoxMjMsInByb2R1dHRvX2tleSI6IkZBVFRVUkEtMjAyNiIsImlhdCI6MTcxNzc1NDQwMCwiZXhwIjoxNzE3NzU0NTAwfQ.a1b2c3d4e5f6g7h8i9j0

↓

STEP 3: PORTALE INVIA JWT ALLA LIBRERIA
{
  "esito": "OK",
  "registration_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

↓

STEP 4: LIBRERIA SALVA IL TOKEN
(in memoria, non lo decodifica, non lo verifica - fiducia cieca)

↓

STEP 5: LIBRERIA USA IL TOKEN
POST /api/v1/client/license/issue
Body: { registration_token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." }

↓

STEP 6: PORTALE VERIFICA IL TOKEN
1. Decodifica il payload
2. Legge: "cliente_id": 123, "exp": 1717754500
3. Controlla: scadenza è passata? NO ✓
4. Verifica firma con chiave privata: Valida? SÌ ✓
5. ✅ Token è autentico e non scaduto!

↓

STEP 7: PORTALE CREA ENTITLEMENT FIRMATO
(stesso meccanismo, ma per la licenza)
```

---

## PARTE 6: JWT NEL PROGETTO BK-SERVICE

### Token utilizzati nel progetto:

#### 1️⃣ **Registration Token** (breve durata)

```json
POST /api/v1/client/register
↓
JWT {
  "cliente_id": 123,
  "product_key": "FATTURA-2026",
  "iat": 1717754400,
  "exp": 1717754500              ← Scade dopo 100 secondi
}
Uso: Valido solo per richiedere la licenza (issue)
```

#### 2️⃣ **Entitlement** (lungo termine)

```json
POST /api/v1/client/license/issue
↓
JWT {
  "cliente_id": 123,
  "product_key": "FATTURA-2026",
  "status": "TRIAL",
  "moduli": ["FATTURAZIONE", "SPESOMETRO"],
  "max_dispositivi": 3,
  "data_scadenza": "2026-07-07",
  "iat": 1717754400,
  "exp": 1688601600              ← Scade il 2026-07-07 00:00
}
Uso: Valido per tutta la durata della licenza
     Salvato in cache sul dispositivo
```

### Confronto dei token:

| Token | Durata | Uso | Dove |
|-------|--------|-----|------|
| **Registration Token** | 100 secondi | Richiedere licenza | Memoria |
| **Entitlement (Trial)** | 30 giorni | Sbloccare app | Cache |
| **Entitlement (Active)** | 1 anno | Sbloccare app | Cache |
| **Offline Cache** | 7 giorni | Offline | Storage |

---

## PARTE 7: TOKEN TEMPORANEI E SCADENZA

### Concetto: Scadenza (Expiration)

```
ANALOGIA: BIGLIETTO DEL CINEMA

Biglietto:
┌──────────────────┐
│ Film: Titanic    │
│ Data: 07-06-2026 │
│ Ora: 20:30       │
│ Scade: 21:00     │
└──────────────────┘

Se arrivi alle 21:15: ❌ Scaduto, non puoi entrare
Se arrivi alle 20:45: ✅ Valido, puoi entrare

TOKEN È UGUALE:
{
  "cliente_id": 123,
  "exp": 1717754500    ← Scade a quest'ora
}

Se lo usi dopo quell'ora: ❌ Scaduto, token invalido
Se lo usi prima: ✅ Valido, puoi usarlo
```

### Nel progetto BK-Service:

```
Registration Token:
- Emesso: 2026-06-07 10:00:00
- Scade: 2026-06-07 10:01:40 (100 secondi)
- Motivo: Vuoi costringere la libreria a usarlo subito

Entitlement Trial:
- Emesso: 2026-06-07 10:00:00
- Scade: 2026-07-07 00:00:00 (30 giorni)
- Motivo: La trial dura 30 giorni

Entitlement Active:
- Emesso: 2026-06-07 10:00:00
- Scade: 2027-06-07 00:00:00 (1 anno)
- Motivo: La licenza annuale dura 1 anno
```

### Verificare scadenza:

```
CODICE PSEUDOCODE:

funzione verifica_token(token):
    payload = decodifica(token)
    ora_attuale = get_time_now()
    
    if ora_attuale > payload.exp:
        return "❌ SCADUTO"
    else:
        return "✅ VALIDO"

Esempio:
token.exp = 1717754500 (07-06-2026 10:01:40)
ora_attuale = 1717754600 (07-06-2026 10:03:20)

1717754600 > 1717754500? SÌ
→ "❌ SCADUTO"
```

---

## PARTE 8: SICUREZZA DELLA FIRMA

### Cosa protegge la firma?

```
SCENARIO: Attacco Man-in-the-Middle

┌────────────────┐         ┌──────────────┐
│  LIBRERIA      │ ────→   │  ATTACCANTE  │ ────→  │ PORTALE │
└────────────────┘         └──────────────┘        └─────────┘

Attaccante INTERCETTA la risposta:
{
  "entitlement": "{ cliente: ABC, status: TRIAL, ... }",
  "firma": "a1b2c3d4e5f6g7h8i9j0"
}

Attaccante MODIFICA:
{
  "entitlement": "{ cliente: ABC, status: ACTIVE, ... }", ← Cambiato!
  "firma": "a1b2c3d4e5f6g7h8i9j0"  ← Stesso (per ora)
}

Libreria RICEVE e VERIFICA:
1. Decodifica: "status: ACTIVE"
2. Verifica firma con CHIAVE PUBBLICA del Portale
3. La firma NON corrisponde!
4. ❌ RIFIUTA il token: "È FALSIFICATO!"
```

### Cosa NON protegge la firma?

```
La firma PROTEGGE da:
✅ Modifiche al contenuto
✅ Falsificazione del token
✅ Usurpazione di identità

Ma NON protegge da:
❌ Intercettazione (leggi la lezione su HTTPS)
❌ Furto del token (leggi la lezione su sicurezza)
❌ Replay attack (token usato più volte)

Per QUESTI rischi, usiamo:
- HTTPS (crittografia della trasmissione)
- Scadenza (exp)
- Token refresh (ring renewal)
```

### Come la firma funziona in dettaglio:

```
FIRMA DIGITALE - Processo matematico:

Payload originale:
{
  "cliente_id": 123,
  "status": "TRIAL"
}

Codifica base64url:
eyJjbGllbnRlX2lkIjogMTIzLCAic3RhdHVzIjogIlRSSUFMIn0

Applica formula matematica + chiave privata:
HMACSHA256(
  "eyJjbGllbnRlX2lkIjogMTIzLCAic3RhdHVzIjogIlRSSUFMIn0",
  "chiave_privata_segreta"
) = a1b2c3d4e5f6g7h8i9j0k1l2m3n4

Se qualcuno cambia il payload in:
{
  "cliente_id": 123,
  "status": "ACTIVE"   ← MODIFICATO
}

E applica la STESSA formula + STESSA chiave:
eyJjbGllbnRlX2lkIjogMTIzLCAic3RhdHVzIjogIkFDVElWRSJ9
HMACSHA256(
  "eyJjbGllbnRlX2lkIjogMTIzLCAic3RhdHVzIjogIkFDVElWRSJ9",
  "chiave_privata_segreta"
) = p9q8r7s6t5u4v3w2x1y0z9a8b7

p9q8r7s6t5u4v3w2x1y0z9a8b7 ≠ a1b2c3d4e5f6g7h8i9j0k1l2m3n4
→ La firma NON corrisponde!
→ Token RIFIUTATO
```

---

## RIASSUNTO FINALE

| Concetto | Cos'è | Esempio |
|----------|-------|---------|
| **Autenticazione** | Provare che sei veramente tu | Token di registrazione |
| **Firma Digitale** | Certificare autenticità | Firma su entitlement |
| **Chiave Privata** | Segreta, per firmare | Solo Portale ha |
| **Chiave Pubblica** | Da condividere, per verificare | Incorporata in Libreria |
| **JWT** | Formato standard per token | registration_token, entitlement |
| **Payload** | I dati dentro il token | cliente_id, status, exp |
| **Firma (JWT)** | Hash del payload + chiave privata | a1b2c3d4e5f6g7h8... |
| **Scadenza (exp)** | Quando il token non è più valido | "exp": 1717754500 |

---

## ✅ CONCETTI CHIAVE DA RICORDARE

1. **Autenticazione = "Chi sei?"** - Verifica identità
2. **Firma ≠ Cifratura** - La firma certifica, la cifratura nasconde
3. **JWT = Formato standard** - Header.Payload.Firma
4. **Chiavi coppia** - Privata (Portale) + Pubblica (Libreria)
5. **Scadenza (exp)** - Token non sono eterni
6. **La firma protegge dal furto e dalla modifica** - Ma non dall'intercettazione

---

**Fine della Lezione**
