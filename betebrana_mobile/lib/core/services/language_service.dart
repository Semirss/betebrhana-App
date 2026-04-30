import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class LanguageEvent {
  const LanguageEvent();
}

class LanguageToggled extends LanguageEvent {
  const LanguageToggled();
}

class LanguageSet extends LanguageEvent {
  final String language; // 'en' or 'am'
  const LanguageSet(this.language);
}

// ─── State ────────────────────────────────────────────────────────────────────
class LanguageState {
  final String language;
  const LanguageState(this.language);

  bool get isAmharic => language == 'am';

  /// Translate a key. Falls back to English, then to the key itself.
  String t(String key) {
    return _translations[language]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  factory LanguageState.initial() => const LanguageState('en');
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static const _key = 'app_language';

  LanguageBloc() : super(LanguageState.initial()) {
    on<LanguageToggled>(_onToggle);
    on<LanguageSet>(_onSet);
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      emit(LanguageState(saved));
    }
  }

  Future<void> _onToggle(LanguageToggled event, Emitter<LanguageState> emit) async {
    final next = state.language == 'en' ? 'am' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next);
    emit(LanguageState(next));
  }

  Future<void> _onSet(LanguageSet event, Emitter<LanguageState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, event.language);
    emit(LanguageState(event.language));
  }
}

// ─── Translation Tables ───────────────────────────────────────────────────────
const Map<String, Map<String, String>> _translations = {
  'en': {
    // Nav
    'Discover': 'Discover',
    'Search': 'Search',
    'My Library': 'My Library',
    'Profile': 'Profile',
    'Settings': 'Settings',

    // Home tab
    'Featured': 'Featured',
    'Open Now': 'Open Now',
    'New Arrivals': 'New Arrivals',
    'Browse by Category': 'Browse by Category',
    'Recommended for you': 'Recommended for you',
    'Trending Now': 'Trending Now',
    'Classics': 'Classics',
    'See all': 'See all',
    'Read today': 'Read today',
    'Sponsored': 'Sponsored',
    'please wait server busy': 'Please wait, server is busy…',

    // Search tab
    'Titles, authors, or topics...': 'Titles, authors, or topics...',
    'Popular Authors': 'Popular Authors',
    'Trending Books': 'Trending Books',
    'Explore Complete Library': 'Explore Complete Library',
    'titles available': 'titles available',
    'Loading library...': 'Loading library...',
    'No books matched your search.': 'No books matched your search.',
    'Search by title or author': 'Search by title or author',
    'No books found': 'No books found',

    // Library tab
    'My Rentals': 'My Rentals',
    'Wishlist': 'Wishlist',
    'Downloaded': 'Downloaded',
    'Loading your library…': 'Loading your library…',
    'You have no active rentals right now.': 'You have no active rentals right now.',
    'Your wishlist is empty.': 'Your wishlist is empty.',
    'No books downloaded for offline reading.': 'No books downloaded for offline reading.',
    'Open': 'Open',
    'Active Rental': 'Active Rental',
    'Available': 'Available',
    'No books available': 'No books available',

    // Settings / Profile
    'Manage your profile and personal preferences':
        'Manage your profile and personal preferences',
    'My Rentals & History': 'My Rentals & History',
    'View your active books and reading history':
        'View your active books and reading history',
    'Preferences': 'Preferences',
    'Dark Theme': 'Dark Theme',
    'Currently enabled — dark mode is on': 'Currently enabled — dark mode is on',
    'Currently disabled — using light mode': 'Currently disabled — using light mode',
    'App Language': 'App Language',
    'Choose your preferred interface language': 'Choose your preferred interface language',
    'Library': 'Library',
    'Log Out': 'Log Out',
    'Downloaded Books': 'Downloaded Books',
    'Currently Borrowed': 'Currently Borrowed',
    'No active rentals': 'No active rentals',
    'Guest User': 'Guest User',
    'Sign in to sync your library': 'Sign in to sync your library',

    // Misc
    'Cancel': 'Cancel',
    'Remove': 'Remove',
    'Book Unavailable': 'Book Unavailable',
    'Loading Book…': 'Loading Book…',
    'Book not found.': 'Book not found.',
    'Please wait…': 'Please wait…',
  },

  'am': {
    // Nav
    'Discover': 'አስስ',
    'Search': 'ፈልግ',
    'My Library': 'የእኔ ቤተ-መጻሕፍት',
    'Profile': 'መገለጫ',
    'Settings': 'ቅንብሮች',

    // Home tab
    'Featured': 'ተመራጭ',
    'Open Now': 'አሁን ክፈት',
    'New Arrivals': 'አዳዲስ መጽሐፍት',
    'Browse by Category': 'በምድብ አስስ',
    'Recommended for you': 'ለእርስዎ የተጠቆሙ',
    'Trending Now': 'አሁን ታዋቂ',
    'Classics': 'ክላሲኮች',
    'See all': 'ሁሉንም ይመልከቱ',
    'Read today': 'ዛሬ ያንብቡ',
    'Sponsored': 'ስፖንሰር',
    'please wait server busy': 'እባክዎ ይጠብቁ…',

    // Search tab
    'Titles, authors, or topics...': 'ርዕሶች፣ ደራሲያን ወይም ርዕሰ ጉዳዮች...',
    'Popular Authors': 'ታዋቂ ደራሲያን',
    'Trending Books': 'በመታየት ላይ ያሉ መጽሐፍት',
    'Explore Complete Library': 'ሙሉ ቤተ-መጽሐፍትን ያስሱ',
    'titles available': 'ርዕሶች ይገኛሉ',
    'Loading library...': 'ቤተ-መጽሐፍትን በመጫን ላይ...',
    'No books matched your search.': 'ከፍለጋዎ ጋር የሚዛመዱ መጽሐፍት የሉም።',
    'Search by title or author': 'በርዕስ ወይም ደራሲ ፈልግ',
    'No books found': 'መጽሐፍት አልተገኙም',

    // Library tab
    'My Rentals': 'የእኔ ኪራዮች',
    'Wishlist': 'የምኞት ዝርዝር',
    'Downloaded': 'የወረዱ',
    'Loading your library…': 'የእርስዎን ቤተ-መጽሐፍት በመጫን ላይ…',
    'You have no active rentals right now.': 'በአሁኑ ጊዜ ምንም ንቁ ኪራዮች የሉዎትም።',
    'Your wishlist is empty.': 'የምኞት ዝርዝርዎ ባዶ ነው።',
    'No books downloaded for offline reading.': 'ከመስመር ውጭ ለማንበብ ምንም መጽሐፍት አልወረዱም።',
    'Open': 'ክፈት',
    'Active Rental': 'ንቁ ኪራይ',
    'Available': 'ይገኛል',
    'No books available': 'መጽሐፍት የሉም',

    // Settings / Profile
    'Manage your profile and personal preferences': 'መገለጫዎን እና የግል ምርጫዎችዎን ያቀናብሩ',
    'My Rentals & History': 'የእኔ ኪራዮች እና ታሪክ',
    'View your active books and reading history': 'ገቢር መጽሐፍትዎን እና የንባብ ታሪክዎን ይመልከቱ',
    'Preferences': 'ምርጫዎች',
    'Dark Theme': 'ጥቁር ገጽታ',
    'Currently enabled — dark mode is on': 'በአሁኑ ጊዜ ነቅቷል - ጥቁር ሁነታ በርቷል',
    'Currently disabled — using light mode': 'በአሁኑ ጊዜ ተሰናክሏል - ነጭ ሁነታን በመጠቀም',
    'App Language': 'የመተግበሪያ ቋንቋ',
    'Choose your preferred interface language': 'የሚመርጡትን የበይነገጽ ቋንቋ ይምረጡ',
    'Library': 'ቤተ-መጽሐፍት',
    'Log Out': 'ውጣ',
    'Downloaded Books': 'የወረዱ መጽሐፍት',
    'Currently Borrowed': 'በአሁኑ ጊዜ የተዋሱ',
    'No active rentals': 'ምንም ንቁ ኪራዮች የሉም',
    'Guest User': 'እንግዳ ተጠቃሚ',
    'Sign in to sync your library': 'ቤተ-መጽሐፍትዎን ለማስተሳሰር ይግቡ',

    // Misc
    'Cancel': 'ሰርዝ',
    'Remove': 'አስወግድ',
    'Book Unavailable': 'መጽሐፍ አይገኝም',
    'Loading Book…': 'መጽሐፍ በመጫን ላይ…',
    'Book not found.': 'መጽሐፍ አልተገኘም።',
    'Please wait…': 'እባክዎ ይጠብቁ…',
  },
};
