import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumService {
  static const String premiumProductId = 'premium_subscription';
  static final InAppPurchase _iap = InAppPurchase.instance;

  static Future<bool> isAvailable() => _iap.isAvailable();

  static StreamSubscription<List<PurchaseDetails>>? _sub;

  static Future<void> initialize(
      {required void Function(bool active) onUpdate}) async {
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        if (p.productID == premiumProductId &&
            p.status == PurchaseStatus.purchased) {
          onUpdate(true);
        }
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }
      }
    });
  }

  static Future<void> buyPremium() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    final response = await _iap.queryProductDetails({premiumProductId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty)
      return;
    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static void dispose() {
    _sub?.cancel();
  }
}
