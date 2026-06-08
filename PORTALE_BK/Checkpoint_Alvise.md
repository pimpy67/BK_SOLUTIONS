# Checkpoint Alvise — Domande Aperte BK Invoice Service

**Data:** 8 giugno 2026  
**Team:** Pavanandrea, Speaker 3  
**Riferimento:** Riunione del 4 giugno 2026

---

## Decisioni già prese (recap)

Prima delle domande, riepiloghiamo ciò che è già stato definito nella riunione del 4 giugno:

| Argomento | Decisione |
|-----------|-----------|
| Iscrizione client | Automatica via `POST /client/register` con P.IVA, chiave prodotto, fingerprint |
| Autenticazione | Tra sistemi (no login utente finale) |
| Licenza Trial | 30 giorni, moduli configurabili da catalogo |
| Licenza Provvisoria | Stessi moduli della licenza standard, durata ~30 giorni, in attesa di pagamento |
| Licenza Standard | Basata su "contratto" (cliente + prodotto + moduli + durata + utenti) |
| DB principale | Tabelle: Clienti, Prodotti, Moduli, Licenze, Dispositivi, Pagamenti, Notifiche |
| Multilingua | Richiesta fin dall'inizio, italiano + inglese |
| Backend | Escluso C#, scelta tra Node.js e Python |
| Frontend | Ionic — sviluppo posticipato |
| ALARM | Unica chiamata in uscita del Portale verso l'ERP, polling configurabile |
| Focus MVP | Backend first — API per catalogo, clienti, contratti |

---

## Domande Aperte

### 1. Validazione P.IVA — Servizio esterno

**Contesto:** Alla registrazione del client, il Portale deve verificare che la P.IVA sia valida e non già registrata. Hai accennato all'integrazione di un servizio esterno.

**Domande:**
- Quale servizio usi? (Agenzia delle Entrate, VeriFactura, altro?)
- Serve validazione anche per clienti esteri (codice fiscale straniero)?
- Ci sono costi da considerare? Chi li sostiene?

---

### 2. Licenza Provvisoria — Creazione e trigger

**Contesto:** Hai definito la licenza provvisoria come *"la stessa licenza con gli stessi moduli, però non annuale e provvisoriamente di un mese, perché attendo che tu mi paghi"*.

**Domande:**
- Quando viene creata esattamente? In automatico alla scadenza della licenza standard, o manualmente dal fornitore?
- Il passaggio da provvisoria a standard avviene solo tramite ALARM (`PAGAMENTO_CONFERMATO`) o anche con altri trigger?
- Nel DB la salviamo come `tipo_licenza = SUBSCRIPTION` con `data_scadenza = +30 giorni`? Oppure hai una nomenclatura diversa?

---

### 3. Trigger di Attivazione — Configurazione lato fornitore

**Contesto:** Hai detto che l'attivazione della licenza può scattare su eventi configurabili dal fornitore, come l'emissione della fattura o il ricevimento del pagamento.

**Domande:**
- Come configura il fornitore quale evento attiva la licenza? Tramite GUI, tabella nel DB, file di configurazione?
- Chi gestisce questa configurazione inizialmente? Noi (Portale) o il fornitore direttamente?
- Può cambiare nel tempo o è fissa per contratto?

---

### 4. Multilingua nel DB — Approccio tecnico

**Contesto:** Hai richiesto il supporto multilingua fin dall'inizio (italiano + inglese) per nomi di prodotti, moduli e notifiche.

**Domande:**
- Preferisci tabelle dedicate per ogni entità (es. `ProdottiTraduzione`, `ModuliTraduzione`) o una tabella generica `Traduzioni` con chiave polimorfica?
- I testi delle email e messaggi in-app devono essere anch'essi multilingua?
- Lingua di default del sistema: italiano o inglese?

---

### 5. Stack Tecnologico — Decisione finale

**Contesto:** Hai lasciato a noi la scelta tra Node.js e Python, escludendo C#.

**Domande:**
- Hai una preferenza tra questi framework?
  - Node.js: **Express** o **Fastify**
  - Python: **FastAPI** o **Django REST Framework**
- Per l'ORM/query builder:
  - Node.js: **Prisma** o **Knex**
  - Python: **SQLAlchemy** o **Tortoise ORM**
- Il Portale girerà su un server BK esistente o su cloud (Azure, AWS)?

---

### 6. Licenza Provvisoria — Mancato pagamento

**Contesto:** Non abbiamo discusso cosa succede se il cliente usa la licenza provvisoria ma poi non paga entro i 30 giorni.

**Domande:**
- Alla scadenza, la licenza passa automaticamente a `SUSPENDED` o `EXPIRED`?
- Il cliente perde l'accesso immediatamente o c'è un periodo di grazia?
- Il fornitore riceve una notifica automatica prima della scadenza?
- I dati del cliente vengono conservati per un eventuale rientro?

---

### 7. Validazione Offline — Firma o Cifratura? ⚠️

**Contesto:** C'è una **discrepanza** tra due documenti:
- Nel riepilogo della riunione si parla di *"stringa crittografata"* salvata localmente
- Nel Workflow D (BPMN) si usa *"valida firma con chiave pubblica embedded"*

Sono due approcci diversi:

| Approccio | Come funziona | Pro | Contro |
|-----------|--------------|-----|--------|
| **Solo firma** (JWT) | Entitlement firmato con chiave privata server, verificato con chiave pubblica embedded nel client | Semplice, standard | Contenuto leggibile da chiunque |
| **Firma + Cifratura** (JWT + AES) | Entitlement firmato E cifrato | Contenuto non leggibile | Più complesso, serve gestione chiave AES |

**Domande:**
- L'entitlement offline deve essere solo **firmato** (verificabile ma leggibile) o anche **cifrato** (non leggibile senza chiave)?
- Se cifrato: la chiave AES è fissa per prodotto, per cliente, o per dispositivo? Dove la conserviamo?
- Per quanto tempo un client può restare offline prima di essere bloccato?

---

### 8. MVP Fase 1 — Perimetro

**Contesto:** Hai indicato di concentrarsi sul backend, posticipando il frontend. Vogliamo allinearci su cosa includere nella prima consegna.

**Proposta team (da validare):**

**DENTRO l'MVP:**
- Schema DB completo (già pronto)
- `POST /client/register` + `POST /client/license/issue` (Workflow A)
- `GET /client/license/status` + `POST /client/heartbeat`
- Sistema ALARM base (polling + elaborazione `PAGAMENTO_CONFERMATO`)
- Email di notifica (template base)

**FUORI dall'MVP:**
- Frontend Ionic
- Workflow D (offline) — richiede libreria client
- Anti-frode avanzato (Workflow E)
- Multilingua completa
- Endpoint fornitore completi

**Domande:**
- Confermi questo perimetro?
- C'è qualcosa che vuoi spostare dentro o fuori?
- Hai una data di riferimento per la prima demo?

---

---

## 9. Modello Enterprise — Libreria installata sul server del Fornitore

**Contesto:** Hai confermato che la licenza è di tipo enterprise e che la libreria viene installata sul **server del Fornitore** (la software house che integra BK nel suo prodotto), non sul dispositivo dell'utente finale. Questo cambia alcune assunzioni del progetto.

**Impatti già analizzati dal team:**

| Componente | Prima (assunto) | Ora (corretto) |
|-----------|----------------|----------------|
| Fingerprint | Hardware PC/telefono (CPU, MAC) | Identità del server del Fornitore |
| `max_dispositivi` | Dispositivi utente | Istanze server (prod, staging, dev...) |
| `Clienti` nel DB | Utente finale | Software house che acquista la licenza |
| Registrazione | Al primo avvio app utente | All'avvio del server applicativo del Fornitore |
| Offline | Utente senza connessione | Server in manutenzione / intranet isolata |
| Anti-frode | Clonazione su molti PC | Copia INSTALL_KEY su server non autorizzati |

**Proposta team sul fingerprint:**
Anziché hardware (instabile su VM/Docker/cloud), usiamo una **INSTALL_KEY** generata da BK al momento della vendita:
```
fingerprint = hash(INSTALL_KEY + hostname_server)
```
La INSTALL_KEY viene consegnata al Fornitore e inserita nel file di configurazione del suo server.

**Domande:**
- **INSTALL_KEY** — la genera BK manualmente (es. via pannello admin) o automaticamente alla firma del contratto?
- **max_istanze** — come viene definito contrattualmente? (es. 1 prod + 1 staging = 2 istanze incluse?)
- **Ambienti isolati** — ci sono Fornitori che operano in intranet senza accesso internet? Se sì, quanto deve durare la cache offline prima di bloccare?
- **Trial enterprise** — il Fornitore può installare la trial sul suo server di test prima di acquistare? Ha senso avere una trial in questo contesto?
- **Utenti finali** — gli utenti finali dell'applicazione del Fornitore sono completamente fuori dal nostro sistema, corretto? Noi tracciamo solo il Fornitore.

---

## Note finali

Portiamo anche un elenco di **micro-domande** emerse dall'analisi dello schema SQL che potrebbero impattare il DB:

- La tabella `Notifiche` ha solo i tipi `SCAD_7GG`, `SCAD_3GG`, `SCAD_1GG`, `SCADUTA` — aggiungiamo un tipo per la licenza provvisoria in scadenza?
- `Pagamenti.rif_erp` è nullable (ammette più NULL) — confermato come comportamento atteso?
- La tabella `Dispositivi` non ha storico heartbeat, solo `ultimo_heartbeat` — confermato che non serve lo storico?
- `Dispositivi.device_id` — in ottica enterprise server, lo rinominiamo `instance_id` o teniamo il nome generico?
