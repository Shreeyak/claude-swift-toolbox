Switched placement from ECC to masked NCC.

Believed ECC would hold at low overlap (assumption from the April web
search). The masked-ncc experiment showed 2.1px vs 5.8px mean error at
under 50% overlap, so the mask-generation approach moves into the
placement pipeline and the ECC path is removed. (abc1234)
