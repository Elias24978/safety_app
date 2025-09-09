// lib/services/ad_manager.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- 1. Se importa SharedPreferences

class AdManager {
  // --- Código para Singleton (Sin cambios) ---
  AdManager._internal() {
    _loadAd();
  }
  static final AdManager instance = AdManager._internal();
  factory AdManager() {
    return instance;
  }

  InterstitialAd? _interstitialAd;
  final String _adUnitId = "ca-app-pub-3940256099942544/1033173712"; // ID de prueba.

  void _loadAd() {
    if (_interstitialAd != null) {
      return;
    }
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Error al cargar el anuncio intersticial: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  // --- 👇 LÓGICA DE TIEMPO ACTUALIZADA ---
  Future<void> showAdAndNavigate(VoidCallback onAdDismissed) async {
    // Se ajusta el intervalo a 2.5 minutos.
    const double adIntervalMinutes = 2.5;

    final prefs = await SharedPreferences.getInstance();
    final lastAdTimestamp = prefs.getInt('lastAdTimestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Se calcula si ya ha pasado el tiempo necesario.
    if (currentTime - lastAdTimestamp < (adIntervalMinutes * 60 * 1000)) {
      debugPrint("No ha pasado suficiente tiempo para mostrar otro anuncio. Navegando...");
      onAdDismissed(); // Navega directamente sin anuncio.
      return;
    }

    if (_interstitialAd == null) {
      debugPrint("Anuncio no listo, navegando directamente.");
      onAdDismissed();
      _loadAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        onAdDismissed();
        ad.dispose();
        _loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Error al mostrar el anuncio: $error');
        onAdDismissed();
        ad.dispose();
        _loadAd();
      },
      // Cuando el anuncio se muestra, se guarda la hora para reiniciar el contador.
      onAdShowedFullScreenContent: (ad) async {
        await prefs.setInt('lastAdTimestamp', DateTime.now().millisecondsSinceEpoch);
        debugPrint("Anuncio mostrado. Guardando la hora.");
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }
}