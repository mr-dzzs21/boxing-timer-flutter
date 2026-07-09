import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/design_system.dart';
import '../core/language_manager.dart';

/// Port of the iOS `OnboardingView` — 4 pages on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final Translations t = context.watch<LanguageManager>().t;

    final List<(String, Color, String, String)> pages =
        <(String, Color, String, String)>[
      ('🥊', DS.accent, t.onboarding1Title, t.onboarding1Text),
      ('⏱', DS.phaseRound, t.onboarding2Title, t.onboarding2Text),
      ('🏃', DS.phaseDone, t.onboarding3Title, t.onboarding3Text),
      ('📊', const Color(0xFFB07CF7), t.onboarding4Title, t.onboarding4Text),
    ];

    return Scaffold(
      backgroundColor: DS.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  t.onboardingSkip,
                  style: const TextStyle(color: DS.textSecondary),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (int i) => setState(() => _page = i),
                itemBuilder: (BuildContext context, int index) {
                  final (String emoji, Color color, String title, String text) =
                      pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 72)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: DS.display(28).copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          style:
                              DS.body(15).copyWith(color: DS.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < pages.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i == _page ? DS.accent : DS.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: DS.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.radiusPill),
                    ),
                  ),
                  onPressed: () {
                    if (_page < pages.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  child: Text(
                    _page < pages.length - 1
                        ? t.onboardingNext
                        : t.onboardingStart,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
