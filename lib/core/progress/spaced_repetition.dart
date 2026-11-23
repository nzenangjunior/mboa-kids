/// Spaced-repetition schedule after an item becomes `acquis`
/// (CLAUDE.md section 7: "Révisions espacées : J+1, J+3, J+7", extended
/// with J+21 and J+60 once the J+7 review succeeds).
const List<int> spacedRepetitionOffsetsInDays = [1, 3, 7, 21, 60];
