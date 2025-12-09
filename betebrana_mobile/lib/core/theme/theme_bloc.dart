// theme_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class ThemeState {
  final bool isDarkMode;

  ThemeState({required this.isDarkMode});

  factory ThemeState.initial() => ThemeState(isDarkMode: true);
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState.initial()) {
    on<ToggleThemeEvent>((event, emit) {
      emit(ThemeState(isDarkMode: !state.isDarkMode));
    });
  }
}