import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../../auth/data/models/user_profile_model.dart';
import '../../auth/domain/entities/user_profile.dart';

abstract class MemberRepository {
  Future<Either<Failure, List<UserProfile>>> listMembers();
  Future<Either<Failure, void>> updateRole(String userId, UserRole role);
  Future<Either<Failure, void>> setActive(String userId, bool isActive);
}

class MemberRepositoryImpl implements MemberRepository {
  @override
  Future<Either<Failure, List<UserProfile>>> listMembers() async {
    try {
      final rows = await SupabaseService.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return Right((rows as List).map((r) => UserProfileModel.fromJson(r)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRole(String userId, UserRole role) async {
    try {
      // RLS policy `profiles_role_update_policy` restricts this column update
      // to callers whose own role is owner/admin — enforced server-side, not
      // just hidden client-side, so this call fails safely for non-admins.
      await SupabaseService.client.from('profiles').update({'role': role.name}).eq('id', userId);
      return const Right(null);
    } catch (e) {
      return Left(PermissionFailure('Could not update role: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setActive(String userId, bool isActive) async {
    try {
      await SupabaseService.client.from('profiles').update({'is_active': isActive}).eq('id', userId);
      return const Right(null);
    } catch (e) {
      return Left(PermissionFailure('Could not update status: $e'));
    }
  }
}
