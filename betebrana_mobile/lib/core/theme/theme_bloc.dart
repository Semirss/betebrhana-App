// theme_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class SetThemeEvent extends ThemeEvent {
  final bool isDarkMode;
  SetThemeEvent(this.isDarkMode);
}

class ThemeState {
  final bool isDarkMode;
  ThemeState({required this.isDarkMode});
  // Default to LIGHT mode
  factory ThemeState.initial() => ThemeState(isDarkMode: false);
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const _key = 'isDarkMode';

  ThemeBloc() : super(ThemeState.initial()) {
    on<ToggleThemeEvent>(_onToggle);
    on<SetThemeEvent>(_onSet);
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_key);
    if (saved != null) {
      emit(ThemeState(isDarkMode: saved));
    }
  }

  Future<void> _onToggle(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    final next = !state.isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, next);
    emit(ThemeState(isDarkMode: next));
  }

  Future<void> _onSet(SetThemeEvent event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, event.isDarkMode);
    emit(ThemeState(isDarkMode: event.isDarkMode));
  }
}