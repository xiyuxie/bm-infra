/*
For each (Model), find the latest pair of results (i.e., RunType = 'HOURLY' and HOURLY_TORCHAX') with the same JobReference.
Compare their throughputs.

Output: Model, ThroughputHourly, ThroughputHourlyTorchax, optionally Devices (but not JobReference).

In other words: for each model, find the latest JobReference where both RunTypes exist, then aggregate and compare.
*/

CREATE OR REPLACE VIEW `TpuCompareBackend` SQL SECURITY INVOKER AS
SELECT
  j.Model,
  STRING_AGG(DISTINCT j.Device, ', ') AS Devices,
  IFNULL(MAX(CASE WHEN j.RunType = 'HOURLY' THEN j.Throughput ELSE NULL END), 0) AS ThroughputHourly,
  IFNULL(MAX(CASE WHEN j.RunType = 'HOURLY_TORCHAX' THEN j.Throughput ELSE NULL END), 0) AS ThroughputHourlyTorchax,
  IFNULL(MAX(CASE WHEN j.RunType = 'HOURLY_JAX' THEN j.Throughput ELSE NULL END), 0) AS ThroughputHourlyJax
FROM (
  SELECT
    f.Model,
    f.JobReference,
    f.RunType,
    f.Device,
    f.Throughput
  FROM HourlyRunAllTPU AS f
  JOIN (
    SELECT
      p.Model,
      MAX(p.JobReference) AS LatestJobRef
    FROM HourlyRunAllTPU AS p
    WHERE p.RunType IN ('HOURLY', 'HOURLY_TORCHAX', 'HOURLY_JAX')
      AND p.CreatedTime <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 59 MINUTE)
    GROUP BY p.Model
  ) AS latest
  ON f.Model = latest.Model AND f.JobReference = latest.LatestJobRef
  WHERE f.RunType IN ('HOURLY', 'HOURLY_TORCHAX', 'HOURLY_JAX')
) AS j
GROUP BY
  j.Model
ORDER BY
  j.Model;