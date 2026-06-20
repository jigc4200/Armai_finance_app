import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import '../services/offline_cache_service.dart';
import 'auth_provider.dart';

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  static const _cacheBucket = 'user_profile';

  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final cache = OfflineCacheService.instance;
    final cached = await cache.readMap(user.id, _cacheBucket);
    final cachedProfile = cached == null ? null : UserProfile.fromMap(cached);
    if (cachedProfile != null) {
      state = AsyncData(cachedProfile);
    }

    final authRepo = ref.watch(authRepositoryProvider);
    try {
      final map = await authRepo.getUserProfile(user.id);
      final fresh = UserProfile.fromMap(map);
      await cache.saveMap(user.id, _cacheBucket, fresh.toMap());
      return fresh;
    } catch (error, stackTrace) {
      if (cachedProfile != null) return cachedProfile;

      // Fallback in case user database entry is not created yet.
      if (user.email != null) {
        return UserProfile(id: user.id, email: user.email!);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(() {
      return UserProfileNotifier();
    });
