import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

const noneError = ErrorWrapper(failed: false);

class ErrorWrapper extends Equatable {
  final bool failed;
  final String message;

  const ErrorWrapper({@required this.failed, this.message});

  @override
  List<Object> get props => [failed, message];

  factory ErrorWrapper.none() => const ErrorWrapper(failed: false);

  factory ErrorWrapper.message(String message) =>
      ErrorWrapper(failed: true, message: message);
}
