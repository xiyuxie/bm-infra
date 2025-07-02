CREATE OR REPLACE VIEW
  `HourlyRunAllTPU` SQL SECURITY INVOKER AS
SELECT
  RunRecord.RecordId,
  RunRecord.JobReference,
  RunRecord.Model,
  RunRecord.CodeHash,
  RunRecord.Status,
  RunRecord.Device,
  RunRecord.RunType,
  RunRecord.MedianITL,
  RunRecord.MedianTPOT,
  RunRecord.MedianTTFT,
  RunRecord.MedianETEL,
  RunRecord.P99ITL,
  RunRecord.P99TPOT,
  RunRecord.P99TTFT,
  RunRecord.P99ETEL,
  IFNULL(RunRecord.Throughput, 0) AS Throughput,
  PARSE_TIMESTAMP('%Y%m%d_%H%M%S', RunRecord.JobReference, 'America/Los_Angeles') AS JobReferenceTime
FROM
  RunRecord
WHERE
  RunRecord.RunType in ('HOURLY', 'HOURLY_TORCHAX') 
  AND RunRecord.Status IN ('COMPLETED',
    'FAILED')  
  AND RunRecord.Device LIKE 'v6e-%'
  AND RunRecord.CreatedTime >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 15 DAY)
ORDER BY
  RunRecord.JobReference;
  