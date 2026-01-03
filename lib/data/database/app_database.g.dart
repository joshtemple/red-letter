// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PassagesTable extends Passages with TableInfo<$PassagesTable, Passage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PassagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _passageIdMeta = const VerificationMeta(
    'passageId',
  );
  @override
  late final GeneratedColumn<String> passageId = GeneratedColumn<String>(
    'passage_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationIdMeta = const VerificationMeta(
    'translationId',
  );
  @override
  late final GeneratedColumn<String> translationId = GeneratedColumn<String>(
    'translation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passageTextMeta = const VerificationMeta(
    'passageText',
  );
  @override
  late final GeneratedColumn<String> passageText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  @override
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mnemonicUrlMeta = const VerificationMeta(
    'mnemonicUrl',
  );
  @override
  late final GeneratedColumn<String> mnemonicUrl = GeneratedColumn<String>(
    'mnemonic_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    passageId,
    translationId,
    reference,
    passageText,
    book,
    chapter,
    startVerse,
    endVerse,
    mnemonicUrl,
    tags,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'passages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Passage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('passage_id')) {
      context.handle(
        _passageIdMeta,
        passageId.isAcceptableOrUnknown(data['passage_id']!, _passageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_passageIdMeta);
    }
    if (data.containsKey('translation_id')) {
      context.handle(
        _translationIdMeta,
        translationId.isAcceptableOrUnknown(
          data['translation_id']!,
          _translationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationIdMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _passageTextMeta,
        passageText.isAcceptableOrUnknown(data['text']!, _passageTextMeta),
      );
    } else if (isInserting) {
      context.missing(_passageTextMeta);
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    } else if (isInserting) {
      context.missing(_startVerseMeta);
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    } else if (isInserting) {
      context.missing(_endVerseMeta);
    }
    if (data.containsKey('mnemonic_url')) {
      context.handle(
        _mnemonicUrlMeta,
        mnemonicUrl.isAcceptableOrUnknown(
          data['mnemonic_url']!,
          _mnemonicUrlMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {passageId};
  @override
  Passage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Passage(
      passageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passage_id'],
      )!,
      translationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_id'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      passageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      )!,
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      )!,
      mnemonicUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mnemonic_url'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
    );
  }

  @override
  $PassagesTable createAlias(String alias) {
    return $PassagesTable(attachedDatabase, alias);
  }
}

class Passage extends DataClass implements Insertable<Passage> {
  /// Unique passage identifier (e.g., "mat-5-44" for Matthew 5:44)
  final String passageId;

  /// Translation identifier (e.g., "niv", "esv", "kjv")
  final String translationId;

  /// Human-readable scripture reference (e.g., "Matthew 5:44")
  final String reference;

  /// The actual scripture text to memorize
  final String passageText;

  /// Book name (e.g., "Matthew")
  final String book;

  /// Chapter number
  final int chapter;

  /// Start verse number
  final int startVerse;

  /// End verse number (same as startVerse if single verse)
  final int endVerse;

  /// Optional URL to visual mnemonic aid (nullable)
  final String? mnemonicUrl;

  /// Comma-separated tags for categorization (e.g., "sermon-on-mount,commands")
  final String tags;
  const Passage({
    required this.passageId,
    required this.translationId,
    required this.reference,
    required this.passageText,
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    this.mnemonicUrl,
    required this.tags,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['passage_id'] = Variable<String>(passageId);
    map['translation_id'] = Variable<String>(translationId);
    map['reference'] = Variable<String>(reference);
    map['text'] = Variable<String>(passageText);
    map['book'] = Variable<String>(book);
    map['chapter'] = Variable<int>(chapter);
    map['start_verse'] = Variable<int>(startVerse);
    map['end_verse'] = Variable<int>(endVerse);
    if (!nullToAbsent || mnemonicUrl != null) {
      map['mnemonic_url'] = Variable<String>(mnemonicUrl);
    }
    map['tags'] = Variable<String>(tags);
    return map;
  }

  PassagesCompanion toCompanion(bool nullToAbsent) {
    return PassagesCompanion(
      passageId: Value(passageId),
      translationId: Value(translationId),
      reference: Value(reference),
      passageText: Value(passageText),
      book: Value(book),
      chapter: Value(chapter),
      startVerse: Value(startVerse),
      endVerse: Value(endVerse),
      mnemonicUrl: mnemonicUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mnemonicUrl),
      tags: Value(tags),
    );
  }

  factory Passage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Passage(
      passageId: serializer.fromJson<String>(json['passage_id']),
      translationId: serializer.fromJson<String>(json['translation_id']),
      reference: serializer.fromJson<String>(json['reference']),
      passageText: serializer.fromJson<String>(json['text']),
      book: serializer.fromJson<String>(json['book']),
      chapter: serializer.fromJson<int>(json['chapter']),
      startVerse: serializer.fromJson<int>(json['start_verse']),
      endVerse: serializer.fromJson<int>(json['end_verse']),
      mnemonicUrl: serializer.fromJson<String?>(json['mnemonic_url']),
      tags: serializer.fromJson<String>(json['tags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'passage_id': serializer.toJson<String>(passageId),
      'translation_id': serializer.toJson<String>(translationId),
      'reference': serializer.toJson<String>(reference),
      'text': serializer.toJson<String>(passageText),
      'book': serializer.toJson<String>(book),
      'chapter': serializer.toJson<int>(chapter),
      'start_verse': serializer.toJson<int>(startVerse),
      'end_verse': serializer.toJson<int>(endVerse),
      'mnemonic_url': serializer.toJson<String?>(mnemonicUrl),
      'tags': serializer.toJson<String>(tags),
    };
  }

  Passage copyWith({
    String? passageId,
    String? translationId,
    String? reference,
    String? passageText,
    String? book,
    int? chapter,
    int? startVerse,
    int? endVerse,
    Value<String?> mnemonicUrl = const Value.absent(),
    String? tags,
  }) => Passage(
    passageId: passageId ?? this.passageId,
    translationId: translationId ?? this.translationId,
    reference: reference ?? this.reference,
    passageText: passageText ?? this.passageText,
    book: book ?? this.book,
    chapter: chapter ?? this.chapter,
    startVerse: startVerse ?? this.startVerse,
    endVerse: endVerse ?? this.endVerse,
    mnemonicUrl: mnemonicUrl.present ? mnemonicUrl.value : this.mnemonicUrl,
    tags: tags ?? this.tags,
  );
  Passage copyWithCompanion(PassagesCompanion data) {
    return Passage(
      passageId: data.passageId.present ? data.passageId.value : this.passageId,
      translationId: data.translationId.present
          ? data.translationId.value
          : this.translationId,
      reference: data.reference.present ? data.reference.value : this.reference,
      passageText: data.passageText.present
          ? data.passageText.value
          : this.passageText,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
      mnemonicUrl: data.mnemonicUrl.present
          ? data.mnemonicUrl.value
          : this.mnemonicUrl,
      tags: data.tags.present ? data.tags.value : this.tags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Passage(')
          ..write('passageId: $passageId, ')
          ..write('translationId: $translationId, ')
          ..write('reference: $reference, ')
          ..write('passageText: $passageText, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('mnemonicUrl: $mnemonicUrl, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    passageId,
    translationId,
    reference,
    passageText,
    book,
    chapter,
    startVerse,
    endVerse,
    mnemonicUrl,
    tags,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Passage &&
          other.passageId == this.passageId &&
          other.translationId == this.translationId &&
          other.reference == this.reference &&
          other.passageText == this.passageText &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.startVerse == this.startVerse &&
          other.endVerse == this.endVerse &&
          other.mnemonicUrl == this.mnemonicUrl &&
          other.tags == this.tags);
}

class PassagesCompanion extends UpdateCompanion<Passage> {
  final Value<String> passageId;
  final Value<String> translationId;
  final Value<String> reference;
  final Value<String> passageText;
  final Value<String> book;
  final Value<int> chapter;
  final Value<int> startVerse;
  final Value<int> endVerse;
  final Value<String?> mnemonicUrl;
  final Value<String> tags;
  final Value<int> rowid;
  const PassagesCompanion({
    this.passageId = const Value.absent(),
    this.translationId = const Value.absent(),
    this.reference = const Value.absent(),
    this.passageText = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.mnemonicUrl = const Value.absent(),
    this.tags = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PassagesCompanion.insert({
    required String passageId,
    required String translationId,
    required String reference,
    required String passageText,
    required String book,
    required int chapter,
    required int startVerse,
    required int endVerse,
    this.mnemonicUrl = const Value.absent(),
    this.tags = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : passageId = Value(passageId),
       translationId = Value(translationId),
       reference = Value(reference),
       passageText = Value(passageText),
       book = Value(book),
       chapter = Value(chapter),
       startVerse = Value(startVerse),
       endVerse = Value(endVerse);
  static Insertable<Passage> custom({
    Expression<String>? passageId,
    Expression<String>? translationId,
    Expression<String>? reference,
    Expression<String>? passageText,
    Expression<String>? book,
    Expression<int>? chapter,
    Expression<int>? startVerse,
    Expression<int>? endVerse,
    Expression<String>? mnemonicUrl,
    Expression<String>? tags,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (passageId != null) 'passage_id': passageId,
      if (translationId != null) 'translation_id': translationId,
      if (reference != null) 'reference': reference,
      if (passageText != null) 'text': passageText,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endVerse != null) 'end_verse': endVerse,
      if (mnemonicUrl != null) 'mnemonic_url': mnemonicUrl,
      if (tags != null) 'tags': tags,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PassagesCompanion copyWith({
    Value<String>? passageId,
    Value<String>? translationId,
    Value<String>? reference,
    Value<String>? passageText,
    Value<String>? book,
    Value<int>? chapter,
    Value<int>? startVerse,
    Value<int>? endVerse,
    Value<String?>? mnemonicUrl,
    Value<String>? tags,
    Value<int>? rowid,
  }) {
    return PassagesCompanion(
      passageId: passageId ?? this.passageId,
      translationId: translationId ?? this.translationId,
      reference: reference ?? this.reference,
      passageText: passageText ?? this.passageText,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      mnemonicUrl: mnemonicUrl ?? this.mnemonicUrl,
      tags: tags ?? this.tags,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (passageId.present) {
      map['passage_id'] = Variable<String>(passageId.value);
    }
    if (translationId.present) {
      map['translation_id'] = Variable<String>(translationId.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (passageText.present) {
      map['text'] = Variable<String>(passageText.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (mnemonicUrl.present) {
      map['mnemonic_url'] = Variable<String>(mnemonicUrl.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PassagesCompanion(')
          ..write('passageId: $passageId, ')
          ..write('translationId: $translationId, ')
          ..write('reference: $reference, ')
          ..write('passageText: $passageText, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('mnemonicUrl: $mnemonicUrl, ')
          ..write('tags: $tags, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProgressTableTable extends UserProgressTable
    with TableInfo<$UserProgressTableTable, UserProgress> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProgressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _passageIdMeta = const VerificationMeta(
    'passageId',
  );
  @override
  late final GeneratedColumn<String> passageId = GeneratedColumn<String>(
    'passage_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL UNIQUE REFERENCES passages(passage_id) ON DELETE CASCADE',
  );
  static const VerificationMeta _masteryLevelMeta = const VerificationMeta(
    'masteryLevel',
  );
  @override
  late final GeneratedColumn<int> masteryLevel = GeneratedColumn<int>(
    'mastery_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(5.0),
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewedMeta = const VerificationMeta(
    'lastReviewed',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewed = GeneratedColumn<DateTime>(
    'last_reviewed',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextReviewMeta = const VerificationMeta(
    'nextReview',
  );
  @override
  late final GeneratedColumn<DateTime> nextReview = GeneratedColumn<DateTime>(
    'next_review',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _semanticReflectionMeta =
      const VerificationMeta('semanticReflection');
  @override
  late final GeneratedColumn<String> semanticReflection =
      GeneratedColumn<String>(
        'semantic_reflection',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSyncMeta = const VerificationMeta(
    'lastSync',
  );
  @override
  late final GeneratedColumn<DateTime> lastSync = GeneratedColumn<DateTime>(
    'last_sync',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    passageId,
    masteryLevel,
    stability,
    difficulty,
    step,
    state,
    lastReviewed,
    nextReview,
    semanticReflection,
    lastSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_progress_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProgress> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('passage_id')) {
      context.handle(
        _passageIdMeta,
        passageId.isAcceptableOrUnknown(data['passage_id']!, _passageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_passageIdMeta);
    }
    if (data.containsKey('mastery_level')) {
      context.handle(
        _masteryLevelMeta,
        masteryLevel.isAcceptableOrUnknown(
          data['mastery_level']!,
          _masteryLevelMeta,
        ),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('last_reviewed')) {
      context.handle(
        _lastReviewedMeta,
        lastReviewed.isAcceptableOrUnknown(
          data['last_reviewed']!,
          _lastReviewedMeta,
        ),
      );
    }
    if (data.containsKey('next_review')) {
      context.handle(
        _nextReviewMeta,
        nextReview.isAcceptableOrUnknown(data['next_review']!, _nextReviewMeta),
      );
    }
    if (data.containsKey('semantic_reflection')) {
      context.handle(
        _semanticReflectionMeta,
        semanticReflection.isAcceptableOrUnknown(
          data['semantic_reflection']!,
          _semanticReflectionMeta,
        ),
      );
    }
    if (data.containsKey('last_sync')) {
      context.handle(
        _lastSyncMeta,
        lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProgress map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProgress(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      passageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passage_id'],
      )!,
      masteryLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery_level'],
      )!,
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      lastReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed'],
      ),
      nextReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review'],
      ),
      semanticReflection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semantic_reflection'],
      ),
      lastSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync'],
      ),
    );
  }

  @override
  $UserProgressTableTable createAlias(String alias) {
    return $UserProgressTableTable(attachedDatabase, alias);
  }
}

class UserProgress extends DataClass implements Insertable<UserProgress> {
  /// Auto-incrementing primary key
  final int id;

  /// Foreign key reference to Passages.passageId
  final String passageId;

  /// Current mastery level (0-4: new, learning, familiar, mastered, locked-in)
  final int masteryLevel;

  /// FSRS: Memory stability in days (how long memory remains stable)
  final double stability;

  /// FSRS: Inherent difficulty of the passage (0-10 scale)
  final double difficulty;

  /// FSRS: Current step in learning/relearning process (null if in review state)
  final int? step;

  /// FSRS: Learning state (0=learning, 1=review, 2=relearning)
  final int state;

  /// Timestamp of last review (Unix epoch seconds)
  final DateTime? lastReviewed;

  /// Timestamp when next review is due (Unix epoch seconds)
  final DateTime? nextReview;

  /// User's semantic reflection text (enforces understanding before rote practice)
  final String? semanticReflection;

  /// Timestamp of last cloud sync (Unix epoch seconds, nullable for offline-only users)
  final DateTime? lastSync;
  const UserProgress({
    required this.id,
    required this.passageId,
    required this.masteryLevel,
    required this.stability,
    required this.difficulty,
    this.step,
    required this.state,
    this.lastReviewed,
    this.nextReview,
    this.semanticReflection,
    this.lastSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['passage_id'] = Variable<String>(passageId);
    map['mastery_level'] = Variable<int>(masteryLevel);
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || lastReviewed != null) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed);
    }
    if (!nullToAbsent || nextReview != null) {
      map['next_review'] = Variable<DateTime>(nextReview);
    }
    if (!nullToAbsent || semanticReflection != null) {
      map['semantic_reflection'] = Variable<String>(semanticReflection);
    }
    if (!nullToAbsent || lastSync != null) {
      map['last_sync'] = Variable<DateTime>(lastSync);
    }
    return map;
  }

  UserProgressTableCompanion toCompanion(bool nullToAbsent) {
    return UserProgressTableCompanion(
      id: Value(id),
      passageId: Value(passageId),
      masteryLevel: Value(masteryLevel),
      stability: Value(stability),
      difficulty: Value(difficulty),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      state: Value(state),
      lastReviewed: lastReviewed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewed),
      nextReview: nextReview == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReview),
      semanticReflection: semanticReflection == null && nullToAbsent
          ? const Value.absent()
          : Value(semanticReflection),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory UserProgress.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProgress(
      id: serializer.fromJson<int>(json['id']),
      passageId: serializer.fromJson<String>(json['passage_id']),
      masteryLevel: serializer.fromJson<int>(json['mastery_level']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      step: serializer.fromJson<int?>(json['step']),
      state: serializer.fromJson<int>(json['state']),
      lastReviewed: serializer.fromJson<DateTime?>(json['last_reviewed']),
      nextReview: serializer.fromJson<DateTime?>(json['next_review']),
      semanticReflection: serializer.fromJson<String?>(
        json['semantic_reflection'],
      ),
      lastSync: serializer.fromJson<DateTime?>(json['last_sync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'passage_id': serializer.toJson<String>(passageId),
      'mastery_level': serializer.toJson<int>(masteryLevel),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'step': serializer.toJson<int?>(step),
      'state': serializer.toJson<int>(state),
      'last_reviewed': serializer.toJson<DateTime?>(lastReviewed),
      'next_review': serializer.toJson<DateTime?>(nextReview),
      'semantic_reflection': serializer.toJson<String?>(semanticReflection),
      'last_sync': serializer.toJson<DateTime?>(lastSync),
    };
  }

  UserProgress copyWith({
    int? id,
    String? passageId,
    int? masteryLevel,
    double? stability,
    double? difficulty,
    Value<int?> step = const Value.absent(),
    int? state,
    Value<DateTime?> lastReviewed = const Value.absent(),
    Value<DateTime?> nextReview = const Value.absent(),
    Value<String?> semanticReflection = const Value.absent(),
    Value<DateTime?> lastSync = const Value.absent(),
  }) => UserProgress(
    id: id ?? this.id,
    passageId: passageId ?? this.passageId,
    masteryLevel: masteryLevel ?? this.masteryLevel,
    stability: stability ?? this.stability,
    difficulty: difficulty ?? this.difficulty,
    step: step.present ? step.value : this.step,
    state: state ?? this.state,
    lastReviewed: lastReviewed.present ? lastReviewed.value : this.lastReviewed,
    nextReview: nextReview.present ? nextReview.value : this.nextReview,
    semanticReflection: semanticReflection.present
        ? semanticReflection.value
        : this.semanticReflection,
    lastSync: lastSync.present ? lastSync.value : this.lastSync,
  );
  UserProgress copyWithCompanion(UserProgressTableCompanion data) {
    return UserProgress(
      id: data.id.present ? data.id.value : this.id,
      passageId: data.passageId.present ? data.passageId.value : this.passageId,
      masteryLevel: data.masteryLevel.present
          ? data.masteryLevel.value
          : this.masteryLevel,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      step: data.step.present ? data.step.value : this.step,
      state: data.state.present ? data.state.value : this.state,
      lastReviewed: data.lastReviewed.present
          ? data.lastReviewed.value
          : this.lastReviewed,
      nextReview: data.nextReview.present
          ? data.nextReview.value
          : this.nextReview,
      semanticReflection: data.semanticReflection.present
          ? data.semanticReflection.value
          : this.semanticReflection,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProgress(')
          ..write('id: $id, ')
          ..write('passageId: $passageId, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('step: $step, ')
          ..write('state: $state, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('nextReview: $nextReview, ')
          ..write('semanticReflection: $semanticReflection, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    passageId,
    masteryLevel,
    stability,
    difficulty,
    step,
    state,
    lastReviewed,
    nextReview,
    semanticReflection,
    lastSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProgress &&
          other.id == this.id &&
          other.passageId == this.passageId &&
          other.masteryLevel == this.masteryLevel &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.step == this.step &&
          other.state == this.state &&
          other.lastReviewed == this.lastReviewed &&
          other.nextReview == this.nextReview &&
          other.semanticReflection == this.semanticReflection &&
          other.lastSync == this.lastSync);
}

class UserProgressTableCompanion extends UpdateCompanion<UserProgress> {
  final Value<int> id;
  final Value<String> passageId;
  final Value<int> masteryLevel;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<int?> step;
  final Value<int> state;
  final Value<DateTime?> lastReviewed;
  final Value<DateTime?> nextReview;
  final Value<String?> semanticReflection;
  final Value<DateTime?> lastSync;
  const UserProgressTableCompanion({
    this.id = const Value.absent(),
    this.passageId = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.step = const Value.absent(),
    this.state = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.semanticReflection = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  UserProgressTableCompanion.insert({
    this.id = const Value.absent(),
    required String passageId,
    this.masteryLevel = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.step = const Value.absent(),
    this.state = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.semanticReflection = const Value.absent(),
    this.lastSync = const Value.absent(),
  }) : passageId = Value(passageId);
  static Insertable<UserProgress> custom({
    Expression<int>? id,
    Expression<String>? passageId,
    Expression<int>? masteryLevel,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<int>? step,
    Expression<int>? state,
    Expression<DateTime>? lastReviewed,
    Expression<DateTime>? nextReview,
    Expression<String>? semanticReflection,
    Expression<DateTime>? lastSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (passageId != null) 'passage_id': passageId,
      if (masteryLevel != null) 'mastery_level': masteryLevel,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (step != null) 'step': step,
      if (state != null) 'state': state,
      if (lastReviewed != null) 'last_reviewed': lastReviewed,
      if (nextReview != null) 'next_review': nextReview,
      if (semanticReflection != null) 'semantic_reflection': semanticReflection,
      if (lastSync != null) 'last_sync': lastSync,
    });
  }

  UserProgressTableCompanion copyWith({
    Value<int>? id,
    Value<String>? passageId,
    Value<int>? masteryLevel,
    Value<double>? stability,
    Value<double>? difficulty,
    Value<int?>? step,
    Value<int>? state,
    Value<DateTime?>? lastReviewed,
    Value<DateTime?>? nextReview,
    Value<String?>? semanticReflection,
    Value<DateTime?>? lastSync,
  }) {
    return UserProgressTableCompanion(
      id: id ?? this.id,
      passageId: passageId ?? this.passageId,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      step: step ?? this.step,
      state: state ?? this.state,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      semanticReflection: semanticReflection ?? this.semanticReflection,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (passageId.present) {
      map['passage_id'] = Variable<String>(passageId.value);
    }
    if (masteryLevel.present) {
      map['mastery_level'] = Variable<int>(masteryLevel.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (lastReviewed.present) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed.value);
    }
    if (nextReview.present) {
      map['next_review'] = Variable<DateTime>(nextReview.value);
    }
    if (semanticReflection.present) {
      map['semantic_reflection'] = Variable<String>(semanticReflection.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<DateTime>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressTableCompanion(')
          ..write('id: $id, ')
          ..write('passageId: $passageId, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('step: $step, ')
          ..write('state: $state, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('nextReview: $nextReview, ')
          ..write('semanticReflection: $semanticReflection, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PassagesTable passages = $PassagesTable(this);
  late final $UserProgressTableTable userProgressTable =
      $UserProgressTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    passages,
    userProgressTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'passages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_progress_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PassagesTableCreateCompanionBuilder =
    PassagesCompanion Function({
      required String passageId,
      required String translationId,
      required String reference,
      required String passageText,
      required String book,
      required int chapter,
      required int startVerse,
      required int endVerse,
      Value<String?> mnemonicUrl,
      Value<String> tags,
      Value<int> rowid,
    });
typedef $$PassagesTableUpdateCompanionBuilder =
    PassagesCompanion Function({
      Value<String> passageId,
      Value<String> translationId,
      Value<String> reference,
      Value<String> passageText,
      Value<String> book,
      Value<int> chapter,
      Value<int> startVerse,
      Value<int> endVerse,
      Value<String?> mnemonicUrl,
      Value<String> tags,
      Value<int> rowid,
    });

final class $$PassagesTableReferences
    extends BaseReferences<_$AppDatabase, $PassagesTable, Passage> {
  $$PassagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UserProgressTableTable, List<UserProgress>>
  _userProgressTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userProgressTable,
        aliasName: $_aliasNameGenerator(
          db.passages.passageId,
          db.userProgressTable.passageId,
        ),
      );

  $$UserProgressTableTableProcessedTableManager get userProgressTableRefs {
    final manager =
        $$UserProgressTableTableTableManager(
          $_db,
          $_db.userProgressTable,
        ).filter(
          (f) => f.passageId.passageId.sqlEquals(
            $_itemColumn<String>('passage_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _userProgressTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PassagesTableFilterComposer
    extends Composer<_$AppDatabase, $PassagesTable> {
  $$PassagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get passageId => $composableBuilder(
    column: $table.passageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationId => $composableBuilder(
    column: $table.translationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passageText => $composableBuilder(
    column: $table.passageText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mnemonicUrl => $composableBuilder(
    column: $table.mnemonicUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userProgressTableRefs(
    Expression<bool> Function($$UserProgressTableTableFilterComposer f) f,
  ) {
    final $$UserProgressTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.userProgressTable,
      getReferencedColumn: (t) => t.passageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserProgressTableTableFilterComposer(
            $db: $db,
            $table: $db.userProgressTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PassagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PassagesTable> {
  $$PassagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get passageId => $composableBuilder(
    column: $table.passageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationId => $composableBuilder(
    column: $table.translationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passageText => $composableBuilder(
    column: $table.passageText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mnemonicUrl => $composableBuilder(
    column: $table.mnemonicUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PassagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PassagesTable> {
  $$PassagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get passageId =>
      $composableBuilder(column: $table.passageId, builder: (column) => column);

  GeneratedColumn<String> get translationId => $composableBuilder(
    column: $table.translationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get passageText => $composableBuilder(
    column: $table.passageText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  GeneratedColumn<String> get mnemonicUrl => $composableBuilder(
    column: $table.mnemonicUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  Expression<T> userProgressTableRefs<T extends Object>(
    Expression<T> Function($$UserProgressTableTableAnnotationComposer a) f,
  ) {
    final $$UserProgressTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.passageId,
          referencedTable: $db.userProgressTable,
          getReferencedColumn: (t) => t.passageId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserProgressTableTableAnnotationComposer(
                $db: $db,
                $table: $db.userProgressTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PassagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PassagesTable,
          Passage,
          $$PassagesTableFilterComposer,
          $$PassagesTableOrderingComposer,
          $$PassagesTableAnnotationComposer,
          $$PassagesTableCreateCompanionBuilder,
          $$PassagesTableUpdateCompanionBuilder,
          (Passage, $$PassagesTableReferences),
          Passage,
          PrefetchHooks Function({bool userProgressTableRefs})
        > {
  $$PassagesTableTableManager(_$AppDatabase db, $PassagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PassagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PassagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PassagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> passageId = const Value.absent(),
                Value<String> translationId = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> passageText = const Value.absent(),
                Value<String> book = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> startVerse = const Value.absent(),
                Value<int> endVerse = const Value.absent(),
                Value<String?> mnemonicUrl = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PassagesCompanion(
                passageId: passageId,
                translationId: translationId,
                reference: reference,
                passageText: passageText,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                mnemonicUrl: mnemonicUrl,
                tags: tags,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String passageId,
                required String translationId,
                required String reference,
                required String passageText,
                required String book,
                required int chapter,
                required int startVerse,
                required int endVerse,
                Value<String?> mnemonicUrl = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PassagesCompanion.insert(
                passageId: passageId,
                translationId: translationId,
                reference: reference,
                passageText: passageText,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                mnemonicUrl: mnemonicUrl,
                tags: tags,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PassagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userProgressTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userProgressTableRefs) db.userProgressTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userProgressTableRefs)
                    await $_getPrefetchedData<
                      Passage,
                      $PassagesTable,
                      UserProgress
                    >(
                      currentTable: table,
                      referencedTable: $$PassagesTableReferences
                          ._userProgressTableRefsTable(db),
                      managerFromTypedResult: (p0) => $$PassagesTableReferences(
                        db,
                        table,
                        p0,
                      ).userProgressTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.passageId == item.passageId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PassagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PassagesTable,
      Passage,
      $$PassagesTableFilterComposer,
      $$PassagesTableOrderingComposer,
      $$PassagesTableAnnotationComposer,
      $$PassagesTableCreateCompanionBuilder,
      $$PassagesTableUpdateCompanionBuilder,
      (Passage, $$PassagesTableReferences),
      Passage,
      PrefetchHooks Function({bool userProgressTableRefs})
    >;
typedef $$UserProgressTableTableCreateCompanionBuilder =
    UserProgressTableCompanion Function({
      Value<int> id,
      required String passageId,
      Value<int> masteryLevel,
      Value<double> stability,
      Value<double> difficulty,
      Value<int?> step,
      Value<int> state,
      Value<DateTime?> lastReviewed,
      Value<DateTime?> nextReview,
      Value<String?> semanticReflection,
      Value<DateTime?> lastSync,
    });
typedef $$UserProgressTableTableUpdateCompanionBuilder =
    UserProgressTableCompanion Function({
      Value<int> id,
      Value<String> passageId,
      Value<int> masteryLevel,
      Value<double> stability,
      Value<double> difficulty,
      Value<int?> step,
      Value<int> state,
      Value<DateTime?> lastReviewed,
      Value<DateTime?> nextReview,
      Value<String?> semanticReflection,
      Value<DateTime?> lastSync,
    });

final class $$UserProgressTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $UserProgressTableTable, UserProgress> {
  $$UserProgressTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PassagesTable _passageIdTable(_$AppDatabase db) =>
      db.passages.createAlias(
        $_aliasNameGenerator(
          db.userProgressTable.passageId,
          db.passages.passageId,
        ),
      );

  $$PassagesTableProcessedTableManager get passageId {
    final $_column = $_itemColumn<String>('passage_id')!;

    final manager = $$PassagesTableTableManager(
      $_db,
      $_db.passages,
    ).filter((f) => f.passageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_passageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserProgressTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserProgressTableTable> {
  $$UserProgressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semanticReflection => $composableBuilder(
    column: $table.semanticReflection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnFilters(column),
  );

  $$PassagesTableFilterComposer get passageId {
    final $$PassagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.passages,
      getReferencedColumn: (t) => t.passageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassagesTableFilterComposer(
            $db: $db,
            $table: $db.passages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserProgressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProgressTableTable> {
  $$UserProgressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semanticReflection => $composableBuilder(
    column: $table.semanticReflection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnOrderings(column),
  );

  $$PassagesTableOrderingComposer get passageId {
    final $$PassagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.passages,
      getReferencedColumn: (t) => t.passageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassagesTableOrderingComposer(
            $db: $db,
            $table: $db.passages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserProgressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProgressTableTable> {
  $$UserProgressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get semanticReflection => $composableBuilder(
    column: $table.semanticReflection,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);

  $$PassagesTableAnnotationComposer get passageId {
    final $$PassagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.passages,
      getReferencedColumn: (t) => t.passageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassagesTableAnnotationComposer(
            $db: $db,
            $table: $db.passages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserProgressTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProgressTableTable,
          UserProgress,
          $$UserProgressTableTableFilterComposer,
          $$UserProgressTableTableOrderingComposer,
          $$UserProgressTableTableAnnotationComposer,
          $$UserProgressTableTableCreateCompanionBuilder,
          $$UserProgressTableTableUpdateCompanionBuilder,
          (UserProgress, $$UserProgressTableTableReferences),
          UserProgress,
          PrefetchHooks Function({bool passageId})
        > {
  $$UserProgressTableTableTableManager(
    _$AppDatabase db,
    $UserProgressTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProgressTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProgressTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProgressTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> passageId = const Value.absent(),
                Value<int> masteryLevel = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<DateTime?> nextReview = const Value.absent(),
                Value<String?> semanticReflection = const Value.absent(),
                Value<DateTime?> lastSync = const Value.absent(),
              }) => UserProgressTableCompanion(
                id: id,
                passageId: passageId,
                masteryLevel: masteryLevel,
                stability: stability,
                difficulty: difficulty,
                step: step,
                state: state,
                lastReviewed: lastReviewed,
                nextReview: nextReview,
                semanticReflection: semanticReflection,
                lastSync: lastSync,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String passageId,
                Value<int> masteryLevel = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<DateTime?> nextReview = const Value.absent(),
                Value<String?> semanticReflection = const Value.absent(),
                Value<DateTime?> lastSync = const Value.absent(),
              }) => UserProgressTableCompanion.insert(
                id: id,
                passageId: passageId,
                masteryLevel: masteryLevel,
                stability: stability,
                difficulty: difficulty,
                step: step,
                state: state,
                lastReviewed: lastReviewed,
                nextReview: nextReview,
                semanticReflection: semanticReflection,
                lastSync: lastSync,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserProgressTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({passageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (passageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.passageId,
                                referencedTable:
                                    $$UserProgressTableTableReferences
                                        ._passageIdTable(db),
                                referencedColumn:
                                    $$UserProgressTableTableReferences
                                        ._passageIdTable(db)
                                        .passageId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserProgressTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProgressTableTable,
      UserProgress,
      $$UserProgressTableTableFilterComposer,
      $$UserProgressTableTableOrderingComposer,
      $$UserProgressTableTableAnnotationComposer,
      $$UserProgressTableTableCreateCompanionBuilder,
      $$UserProgressTableTableUpdateCompanionBuilder,
      (UserProgress, $$UserProgressTableTableReferences),
      UserProgress,
      PrefetchHooks Function({bool passageId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PassagesTableTableManager get passages =>
      $$PassagesTableTableManager(_db, _db.passages);
  $$UserProgressTableTableTableManager get userProgressTable =>
      $$UserProgressTableTableTableManager(_db, _db.userProgressTable);
}
