import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../utils/app_haptics.dart';
import '../l10n/app_localizations.dart';
import '../widgets/animated_gradient_background.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  /// Called the first time a PIN is created (instead of only [onUnlocked]).
  final VoidCallback? onFirstSetupComplete;

  const LockScreen({
    super.key,
    required this.onUnlocked,
    this.onFirstSetupComplete,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const _pinKey = 'etherlog_pin';
  static const _storage = FlutterSecureStorage();

  final LocalAuthentication _auth = LocalAuthentication();

  String _pin = '';
  String? _storedPin;
  bool _isSetup = false; // first launch: create PIN
  bool _confirmMode = false;
  String _firstPin = '';
  String? _error;
  bool _biometricAvailable = false;
  bool _busy = false;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final stored = await _storage.read(key: _pinKey);
    bool bio = false;
    try {
      final can = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      bio = can && supported;
    } catch (_) {
      bio = false;
    }
    if (!mounted) return;
    setState(() {
      _storedPin = stored;
      _isSetup = stored == null || stored.isEmpty;
      _biometricAvailable = bio && !_isSetup;
    });
  }

  Future<void> _onDigit(String d) async {
    if (_busy || _pin.length >= 4) return;
    await AppHaptics.light();
    setState(() {
      _error = null;
      _pin += d;
    });
    if (_pin.length == 4) {
      await _onPinComplete();
    }
  }

  Future<void> _onBackspace() async {
    if (_pin.isEmpty) return;
    await AppHaptics.selection();
    setState(() {
      _error = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _onPinComplete() async {
    setState(() => _busy = true);

    if (_isSetup) {
      if (!_confirmMode) {
        await AppHaptics.medium();
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _confirmMode = true;
          _busy = false;
        });
        return;
      }

      // Confirm PIN
      if (_pin == _firstPin) {
        await _storage.write(key: _pinKey, value: _pin);
        await AppHaptics.medium();
        if (!mounted) return;
        setState(() {
          _storedPin = _pin;
          _isSetup = false;
          _confirmMode = false;
          _pin = '';
          _busy = false;
        });
        if (widget.onFirstSetupComplete != null) {
          widget.onFirstSetupComplete!();
        } else {
          widget.onUnlocked();
        }
      } else {
        await AppHaptics.heavy();
        setState(() {
          _error = l10n.pinsDoNotMatch;
          _pin = '';
          _firstPin = '';
          _confirmMode = false;
          _busy = false;
        });
      }
      return;
    }

    // Unlock with PIN
    if (_pin == _storedPin) {
      await AppHaptics.medium();
      if (!mounted) return;
      setState(() {
        _pin = '';
        _busy = false;
      });
      widget.onUnlocked();
    } else {
      await AppHaptics.heavy();
      setState(() {
        _error = l10n.incorrectPin;
        _pin = '';
        _busy = false;
      });
    }
  }

  Future<void> _onBiometric() async {
    if (_busy || _isSetup) return;
    await AppHaptics.light();
    setState(() => _busy = true);
    try {
      final ok = await _auth.authenticate(
        localizedReason: l10n.unlockEtherlog,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (ok) {
        await AppHaptics.medium();
        if (!mounted) return;
        setState(() => _busy = false);
        widget.onUnlocked();
      } else {
        await AppHaptics.heavy();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = l10n.biometricUnlockFailed;
        });
      }
    } on PlatformException catch (e) {
      await AppHaptics.heavy();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message ?? l10n.biometricNotAvailable;
      });
    } catch (_) {
      await AppHaptics.heavy();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.biometricNotAvailableUsePin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSetup
        ? (_confirmMode ? l10n.confirmPin : l10n.createPin)
        : l10n.enterPin;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 36),
            // Logo
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.medical_services_rounded,
                  size: 44,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppTheme.primary : Colors.transparent,
                    border: Border.all(
                      color: filled ? AppTheme.primary : AppTheme.surfaceLight,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: AppTheme.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const Spacer(),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _keyRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _keyRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _keyRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _isSetup
                          ? const SizedBox(width: 72, height: 72)
                          : _specialKey(
                        icon: _biometricAvailable
                            ? Icons.fingerprint
                            : Icons.backspace_outlined,
                        onTap: _biometricAvailable
                            ? _onBiometric
                            : _onBackspace,
                      ),
                      _digitKey('0'),
                      _specialKey(
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_biometricAvailable)
              TextButton.icon(
                onPressed: _busy ? null : _onBiometric,
                icon: Icon(Icons.fingerprint, color: AppTheme.primary),
                label: Text(
                  l10n.unlockWithBiometric,
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _keyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_digitKey).toList(),
    );
  }

  Widget _digitKey(String d) {
    return _roundButton(
      onTap: () => _onDigit(d),
      child: Text(
        d,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _specialKey({required IconData icon, required VoidCallback onTap}) {
    return _roundButton(
      onTap: onTap,
      child: Icon(icon, color: AppTheme.textSecondary, size: 26),
    );
  }

  Widget _roundButton({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: AppTheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _busy ? null : onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(child: child),
        ),
      ),
    );
  }
}
