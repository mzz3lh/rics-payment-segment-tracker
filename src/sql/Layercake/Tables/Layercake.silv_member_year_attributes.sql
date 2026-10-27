CREATE TABLE Layercake.silv_member_year_attributes
(
    contact_no              nvarchar(200) NOT NULL,
    campaign_year           int           NOT NULL,
    payment_method_id       int           NOT NULL,
    payment_method_carried  bit           NOT NULL CONSTRAINT DF_Layercake_silv_member_year_attributes_payment_method_carried DEFAULT 0,
    payer_type_id           int           NOT NULL,
    payer_type_carried      bit           NOT NULL CONSTRAINT DF_Layercake_silv_member_year_attributes_payer_type_carried DEFAULT 0,
    corporate_account_ref   nvarchar(100) NULL,
    concession_type_id      int           NOT NULL,
    concession_type_carried bit           NOT NULL CONSTRAINT DF_Layercake_silv_member_year_attributes_concession_type_carried DEFAULT 0,
    segment_invoice_rec_id  bigint        NULL,
    load_id                 bigint        NOT NULL,
    created_at              datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_silv_member_year_attributes_created_at DEFAULT SYSDATETIME(),
    updated_at              datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_silv_member_year_attributes_updated_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_silv_member_year_attributes PRIMARY KEY CLUSTERED (contact_no, campaign_year),
    CONSTRAINT FK_Layercake_silv_member_year_attributes_silv_ref_payment_method
        FOREIGN KEY (payment_method_id) REFERENCES Layercake.silv_ref_payment_method (id),
    CONSTRAINT FK_Layercake_silv_member_year_attributes_silv_ref_payer_type
        FOREIGN KEY (payer_type_id) REFERENCES Layercake.silv_ref_payer_type (id),
    CONSTRAINT FK_Layercake_silv_member_year_attributes_silv_ref_concession_type
        FOREIGN KEY (concession_type_id) REFERENCES Layercake.silv_ref_concession_type (id)
);
