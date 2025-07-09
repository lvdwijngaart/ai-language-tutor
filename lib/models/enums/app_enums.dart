enum Language {
  spanish('Spanish', '🇪🇸', 'es-ES', '¡Hola!'),
  french('French', '🇫🇷', 'fr-FR', 'Bonjour!'),
  german('German', '🇩🇪', 'de-DE', 'Hallo!'),
  italian('Italian', '🇮🇹', 'it-IT', 'Ciao!'),
  portuguese('Portuguese', '🇵🇹', 'pt-PT', 'Olá!'),
  dutch('Dutch', '🇳🇱', 'nl-NL', 'Hallo!'),
  chinesePinyin('Chinese (Pinyin)', '🇨🇳', 'zh-CN', '你好!');

  const Language(
    this.displayName,
    this.flagEmoji,
    this.localeCode,
    this.greeting,
  );
  final String displayName;
  final String flagEmoji;
  final String localeCode;
  final String greeting;

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
