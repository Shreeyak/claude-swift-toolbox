"tile-first" (computing placement per tile before global refine) wins the blend comparison.

Tile-first beats whole-frame refinement 2.1px vs 3.4px mean error on
data/clips (the masked-ncc experiment, run004). The tile-first ordering
also halves peak memory since only one tile's pyramid is resident.
