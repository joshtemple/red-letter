enum PracticeMode {
  impression,
  reflection,
  randomWords,
  rotatingClauses,
  firstTwoWords,
  prompted,
  reconstruction;

  String get displayName {
    switch (this) {
      case PracticeMode.impression:
        return 'Impression';
      case PracticeMode.reflection:
        return 'Reflection';
      case PracticeMode.randomWords:
        return 'Cloze: Random Words';
      case PracticeMode.rotatingClauses:
        return 'Cloze: Missing Clauses';
      case PracticeMode.firstTwoWords:
        return 'Cloze: First Two Words';
      case PracticeMode.prompted:
        return 'Prompted';
      case PracticeMode.reconstruction:
        return 'Reconstruction';
    }
  }

  String get description {
    switch (this) {
      case PracticeMode.impression:
        return 'Full text + visual mnemonic display';
      case PracticeMode.reflection:
        return 'Mandatory reflection prompt (semantic encoding)';
      case PracticeMode.randomWords:
        return '1-2 random non-trivial words removed per clause';
      case PracticeMode.rotatingClauses:
        return 'One entire clause hidden (rotating)';
      case PracticeMode.firstTwoWords:
        return 'Only the first 2 words of each clause shown';
      case PracticeMode.prompted:
        return 'Blank input with sparse prompting';
      case PracticeMode.reconstruction:
        return 'Total independent recall';
    }
  }

  PracticeMode? get next {
    final index = PracticeMode.values.indexOf(this);
    if (index < PracticeMode.values.length - 1) {
      return PracticeMode.values[index + 1];
    }
    return null;
  }
}
