enum Language {
  spanish('Spanish', '🇪🇸', 'es-ES', '¡Hola!', 'spanish'),
  french('French', '🇫🇷', 'fr-FR', 'Bonjour!', 'french'),
  german('German', '🇩🇪', 'de-DE', 'Hallo!', 'german'),
  italian('Italian', '🇮🇹', 'it-IT', 'Ciao!', 'italian'),
  portuguese('Portuguese', '🇵🇹', 'pt-PT', 'Olá!', 'portuguese'),
  dutch('Dutch', '🇳🇱', 'nl-NL', 'Hallo!', 'dutch'),
  chinesePinyin('Chinese (Pinyin)', '🇨🇳', 'zh-CN', '你好!', null);

  const Language(
    this.displayName,
    this.flagEmoji,
    this.localeCode,
    this.greeting,
    this.dbConfig
  );
  final String displayName;
  final String flagEmoji;
  final String localeCode;
  final String greeting;
  final String? dbConfig;

  // Get fallback locales for speech recognition
  List<String> get fallbackLocales {
    switch (this) {
      case Language.spanish:
        return ['es-ES', 'es-US', 'es-MX', 'es-AR'];
      case Language.french:
        return ['fr-FR', 'fr-CA', 'fr-BE'];
      case Language.german:
        return ['de-DE', 'de-AT', 'de-CH'];
      case Language.italian:
        return ['it-IT', 'it-CH'];
      case Language.portuguese:
        return ['pt-PT', 'pt-BR'];
      case Language.dutch:
        return ['nl-NL', 'nl-BE'];
      case Language.chinesePinyin:
        return ['zh-CN', 'zh-TW', 'zh-HK'];
    }
  }

  static Language fromCode(String code) {
    return Language.values.firstWhere(
      (lang) => lang.localeCode == code, 
      orElse: () => Language.spanish
    );
  }
}

extension LanguageParsing on Language {
  static Language fromString(String value) {
    return Language.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid language value: $value'),
    );
  }
}

enum ProficiencyLevel {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const ProficiencyLevel(this.displayName);
  final String displayName;
}
