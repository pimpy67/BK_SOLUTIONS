# CLAUDE.md — Contesto Progetto BK Invoice Service

Questo file serve a contestualizzare Claude Code nelle sessioni future.
Aggiornato: 8 giugno 2026.

---

## Cos'è questo progetto

**BK Invoice Service** è un sistema di gestione licenze software B2B sviluppato da BK Solutions.
Permette ai Fornitori (software house clienti di BK) di proteggere le loro applicazioni tramite
una libreria client che si registra e valida le licenze presso un server centrale (il Portale).

### Modello di business
- BK Solutions vende licenze enterprise ai **Fornitori** (software house)
- Il Fornitore integra la **Libreria Client** nel suo server applicativo
- La libreria si auto-registra al primo avvio del server e valida periodicamente la licenza
- Gli utenti finali dell'applicazione del Fornitore sono **fuori dal nostro sistema**

---

## Team

- **Alvise** — responsabile tecnico, definisce architettura e requisiti
- **Luca (Speaker 4)** — revisore, ha richiesto workflow chiari
- **Pavanandrea (Speaker 2)** — sviluppatore (utente di questo repo)
- **Speaker 3** — sviluppatore
- **Cristina (Speaker 5)** — coinvolta nella progettazione DB

---

## Struttura del repository

```
BK_ANALISI/
├── CLAUDE.md                          ← questo file
├── PORTALE_BK/
│   ├── Riepilogo servizio fatturazione.md   ← verbale riunione 4 giugno 2026
│   ├── Checkpoint_Alvise.md                 ← domande aperte per Alvise
│   ├── bk_invoice_service_schema.sql        ← schema DB completo (SQL Server)
│   ├── Workflow_A_Primo_Avvio_Trial.bpmn
│   ├── Workflow_B_Acquisto_Attivazione.bpmn
│   ├── Workflow_C_Rinnovo.bpmn
│   ├── Workflow_D_Offline.bpmn
│   ├── Workflow_E_AntiFrode.bpmn
│   ├── BPMN/                               ← immagini PNG dei workflow
│   └── DOCUMENTAZIONE/
│       ├── 01_Lezione_API_REST_GET_POST.md
│       ├── 02_Lezione_Autenticazione_JWT.md
│       ├── 03_Lezione_ALARM_Polling.md
│       └── 04_Lezione_Database_Tabelle.md
└── SINOTTICO_PRODUZIONE/
    └── sinottico_produzione_analisi.docx/.pdf
```

---

## Architettura del sistema

### Tre componenti principali

```
[Libreria Client]  ←→  [Portale BK-Service]  ←→  [ERP Fornitore]
  (nel server           (backend centrale)         (gestionale vendite)
   del Fornitore)
```

- **Libreria Client**: integrata nel server del Fornitore. Si registra, ottiene l'entitlement firmato, lo salva in cache, invia heartbeat periodici.
- **Portale BK-Service**: server centrale BK. Espone API REST. Unica chiamata in uscita: il polling ALARM verso l'ERP.
- **ERP Fornitore**: gestionale del Fornitore. Registra pagamenti e li mette in coda. Il Portale fa polling (GET /alarm) per raccoglierli.

### Flusso di registrazione (Workflow A)

1. Fornitore installa server applicativo con INSTALL_KEY nel config
2. Libreria genera fingerprint = `hash(INSTALL_KEY + hostname)`
3. `POST /client/register` → Portale valida P.IVA e product_key, crea cliente e genera `registration_token` (JWT, ~100 sec)
4. `POST /client/license/issue` → Portale crea licenza TRIAL, registra istanza server, firma entitlement (JWT RS256)
5. Libreria salva entitlement in cache e sblocca le funzioni trial

### Stati licenza

```
TRIAL → ACTIVE (dopo pagamento confermato via ALARM)
ACTIVE → SUSPENDED (mancato pagamento / comando fornitore)
ACTIVE → EXPIRED (scadenza non rinnovata)
* → ACTIVE (rinnovo via Workflow C)
```

### Tipi licenza

| Tipo | Descrizione |
|------|-------------|
| `TRIAL` | 30 giorni, moduli configurabili da catalogo |
| `SUBSCRIPTION` | Licenza standard annuale |
| `SUBSCRIPTION` provvisoria | Stessi moduli standard, durata ~30 giorni, in attesa di pagamento rinnovo |

---

## Schema Database (SQL Server)

File: `PORTALE_BK/bk_invoice_service_schema.sql`

| Tabella | Scopo |
|---------|-------|
| `Prodotti` | Catalogo app con chiave univoca |
| `Moduli` | Funzionalità attivabili per prodotto |
| `Clienti` | Anagrafica Fornitori (P.IVA, SDI, PEC) — NON utenti finali |
| `Licenze` | Una riga per coppia cliente+prodotto |
| `Licenze_Moduli` | N:M — moduli attivi per licenza |
| `Dispositivi` | Istanze server autorizzate (heartbeat) |
| `Notifiche` | Log avvisi scadenza (SCAD_7GG, SCAD_3GG, SCAD_1GG, SCADUTA) |
| `Pagamenti` | Storico pagamenti, idempotenza via `rif_erp` |

Convenzioni schema:
- Chiavi primarie `BIGINT IDENTITY`
- `NVARCHAR` ovunque (supporto clienti esteri)
- Date in `DATETIME2` UTC (`SYSUTCDATETIME()`)
- `updated_at` gestito da trigger su tutte le tabelle principali
- Indice `IX_Licenze_status_scadenza` per il cron job notturno

---

## Decisioni tecniche prese

| Argomento | Decisione |
|-----------|-----------|
| Backend | Node.js o Python — **ancora da decidere con Alvise** |
| Frontend | Ionic — **posticipato** |
| DB | Microsoft SQL Server (T-SQL) |
| Autenticazione | JWT tra sistemi (no login utente finale) |
| Firma entitlement | RS256 (RSA asimmetrico) — client verifica offline con chiave pubblica embedded |
| Fingerprint | `hash(INSTALL_KEY + hostname)` — no hardware fingerprint (instabile su VM/Docker) |
| ALARM | Polling GET verso ERP, unica chiamata in uscita del Portale |
| Offline | Cache entitlement firmato sul server del Fornitore |
| Multilingua | Richiesta da subito, IT + EN — approccio DB da definire |
| C# | **Escluso** da Alvise |

---

## Workflow BPMN

| File | Descrizione |
|------|-------------|
| Workflow A | Primo avvio / registrazione trial |
| Workflow B | Acquisto e attivazione (via ALARM + PAGAMENTO_CONFERMATO) |
| Workflow C | Rinnovo licenza |
| Workflow D | Modalità offline (firma locale con chiave pubblica embedded) |
| Workflow E | Anti-frode (limite istanze + rilevamento session_id duplicati) |

---

## Domande aperte — vedere Checkpoint_Alvise.md

Le domande da portare ad Alvise sono documentate in `PORTALE_BK/Checkpoint_Alvise.md`.
Le principali:

1. Servizio esterno per validazione P.IVA (Agenzia Entrate? VeriFactura? Costo?)
2. Trigger creazione licenza provvisoria (automatico a scadenza o manuale?)
3. Come il Fornitore configura il trigger di attivazione (GUI? DB? File?)
4. Approccio multilingua nel DB (tabelle dedicate o tabella generica `Traduzioni`?)
5. Stack tecnologico definitivo (Node.js/Python + framework + ORM)
6. Cosa succede se il cliente non paga durante la licenza provvisoria
7. Validazione offline: solo firmata (RS256) o anche cifrata (AES)? — **c'è contraddizione tra riepilogo riunione e Workflow D**
8. Perimetro MVP Fase 1
9. INSTALL_KEY: generata manualmente o automaticamente alla firma contratto?
10. max_istanze: come definito contrattualmente?
11. Durata cache offline per Fornitori in intranet isolata

---

## Stato avanzamento (8 giugno 2026)

- [x] Analisi requisiti (riunione 4 giugno)
- [x] Schema DB
- [x] Workflow BPMN (A-E)
- [x] Documentazione tecnica (4 lezioni)
- [x] Documento domande aperte per Alvise
- [ ] Risposta alle domande aperte da parte di Alvise
- [ ] Scelta stack tecnologico
- [ ] Scaffolding progetto backend
- [ ] Implementazione Workflow A (register + issue)
- [ ] Implementazione ALARM
- [ ] Implementazione heartbeat + anti-frode
- [ ] Frontend Ionic (posticipato)
