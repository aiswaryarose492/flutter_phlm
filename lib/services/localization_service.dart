import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizationService extends ChangeNotifier {
  static final AppLocalizationService instance =
      AppLocalizationService._internal();
  AppLocalizationService._internal();

  static const _languageKey = 'app_language_code';
  static const _supportedLocales = [Locale('en'), Locale('ml'), Locale('hi')];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  List<Locale> get supportedLocales => _supportedLocales;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_languageKey);
    if (code != null) {
      _locale = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    notifyListeners();
  }

  String tr(String key) {
    final messages = _messagesFor(_locale.languageCode);
    return messages[key] ?? _messagesFor('en')[key] ?? key;
  }

  Map<String, String> _messagesFor(String languageCode) {
    switch (languageCode) {
      case 'ml':
        return _malayalam;
      case 'hi':
        return _hindi;
      case 'en':
      default:
        return _english;
    }
  }

  static const _english = {
    'appName': 'PHLM',
    'role_patient': 'Patient',
    'role_doctor': 'Doctor',
    'role_staff': 'Staff',
    'role_admin': 'Admin',
    'role_lab': 'Lab',
    'role_pharmacy': 'Pharmacy',
    'action_book': 'Book',
    'action_cancel': 'Cancel',
    'action_confirm': 'Confirm',
    'action_save': 'Save',
    'settings_language': 'Language',
    'settings_dark_mode': 'Dark Mode',
    'offline_banner': 'Offline — showing cached data',
  };

  static const _malayalam = {
    'appName': 'PHLM',
    'role_patient': 'രോഗി',
    'role_doctor': 'ഡോക്ടർ',
    'role_staff': 'ജീവനക്കാരൻ',
    'role_admin': 'അഡ്മിൻ',
    'role_lab': 'ലാബ്',
    'role_pharmacy': 'ഫാർമസി',
    'action_book': 'ബുക്ക് ചെയ്യുക',
    'action_cancel': 'റദ്ദാക്കുക',
    'action_confirm': 'സ്ഥിരീകരിക്കുക',
    'action_save': 'സേവ് ചെയ്യുക',
    'settings_language': 'ഭാഷ',
    'settings_dark_mode': 'ഇരുണ്ട മോഡ്',
    'offline_banner': 'ഓഫ്‌ലൈൻ — കാഷ് ചെയ്ത ഡാറ്റ കാണിക്കുന്നു',
  };

  static const _hindi = {
    'appName': 'PHLM',
    'role_patient': 'मरीज',
    'role_doctor': 'डॉक्टर',
    'role_staff': 'कर्मचारी',
    'role_admin': 'व्यवस्थापक',
    'role_lab': 'लैब',
    'role_pharmacy': 'फार्मेसी',
    'action_book': 'बुक करें',
    'action_cancel': 'रद्द करें',
    'action_confirm': 'पुष्टि करें',
    'action_save': 'सहेजें',
    'settings_language': 'भाषा',
    'settings_dark_mode': 'डार्क मोड',
    'offline_banner': 'ऑफ़लाइन — कैश किया गया डेटा दिखा रहे हैं',
  };
}
