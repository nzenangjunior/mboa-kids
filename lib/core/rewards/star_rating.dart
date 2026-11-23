/// Stars earned at the end of a 5-question game, from how many of the
/// main questions (not retries) were answered correctly on the first
/// try (CLAUDE.md section 8). Never 0: a game is always worth at least
/// one star, consistent with "pas de punition" (CLAUDE.md rule 5).
int starsForFirstTryCorrect(int correctFirstTryCount) {
  if (correctFirstTryCount >= 5) return 3;
  if (correctFirstTryCount >= 3) return 2;
  return 1;
}

/// Stars earned for a finished tracing activity (CLAUDE.md section 10),
/// from the fraction of items (letters/numbers) whose guided-then-unguided
/// pair was completed with no failed attempt. The activity's queue length
/// varies session to session (unlike the alphabet game's fixed 5
/// questions), so this uses a ratio instead of fixed counts. Never 0,
/// consistent with "pas de punition" (CLAUDE.md rule 5).
int starsForTracingFirstTry(int firstTryCount, int totalCount) {
  if (totalCount <= 0) return 1;
  final ratio = firstTryCount / totalCount;
  if (ratio >= 0.8) return 3;
  if (ratio >= 0.4) return 2;
  return 1;
}
