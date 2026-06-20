import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import 'auth_provider.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final authRepo = ref.watch(authRepositoryProvider);
  try {
    final map = await authRepo.getUserProfile(user.id);
    return UserProfile.fromMap(map);
  } catch (e) {
    // Fallback in case user database entry is not created yet
    return UserProfile(id: user.id, email: user.email ?? '');
  }
});
