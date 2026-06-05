import 'package:betebrana_mobile/core/services/language_service.dart';
import 'package:betebrana_mobile/core/theme/app_theme.dart';
import 'package:betebrana_mobile/core/theme/theme_bloc.dart';
import 'package:betebrana_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_event.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileSettingsTab extends StatelessWidget {
  const ProfileSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final langState = context.watch<LanguageBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userState = context.watch<AuthBloc>().state;
    AuthUser? user = (userState is AuthAuthenticated) ? userState.user : null;

    final initial = user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'G';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(langState.t('Settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Authentic User Profile
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.purple.withOpacity(0.1),
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 28, color: AppColors.purple, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? langState.t('Guest User'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? langState.t('Sign in to sync your library'),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            Text(
              langState.t('PREFERENCES').toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey[850]! : Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // Theme Toggle
                  BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, themeState) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.dark_mode_outlined, color: AppColors.orange, size: 20),
                        ),
                        title: Text(langState.t('Dark Theme'), style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Switch.adaptive(
                          value: themeState.isDarkMode,
                          onChanged: (_) => context.read<ThemeBloc>().add(ToggleThemeEvent()),
                          activeColor: AppColors.orange,
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.grey[850] : Colors.grey[200], indent: 56),
                  
                  // Language
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.language_outlined, color: Colors.blue, size: 20),
                    ),
                    title: Text(langState.t('App Language'), style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: langState.isAmharic ? 'am' : 'en',
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded, 
                            color: isDark ? Colors.white70 : Colors.blue,
                            size: 18,
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'am', child: Text('አማርኛ')),
                          ],
                          onChanged: (val) {
                            if (val != null) context.read<LanguageBloc>().add(LanguageSet(val));
                          },
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: isDark ? Colors.grey[850] : Colors.grey[200], indent: 56),

                  // Font Style
                  BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, themeState) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.font_download_outlined, color: AppColors.purple, size: 20),
                        ),
                        title: Text(langState.t('Font Style'), style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: themeState.fontFamily,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded, 
                                color: isDark ? Colors.white70 : AppColors.purple,
                                size: 18,
                              ),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              items: const [
                                DropdownMenuItem(value: 'System', child: Text('System')),
                                DropdownMenuItem(value: 'Abyssinica SIL', child: Text('Abyssinica')),
                                DropdownMenuItem(value: 'Kefa', child: Text('Kefa')),
                                DropdownMenuItem(value: 'Noto Sans Ethiopic', child: Text('Noto Sans')),
                              ],
                              onChanged: (val) {
                                if (val != null) context.read<ThemeBloc>().add(ChangeFontEvent(val));
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(langState.t('Log Out'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
