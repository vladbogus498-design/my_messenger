import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _darkTheme = true;
  bool _notifications = true;
  bool _privacyMode = true;
  String _selfDestructTimer = '5 seconds';
  String _userStatus = 'Online';

  final List<String> _timerOptions = [
    '5 seconds',
    '1 minute',
    '1 hour',
    '1 day',
    '1 week'
  ];
  final List<String> _statusOptions = [
    'Online',
    'Busy',
    'Away',
    'Invisible',
    'Do Not Disturb'
  ];

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.deepPurple,
              child: Text(
                _user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Profile picture coming soon!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CLOSE', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Online':
        return Colors.green;
      case 'Busy':
        return Colors.orange;
      case 'Away':
        return Colors.yellow;
      case 'Invisible':
        return Colors.grey;
      case 'Do Not Disturb':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Online':
        return Icons.circle;
      case 'Busy':
        return Icons.work;
      case 'Away':
        return Icons.access_time;
      case 'Invisible':
        return Icons.visibility_off;
      case 'Do Not Disturb':
        return Icons.notifications_off;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            SizedBox(height: 40),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple,
              child: Text(
                _user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _user?.email ?? 'Unknown User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            // Status Selector
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(_userStatus),
                      color: _getStatusColor(_userStatus), size: 16),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _userStatus,
                    dropdownColor: Colors.grey[800],
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    underline: Container(),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                    onChanged: (value) {
                      setState(() => _userStatus = value!);
                    },
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Icon(_getStatusIcon(status),
                                color: _getStatusColor(status), size: 16),
                            SizedBox(width: 8),
                            Text(status),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),
            Text(
              'Member since: ${DateTime.now().toString().substring(0, 10)}',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 30),

            // Account Info Card
            _buildInfoCard(
              title: 'ACCOUNT INFORMATION',
              children: [
                _buildInfoRow(
                    'User ID', _user?.uid.substring(0, 8) ?? 'Unknown'),
                _buildInfoRow('Email Verified',
                    _user?.emailVerified.toString() ?? 'false'),
                _buildInfoRow('Account Type', 'PREMIUM 🚀'),
                _buildInfoRow('Storage Used', '15% of 1GB'),
                _buildInfoRow('Current Status', _userStatus),
              ],
            ),

            SizedBox(height: 20),

            // Privacy & Settings Card
            _buildInfoCard(
              title: 'PRIVACY & SETTINGS',
              children: [
                // Self-Destruct Timer
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.deepPurple, size: 20),
                      SizedBox(width: 12),
                      Text('Self-Destruct Timer',
                          style: TextStyle(color: Colors.white)),
                      Spacer(),
                      DropdownButton<String>(
                        value: _selfDestructTimer,
                        dropdownColor: Colors.grey[800],
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        onChanged: (value) {
                          setState(() => _selfDestructTimer = value!);
                        },
                        items: _timerOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Privacy Mode
                _buildSwitchRow(
                  'Privacy Mode',
                  'Hide typing status',
                  _privacyMode,
                  (value) => setState(() => _privacyMode = value),
                ),

                // Dark Theme
                _buildSwitchRow(
                  'Dark Theme',
                  'Always stay dark',
                  _darkTheme,
                  (value) => setState(() => _darkTheme = value),
                ),
// Notifications
                _buildSwitchRow(
                  'Notifications',
                  'Message alerts',
                  _notifications,
                  (value) => setState(() => _notifications = value),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Stats Card
            _buildInfoCard(
              title: 'YOUR STATS',
              children: [
                _buildStatRow('Chats Created', '12', Icons.chat),
                _buildStatRow('Messages Sent', '47', Icons.message),
                _buildStatRow('Self-Destructed', '23', Icons.auto_delete),
                _buildStatRow('Privacy Score', '98%', Icons.security),
              ],
            ),

            SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showEditDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                    child: Text('EDIT PROFILE'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('LOGOUT'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // App Info
            Text(
              'DarkKick v1.0.0 • Messages that leave no trace',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(color: Colors.grey, fontSize: 14)),
          SizedBox(width: 8),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white, fontSize: 14)),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 16),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
          Spacer(),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
