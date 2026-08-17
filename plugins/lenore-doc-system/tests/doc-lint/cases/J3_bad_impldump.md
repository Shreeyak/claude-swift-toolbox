Debugged the retry logic.

RetryPolicy.swift line 42 calls Jitter.compute(seed: nil, base: 200ms,
factor: 1.8, cap: 5000ms). The cap was applied via min(delay, cap) but delay
was computed in microseconds while cap was in milliseconds, so the min() was
comparing mismatched units, effectively disabling the cap. Changed cap to
5_000_000 microseconds. Also refactored JitterConfig to use a Duration type
instead of raw Int64 microseconds throughout, updated 6 call sites in
Scheduler.swift, NetworkClient.swift, and RetryPolicyTests.swift.
