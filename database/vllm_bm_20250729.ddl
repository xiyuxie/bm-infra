ALTER TABLE RunRecord ADD COLUMN ModelTag STRING(64) DEFAULT('PROD');
CREATE INDEX IDX_RunRecord_ModelTag ON RunRecord (ModelTag);

ALTER TABLE RunRecord ADD COLUMN AccuracyMetrics JSON;
CREATE INDEX IDX_RunRecord_AccuracyMetrics ON RunRecord (AccuracyMetrics);
