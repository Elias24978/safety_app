// lib/services/ad_manager.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  InterstitialAd? _interstitialAd;

  // TODO: Reemplaza con tu ID de bloque de anuncios de AdMob cuando estés listo para producción
  final String _adUnitId = "ca-app-pub-3940256099942544/1033173712"; // ID de prueba de Google

  AdManager() {
    _loadAd(); // Pre-carga el primer anuncio al iniciar el manager
  }

  void _loadAd() {
    // Si ya hay un anuncio cargado o en proceso, no hagas nada.
    // Esto previene el error "Ad for following adId already exists".
    if (_interstitialAd != null) {
      return;
    }

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          // El anuncio se cargó correctamente, lo guardamos para usarlo después.
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Error al cargar el anuncio intersticial: $error');
          // Limpiamos la referencia para poder intentar cargar de nuevo más tarde.
          _interstitialAd = null;
        },
      ),
    );
  }

  void showAdAndNavigate(VoidCallback onAdDismissed) {
    // Primero, comprueba si el anuncio está listo.
    if (_interstitialAd == null) {
      print("Anuncio no listo, navegando directamente.");
      // Si no está listo, ejecuta la acción (navegar) directamente para no bloquear al usuario.
      onAdDismissed();
      // Y solicita un nuevo anuncio para la próxima vez.
      _loadAd();
      return;
    }

    // El anuncio está listo. Configuramos su comportamiento antes de mostrarlo.
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      // ¡MUY IMPORTANTE! Se llama cuando el usuario cierra el anuncio.
      onAdDismissedFullScreenContent: (ad) {
        // 1. Llama a la acción original (en tu caso, navegar a la siguiente pantalla).
        onAdDismissed();
        // 2. Descarta el anuncio para liberar la memoria y el ID. Es crucial.
        ad.dispose();
        // 3. Pide que se cargue el siguiente anuncio para tenerlo listo para la próxima vez.
        _loadAd();
      },
      // Se llama si hubo un error al mostrar el anuncio.
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Error al mostrar el anuncio: $error');
        // 1. Llama a la acción original para no interrumpir al usuario.
        onAdDismissed();
        // 2. Descarta el anuncio fallido.
        ad.dispose();
        // 3. Pide que se cargue uno nuevo.
        _loadAd();
      },
    );

    // Muestra el anuncio que ya teníamos cargado.
    _interstitialAd!.show();

    // Limpiamos la referencia aquí porque un anuncio solo se puede mostrar una vez.
    _interstitialAd = null;
  }
}