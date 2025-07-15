ALTER TABLE RunRecord ADD COLUMN OutputTokenThroughput FLOAT64;
ALTER TABLE RunRecord ADD COLUMN TotalTokenThroughput FLOAT64;

CREATE INDEX IDX_RunRecord_OutputTokenThroughput ON RunRecord (OutputTokenThroughput);
CREATE INDEX IDX_RunRecord_TotalTokenThroughput ON RunRecord (TotalTokenThroughput);