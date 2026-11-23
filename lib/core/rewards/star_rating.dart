/// Stars earned at the end of a 5-question game, from how many of the
/// main questions (not retries) were answered correctly on the first
/// try (CLAUDE.md section 8). Never 0: a game is always worth at least
/// one star, consistent with "pas de punition" (CLAUDE.md rule 5).
int starsForFirstTryCorrect(int correctFirstTryCount) {
  if (correctFirstTryCount >= 5) return 3;
  if (correctFirstTryCount >= 3) return 2;
  return 1;
}
