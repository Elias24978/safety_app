import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final String _apiKeyAndroid = "goog_yYQLcQDPLIxEXCfmhKJMIdbYkQc";

  bool _isInitialized = false;

  // ✅ MAPA ELIMINADO: Ya no se necesita mapa manual para Opción B

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (kDebugMode) {
        // ✅ LogLevel ERROR para producción/seguridad
        await Purchases.setLogLevel(LogLevel.error);
      }

      PurchasesConfiguration? configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_apiKeyAndroid);
      }

      if (configuration != null) {
        await Purchases.configure(configuration);
        _isInitialized = true;
        debugPrint("💰 [PurchaseService] Inicializado (Dinámico v9.3.0).");
      }
    } catch (e) {
      debugPrint("❌ [PurchaseService] Error init: $e");
    }
  }

  // ✅ Método actualizado: Recibe el storeProductId directamente desde el objeto Curso
  Future<Package?> getOfferingForCourse(String? storeProductId) async {
    if (storeProductId == null || storeProductId.isEmpty) {
      debugPrint("⚠️ [PurchaseService] Curso sin ID de tienda configurado en Airtable.");
      return null;
    }

    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        try {
          // Buscamos dinámicamente el paquete que coincida con el ID de Airtable
          return offerings.current!.availablePackages.firstWhere(
                  (p) => p.storeProduct.identifier == storeProductId || p.identifier == storeProductId
          );
        } catch (_) {}
      }

      debugPrint("⚠️ [PurchaseService] No hay oferta activa en Google para: $storeProductId");
      return null;
    } catch (e) {
      debugPrint("❌ [PurchaseService] Error buscando oferta: $e");
      return null;
    }
  }

  /// Compra con manejo de 'Ya Comprado' (Re-certificación)
  Future<bool> purchasePackage(Package package) async {
    try {
      debugPrint("🛒 [PurchaseService] Comprando: ${package.storeProduct.identifier}");

      // ✅ CORRECCIÓN v9.3.0:
      // 1. Usamos PurchaseParams.package()
      // 2. No asignamos el resultado a CustomerInfo para evitar errores de tipo
      await Purchases.purchase(
        PurchaseParams.package(package),
      );

      // ✅ Si llegamos aquí sin excepción, asumimos éxito (consumible comprado)
      return true;

    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);

      // ✅ MANEJO DE 'YA COMPRADO':
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        debugPrint("✅ [PurchaseService] Producto ya activo (Re-certificación). Procediendo...");
        return true;
      }

      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint("❌ [PurchaseService] Error compra: $e");
      } else {
        debugPrint("USER [PurchaseService] Cancelado por usuario.");
      }
      return false;
    } catch (e) {
      debugPrint("❌ [PurchaseService] Error general: $e");
      return false;
    }
  }

  Future<bool> checkCourseAccess(String? storeProductId) async {
    if (storeProductId == null || storeProductId.isEmpty) return false;

    try {
      CustomerInfo info = await Purchases.getCustomerInfo();

      // 🚨 IMPORTANTE: Para consumibles puros sin entitlement, esto suele ser false.
      // Solo verificamos Entitlements activos por si acaso.
      bool entitled = info.entitlements.all.values.any((e) =>
      e.isActive && (e.productIdentifier == storeProductId || e.identifier == storeProductId)
      );

      debugPrint("🔍 [Access] $storeProductId -> Entitlement Activo: $entitled");
      return entitled;

    } catch (e) {
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      debugPrint("✅ [PurchaseService] Restaurado.");
    } catch (e) {
      debugPrint("❌ [PurchaseService] Error restaurando: $e");
    }
  }
}