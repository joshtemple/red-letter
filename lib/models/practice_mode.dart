enum PracticeMode {
  impression,
  reflection,
  scaffolding,
  prompted,
  reconstruction;

  String get displayName {
    switch (this) {
      case PracticeMode.impression:
        return 'Impression';
      case PracticeMode.reflection:
        return 'Reflection';
      case PracticeMode.scaffolding:
        return 'Scaffolding';
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
      case PracticeMode.scaffolding:
        return 'Variable ratio occlusion (random words hidden)';
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
