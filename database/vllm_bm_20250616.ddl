ALTER TABLE RunRecord ADD COLUMN TryCount INT64 DEFAULT(0);
CREATE INDEX IDX_RunRecord_TryCount ON RunRecord (TryCount);

