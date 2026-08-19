P95 latency regression on batch resize traced to the RFC 9110 retry rules.

The resize path's P95 rose from 80ms to 210ms after enabling retries.
Per RFC 9110 semantics our 429 handling retries the whole batch; run012
measured that splitting the batch first restores P95 to 85ms (commit
abc1234). CVE-2024-31317 is unrelated despite the similar stack trace.
