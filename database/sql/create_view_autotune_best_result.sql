CREATE OR REPLACE VIEW
  `AutoTuneBestResult` SQL SECURITY INVOKER AS
SELECT
  r.JobReference,
  r.Model,
  r.CodeHash,
  r.Device,
  r.Dataset,
  r.Throughput,
  r.MaxNumSeqs,
  r.MaxNumBatchedTokens,
  r.TensorParallelSize,
  r.MaxModelLen,
  r.InputLen,
  r.OutputLen,
  r.ExpectedETEL
FROM RunRecord r
WHERE r.RunType = 'AUTOTUNE'
  AND r.Status IN ('COMPLETED', 'FAILED')
  AND r.CreatedTime >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND r.Throughput = (
    SELECT MAX(r2.Throughput)
    FROM RunRecord r2
    WHERE r2.JobReference = r.JobReference
      AND r2.Model = r.Model
      AND r2.CodeHash = r.CodeHash
      AND r2.Device = r.Device
      AND r2.InputLen = r.InputLen
      AND r2.OutputLen = r.OutputLen
      AND r2.ExpectedETEL = r.ExpectedETEL
      AND r2.RunType = 'AUTOTUNE'
      AND r2.Status IN ('COMPLETED', 'FAILED')
      AND r2.CreatedTime >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  )
ORDER BY r.JobReference;
