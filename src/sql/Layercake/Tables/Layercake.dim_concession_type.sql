CREATE TABLE Layercake.dim_concession_type
(
    id                   int           NOT NULL,
    concession_type_name nvarchar(100) NOT NULL,
    is_full_concession   bit           NOT NULL,
    is_perpetual         bit           NOT NULL,
    load_id              bigint        NULL,
    created_at           datetime2(3)  NOT NULL,
    updated_at           datetime2(3)  NOT NULL,
    CONSTRAINT PK_Layercake_dim_concession_type PRIMARY KEY CLUSTERED (id)
);
