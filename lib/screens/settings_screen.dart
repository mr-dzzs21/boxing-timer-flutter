import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/design_system.dart';
import '../core/language_manager.dart';
import '../services/user_settings.dart';
import 'donation_screen.dart';

const String _kAppVersion = '1.3.0 (1)';
const String _kPlayStoreId = 'com.diyarkaymaz.boxintervaltimer';

/// Port of the iOS `SettingsView` — dark cards instead of a system Form.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LanguageManager lang = context.watch<LanguageManager>();
    final Translations t = lang.t;
    final UserSettings settings = context.watch<UserSettings>();

    return Scaffold(
      backgroundColor: DS.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(
                    t.settingsTitle,
                    style: DS.headline(17).copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _section(t.audioHaptic, <Widget>[
                    _toggle(t.soundEnabled, settings.soundEnabled,
                        settings.setSoundEnabled),
                    const Divider(color: DS.divider, height: 1),
                    _toggle(t.vibrationEnabled, settings.vibrationEnabled,
                        settings.setVibrationEnabled),
                    const Divider(color: DS.divider, height: 1),
                    _toggle(t.warningEnabled, settings.warningEnabled,
                        settings.setWarningEnabled),
                    const Divider(color: DS.divider, height: 1),
                    _toggle(t.comboTrainer, settings.comboTrainerEnabled,
                        settings.setComboTrainerEnabled),
                    if (settings.comboTrainerEnabled) ...<Widget>[
                      const Divider(color: DS.divider, height: 1),
                      DSStepperRow(
                        label: t.comboInterval,
                        value: settings.comboIntervalSeconds,
                        unit: 's',
                        min: 4,
                        max: 30,
                        step: 2,
                        onChanged: (int v) =>
                            settings.setComboIntervalSeconds(v),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),
                  _section('Todos', <Widget>[
                    _toggle(
                      t.todoNotifications,
                      settings.todoNotificationsEnabled,
                      settings.setTodoNotificationsEnabled,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(DS.radiusCard),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DonationScreen(),
                      ),
                    ),
                    child: DSCard(
                      child: Row(
                        children: <Widget>[
                          const Text('🙏', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.donationSupport,
                              style:
                                  DS.body().copyWith(color: Colors.white),
                            ),
                          ),
                          const Icon(Icons.favorite,
                              color: DS.accent, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(t.language, <Widget>[
                    for (final AppLanguage l in AppLanguage.values) ...<Widget>[
                      if (l != AppLanguage.values.first)
                        const Divider(color: DS.divider, height: 1),
                      InkWell(
                        onTap: () => lang.setLanguage(l),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  l.displayName,
                                  style: DS
                                      .body()
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                              if (lang.current == l)
                                const Icon(Icons.check,
                                    color: DS.accent, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),
                  _section(t.about, <Widget>[
                    _kv(t.version, _kAppVersion),
                    const Divider(color: DS.divider, height: 1),
                    _kv(t.developer, 'Diyar Kaymaz'),
                    const Divider(color: DS.divider, height: 1),
                    _link(
                      icon: Icons.mail_outline,
                      iconColor: DS.accent,
                      title: t.feedbackButton,
                      onTap: () => _open(
                        'mailto:box.timer.app@gmail.com?subject=Feedback%20-%20Box%20Interval%20Timer',
                      ),
                    ),
                    const Divider(color: DS.divider, height: 1),
                    _link(
                      icon: Icons.star,
                      iconColor: Colors.amber,
                      title: t.rateApp,
                      onTap: _openPlayStore,
                    ),
                    const Divider(color: DS.divider, height: 1),
                    _link(
                      icon: Icons.lock_outline,
                      iconColor: DS.textSecondary,
                      title: t.privacyPolicy,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _section(t.presetsInfo, <Widget>[
                    const Text(
                      '• Boxen: 12x3min\n'
                      '• MMA: 3x5min\n'
                      '• K1: 3x3min\n'
                      '• Muay Thai: 5x3min\n'
                      '• BJJ: 1x5min\n'
                      '• Judo: 1x4min\n'
                      '• Ringen: 3x2min\n'
                      '• Taekwondo: 3x2min',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: DS.textSecondary,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: DS.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        DSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }

  static Widget _toggle(
      String title, bool value, Future<void> Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: DS.body().copyWith(color: Colors.white)),
      value: value,
      activeTrackColor: DS.accent,
      onChanged: (bool v) => onChanged(v),
    );
  }

  static Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child:
                Text(label, style: DS.body().copyWith(color: Colors.white)),
          ),
          Text(value, style: DS.body().copyWith(color: DS.textSecondary)),
        ],
      ),
    );
  }

  static Widget _link({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child:
                  Text(title, style: DS.body().copyWith(color: Colors.white)),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: DS.textTertiary),
          ],
        ),
      ),
    );
  }

  static Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  static Future<void> _openPlayStore() async {
    try {
      final bool ok = await launchUrl(
        Uri.parse('market://details?id=$_kPlayStoreId'),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw Exception('no market');
    } catch (_) {
      await _open(
          'https://play.google.com/store/apps/details?id=$_kPlayStoreId');
    }
  }
}

/// Port of the iOS `PrivacyPolicyView`.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.watch<LanguageManager>().t;

    return Scaffold(
      backgroundColor: DS.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(
                    t.privacyNavTitle,
                    style: DS.headline(17).copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Text('🥊 Box Interval Timer',
                      style: DS.display(26).copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(t.privacyDate,
                      style: const TextStyle(
                          fontSize: 12, color: DS.textSecondary)),
                  const SizedBox(height: 16),
                  DSCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.verified_user,
                            color: DS.phaseRound, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.privacySummary,
                            style: DS.body(14).copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _policy(Icons.storage, t.privacyS1Title, t.privacyS1Text),
                  _policy(Icons.wifi_off, t.privacyS2Title, t.privacyS2Text),
                  _policy(Icons.credit_card, t.privacyS3Title, t.privacyS3Text),
                  _policy(Icons.notifications_none, t.privacyS4Title,
                      t.privacyS4Text),
                  _policy(Icons.mail_outline, 'Kontakt',
                      'box.timer.app@gmail.com'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => SettingsScreen._open(
                      'https://mr-dzzs21.github.io/boxing-timer-flutter/privacy-policy.html',
                    ),
                    icon: const Icon(Icons.public, color: DS.accent, size: 18),
                    label: Text(
                      t.privacyOpenBrowser,
                      style: const TextStyle(color: DS.accent),
                    ),
                  ),
                  const Center(
                    child: Text(
                      '© 2026 Diyar Kaymaz',
                      style:
                          TextStyle(fontSize: 12, color: DS.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _policy(IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: DS.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: DS.headline(17).copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(text, style: DS.body(14).copyWith(color: DS.textSecondary)),
          ],
        ),
      ),
    );
  }
}
