/*====================================================================
    Layercake.brnz_subs_status
    Bronze layer - table, keys and intrinsic indexes
====================================================================*/

--------------------------------------------------------------
--  Subs.vwSubsMemberStatuses -> Layercake.brnz_subs_status
--  natural key: contact + campaign year
--  inv_total_amount and retired_concession added by MOD-017
--  (RULE-103, Q-043); appended after the audit columns, as the
--  change script adds them.
--------------------------------------------------------------
create table Layercake.brnz_subs_status
(
    [Contact No.]             nvarchar(200) not null,
    [Campaign Year]           int not null,
    [Member Invoice Position] varchar(18) null,
    [Renewal Date]            date null,
    [Renewal Date Adj]        date null,
    _loaded_at                datetime2(3) not null constraint df_brnz_subs_status_loaded  default sysdatetime(),
    _updated_at               datetime2(3) not null constraint df_brnz_subs_status_updated default sysdatetime(),
    _is_deleted               bit not null constraint df_brnz_subs_status_isdel default 0,
    _deleted_at               datetime2(3) null,
    inv_total_amount          numeric(38,6) null,
    retired_concession        varchar(17) null,
    constraint pk_brnz_subs_status primary key clustered ([Contact No.], [Campaign Year])
);
