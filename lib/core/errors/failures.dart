import 'package:equatable/equatable.dart';

/// Base failure type returned by repositories (right-hand side error in
/// Either<Failure, T> using dartz). UI layers map these to human copy.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection. Check your network and try again.'])
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class InviteFailure extends Failure {
  const InviteFailure(super.message, {super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Could not read local data.']) : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Something went wrong. Please try again.']) : super(message);
}

/// Exceptions thrown at the data-source layer, caught by repositories and
/// converted into Failures for the domain layer.
class ServerException implements Exception {
  final String message;
  final String? code;
  ServerException(this.message, {this.code});
}

class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException(this.message, {this.code});
}

class InviteException implements Exception {
  final String message;
  final String? code;
  InviteException(this.message, {this.code});
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error']);
}
