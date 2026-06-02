# 🚀 QUICK START GUIDE - Новая архитектура DarkKick

## ⚡ За 10 минут

### 1️⃣ Добавить зависимости
```bash
# Обновите pubspec.yaml (см. PUBSPEC_UPDATES.txt)
flutter pub get
dart run build_runner build
```

### 2️⃣ Инициализировать в main.dart
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'data/datasources/http/secure_http_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализировать Hive
  await Hive.initFlutter();
  
  // Инициализировать Firebase
  await Firebase.initializeApp();
  
  // Инициализировать HTTP client с SSL pinning
  await SecureHttpClient.initialize();
  
  // Инициализировать security keys (опционально)
  // WidgetsBinding.instance.addPostFrameCallback((_) async {
  //   final security = SecurityServiceImpl(...);
  //   await security.generateAndStoreKeyPair();
  // });
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### 3️⃣ Использовать Repository (вместо прямых Firestore вызовов)

**Старый способ ❌:**
```dart
final snapshot = await firestore
    .collection('chats')
    .where('participants', arrayContains: userId)
    .get();
```

**Новый способ ✅:**
```dart
final result = await repository.getChats(userId);

result.fold(
  onSuccess: (chats) => print('${chats.length} chатов'),
  onFailure: (error) => print('Ошибка: ${error.message}'),
);
```

### 4️⃣ Использовать Offline-first
```dart
// Это просто работает автоматически!
// - Сначала возвращает кеш (быстро)
// - Потом синхронизирует с серваком
// - Показывает кеш даже офлайн

final chats = await repository.getChats(userId);
```

### 5️⃣ Отправить секретное сообщение
```dart
// Шифрование автоматически!
final encrypted = await security.encryptMessage(
  "DarkKick Secret", 
  recipientId: "user123"
);

await repository.sendMessage(chatId, Message(
  text: encrypted.value, // использовать зашифрованный текст
  isEncrypted: true,
));
```

---

## 📊 Сравнение: Старое vs Новое

| Функция | Старая архитектура | Новая архитектура |
|---------|-------------------|-------------------|
| **Офлайн** | ❌ Не работает | ✅ Полная поддержка через Hive |
| **Ошибки** | String messages | ✅ Typed Result<T> |
| **Безопасность** | ❌ Ключи в памяти | ✅ Keychain/Keystore + SSL pinning |
| **Кеш** | ❌ Нет | ✅ Автоматический |
| **Тестируемость** | 😞 Сложно | ✅ Легко мокировать |
| **Масштабируемость** | 😞 Хардкод | ✅ Паттерны |

---

## 🔒 Как включить Security

### Первый запуск: Сгенерировать ключи

```dart
// В SplashScreen или после авторизации
final security = SecurityServiceImpl(keyStorage: storage);

final result = await security.generateAndStoreKeyPair();
if (result.isSuccess) {
  print('✅ Ключи сгенерированы и сохранены');
} else {
  print('❌ Ошибка: ${result.fold(onSuccess: (_) => '', onFailure: (f) => f.message)}');
}
```

### Шифрование сообщение

```dart
final encrypted = await security.encryptMessage(
  "DarkKick Mode Activated", 
  recipientUserId: "friend_id"
);

// Отправить encrypted.value в Firestore
```

### Расшифровка (с биометрией)

```dart
// Требует сканирование отпечатка / Face ID
final decrypted = await security.decryptMessage(encryptedText);

// Теперь можно показать пользователю
```

---

## 🏗️ Структура кода

```
ВЫ ПИШИТЕ:         | СИСТЕМА ДЕЛАЕТ:
─────────────────────────────────────────────────
Экран (UI)         | Repository.getChats() ─┐
                                            │
                   Проверка: Есть ли локально?
                                            │
                   ├─ ДА: возвращаем кеш   
                   │  (+ синхро в фоне)
                   │
                   └─ НЕТ: запрос Firestore
                      + сохранение в Hive

ВЫ НЕ ИСПОЛЬЗУЕТЕ:
- Прямые Firestore queries
- ChatService.sendMessage
- UserService.getUser
- Строки ошибок
```

---

## 🧪 Тестирование офлайн

**Способ 1: Режим полета**
1. Включить режим полета в телефоне
2. Открыть чат - видим кеш
3. Отправить сообщение - сохраняется локально
4. Выключить полет - сообщение отправляется

**Способ 2: Отключить WiFi/мобу**
- То же самое, но с вай-фаем

**Способ 3: Proxy перехват (для отладки)**
```dart
// В secure_http_client.dart для отладки:
if (kDebugMode) {
  return true; // Пропустить SSL check для Charles/Fiddler
}
```

---

## ⚠️ Частые ошибки

### ❌ Прямой вызов Firestore
```dart
// НЕПРАВИЛЬНО!
firestore.collection('chats').snapshots();
```

### ✅ Через Repository
```dart
// ПРАВИЛЬНО!
repository.watchChats(userId);
```

---

### ❌ Ловить Exception
```dart
try {
  await repository.sendMessage(...);
} catch (e) {
  // Result уже обработал ошибку!
}
```

### ✅ Использовать Result
```dart
final result = await repository.sendMessage(...);
result.fold(
  onSuccess: (_) => showSnackBar("Отправлено"),
  onFailure: (f) => showSnackBar(f.message),
);
```

---

### ❌ Логировать ключи
```dart
appLogger.d('Private key: $privateKey'); // НИКОГДА!
```

### ✅ Логировать события
```dart
appLogger.i('Message encrypted successfully');
appLogger.e('Encryption failed', error: e);
```

---

## 📱 Миграция экранов

### ChatScreen → ChatScreenRefactored

**Старый:**
```dart
StreamBuilder(
  stream: firestore.collection('chats').snapshots(),
  builder: (_, snapshot) { ... }
)
```

**Новый (см. chat_screen_refactored.dart):**
```dart
ConsumerWidget with ref.watch(userChatsProvider(userId))
```

### Для каждого экрана:
1. Скопировать pattern из `chat_screen_refactored.dart`
2. Заменить `StreamBuilder` на `AsyncValue.when`
3. Использовать `ref.watch(provider)` вместо прямых Firestore запросов
4. Обработать error states

---

## 🔍 Отладочные команды

### Посмотреть локальные данные
```bash
flutter pub add hive_explorer
# В коде добавить:
await openHiveExplorer(context);
```

### Мониторить Firestore + Hive sync
```dart
// Добавить логирование в ChatRepositoryImpl
appLogger.d('Cache: ${localChats.length}, Remote: ${remoteChats.length}');
```

### Проверить SSL pinning
```bash
# Используйте Charles Proxy или Fiddler
# Попробуйте перехватить HTTPS - должна быть ошибка
```

---

## 🎯 Следующие шаги

### Week 1: Инфраструктура (ЭТА PR)
- [x] Repository Pattern готов
- [x] Offline caching готов
- [x] Security Service готова
- [ ] Старые экраны пока еще работают

### Week 2: Миграция UI
- [ ] ChatScreen → ChatScreenRefactored
- [ ] SingleChatScreen → новая версия
- [ ] Тестирование офлайн

### Week 3: Финализация
- [ ] ProfileScreen + SettingsScreen
- [ ] DeleteOldServices
- [ ] Полное тестирование

---

## 💬 FAQ

**Q: Будут ли мои старые экраны работать?**  
A: ✅ Да! Старые экраны работают параллельно. Можно мигрировать постепенно.

**Q: Где хранятся приватные ключи?**  
A: 🔒 В iOS Keychain / Android Keystore - защищено ОС.

**Q: Работает ли без интернета?**  
A: ✅ Да! Hive кеширует локально, syncs при подключении.

**Q: Нужно ли менять Firestore правила?**  
A: ❌ Нет. Repository работает с текущими правилами.

**Q: Как тестировать?**  
A: Включить режим полета, открыть чат - видите кеш.

---

## 📚 Полная документация

См. `REFACTORING_GUIDE.md` для:
- Полной архитектуры
- Примеров для каждого экрана
- Troubleshooting guide

---

**Happy refactoring! 🚀**

Created: 2026-03-01  
Version: 1.0
