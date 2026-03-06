import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/screens/auth/login_screen.dart';
import 'package:conti_app/screens/auth/splash_screen.dart';
import 'package:conti_app/screens/home/home_screen.dart';
import 'package:conti_app/screens/team/team_shell_screen.dart';
import 'package:conti_app/screens/team/team_create_screen.dart';
import 'package:conti_app/screens/team/team_join_screen.dart';
import 'package:conti_app/screens/team/team_members_screen.dart';
import 'package:conti_app/screens/song/song_list_screen.dart';
import 'package:conti_app/screens/song/song_detail_screen.dart';
import 'package:conti_app/screens/song/song_form_screen.dart';
import 'package:conti_app/screens/song/song_section_editor.dart';
import 'package:conti_app/screens/song/song_stats_screen.dart';
import 'package:conti_app/screens/song/arrangement_form_screen.dart';
import 'package:conti_app/screens/setlist/setlist_list_screen.dart';
import 'package:conti_app/screens/setlist/setlist_detail_screen.dart';
import 'package:conti_app/screens/setlist/setlist_form_screen.dart';
import 'package:conti_app/screens/setlist/setlist_templates_screen.dart';
import 'package:conti_app/screens/schedule/schedule_board_screen.dart';
import 'package:conti_app/screens/schedule/schedule_assign_screen.dart';
import 'package:conti_app/screens/schedule/schedule_matrix_screen.dart';
import 'package:conti_app/screens/schedule/my_schedule_screen.dart';
import 'package:conti_app/screens/schedule/blockout_form_screen.dart';
import 'package:conti_app/screens/team/member_positions_screen.dart';
import 'package:conti_app/screens/profile/profile_screen.dart';
import 'package:conti_app/screens/team/team_notices_screen.dart';
import 'package:conti_app/screens/setlist/setlist_notes_screen.dart';
import 'package:conti_app/screens/conti/conti_list_screen.dart';
import 'package:conti_app/screens/conti/conti_detail_screen.dart';
import 'package:conti_app/screens/conti/conti_form_screen.dart';
import 'package:conti_app/screens/cuesheet/cuesheet_list_screen.dart';
import 'package:conti_app/screens/cuesheet/cuesheet_detail_screen.dart';
import 'package:conti_app/screens/cuesheet/cuesheet_form_screen.dart';
import 'package:conti_app/screens/notification/notification_list_screen.dart';
import 'package:conti_app/screens/notification/notification_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.initial;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/';

      if (isLoading && isSplash) return null;
      if (isLoading) return '/';
      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && (isLoginRoute || isSplash)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: '/notifications/settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      // Team routes
      GoRoute(
        path: '/teams/create',
        builder: (context, state) => const TeamCreateScreen(),
      ),
      GoRoute(
        path: '/teams/join',
        builder: (context, state) => const TeamJoinScreen(),
      ),
      // ─── Team Shell (with bottom navigation) ───
      GoRoute(
        path: '/teams/:teamId',
        builder: (context, state) {
          final teamId = int.parse(state.pathParameters['teamId']!);
          return TeamShellScreen(teamId: teamId);
        },
        routes: [
          // ─── Team Management ───
          GoRoute(
            path: 'members',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return TeamMembersScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'members/:memberId/positions',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final memberId =
                  int.parse(state.pathParameters['memberId']!);
              return MemberPositionsScreen(
                  teamId: teamId, memberId: memberId);
            },
          ),
          GoRoute(
            path: 'members/:memberId/blockouts',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final memberId =
                  int.parse(state.pathParameters['memberId']!);
              return BlockoutFormScreen(
                  teamId: teamId, memberId: memberId);
            },
          ),
          GoRoute(
            path: 'notices',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return TeamNoticesScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'my-schedule',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return MyScheduleScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'schedule-matrix',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return ScheduleMatrixScreen(teamId: teamId);
            },
          ),
          // ─── Song routes ───
          GoRoute(
            path: 'songs',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return SongListScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'songs/stats',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return SongStatsScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'songs/create',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return SongFormScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'songs/:songId',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final songId = int.parse(state.pathParameters['songId']!);
              return SongDetailScreen(teamId: teamId, songId: songId);
            },
          ),
          GoRoute(
            path: 'songs/:songId/edit',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final songId = int.parse(state.pathParameters['songId']!);
              return SongFormScreen(teamId: teamId, songId: songId);
            },
          ),
          GoRoute(
            path: 'songs/:songId/structure/edit',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final songId = int.parse(state.pathParameters['songId']!);
              return SongSectionEditorScreen(
                  teamId: teamId, songId: songId);
            },
          ),
          GoRoute(
            path: 'songs/:songId/arrangements/create',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final songId = int.parse(state.pathParameters['songId']!);
              return ArrangementFormScreen(teamId: teamId, songId: songId);
            },
          ),
          GoRoute(
            path: 'songs/:songId/arrangements/:arrangementId/edit',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final songId = int.parse(state.pathParameters['songId']!);
              final arrangementId =
                  int.parse(state.pathParameters['arrangementId']!);
              return ArrangementFormScreen(
                  teamId: teamId,
                  songId: songId,
                  arrangementId: arrangementId);
            },
          ),
          // ─── Setlist routes ───
          GoRoute(
            path: 'setlists',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return SetlistListScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'setlists/create',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return SetlistFormScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'setlist-templates',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return SetlistTemplatesScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'setlists/:setlistId',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final setlistId =
                  int.parse(state.pathParameters['setlistId']!);
              return SetlistDetailScreen(
                  teamId: teamId, setlistId: setlistId);
            },
          ),
          GoRoute(
            path: 'setlists/:setlistId/edit',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final setlistId =
                  int.parse(state.pathParameters['setlistId']!);
              return SetlistFormScreen(
                  teamId: teamId, setlistId: setlistId);
            },
          ),
          GoRoute(
            path: 'setlists/:setlistId/notes',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final setlistId =
                  int.parse(state.pathParameters['setlistId']!);
              return SetlistNotesScreen(
                  teamId: teamId, setlistId: setlistId);
            },
          ),
          GoRoute(
            path: 'setlists/:setlistId/schedule',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final setlistId =
                  int.parse(state.pathParameters['setlistId']!);
              return ScheduleBoardScreen(
                  teamId: teamId, setlistId: setlistId);
            },
          ),
          GoRoute(
            path: 'setlists/:setlistId/schedule/assign',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final setlistId =
                  int.parse(state.pathParameters['setlistId']!);
              return ScheduleAssignScreen(
                  teamId: teamId, setlistId: setlistId);
            },
          ),
          // ─── Conti routes ───
          GoRoute(
            path: 'contis',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return ContiListScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'contis/create',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return ContiFormScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'contis/:contiId',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final contiId = int.parse(state.pathParameters['contiId']!);
              return ContiDetailScreen(teamId: teamId, contiId: contiId);
            },
          ),
          GoRoute(
            path: 'contis/:contiId/edit',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final contiId = int.parse(state.pathParameters['contiId']!);
              return ContiFormScreen(teamId: teamId, contiId: contiId);
            },
          ),
          GoRoute(
            path: 'contis/:contiId/notes',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final contiId = int.parse(state.pathParameters['contiId']!);
              return SetlistNotesScreen(teamId: teamId, setlistId: contiId);
            },
          ),
          // ─── Cue Sheet routes ───
          GoRoute(
            path: 'cuesheets',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return CueSheetListScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'cuesheets/create',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              return CueSheetFormScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'cuesheets/:cueSheetId',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final cueSheetId = int.parse(state.pathParameters['cueSheetId']!);
              return CueSheetDetailScreen(teamId: teamId, cueSheetId: cueSheetId);
            },
          ),
          GoRoute(
            path: 'cuesheets/:cueSheetId/edit',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final cueSheetId = int.parse(state.pathParameters['cueSheetId']!);
              return CueSheetFormScreen(teamId: teamId, cueSheetId: cueSheetId);
            },
          ),
          GoRoute(
            path: 'cuesheets/:cueSheetId/schedule',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final cueSheetId = int.parse(state.pathParameters['cueSheetId']!);
              return ScheduleBoardScreen(teamId: teamId, setlistId: cueSheetId);
            },
          ),
          GoRoute(
            path: 'cuesheets/:cueSheetId/schedule/assign',
            builder: (context, state) {
              final teamId = int.parse(state.pathParameters['teamId']!);
              final cueSheetId = int.parse(state.pathParameters['cueSheetId']!);
              return ScheduleAssignScreen(teamId: teamId, setlistId: cueSheetId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('페이지를 찾을 수 없어요: ${state.error}')),
    ),
  );
});
