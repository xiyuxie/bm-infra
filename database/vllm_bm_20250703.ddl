ALTER TABLE RunRecord ADD COLUMN ExtraEnvs STRING(1024);
CREATE INDEX IDX_RunRecord_ExtraEnvs ON RunRecord (ExtraEnvs);
