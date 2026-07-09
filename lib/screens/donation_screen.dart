import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../core/design_system.dart';
import '../core/language_manager.dart';
import '../services/donation_manager.dart';

/// Port of the iOS `DonationView` (tip jar).
class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  DonationManager? _manager;
  bool _thanked = false;
  String? _shownError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _manager = context.read<DonationManager>();
      _manager!.addListener(_onManagerChanged);
      _manager!.loadProducts();
    });
  }

  @override
  void dispose() {
    _manager?.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (!mounted) return;
    final DonationManager dm = _manager!;
    final Translations t = context.read<LanguageManager>().t;
    if (dm.purchaseSuccess && !_thanked) {
      _thanked = true;
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: DS.surface,
          title: Text(t.donationThankYou,
              style: const TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.ok, style: const TextStyle(color: DS.accent)),
            ),
          ],
        ),
      );
    }
    final String? err = dm.errorMessage;
    if (err != null && err != _shownError) {
      _shownError = err;
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: DS.surface,
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          content:
              Text(err, style: const TextStyle(color: DS.textSecondary)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.ok, style: const TextStyle(color: DS.accent)),
            ),
          ],
        ),
      );
    }
  }

  String _emoji(String productId) {
    switch (productId) {
      case DonationManager.tipCoffeeId:
        return '☕';
      case DonationManager.tipTrainingId:
        return '🥊';
      case DonationManager.tipChampionId:
        return '🏆';
      default:
        return '💛';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Translations t = context.watch<LanguageManager>().t;
    final DonationManager dm = context.watch<DonationManager>();

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
                    t.donationSupport,
                    style: DS.headline(17).copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  const SizedBox(height: 12),
                  const Center(
                      child: Text('🥊', style: TextStyle(fontSize: 64))),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      t.donationTitle,
                      textAlign: TextAlign.center,
                      style: DS.display(24).copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      t.donationSubtitle,
                      textAlign: TextAlign.center,
                      style: DS.body(14).copyWith(color: DS.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (dm.isLoading)
                    Column(
                      children: <Widget>[
                        const CircularProgressIndicator(color: DS.accent),
                        const SizedBox(height: 12),
                        Text(t.loading,
                            style: const TextStyle(color: DS.textSecondary)),
                      ],
                    )
                  else if (dm.products.isEmpty)
                    Column(
                      children: <Widget>[
                        const Icon(Icons.wifi_off,
                            size: 40, color: DS.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          t.donationUnavailable,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: DS.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        DSPrimaryButton(
                          label: t.retry,
                          onPressed: dm.loadProducts,
                        ),
                      ],
                    )
                  else
                    for (final ProductDetails p in dm.products)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(DS.radiusCard),
                          onTap:
                              dm.isPurchasing ? null : () => dm.purchase(p),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: DS.surface,
                              borderRadius:
                                  BorderRadius.circular(DS.radiusCard),
                              border: Border.all(color: DS.divider),
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(_emoji(p.id),
                                    style: const TextStyle(fontSize: 30)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        p.title,
                                        style: DS
                                            .headline(16)
                                            .copyWith(color: Colors.white),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p.description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: DS.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  p.price,
                                  style: DS
                                      .headline(17)
                                      .copyWith(color: DS.accent),
                                ),
                              ],
                            ),
                          ),
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
}

/// Bottom sheet shown after 30 days of use — port of `DonationPromptView`.
class DonationPromptSheet extends StatelessWidget {
  const DonationPromptSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: DS.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const DonationPromptSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Translations t = context.watch<LanguageManager>().t;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('🥊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              t.donationTitle,
              textAlign: TextAlign.center,
              style: DS.display(24).copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              t.donationSubtitle,
              textAlign: TextAlign.center,
              style: DS.body(14).copyWith(color: DS.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: DS.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DS.radiusPill),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DonationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: Text(
                  t.donationSupport,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                t.cancel,
                style: const TextStyle(color: DS.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
