CREATE TABLE Layercake.silv_event_amount
(
    event_nk              nvarchar(220) NOT NULL,
    event_id              int           NOT NULL,
    contact_no            nvarchar(200) NOT NULL,
    event_type            varchar(20)   NOT NULL,
    event_date            date          NOT NULL,
    amount_campaign_year  int           NOT NULL,
    invoice_rec_id        bigint        NULL,
    match_outcome         varchar(30)   NOT NULL,
    subs_amount_gbp       decimal(19,4) NULL,
    invoiced_subtotal_gbp decimal(19,4) NULL,
    amount_status         varchar(30)   NOT NULL,
    load_id               bigint        NOT NULL,
    created_at            datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_silv_event_amount_created_at DEFAULT SYSDATETIME(),
    updated_at            datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_silv_event_amount_updated_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_silv_event_amount PRIMARY KEY CLUSTERED (event_nk),
    -- RULE-088, Q-045: the six amount_status values; 'Unmapped lines' is retired.
    CONSTRAINT CK_Layercake_silv_event_amount_amount_status CHECK (amount_status IN
        ('Before invoice data', 'No invoice', 'Counted on another event', 'Full Concession', 'Fully credited', 'Invoiced'))
);

CREATE INDEX IX_silv_event_amount_contact_no_amount_campaign_year
    ON Layercake.silv_event_amount (contact_no, amount_campaign_year);

CREATE INDEX IX_silv_event_amount_invoice_rec_id
    ON Layercake.silv_event_amount (invoice_rec_id);
