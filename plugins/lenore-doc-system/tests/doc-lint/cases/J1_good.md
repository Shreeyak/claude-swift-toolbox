Fixed the flaky retry test by seeding the RNG before each run.

The test occasionally failed because the backoff jitter used an unseeded
random source, so two consecutive runs could pick different delays and race
the timeout. Seeding it per-test made the failure reproducible, and from
there the actual bug (a missing clamp on max delay) was easy to spot and fix.
