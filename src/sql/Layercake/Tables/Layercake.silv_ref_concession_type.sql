CREATE TABLE Layercake.silv_ref_concession_type
(
    id                   int              IDENTITY(1, 1) NOT NULL,
    concession_type_bk   uniqueidentifier NULL,
    concession_type_name nvarchar(100)    NOT NULL,
    item_code            nvarchar(100)    NULL,
    is_full_concession   bit              NOT NULL CONSTRAINT DF_Layercake_silv_ref_concession_type_is_full_concession DEFAULT 0,
    is_perpetual         bit              NOT NULL CONSTRAINT DF_Layercake_silv_ref_concession_type_is_perpetual DEFAULT 0,
    load_id              bigint           NULL,
    created_at           datetime2(3)     NOT NULL CONSTRAINT DF_Layercake_silv_ref_concession_type_created_at DEFAULT SYSDATETIME(),
    updated_at           datetime2(3)     NOT NULL CONSTRAINT DF_Layercake_silv_ref_concession_type_updated_at DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Layercake_silv_ref_concession_type PRIMARY KEY CLUSTERED (id)
);

-- The business key is unique where present; the seeded rows have none.
CREATE UNIQUE INDEX IX_silv_ref_concession_type_concession_type_bk
    ON Layercake.silv_ref_concession_type (concession_type_bk)
    WHERE concession_type_bk IS NOT NULL;
