import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId; // Если null, используется текущий пользователь
  final bool isMyProfile;

  const UserProfileScreen({
    Key? key,
    this.userId,
    this.isMyProfile = false,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _targetUserId {
    return widget.userId ?? _auth.currentUser?.uid ?? '';
  }

  bool get _isMyProfile {
    return widget.isMyProfile || _auth.currentUser?.uid == _targetUserId;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final targetUserId = _targetUserId;
      if (targetUserId.isEmpty) {
        appLogger.w('Cannot load user data: no userId provided and user not authenticated');
        setState(() => _isLoading = false);
        return;
      }

      final user = await UserService.getUserData(targetUserId);
      if (user != null) {
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _bioController.text = user.bio ?? '';
        });
      } else {
        appLogger.w('User data not found for userId: $targetUserId');
      }
    } catch (e) {
      appLogger.e('Error loading user data for userId: ${_targetUserId}', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Загружаем аватар...')),
        );

        final imageUrl =
            await StorageService.uploadUserAvatar(File(image.path));
        await UserService.updateUserData(photoURL: imageUrl);

        await _loadUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Аватар обновлен! ✅')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки аватара: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    try {
      await UserService.updateUserData(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      setState(() => _isEditing = false);
      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Профиль сохранен! ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          title: Text('Профиль'),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Text('Пользователь не найден',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование' : 'Профиль'),
        backgroundColor: Colors.black,
        actions: _isMyProfile
            ? [
                if (_isEditing)
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed: _saveProfile,
                  )
                else
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            // Аватар
            GestureDetector(
              onTap: _isMyProfile && !_isEditing ? _uploadAvatar : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurple,
                    backgroundImage: _user!.photoURL != null
                        ? NetworkImage(_user!.photoURL!)
                        : null,
                    child: _user!.photoURL == null
                        ? Text(
                            _user!.name[0].toUpperCase(),
                            style: TextStyle(fontSize: 36, color: Colors.white),
                          )
                        : null,
                  ),
                  if (_isMyProfile && !_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.camera_alt, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Имя
            if (_isEditing && _isMyProfile)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
              )
            else
              Text(
                _user!.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

            SizedBox(height: 8),

            // Email
            Text(
              _user!.email,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            SizedBox(height: 16),

            // Био
            if (_isEditing && _isMyProfile)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _bioController,
                  maxLines: 3,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Описание профиля',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    hintText: 'Расскажите о себе...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else if (_user!.bio != null && _user!.bio!.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _user!.bio!,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            SizedBox(height: 30),

            // Информация
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('ID пользователя', _user!.uid.substring(0, 8)),
                  Divider(),
                  _buildInfoRow(
                      'Зарегистрирован',
                      _user!.createdAt != null
                          ? '${_user!.createdAt!.day}.${_user!.createdAt!.month}.${_user!.createdAt!.year}'
                          : 'Неизвестно'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
          Spacer(),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
