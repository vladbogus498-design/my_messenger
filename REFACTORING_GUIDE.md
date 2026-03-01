# 🛠️ REFACTORING GUIDE - Переход на новую архитектуру

## 📋 Обзор изменений

Этот PR переносит приложение на чистую, масштабируемую архитектуру с:

1. **Repository Pattern** - отделение UI от бизнес-логики
2. **Secure Key Management** - приватные ключи в Keychain/Keystore
3. **Offline-first** - локальное кеширование через Hive
4. **Result<T> Pattern** - типизированная обработка ошибок
5. **SSL Pinning** - защита от MITM атак

---

## 🏗️ Новая структура проекта

```
lib/
├── domain/                          # Доменный слой (бизнес-логика)
│   ├── entities/
│   │   └── result.dart             # Unified Result<T> type
│   ├── failures/
│   │   └── app_failure.dart        # Error hierarchy
│   └── services/
│       └── security_service.dart   # Abstract security contract
│
├── data/                            # Слой данных
│   ├── datasources/
│   │   ├── local/
│   │   │   └── hive_local_datasource.dart      # Hive cache
│   │   ├── remote/
│   │   │   └── firebase_remote_datasource.dart # Firestore adapter
│   │   ├── secure/
│   │   │   └── platform_secure_key_storage.dart # Keychain/Keystore
│   │   └── http/
│   │       └── secure_http_client.dart         # SSL Pinning + retry
│   ├── repositories/
│   │   └── chat_repository_impl.dart           # Offline-first logic
│   └── providers/
│       └── core_providers.dart                 # Riverpod setup
│
├── auth/                            # Экраны авторизации
├── screens/                         # UI экраны
├── models/                          # Data models (не меняются)
├── theme/                           # Theme system
└── utils/                           # Utilities
```

---

## 🔄 Миграция существующего кода

### Step 1: Обновить pubspec.yaml

Добавить зависимости:
```yaml
dependencies:
  # Offline storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Security
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.1.0
  pointycastle: ^3.7.0
  
  # SSL Pinning & HTTP
  dio: ^5.3.0
  dio_smart_retry: ^5.2.0
  
  # State management (уже есть)
  flutter_riverpod: ^2.4.0
```

### Step 2: Инициализировать Hive и Security

В `main.dart`:
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'data/providers/core_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Security & HTTP client
  await SecureHttpClient.initialize();
  
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}
```

### Step 3: Переписать существующие провайдеры

**Старый способ:**
```dart
final chatsProvider = StreamProvider<List<Chat>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  // ...direct Firestore query
});
```

**Новый способ:**
```dart
final userChatsProvider = StreamProvider.family<List<Chat>, String>((ref, userId) async* {
  // Используем репозиторий с offline поддержкой
  final chatRepo = ref.watch(chatRepositoryProvider);
  await for (final chats in chatRepo.watchChats(userId)) {
    yield chats;
  }
});

// В UI:
ref.watch(userChatsProvider(currentUserId))
```

### Step 4: Переписать экраны

**Старый ChatScreen:**
```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    return StreamBuilder(
      stream: firestore
          .collection('chats')
          .where('participants', arrayContains: uid)
          .snapshots(),
      builder: (context, snapshot) {
        // ...rendering
      }
    );
  }
}
```

**Новый ChatScreen:**
```dart
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.whenData((user) {
      if (user == null) return const AuthScreen();
      
      final chatsAsync = ref.watch(userChatsProvider(user.uid));
      
      return chatsAsync.when(
        data: (chats) => _buildChatList(chats),
        loading: () => const LoadingWidget(),
        error: (err, stack) => _buildErrorWidget(err),
      );
    }).whenData((screen) {
      return screen;
    });
  }
}
```

### Step 5: Миграция отправки сообщений

**Старый способ:**
```dart
await ChatService.sendMessage(chatId, message);
```

**Новый способ:**
```dart
final result = await ref.read(chatRepositoryProvider).sendMessage(
  chatId,
  message,
);

result.fold(
  onSuccess: (_) => showSnackBar('Message sent'),
  onFailure: (failure) => showSnackBar(failure.message),
);
```

---

## 🔐 Использование Security Service

### Генерация ключей (первый запуск):
```dart
final security = await ref.watch(securityServiceProvider.future);
final result = await security.generateAndStoreKeyPair();

if (result.isSuccess) {
  print('Keys stored securely in Keychain/Keystore');
}
```

### Шифрование сообщения:
```dart
final security = await ref.watch(securityServiceProvider.future);

final encrypted = await security.encryptMessage(
  "Hello, DarkKick!",
  recipientUserId: "user123",
);

encrypted.fold(
  onSuccess: (ciphertext) => sendToFirestore(ciphertext),
  onFailure: (failure) => showError(failure.message),
);
```

### Расшифровка с биометрией:
```dart
final security = await ref.watch(securityServiceProvider.future);

// Требует отпечатка пальца / Face ID
final privateKeyResult = await security.getPrivateKey(
  requireBiometric: true,
);

privateKeyResult.fold(
  onSuccess: (key) {
    // Используем приватный ключ для расшифровки
  },
  onFailure: (failure) => showError('Not authenticated'),
);
```

---

## 🔍 Отладка и логирование

### Просмотр локальных данных:
```dart
final local = await ref.watch(localDataSourceProvider.future);
final allChats = await local.getAllChats();
print('Cached chats: ${allChats.length}');
```

### Мониторинг ошибок:
```dart
final error = ref.watch(errorNotifierProvider);
if (error != null) {
  print('Error: ${error.message} (${error.code})');
}
```

### Отключить SSL Pinning для локальной разработки:
```dart
// В secure_http_client.dart
if (kDebugMode) {
  // Skip certificate validation in debug
  return true;
}
```

---

## 📱 Тестирование оффлайн режима

1. **Включить режим полета** в эмуляторе
2. **Отправить сообщение** - оно сохранится локально
3. **Выключить режим полета** - сообщение синхронизируется
4. **Проверить Hive** локальный кеш

---

## ⚠️ Важные замечания

### Bezopasnost:
- ✅ Приватные ключи **никогда** не покидают устройство
- ✅ Hive можно зашифровать с помощью `encryptionKey`
- ✅ SSL Pinning защищает от MITM
- ❌ НЕ логируйте приватные ключи!
- ❌ НЕ отправляйте ключи на сервер!

### Производительность:
- Первый запуск Hive занимает время
- Используйте пагинацию для больших списков
- Кешируйте изображения пользователей

### Совместимость:
- Старые данные Firestore будут в sync с Hive
- Нужны миграции для данных, которые изменили структуру
- Используйте `Timestamp` для дат в Firestore

---

## 🚀 Градуальная миграция

**Фаза 1 (текущий PR):** Создать инфраструктуру, оставить старые экраны работающими

**Фаза 2:** Мигрировать экраны чатов (ChatScreen, SingleChatScreen)

**Фаза 3:** Мигрировать авторизацию (AuthScreen, AuthProvider)

**Фаза 4:** Мигрировать профиль (UserProfileScreen, SettingsScreen)

**Фаза 5:** Удалить старые Services (ChatService, UserService)

---

## 📚 Дополнительные ресурсы

- [Repository Pattern](https://resocoder.com/flutter-clean-architecture)
- [Result Types in Dart](https://dart.dev/guides/language/records)
- [Riverpod Documentation](https://riverpod.dev)
- [Hive Offline-first](https://docs.hivedb.dev)
- [SSL Pinning Best Practices](https://owasp.org/www-community/Pinning_Cheat_Sheet)

---

## ✅ Чек-лист для code review

- [ ] Все новые файлы в правильной иерархии
- [ ] Нет прямых импортов Firestore в UI коде
- [ ] Ошибки обрабатываются через AppFailure
- [ ] Логирование не содержит чувствительных данных
- [ ] Тесты написаны для Repository слоя
- [ ] Документация обновлена
- [ ] Нет утечек памяти (проверить StreamSubscriptions)

---

**Автор:** GitHub Copilot  
**Дата:** 2026-03-01  
**Версия:** 1.0
