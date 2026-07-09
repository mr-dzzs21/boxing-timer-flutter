// Tip-jar in-app purchases — port of iOS DonationManager.swift (StoreKit 2).
//
// Product IDs must exist identically in App Store Connect / Play Console
// (type: consumable). Store-unavailable is handled gracefully: products
// simply stay empty and no error is surfaced.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class DonationManager extends ChangeNotifier {
  /// ⚠️ Must match App Store Connect / Play Console exactly (consumables).
  static const String tipCoffeeId = 'box.tip.coffee'; // 0,99 € – Kleiner Kaffee
  static const String tipTrainingId = 'box.tip.training'; // 2,99 € – Training
  static const String tipChampionId = 'box.tip.champion'; // 11,99 € – Danke

  static const Set<String> _productIds = <String>{
    tipCoffeeId,
    tipTrainingId,
    tipChampionId,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> products = <ProductDetails>[];
  bool isLoading = false;
  bool isPurchasing = false;
  bool purchaseSuccess = false;
  String? errorMessage;

  DonationManager() {
    // iOS: Transaction.updates listener that finishes verified transactions.
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        errorMessage = error.toString();
        isPurchasing = false;
        notifyListeners();
      },
    );
  }

  /// Loads the tip products, sorted by ascending price (as iOS does).
  Future<void> loadProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        // Store unavailable (no Play account, emulator, ...) — degrade
        // gracefully with an empty product list and no error.
        products = <ProductDetails>[];
      } else {
        final response = await _iap.queryProductDetails(_productIds);
        if (response.error != null) {
          errorMessage = response.error!.message;
        }
        products = List<ProductDetails>.of(response.productDetails)
          ..sort((ProductDetails a, ProductDetails b) =>
              a.rawPrice.compareTo(b.rawPrice));
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Starts a consumable purchase. Completion (success/error/cancel) arrives
  /// asynchronously via the purchase stream.
  Future<void> purchase(ProductDetails product) async {
    if (isPurchasing) return;
    isPurchasing = true;
    purchaseSuccess = false;
    errorMessage = null;
    notifyListeners();
    try {
      final started = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        isPurchasing = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e.toString();
      isPurchasing = false;
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Keep the spinner; a terminal status follows.
          break;
        case PurchaseStatus.purchased:
          purchaseSuccess = true;
          isPurchasing = false;
          break;
        case PurchaseStatus.restored:
          // Consumables are not restorable; just finish the transaction.
          isPurchasing = false;
          break;
        case PurchaseStatus.error:
          // iOS: errorMessage = error.localizedDescription.
          errorMessage = purchase.error?.message ?? 'Purchase failed';
          isPurchasing = false;
          break;
        case PurchaseStatus.canceled:
          // iOS: .userCancelled → no error, just stop.
          isPurchasing = false;
          break;
      }
      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (e) {
          debugPrint('DonationManager: completePurchase failed: $e');
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
