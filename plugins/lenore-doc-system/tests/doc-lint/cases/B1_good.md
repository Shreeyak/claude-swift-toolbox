Login form submits twice when Enter is pressed while the submit button has focus.

Repro: focus the password field, type a valid password, then press Enter.
Expected: exactly one POST to /api/login.
Actual: two POST requests fire, ~40ms apart (confirmed in network tab); the
second one is rejected server-side as a duplicate nonce, showing a spurious
"invalid credentials" toast even though the first request succeeded.
