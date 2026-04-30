import 'dart:async';

import 'package:betebrana_mobile/core/services/language_service.dart';
import 'package:betebrana_mobile/core/theme/app_theme.dart';
import 'package:betebrana_mobile/core/theme/theme_bloc.dart';
import 'package:betebrana_mobile/features/library/data/book_repository.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_bloc.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_event.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tabs/home_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/profile_settings_tab.dart';
import 'tabs/search_tab.dart';

// --- MAIN ENTRY POINT ---
class MainLibraryPage extends StatelessWidget {
  const MainLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final isDark = themeState.isDarkMode;
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: isDark ? AppTheme.dark() : AppTheme.light(),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            home: RepositoryProvider(
              create: (_) => BookRepository(),
              child: BlocProvider(
                create: (context) => LibraryBloc(context.read<BookRepository>())
                  ..add(const LibraryStarted()),
                child: const _MainLibraryView(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MainLibraryView extends StatefulWidget {
  const _MainLibraryView();

  @override
  State<_MainLibraryView> createState() => MainLibraryViewState();
}

class MainLibraryViewState extends State<_MainLibraryView> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _refreshTimer;
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLibrary();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _refreshLibrary();
    });
  }

  void _refreshLibrary() {
    final libraryBloc = context.read<LibraryBloc>();
    if (libraryBloc.state is! LibraryLoading) {
      libraryBloc.add(LibraryRefreshed());
    }
  }

  void _onHomeTapped() {
    if (_currentIndex == 0) {
      // Refresh hero-ads and clear caches if tapping Home while already on Home
      _homeTabKey.currentState?.refresh();
    } else {
      setState(() => _currentIndex = 0);
    }
  }

  // Public method to allow children to switch tabs
  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(key: _homeTabKey),
          const SearchTab(),
          const LibraryTab(),
          const ProfileSettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 0) {
              _onHomeTapped();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          selectedItemColor: AppColors.orange,
          unselectedItemColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: lang.t('Discover'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_outlined),
              activeIcon: const Icon(Icons.search),
              label: lang.t('Search'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.book_outlined),
              activeIcon: const Icon(Icons.book),
              label: lang.t('Library'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: lang.t('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}