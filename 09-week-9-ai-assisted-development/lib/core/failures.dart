/// Core failure representations across the application (Pure Dart - No Flutter dependency)
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
