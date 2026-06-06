/* =====================================================================
   BK INVOICE SERVICE  -  Schema database
   Motore: Microsoft SQL Server (T-SQL)
   Servizio di licensing / autorizzazione web app B2B

   Convenzioni:
   - Chiavi primarie surrogate BIGINT IDENTITY (id_*) usate per i collegamenti
   - p_iva, chiavi prodotto/licenza e rif_erp sono UNIQUE (dati di business)
   - Stringhe in NVARCHAR (supporto clienti esteri)
   - Date/ora in DATETIME2, salvate in UTC (SYSUTCDATETIME)
   - "enum" resi con vincoli CHECK

   Eseguire i batch nell'ordine indicato (rispetta le dipendenze FK).
   ===================================================================== */


/* ---------------------------------------------------------------------
   1. PRODOTTI
   Catalogo dei prodotti. Ogni prodotto ha una chiave fissa.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Prodotti (
    id_prodotto     BIGINT          IDENTITY(1,1) NOT NULL,
    chiave_prodotto NVARCHAR(100)   NOT NULL,
    nome            NVARCHAR(200)   NOT NULL,
    descrizione     NVARCHAR(500)   NULL,
    versione        NVARCHAR(50)    NULL,
    attivo          BIT             NOT NULL CONSTRAINT DF_Prodotti_attivo DEFAULT (1),
    created_at      DATETIME2(3)    NOT NULL CONSTRAINT DF_Prodotti_created DEFAULT (SYSUTCDATETIME()),
    updated_at      DATETIME2(3)    NOT NULL CONSTRAINT DF_Prodotti_updated DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Prodotti PRIMARY KEY (id_prodotto),
    CONSTRAINT UQ_Prodotti_chiave UNIQUE (chiave_prodotto)
);
GO


/* ---------------------------------------------------------------------
   2. MODULI
   Moduli funzionali appartenenti a un prodotto (attivabili in licenza).
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Moduli (
    id_modulo    BIGINT         IDENTITY(1,1) NOT NULL,
    id_prodotto  BIGINT         NOT NULL,
    codice       NVARCHAR(100)  NOT NULL,
    nome         NVARCHAR(200)  NOT NULL,
    descrizione  NVARCHAR(500)  NULL,
    attivo       BIT            NOT NULL CONSTRAINT DF_Moduli_attivo DEFAULT (1),
    created_at   DATETIME2(3)   NOT NULL CONSTRAINT DF_Moduli_created DEFAULT (SYSUTCDATETIME()),
    updated_at   DATETIME2(3)   NOT NULL CONSTRAINT DF_Moduli_updated DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Moduli PRIMARY KEY (id_modulo),
    CONSTRAINT UQ_Moduli_prodotto_codice UNIQUE (id_prodotto, codice),
    CONSTRAINT FK_Moduli_Prodotti FOREIGN KEY (id_prodotto)
        REFERENCES dbo.Prodotti (id_prodotto) ON DELETE CASCADE
);
GO


/* ---------------------------------------------------------------------
   3. CLIENTI
   Anagrafica completa (decisione: dati fiscali conservati nel gestionale).
   p_iva: identificatore "pubblico" usato dall'app; UNIQUE e indicizzato.
   deleted_at: SOLO per cancellazione reale del cliente (soft delete),
               NON per la scadenza del trial (quella vive su Licenze.status).
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Clienti (
    id_cliente          BIGINT         IDENTITY(1,1) NOT NULL,
    p_iva               NVARCHAR(20)   NOT NULL,
    codice_fiscale      NVARCHAR(20)   NULL,
    ragione_sociale     NVARCHAR(255)  NOT NULL,
    chiave_cliente      NVARCHAR(100)  NOT NULL,
    email               NVARCHAR(255)  NULL,
    pec                 NVARCHAR(255)  NULL,
    codice_destinatario NVARCHAR(7)    NULL,            -- codice SDI
    indirizzo           NVARCHAR(255)  NULL,
    cap                 NVARCHAR(10)   NULL,
    citta               NVARCHAR(100)  NULL,
    provincia           NVARCHAR(5)    NULL,
    nazione             NVARCHAR(2)    NOT NULL CONSTRAINT DF_Clienti_nazione DEFAULT ('IT'),
    created_at          DATETIME2(3)   NOT NULL CONSTRAINT DF_Clienti_created DEFAULT (SYSUTCDATETIME()),
    updated_at          DATETIME2(3)   NOT NULL CONSTRAINT DF_Clienti_updated DEFAULT (SYSUTCDATETIME()),
    deleted_at          DATETIME2(3)   NULL,
    CONSTRAINT PK_Clienti PRIMARY KEY (id_cliente),
    CONSTRAINT UQ_Clienti_piva UNIQUE (p_iva)
);
GO


/* ---------------------------------------------------------------------
   4. LICENZE
   Una riga per coppia cliente+prodotto. Il rinnovo ESTENDE data_scadenza
   sulla stessa riga; lo storico dei pagamenti vive in Pagamenti.
   status: stato corrente | tipo_licenza: natura della licenza
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Licenze (
    id_licenza      BIGINT         IDENTITY(1,1) NOT NULL,
    chiave_licenza  NVARCHAR(255)  NOT NULL,            -- combinazione prodotto+cliente
    id_cliente      BIGINT         NOT NULL,
    id_prodotto     BIGINT         NOT NULL,
    status          NVARCHAR(20)   NOT NULL CONSTRAINT DF_Licenze_status DEFAULT ('TRIAL'),
    tipo_licenza    NVARCHAR(20)   NOT NULL CONSTRAINT DF_Licenze_tipo DEFAULT ('TRIAL'),
    data_inizio     DATE           NOT NULL CONSTRAINT DF_Licenze_inizio DEFAULT (CAST(SYSUTCDATETIME() AS DATE)),
    data_scadenza   DATE           NOT NULL,
    max_dispositivi INT            NOT NULL CONSTRAINT DF_Licenze_maxdev DEFAULT (1),
    created_at      DATETIME2(3)   NOT NULL CONSTRAINT DF_Licenze_created DEFAULT (SYSUTCDATETIME()),
    updated_at      DATETIME2(3)   NOT NULL CONSTRAINT DF_Licenze_updated DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Licenze PRIMARY KEY (id_licenza),
    CONSTRAINT UQ_Licenze_chiave UNIQUE (chiave_licenza),
    CONSTRAINT UQ_Licenze_cliente_prodotto UNIQUE (id_cliente, id_prodotto),
    CONSTRAINT CK_Licenze_status CHECK (status IN ('TRIAL','ACTIVE','EXPIRED','SUSPENDED')),
    CONSTRAINT CK_Licenze_tipo   CHECK (tipo_licenza IN ('TRIAL','SUBSCRIPTION')),
    CONSTRAINT FK_Licenze_Clienti  FOREIGN KEY (id_cliente)
        REFERENCES dbo.Clienti (id_cliente),
    CONSTRAINT FK_Licenze_Prodotti FOREIGN KEY (id_prodotto)
        REFERENCES dbo.Prodotti (id_prodotto)
);
GO

-- Indice per il Cron Job notturno: scansione veloce delle licenze in scadenza
CREATE INDEX IX_Licenze_status_scadenza
    ON dbo.Licenze (status, data_scadenza)
    INCLUDE (id_cliente, id_prodotto);
GO


/* ---------------------------------------------------------------------
   5. LICENZE_MODULI
   Quali moduli sono attivi per una specifica licenza (relazione N:M).
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Licenze_Moduli (
    id_licenza       BIGINT       NOT NULL,
    id_modulo        BIGINT       NOT NULL,
    attivo           BIT          NOT NULL CONSTRAINT DF_LicMod_attivo DEFAULT (1),
    data_attivazione DATETIME2(3) NOT NULL CONSTRAINT DF_LicMod_data DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Licenze_Moduli PRIMARY KEY (id_licenza, id_modulo),
    CONSTRAINT FK_LicMod_Licenze FOREIGN KEY (id_licenza)
        REFERENCES dbo.Licenze (id_licenza) ON DELETE CASCADE,
    CONSTRAINT FK_LicMod_Moduli  FOREIGN KEY (id_modulo)
        REFERENCES dbo.Moduli (id_modulo)
);
GO


/* ---------------------------------------------------------------------
   6. DISPOSITIVI
   Device autorizzati per una licenza. Heartbeat senza storico:
   si aggiorna solo ultimo_heartbeat (decisione presa).
   Il limite multi-dispositivo si confronta con Licenze.max_dispositivi.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Dispositivi (
    id_dispositivo      BIGINT         IDENTITY(1,1) NOT NULL,
    id_licenza          BIGINT         NOT NULL,
    device_id           NVARCHAR(255)  NOT NULL,
    piattaforma         NVARCHAR(50)   NULL,           -- es. ANDROID, WINDOWS
    session_id_corrente NVARCHAR(255)  NULL,
    data_registrazione  DATETIME2(3)   NOT NULL CONSTRAINT DF_Disp_datareg DEFAULT (SYSUTCDATETIME()),
    ultimo_heartbeat    DATETIME2(3)   NULL,
    attivo              BIT            NOT NULL CONSTRAINT DF_Disp_attivo DEFAULT (1),
    CONSTRAINT PK_Dispositivi PRIMARY KEY (id_dispositivo),
    CONSTRAINT UQ_Dispositivi_licenza_device UNIQUE (id_licenza, device_id),
    CONSTRAINT FK_Dispositivi_Licenze FOREIGN KEY (id_licenza)
        REFERENCES dbo.Licenze (id_licenza) ON DELETE CASCADE
);
GO

-- Lookup rapido del device nei controlli heartbeat / anti-abuso
CREATE INDEX IX_Dispositivi_device ON dbo.Dispositivi (device_id);
GO


/* ---------------------------------------------------------------------
   7. NOTIFICHE
   Log degli avvisi inviati (sostituisce le colonne-flag su Licenze).
   Vincolo per-ciclo: un avviso di ciascun tipo, per licenza, per ciclo
   di scadenza. Al rinnovo cambia data_scadenza_ciclo => avvisi ripartono.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Notifiche (
    id_notifica         BIGINT         IDENTITY(1,1) NOT NULL,
    id_licenza          BIGINT         NOT NULL,
    tipo                NVARCHAR(20)   NOT NULL,
    canale              NVARCHAR(20)   NOT NULL,
    data_scadenza_ciclo DATE           NOT NULL,        -- scadenza del ciclo a cui si riferisce
    data_invio          DATETIME2(3)   NOT NULL CONSTRAINT DF_Notif_data DEFAULT (SYSUTCDATETIME()),
    esito               NVARCHAR(20)   NOT NULL CONSTRAINT DF_Notif_esito DEFAULT ('INVIATA'),
    CONSTRAINT PK_Notifiche PRIMARY KEY (id_notifica),
    CONSTRAINT UQ_Notifiche_ciclo UNIQUE (id_licenza, tipo, data_scadenza_ciclo),
    CONSTRAINT CK_Notifiche_tipo   CHECK (tipo IN ('SCAD_7GG','SCAD_3GG','SCAD_1GG','SCADUTA')),
    CONSTRAINT CK_Notifiche_canale CHECK (canale IN ('PUSH','EMAIL')),
    CONSTRAINT CK_Notifiche_esito  CHECK (esito IN ('INVIATA','FALLITA')),
    CONSTRAINT FK_Notifiche_Licenze FOREIGN KEY (id_licenza)
        REFERENCES dbo.Licenze (id_licenza) ON DELETE CASCADE
);
GO


/* ---------------------------------------------------------------------
   8. PAGAMENTI
   Storico di checkout/rinnovi. rif_erp univoco = idempotenza del webhook
   (lo stesso webhook ricevuto due volte non crea due righe).
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Pagamenti (
    id_pagamento        BIGINT         IDENTITY(1,1) NOT NULL,
    id_licenza          BIGINT         NOT NULL,
    id_cliente          BIGINT         NOT NULL,
    piano               NVARCHAR(100)  NULL,
    importo             DECIMAL(10,2)  NULL,
    valuta              NVARCHAR(3)    NOT NULL CONSTRAINT DF_Pag_valuta DEFAULT ('EUR'),
    metodo              NVARCHAR(50)   NULL,
    stato               NVARCHAR(20)   NOT NULL CONSTRAINT DF_Pag_stato DEFAULT ('PENDING'),
    rif_erp             NVARCHAR(255)  NULL,
    webhook_ricevuto_at DATETIME2(3)   NULL,
    created_at          DATETIME2(3)   NOT NULL CONSTRAINT DF_Pag_created DEFAULT (SYSUTCDATETIME()),
    updated_at          DATETIME2(3)   NOT NULL CONSTRAINT DF_Pag_updated DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Pagamenti PRIMARY KEY (id_pagamento),
    CONSTRAINT CK_Pagamenti_stato CHECK (stato IN ('PENDING','CONFIRMED','FAILED')),
    CONSTRAINT FK_Pagamenti_Licenze FOREIGN KEY (id_licenza)
        REFERENCES dbo.Licenze (id_licenza),
    CONSTRAINT FK_Pagamenti_Clienti FOREIGN KEY (id_cliente)
        REFERENCES dbo.Clienti (id_cliente)
);
GO

-- rif_erp univoco solo quando valorizzato (indice filtrato: ammette piu' NULL)
CREATE UNIQUE INDEX UX_Pagamenti_riferp
    ON dbo.Pagamenti (rif_erp)
    WHERE rif_erp IS NOT NULL;
GO


/* ---------------------------------------------------------------------
   TRIGGER  -  manutenzione automatica di updated_at
   --------------------------------------------------------------------- */
CREATE TRIGGER trg_Prodotti_updated ON dbo.Prodotti AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p SET updated_at = SYSUTCDATETIME()
    FROM dbo.Prodotti p INNER JOIN inserted i ON p.id_prodotto = i.id_prodotto;
END;
GO

CREATE TRIGGER trg_Moduli_updated ON dbo.Moduli AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE m SET updated_at = SYSUTCDATETIME()
    FROM dbo.Moduli m INNER JOIN inserted i ON m.id_modulo = i.id_modulo;
END;
GO

CREATE TRIGGER trg_Clienti_updated ON dbo.Clienti AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c SET updated_at = SYSUTCDATETIME()
    FROM dbo.Clienti c INNER JOIN inserted i ON c.id_cliente = i.id_cliente;
END;
GO

CREATE TRIGGER trg_Licenze_updated ON dbo.Licenze AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE l SET updated_at = SYSUTCDATETIME()
    FROM dbo.Licenze l INNER JOIN inserted i ON l.id_licenza = i.id_licenza;
END;
GO

CREATE TRIGGER trg_Pagamenti_updated ON dbo.Pagamenti AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p SET updated_at = SYSUTCDATETIME()
    FROM dbo.Pagamenti p INNER JOIN inserted i ON p.id_pagamento = i.id_pagamento;
END;
GO


/* =====================================================================
   DATI DI ESEMPIO (riferimento iniziale - da adattare/rimuovere)
   ===================================================================== */
INSERT INTO dbo.Prodotti (chiave_prodotto, nome, descrizione, versione)
VALUES (N'BK-INV-001', N'BK Invoice', N'Gestionale fatturazione', N'1.0');
GO

INSERT INTO dbo.Moduli (id_prodotto, codice, nome)
VALUES
    (1, N'FATT',  N'Fatturazione elettronica'),
    (1, N'MAGA',  N'Magazzino'),
    (1, N'REPO',  N'Reportistica');
GO
