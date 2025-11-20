import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_service.dart';
import '../services/encryption_service.dart';
import '../utils/logger.dart';

class SecuritySettingsScreen extends StatefulWidget {
  @override
  _SecuritySettingsScreenState createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricEnabled = false;
  bool _encryptionEnabled = false;
  bool _twoFactorEnabled = false;
  bool _screenshotBlocking = false;
  bool _incognitoKeyboard = false;
  String _autoLockTimer = '1 minute';

  final List<String> _lockTimerOptions = [
    'Immediately',
    '30 seconds',
    '1 minute',
    '5 minutes',
    '10 minutes',
    '30 minutes',
    'Never'
  ];

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometricEnabled') ?? false;
      _encryptionEnabled = prefs.getBool('encryptionEnabled') ?? false;
      _twoFactorEnabled = prefs.getBool('twoFactorEnabled') ?? false;
      _screenshotBlocking = prefs.getBool('screenshotBlocking') ?? false;
      _incognitoKeyboard = prefs.getBool('incognitoKeyboard') ?? false;
      _autoLockTimer = prefs.getString('autoLockTimer') ?? '1 minute';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
    appLogger.d('Security setting saved: $key = $value');
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final canAuth = await BiometricService.canAuthenticate();
      if (!canAuth) {
        _showMessage(
            'Biometric authentication not available on this device',
            isError: true);
        return;
      }

      final authenticated = await BiometricService.authenticate();
      if (authenticated) {
        setState(() => _biometricEnabled = true);
        await _saveSetting('biometricEnabled', true);
        _showMessage('Biometric authentication enabled! 🔐');
      } else {
        _showMessage('Authentication failed', isError: true);
      }
    } else {
      setState(() => _biometricEnabled = false);
      await _saveSetting('biometricEnabled', false);
      _showMessage('Biometric authentication disabled');
    }
  }

  Future<void> _toggleEncryption(bool value) async {
    setState(() => _encryptionEnabled = value);
    await _saveSetting('encryptionEnabled', value);
    if (value) {
      _showMessage('End-to-end encryption enabled! 🔒');
    } else {
      _showMessage('Encryption disabled');
    }
  }

  Future<void> _testEncryption() async {
    final testMessage = 'Hello, this is a secret message! 🔐';
    final password = 'test_password_123';

    // Шифрование
    final encrypted = EncryptionService.encryptText(testMessage, password);
    appLogger.d('Encryption test - Encrypted: ${encrypted.substring(0, encrypted.length > 50 ? 50 : encrypted.length)}...');

    // Дешифрование
    final decrypted = EncryptionService.decryptText(encrypted, password);
    appLogger.d('Encryption test - Decrypted successfully: ${decrypted == testMessage}');

    if (decrypted == testMessage) {
      _showMessage('✅ Encryption test successful!\nOriginal: $testMessage');
    } else {
      _showMessage('❌ Encryption test failed!', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Security & Privacy'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('🔐 AUTHENTICATION', Icons.security),
            _buildSecurityCard(
              children: [
                _buildSwitchTile(
                  title: 'Biometric Lock',
                  subtitle: 'Use fingerprint or face to unlock app',
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                  icon: Icons.fingerprint,
                ),
                Divider(color: Colors.grey[700]),
                _buildSwitchTile(
                  title: 'Two-Factor Authentication',
                  subtitle: 'Add extra layer of security',
                  value: _twoFactorEnabled,
                  onChanged: (value) {
                    setState(() => _twoFactorEnabled = value);
                    _saveSetting('twoFactorEnabled', value);
                  },
                  icon: Icons.verified_user,
                ),
                Divider(color: Colors.grey[700]),
                _buildDropdownTile(
                  title: 'Auto-Lock Timer',
                  subtitle: 'Lock app after inactivity',
                  value: _autoLockTimer,
                  items: _lockTimerOptions,
                  onChanged: (value) {
                    setState(() => _autoLockTimer = value!);
                    _saveSetting('autoLockTimer', value);
                  },
                  icon: Icons.timer,
                ),
              ],
            ),

            SizedBox(height: 20),

            _buildSectionHeader('🔒 ENCRYPTION', Icons.lock),
            _buildSecurityCard(
              children: [
                _buildSwitchTile(
                  title: 'End-to-End Encryption',
                  subtitle: 'Encrypt all messages automatically',
                  value: _encryptionEnabled,
                  onChanged: _toggleEncryption,
                  icon: Icons.lock_outline,
                ),
                Divider(color: Colors.grey[700]),
                ListTile(
                  leading: Icon(Icons.science, color: Colors.deepPurple),
                  title: Text('Test Encryption',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('Test message encryption/decryption',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 16),
                  onTap: _testEncryption,
                ),
              ],
            ),

            SizedBox(height: 20),

            _buildSectionHeader('🛡️ PRIVACY', Icons.privacy_tip),
            _buildSecurityCard(
              children: [
                _buildSwitchTile(
                  title: 'Block Screenshots',
                  subtitle: 'Prevent screenshots in chats',
                  value: _screenshotBlocking,
                  onChanged: (value) {
                    setState(() => _screenshotBlocking = value);
                    _saveSetting('screenshotBlocking', value);
                    _showMessage(
                        'Screenshot blocking ${value ? "enabled" : "disabled"}');
                  },
                  icon: Icons.screenshot_monitor,
                ),
                Divider(color: Colors.grey[700]),
                _buildSwitchTile(
                  title: 'Incognito Keyboard',
                  subtitle: 'Disable keyboard learning',
                  value: _incognitoKeyboard,
                  onChanged: (value) {
                    setState(() => _incognitoKeyboard = value);
                    _saveSetting('incognitoKeyboard', value);
                  },
                  icon: Icons.keyboard_hide,
                ),
              ],
            ),

            SizedBox(height: 20),

            _buildSectionHeader('⚠️ DANGER ZONE', Icons.warning),
            _buildSecurityCard(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.delete_forever, color: Colors.red, size: 28),
                  title: Text('Delete All Messages',
                      style: TextStyle(color: Colors.red)),
                  subtitle: Text('Permanently delete all chat data',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: Colors.red, size: 16),
                  onTap: () => _showDeleteConfirmation(context),
                ),
                Divider(color: Colors.grey[700]),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.orange, size: 28),
                  title: Text('Clear All Sessions',
                      style: TextStyle(color: Colors.orange)),
                  subtitle: Text('Log out from all devices',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: Colors.orange, size: 16),
                  onTap: () => _showMessage('Session clearing coming soon!'),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Security Score
            _buildSecurityScore(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard({required List<Widget> children}) {
    return Card(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: Colors.grey[800],
        style: TextStyle(color: Colors.white, fontSize: 12),
        underline: Container(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSecurityScore() {
    int score = 0;
    int maxScore = 6;

    if (_biometricEnabled) score++;
    if (_encryptionEnabled) score++;
    if (_twoFactorEnabled) score++;
    if (_screenshotBlocking) score++;
    if (_incognitoKeyboard) score++;
    if (_autoLockTimer != 'Never') score++;

    double percentage = (score / maxScore) * 100;
    Color scoreColor = percentage >= 80
        ? Colors.green
        : percentage >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: scoreColor, size: 24),
                SizedBox(width: 8),
                Text(
                  'Security Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 8,
            ),
            SizedBox(height: 12),
            Text(
              '$score out of $maxScore security features enabled',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('⚠️ Delete All Messages?',
            style: TextStyle(color: Colors.red)),
        content: Text(
          'This will permanently delete all your messages and chat history. This action cannot be undone!',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Message deletion coming soon!', isError: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }
}
