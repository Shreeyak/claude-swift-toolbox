The scheduler's priority queue starves low-priority tasks under sustained load.

When high-priority tasks arrive faster than the worker pool can drain them,
low-priority tasks never get scheduled because the queue always pops the
highest-priority item first with no aging. A fix would add an aging factor
that boosts effective priority the longer a task waits.
