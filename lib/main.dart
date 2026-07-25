import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/design_system.dart';
import 'core/language_manager.dart';
import 'screens/donation_screen.dart';
import 'screens/fight_timer_screen.dart';
import 'screens/history_screen.dart';
import 'screens/interval_timer_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'screens/todo_screen.dart';
import 'services/donation_manager.dart';
import 'services/history_repository.dart';
import 'services/profile_manager.dart';
import 'services/prompt_manager.dart';
import 'services/todo_manager.dart';
import 'services/user_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final UserSettings settings = await UserSettings.load();
  final LanguageManager language = LanguageManager();
  await language.load();
  final TodoManager todos = TodoManager();
  await todos.load();
  final ProfileManager profiles = ProfileManager();
  await profiles.load();
  final PromptManager prompts = PromptManager();
  await prompts.load();
  final DonationManager donations = DonationManager();

  await todos.recordAppOpen();
  if (settings.todoNotificationsEnabled) {
    await todos.scheduleReminderIfNeeded();
  }

  runApp(BoxTimerApp(
    settings: settings,
    language: language,
    todos: todos,
    profiles: profiles,
    prompts: prompts,
    donations: donations,
  ));
}

class BoxTimerApp extends StatelessWidget {
  const BoxTimerApp({
    super.key,
    required this.settings,
    required this.language,
    required this.todos,
    required this.profiles,
    required this.prompts,
    required this.donations,
  });

  final UserSettings settings;
  final LanguageManager language;
  final TodoManager todos;
  final ProfileManager profiles;
  final PromptManager prompts;
  final DonationManager donations;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserSettings>.value(value: settings),
        ChangeNotifierProvider<LanguageManager>.value(value: language),
        ChangeNotifierProvider<TodoManager>.value(value: todos),
        ChangeNotifierProvider<ProfileManager>.value(value: profiles),
        ChangeNotifierProvider<PromptManager>.value(value: prompts),
        ChangeNotifierProvider<DonationManager>.value(value: donations),
        ChangeNotifierProvider<HistoryRepository>.value(
          value: HistoryRepository.instance,
        ),
      ],
      child: Consumer<LanguageManager>(
        builder: (BuildContext context, LanguageManager lang, _) {
          return MaterialApp(
            title: 'Box Timer',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: DS.bg,
              colorScheme: ColorScheme.fromSeed(
                seedColor: DS.accent,
                brightness: Brightness.dark,
              ),
            ),
            builder: (BuildContext context, Widget? child) {
              return Directionality(
                textDirection: lang.current.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const RootTabs(),
          );
        },
      ),
    );
  }
}

/// Tab-Navigation — Reihenfolge wie iOS: Fight, Intervals, Todos, Stats,
/// Stopwatch, History. Eigene dunkle Bottom-Bar mit Orange-Akzent.
class RootTabs extends StatefulWidget {
  const RootTabs({super.key});

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final PromptManager prompts = context.read<PromptManager>();
      if (prompts.shouldShowDonationPrompt) {
        DonationPromptSheet.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Translations t = context.watch<LanguageManager>().t;

    final List<(IconData, String)> tabs = <(IconData, String)>[
      (Icons.timer, t.tabFightTimer),
      (Icons.directions_run, t.tabIntervals),
      (Icons.check_circle_outline, t.tabTodos),
      (Icons.bar_chart, t.tabStats),
      (Icons.av_timer, t.tabStopwatch),
      (Icons.history, t.tabHistory),
    ];

    return Scaffold(
      backgroundColor: DS.bg,
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          FightTimerScreen(),
          IntervalTimerScreen(),
          TodoScreen(),
          StatsScreen(),
          StopwatchScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: DS.bg,
          border: Border(top: BorderSide(color: DS.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < tabs.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _index = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            tabs[i].$1,
                            size: 22,
                            color:
                                _index == i ? DS.accent : DS.textTertiary,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tabs[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color:
                                  _index == i ? DS.accent : DS.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
