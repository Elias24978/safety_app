import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:safety_app/screens/auth_gate.dart';
import 'package:safety_app/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Visibilidad
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Requisitos
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasDigits = false;

  // Términos
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordRequirements);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.removeListener(_updatePasswordRequirements);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordRequirements() {
    final text = _passwordController.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasUppercase = text.contains(RegExp(r'[A-Z]'));
      _hasDigits = text.contains(RegExp(r'[0-9]'));
    });
  }

  // --- Registro con Email ---
  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog("Por favor completa todos los campos.");
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog("Las contraseñas no coinciden.");
      return;
    }
    if (!_hasMinLength || !_hasUppercase || !_hasDigits) {
      _showErrorDialog("La contraseña no cumple con los requisitos de seguridad.");
      return;
    }
    if (!_acceptTerms) {
      _showErrorDialog("Debes aceptar los Términos y Condiciones para continuar.");
      return;
    }

    _showLoadingDialog();

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        _navigateToAuthGate();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      String mensaje = "Ocurrió un error.";
      if (e.code == 'email-already-in-use') mensaje = "Este correo ya está registrado.";
      if (e.code == 'weak-password') mensaje = "La contraseña es muy débil.";
      if (e.code == 'invalid-email') mensaje = "El formato del correo no es válido.";
      _showErrorDialog(mensaje);
    }
  }

  // --- Registro con Google (Actualizado) ---
  Future<void> _signInWithGoogle() async {
    if (!_acceptTerms) {
      _showErrorDialog("Debes aceptar los Términos y Condiciones primero.");
      return;
    }

    _showLoadingDialog();

    try {
      // --- LÍNEA NUEVA ---
      // Forzamos la desconexión de Google anterior para asegurar que
      // siempre aparezca la lista de cuentas para elegir.
      await GoogleSignIn().signOut();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pop(context);
        _navigateToAuthGate();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorDialog("Error al iniciar con Google.");
    }
  }

  // --- Helpers ---
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _navigateToAuthGate() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Atención'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Términos y Condiciones"),
        content: const SingleChildScrollView(
          child: Text(
              "TÉRMINOS Y CONDICIONES DE USO\n\n"
                  "1. Aceptación de los Términos\n"
                  "Al descargar o utilizar la aplicación Safety App, usted acepta estar legalmente vinculado por estos términos.\n\n"
                  "2. Uso de la Aplicación\n"
                  "La aplicación está destinada a facilitar la gestión de seguridad. Usted se compromete a utilizarla únicamente con fines legales.\n\n"
                  "3. Cuentas y Seguridad\n"
                  "Usted es responsable de mantener la confidencialidad de su contraseña.\n\n"
                  "4. Modificaciones\n"
                  "Nos reservamos el derecho de modificar estos términos en cualquier momento."
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
          ElevatedButton(
            onPressed: () {
              setState(() => _acceptTerms = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2A2A2A)),
            child: const Text("Aceptar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aviso de Privacidad"),
        content: const SingleChildScrollView(
          child: Text(
              "AVISO DE PRIVACIDAD\n\n"
                  "1. Información Recopilada\n"
                  "Recopilamos información personal como nombre y correo electrónico.\n\n"
                  "2. Uso de Datos\n"
                  "Sus datos se utilizan para autenticación y soporte.\n\n"
                  "3. Seguridad de Datos\n"
                  "Implementamos medidas de seguridad para proteger su información.\n\n"
                  "4. Sus Derechos\n"
                  "Puede solicitar el acceso o eliminación de sus datos."
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar"))],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: isMet ? Colors.green[700] : Colors.grey, fontSize: 12),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFF535C68);
    final linkColor = const Color(0xFF3E64FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text("¡Regístrate!", textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              Text("Crea una cuenta, es gratis", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildRequirementRow("Mínimo 8 caracteres", _hasMinLength),
              _buildRequirementRow("Al menos un número", _hasDigits),
              _buildRequirementRow("Al menos una mayúscula", _hasUppercase),
              const SizedBox(height: 15),

              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirmar Contraseña",
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24, width: 24,
                    child: Checkbox(
                      value: _acceptTerms,
                      activeColor: Colors.black,
                      onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: "Al registrarte aceptas nuestros ",
                        style: TextStyle(color: textColor, fontSize: 13),
                        children: [
                          TextSpan(
                            text: "Términos y Condiciones",
                            style: TextStyle(color: linkColor, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                          ),
                          const TextSpan(text: " y "),
                          TextSpan(
                            text: "Aviso de Privacidad",
                            style: TextStyle(color: linkColor, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()..onTap = _showPrivacyDialog,
                          ),
                          const TextSpan(text: " de Safety App."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              MaterialButton(
                height: 55,
                minWidth: double.infinity,
                color: const Color(0xff2A2A2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                onPressed: _signUp,
                child: const Text("Registrarse", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),

              const SizedBox(height: 20),
              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("O", style: TextStyle(color: Colors.grey))), Expanded(child: Divider())]),
              const SizedBox(height: 20),

              OutlinedButton(
                onPressed: _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/google_logo.png', height: 24),
                    const SizedBox(width: 10),
                    const Text("REGISTRARSE CON GOOGLE", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Ya tienes una cuenta? "),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text("Inicia sesión", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}