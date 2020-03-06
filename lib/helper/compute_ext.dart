import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';
import 'dart:ffi';
import 'package:mikack/models.dart' as models;

class ComputeController {
  ComputeController(this.isolate, this.resultPort, this.errorPort,
      this.debugLabel, this.flowId);

  final Isolate isolate;
  final ReceivePort resultPort;
  final ReceivePort errorPort;
  final String debugLabel;
  final int flowId;
}

Future<ComputeController> createComputeController<Q, R>(
    ComputeCallback<Q, R> callback, Q message,
    {String debugLabel}) async {
  debugLabel ??= kReleaseMode ? 'compute' : callback.toString();
  final Flow flow = Flow.begin();
  Timeline.startSync('$debugLabel: start', flow: flow);
  final ReceivePort resultPort = ReceivePort();
  final ReceivePort errorPort = ReceivePort();
  Timeline.finishSync();
  Isolate isolate = await Isolate.spawn<_IsolateConfiguration<Q, FutureOr<R>>>(
    _spawn,
    _IsolateConfiguration<Q, FutureOr<R>>(
      callback,
      message,
      resultPort.sendPort,
      debugLabel,
      flow.id,
    ),
    errorsAreFatal: true,
    onExit: resultPort.sendPort,
    onError: errorPort.sendPort,
  );
  return ComputeController(isolate, resultPort, errorPort, debugLabel, flow.id);
}

Future<R> controllableCompute<Q, R>(ComputeController controller) async {
  final Completer<R> result = Completer<R>();
  controller.errorPort.listen((dynamic errorData) {
    assert(errorData is List<dynamic>);
    assert(errorData.length == 2);
    final Exception exception = Exception(errorData[0]);
    final StackTrace stack = StackTrace.fromString(errorData[1] as String);
    if (result.isCompleted) {
      Zone.current.handleUncaughtError(exception, stack);
    } else {
      result.completeError(exception, stack);
    }
  });
  Tuple2<String, TaskCommand> command;
  controller.resultPort.listen((dynamic data) {
    if (data is Tuple2<String, TaskCommand>)
      command = data;
    else if (!result.isCompleted) result.complete(data as R);
  });
  await result.future;
  // 任务结束执行命令
  if (command != null) {
    switch (command.item1) {
      case 'free':
        command.item2.free();
    }
  }
  Timeline.startSync('${controller.debugLabel}: end',
      flow: Flow.end(controller.flowId));
  controller.resultPort.close();
  controller.errorPort.close();
  controller.isolate.kill();
  Timeline.finishSync();
  return result.future;
}

@immutable
class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
    this.callback,
    this.message,
    this.resultPort,
    this.debugLabel,
    this.flowId,
  );

  final ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;
  final int flowId;

  FutureOr<R> apply() => callback(message);
}

Future<void> _spawn<Q, R>(
    _IsolateConfiguration<Q, FutureOr<R>> configuration) async {
  R result;
  await Timeline.timeSync(
    configuration.debugLabel,
    () async {
      final FutureOr<R> applicationResult = await configuration.apply();
      result = await applicationResult;
    },
    flow: Flow.step(configuration.flowId),
  );
  Timeline.timeSync(
    '${configuration.debugLabel}: returning result',
    () {
      configuration.resultPort.send(result);
    },
    flow: Flow.step(configuration.flowId),
  );
}

abstract class TaskCommand {
  void free();
}

class ValuePageIterator implements TaskCommand {
  ValuePageIterator(this.createdIterPointerAddress, this.iterPointerAddress);

  final int createdIterPointerAddress;
  final int iterPointerAddress;

  models.PageIterator asPageIterator() {
    return models.PageIterator(
        Pointer.fromAddress(this.createdIterPointerAddress),
        Pointer.fromAddress(this.iterPointerAddress));
  }

  @override
  void free() {
    asPageIterator().free();
  }
}

extension PageInteratorCopyable on models.PageIterator {
  ValuePageIterator asValuePageInaterator() {
    return ValuePageIterator(
        this.createdIterPointer.address, this.iterPointer.address);
  }
}
