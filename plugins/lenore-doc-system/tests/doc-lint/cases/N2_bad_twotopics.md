Scheduler starvation and also the login page redesign.

The scheduler's priority queue can starve low-priority tasks under load,
we should add aging. Separately, the login page redesign mockups are done
and need review; the new flow removes the password-strength meter and adds
a magic-link option instead.
