int scoreForLabels(Iterable<String> labels) {
  int score = 0;
  for (final l in labels) {
    switch (l.toLowerCase()) {
      case 'person':
        score += 10;
        break;
      case 'dog':
        score += 8;
        break;
      case 'cat':
        score += 7;
        break;
      default:
        score += 1;
    }
  }
  return score;
}
