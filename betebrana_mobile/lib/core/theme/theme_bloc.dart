// theme_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class SetThemeEvent extends ThemeEvent {
  final bool isDarkMode;
  SetThemeEvent(this.isDarkMode);
}

class ChangeFontEvent extends ThemeEvent {
  final String fontFamily;
  ChangeFontEvent(this.fontFamily);
}

class ThemeState {
  final bool isDarkMode;
  final String fontFamily;
  ThemeState({required this.isDarkMode, this.fontFamily = 'Abyssinica SIL'});
  // Default to LIGHT mode
  factory ThemeState.initial() => ThemeState(isDarkMode: false, fontFamily: 'Abyssinica SIL');
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const _key = 'isDarkMode';

  static const _fontKey = 'fontFamily';

  ThemeBloc() : super(ThemeState.initial()) {
    on<ToggleThemeEvent>(_onToggle);
    on<SetThemeEvent>(_onSet);
    on<ChangeFontEvent>(_onChangeFont);
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_key);
    final savedFont = prefs.getString(_fontKey) ?? 'Abyssinica SIL';
    if (saved != null) {
      emit(ThemeState(isDarkMode: saved, fontFamily: savedFont));
    } else {
      emit(ThemeState(isDarkMode: false, fontFamily: savedFont));
    }
  }

  Future<void> _onToggle(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    final next = !state.isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, next);
    emit(ThemeState(isDarkMode: next, fontFamily: state.fontFamily));
  }

  Future<void> _onSet(SetThemeEvent event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, event.isDarkMode);
    emit(ThemeState(isDarkMode: event.isDarkMode, fontFamily: state.fontFamily));
  }

  Future<void> _onChangeFont(ChangeFontEvent event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, event.fontFamily);
    emit(ThemeState(isDarkMode: state.isDarkMode, fontFamily: event.fontFamily));
  }
}