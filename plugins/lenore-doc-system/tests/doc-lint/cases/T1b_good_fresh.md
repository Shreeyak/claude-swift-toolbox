Backfill legacy user records once the schema migration lands.

Run scripts/backfill_users.py against the users table after the email_verified
column migration (commit 9f2ac71) ships; the rollout should batch by 5000 rows
per scripts/backfill_users.py --batch-size flag, per the plan in
docs/notes/backfill-plan.md.
