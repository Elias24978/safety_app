// lib/services/ad_manager.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  // --- INICIO: CÓDIGO PARA SINGLETON ---
  AdManager._internal() {
    _loadAd(); // Pre-cargamos un anuncio al iniciar.
  }
  static final AdManager _instance = AdManager._internal();
  factory AdManager() {
    return _instance;
  }
  // --- FIN: CÓDIGO PARA SINGLETON ---

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
          // Es mejor usar debugPrint en lugar de print para depuración en Flutter.
          debugPrint('Error al cargar el anuncio intersticial: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void showAdAndNavigate(VoidCallback onAdDismissed) {
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
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}