# CLAUDE.md — Contesto Progetto BK Shield

Questo file serve a contestualizzare Claude Code nelle sessioni future.
Aggiornato: 8 giugno 2026.

> **Nome del servizio: BK Shield** — sistema di licensing B2B sviluppato da BK Solutions.

---

## Glossario dei ruoli — IMPORTANTE

Il termine "Fornitore" nei documenti originali (riunione, BPMN) è ambiguo. Usare sempre questa tabella:

| Termine | Chi è | Nel sistema |
|---------|-------|-------------|
| **BK Solutions** | Chi sviluppa e vende il servizio di licensing | Operatore del Portale |
| **Software House** | Azienda che **acquista** la licenza da BK e integra la libreria nel suo server | `dbo.Clienti` nel DB |
| **ERP BK** | Gestionale interno di BK Solutions (es. Business Central) | Sistema che genera gli eventi ALARM |
| **Utente finale** | Chi usa l'applicazione della Software House | **Fuori dal nostro sistema** |

> Nei BPMN la lane "ERP/Fornitore" = **ERP interno di BK Solutions**, non un sistema della Software House.
> Il Portale fa polling ALARM verso BK stesso, non verso la Software House.

---

## Cos'è questo progetto

**BK Shield** è un sistema di gestione licenze software B2B sviluppato da BK Solutions.
Permette alle **Software House** clienti di BK di proteggere le loro applicazioni tramite
una libreria client che si registra e valida le licenze presso un server centrale (il Portale).

### Modello di business
- BK Solutions vende licenze enterprise alle **Software House**
- La Software House integra la **Libreria Client** nel suo server applicativo
- La libreria si auto-registra al primo avvio del server e valida periodicamente la licenza
- Quando la Software House paga BK, l'**ERP interno di BK** registra il pagamento
- Il Portale fa polling verso l'**ERP di BK** (non della Software House) per attivare le licenze
- Gli utenti finali dell'applicazione della Software House sono **fuori dal nostro sistema**

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
[Libreria Client]  ←→  [Portale BK-Service]  ←→  [ERP interno BK]
  (nel server della      (backend centrale)         (gestionale BK,
   Software House)                                   es. Business Central)
```

- **Libreria Client**: integrata nel server della Software House. Si registra, ottiene l'entitlement firmato, lo salva in cache, invia heartbeat periodici.
- **Portale BK-Service**: server centrale di BK Solutions. Espone API REST. **Non blocca mai le app attivamente** — emette entitlement firmati. L'unica chiamata in uscita è il polling ALARM verso l'ERP interno BK (non verso la Software House).
- **ERP interno BK**: gestionale di BK Solutions (es. Business Central). Quando una Software House paga, l'ERP mette l'evento in coda. Il Portale fa polling (GET /alarm) per raccoglierlo e aggiornare la licenza.

### Principio architetturale fondamentale

> Il Portale **non blocca** le app: emette un **entitlement firmato** (JWT RS256) che dichiara i diritti (moduli, scadenza, max istanze). La libreria verifica la firma con la **chiave pubblica embedded** e applica le regole localmente. Se la licenza è scaduta o un modulo non è incluso, è **la libreria** a non sbloccare — il Portale non interviene in real-time.
>
> L'unica chiamata in uscita del Portale è il polling ALARM verso l'**ERP interno di BK Solutions** per raccogliere eventi come `PAGAMENTO_CONFERMATO` o `SOSPENDI_LICENZA`.

### Fase 1 — Trial (nessun contratto)

```
Software House (nessun contratto, nessuna INSTALL_KEY)
   │
   └─► POST /client/register { P.IVA, product_key, ragione_sociale, email, paese }
            │
            ▼
       Portale: valida P.IVA + product_key
                verifica nessuna trial attiva per quella P.IVA
            │
            ▼
       Crea licenza TRIAL (30 gg, moduli trial configurati da BK)
       Firma entitlement JWT RS256
       Genera license_key univoca
            │
            ▼
       201 → { license_key, entitlement_jwt, expires_at, modules[] }
            │
            ▼
       Libreria salva entitlement in cache locale
       Verifica firma con chiave pubblica embedded → sblocca moduli trial
```

- Nessun OTP, nessun fingerprint, nessuna INSTALL_KEY
- Identificativo univoco: `P.IVA + paese` (supporto clienti esteri)
- Una sola trial per azienda per prodotto (409 se già usata)
- Nessun polling ALARM nella fase trial — attivazione immediata diretta

### Fase 2 — Licenza post-acquisto (contratto firmato)

```
BK Solutions genera INSTALL_KEY → consegnata alla Software House
Software House inserisce INSTALL_KEY nel config del server
   │
   └─► POST /client/register { P.IVA, product_key, install_key, fingerprint }
            │
            ├─► Prima istanza (nuova) → OTP email → /register/verify → entitlement ACTIVE
            └─► Istanze successive (fingerprint già noto) → entitlement ACTIVE immediato

In parallelo:
   Software House paga BK
   ERP interno BK mette PAGAMENTO_CONFERMATO in coda
   Portale fa polling ALARM → riceve evento → aggiorna licenza TRIAL → ACTIVE
   Al prossimo heartbeat → Libreria riceve entitlement aggiornato e sblocca moduli completi
```

- Fingerprint = `hash(INSTALL_KEY + hostname)` — identifica ogni istanza server
- OTP email solo alla prima registrazione di ogni nuova istanza
- `max_istanze` definito contrattualmente (es. 1 prod + 1 staging)
- Anti-frode: blocco automatico + alert email se `max_istanze` superato

### Stati licenza

```
TRIAL → ACTIVE (dopo pagamento Software House a BK, confermato via ALARM dall'ERP interno BK)
ACTIVE → SUSPENDED (mancato pagamento / comando da ERP BK)
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
| `Clienti` | Anagrafica Software House (P.IVA, SDI, PEC) — NON utenti finali |
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
| Fingerprint | Solo nel **post-acquisto**: `hash(INSTALL_KEY + hostname)` per contare istanze. Nella **trial non serve** — la P.IVA è sufficiente (una trial per azienda) |
| ALARM | Polling GET verso **ERP interno BK** (non verso la Software House), unica chiamata in uscita del Portale |
| Offline | Cache entitlement firmato sul server della Software House |
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

## Stato avanzamento BK Shield (8 giugno 2026)

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
