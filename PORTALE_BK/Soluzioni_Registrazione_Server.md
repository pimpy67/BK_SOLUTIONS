# Certificazione Server — 4 Soluzioni a Confronto

**Progetto:** BK Invoice Service  
**Data:** 8 giugno 2026  
**Argomento:** Come certifichiamo il server del Fornitore alla registrazione?

---

## Contesto

Quando il server del Fornitore si presenta al Portale BK per registrarsi,
dobbiamo verificare che sia **effettivamente autorizzato**. Tre rischi da coprire:

- Server legittimo del Fornitore ✅
- Server di qualcuno che ha rubato le credenziali ❌
- Server aggiuntivo oltre il limite di istanze acquistate ❌

---

## Soluzione 1 — Email + Codice OTP

**Flusso:**
```
Server → POST /register { p_iva, product_key, fingerprint }
       ← 202 Accepted + pending_token
       → Email con codice OTP (6 cifre, scade in 15 min)
Server → POST /register/verify { pending_token, otp }
       ← 200 OK + registration_token
```

**Vantaggi**
- Verifica umana garantita ad ogni registrazione
- Nessun segreto da consegnare in anticipo
- Standard riconosciuto (usato da molti SaaS)

**Svantaggi**
- Richiede intervento dell'amministratore ad ogni prima attivazione
- Blocca deploy automatici e CI/CD
- Dipende dalla disponibilità del servizio email

**Adatta per:** Fornitori piccoli, senza infrastrutture automatizzate.

---

## Soluzione 2 — INSTALL_KEY pre-condivisa

**Flusso:**
```
[Alla firma del contratto]
BK genera INSTALL_KEY univoca → consegnata al Fornitore via email sicura
Fornitore la inserisce nel config del server: INSTALL_KEY=BK-xxxx-yyyy

[Ad ogni avvio del server]
Server → POST /register { p_iva, product_key, fingerprint, install_key }
       ← 200 OK + registration_token  (nessuna interazione umana)
```

**Vantaggi**
- Completamente automatico, supporta CI/CD
- Nessun intervento umano necessario
- Standard enterprise (simile alle API key)

**Svantaggi**
- Se la chiave viene rubata o condivisa, chiunque può usarla
- Nessuna verifica che il server appartenga davvero al Fornitore
- Richiede processo sicuro di consegna iniziale della chiave

**Adatta per:** Fornitori con infrastrutture automatizzate, deploy frequenti.

---

## Soluzione 3 — INSTALL_KEY + OTP solo alla prima registrazione ⭐ Consigliata

**Flusso:**
```
[Alla firma del contratto]
BK genera INSTALL_KEY → consegnata al Fornitore

[Prima registrazione di ogni nuova istanza server]
Server → POST /register { p_iva, product_key, fingerprint, install_key }
       ← 202 Accepted + pending_token
       → Email OTP al Fornitore (verifica una tantum)
Server → POST /register/verify { pending_token, otp }
       ← 200 OK + registration_token

[Avvii successivi dello stesso server — fingerprint già nel DB]
Server → POST /register { p_iva, product_key, fingerprint, install_key }
       ← 200 OK + registration_token  (immediato, nessun OTP)
```

**Vantaggi**
- Verifica umana solo una volta per ogni nuova istanza
- Deploy automatici dopo la prima attivazione
- Doppio controllo: INSTALL_KEY + conferma via email
- Bilanciamento ottimale sicurezza / automazione

**Svantaggi**
- Leggermente più complessa da implementare
- Richiede comunque gestione sicura della INSTALL_KEY

**Adatta per:** La maggior parte dei casi enterprise — **soluzione raccomandata**.

---

## Soluzione 4 — Link email (variante della Soluzione 1)

**Flusso:**
```
Server → POST /register { p_iva, product_key, fingerprint }
       ← 202 Accepted + pending_token
       → Email con link: https://portale.bk/activate?token=eyJ...
Admin  → Clicca il link nel browser
       ← Pagina di conferma
Server → polling GET /register/status?pending_token=...
       ← 200 OK + registration_token (quando il link è stato cliccato)
```

**Vantaggi**
- Più semplice per l'amministratore (un clic, nessun codice da trascrivere)
- Link con scadenza automatica (es. 15 minuti)
- Nessun rischio di errore di trascrizione

**Svantaggi**
- Richiede che l'admin abbia accesso a un browser
- Non funziona in ambienti headless o isolati da internet
- Il server deve fare polling per sapere quando il link è stato cliccato

**Adatta per:** Fornitori con admin non tecnici che preferiscono un'interfaccia web.

---

## Tabella comparativa

| Criterio | Sol. 1 OTP | Sol. 2 INSTALL_KEY | Sol. 3 Combinata ⭐ | Sol. 4 Link |
|----------|:----------:|:------------------:|:------------------:|:-----------:|
| Verifica umana | ✅ Sempre | ❌ Mai | ✅ Prima volta | ✅ Sempre |
| Deploy automatico | ❌ | ✅ | ✅ Dopo prima volta | ❌ |
| Sicurezza | Alta | Media | Alta | Alta |
| Semplicità admin | Media | Alta | Media | Alta |
| Supporto CI/CD | ❌ | ✅ | ✅ | ❌ |
| Dipendenza email | ✅ | ❌ | ✅ Prima volta | ✅ |

---

## Schema decisionale

```
Nuovo Fornitore — prima registrazione
  └─► Soluzione 3: INSTALL_KEY + OTP email (una tantum)

Stesso Fornitore — nuova istanza server
  └─► Soluzione 3: INSTALL_KEY + OTP email (una tantum per istanza)

Stesso Fornitore — riavvio server già registrato
  └─► Automatico: fingerprint già nel DB, nessun OTP

Fornitore supera max_istanze
  └─► Blocco automatico + email alert al Fornitore
```

---

## Domande per Alvise

1. Il Fornitore usa CI/CD e deploy automatici? → Se sì, la Soluzione 2 o 3 è obbligatoria
2. Preferiamo OTP numerico (Soluzioni 1 e 3) o link email (Soluzione 4)?
3. La INSTALL_KEY viene generata manualmente da un operatore BK o automaticamente alla firma del contratto?
4. In caso di istanza non autorizzata, blocchiamo subito o mandiamo prima un alert al Fornitore?
