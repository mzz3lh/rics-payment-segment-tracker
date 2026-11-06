-- MOD-008 changes no structure of Layercake.silv_data_anomaly (DES-001: structure unchanged);
-- the module only writes rows through usp_load_silv_data_anomaly_segment. The table has no
-- CHECK or FOREIGN KEY constraints, so this statement is a no-op kept for the change-script check.
ALTER TABLE Layercake.silv_data_anomaly CHECK CONSTRAINT ALL;
