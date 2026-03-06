import 'package:flutter/material.dart';
import 'package:conti_app/screens/team/team_detail_screen.dart';
import 'package:conti_app/screens/song/song_list_screen.dart';
import 'package:conti_app/screens/conti/conti_list_screen.dart';
import 'package:conti_app/screens/cuesheet/cuesheet_list_screen.dart';
import 'package:conti_app/screens/team/team_more_tab.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_shadows.dart';

class TeamShellScreen extends StatefulWidget {
  final int teamId;
  final int initialTab;

  const TeamShellScreen({
    super.key,
    required this.teamId,
    this.initialTab = 0,
  });

  @override
  State<TeamShellScreen> createState() => _TeamShellScreenState();
}

class _TeamShellScreenState extends State<TeamShellScreen> {
  late int _currentIndex;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _tabs = [
      TeamDashboardTab(teamId: widget.teamId),
      SongListScreen(teamId: widget.teamId),
      ContiListScreen(teamId: widget.teamId),
      CueSheetListScreen(teamId: widget.teamId),
      TeamMoreTab(teamId: widget.teamId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          boxShadow: AppShadow.bottomNav(isDark),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.primaryLight,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.music_note_outlined),
              selectedIcon: Icon(Icons.music_note_rounded, color: AppColors.primary),
              label: '찬양',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music_rounded, color: AppColors.primary),
              label: '콘티',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.primary),
              label: '큐시트',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              selectedIcon: Icon(Icons.more_horiz_rounded, color: AppColors.primary),
              label: '더보기',
            ),
          ],
        ),
      ),
    );
  }
}
