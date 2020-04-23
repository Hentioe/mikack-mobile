import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

const noneError = ErrorWrapper(error: false);

class ErrorWrapper extends Equatable {
  final bool error;
  final String message;

  const ErrorWrapper({@required this.error, this.message});

  @override
  List<Object> get props => [error, message];

  factory ErrorWrapper.none() => const ErrorWrapper(error: false);

  factory ErrorWrapper.message(String message) =>
      ErrorWrapper(error: true, message: message);
}
