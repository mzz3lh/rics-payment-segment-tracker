CREATE TABLE Layercake.silv_ref_invoice_line_type
(
    item_code        nvarchar(50)  NOT NULL,
    ric_invoice_type nvarchar(10)  NOT NULL,
    line_type        varchar(40)   NOT NULL,
    load_id          bigint        NULL,
    created_at       datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_silv_ref_invoice_line_type_created_at DEFAULT SYSDATETIME(),
    updated_at       datetime2(3)  NOT NULL CONSTRAINT DF_Layercake_silv_ref_invoice_line_type_updated_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_silv_ref_invoice_line_type PRIMARY KEY CLUSTERED (item_code, ric_invoice_type),
    CONSTRAINT CK_Layercake_silv_ref_invoice_line_type_line_type CHECK (line_type IN ('subscription', 'concession', 'readmission fee', 'enrolment or application fee', 'tax', 'other', 'unmapped'))
);
