CREATE OR REPLACE VIEW
  `AllRuns` SQL SECURITY INVOKER AS
SELECT
  RunRecord.JobReference,
  RunRecord.RecordId,
  RunRecord.Model,
  RunRecord.Status,
  RunRecord.CodeHash,
  RunRecord.Device,
  RunRecord.RunBy,
  RunRecord.RunType,
  RunRecord.LastUpdate,
  RunRecord.TryCount,
  RunRecord.CreatedTime,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), RunRecord.LastUpdate, MINUTE) AS CurrentStatusLastTime
FROM
  RunRecord
WHERE  
  RunRecord.RunType in ('HOURLY', 'AUTOTUNE')
ORDER BY
  RunRecord.JobReference;