import 'dart:async';

import 'package:flutter/widgets.dart';

import 'list_notifier.dart';

typedef ValueBuilderUpdateCallback<T> = void Function(T snapshot);
typedef ValueBuilderBuilder<T> = Widget Function(
    T snapshot, ValueBuilderUpdateCallback<T> updater);

/// Manages a local state like ObxValue, but uses a callback instead of
/// a Rx value.
///
/// Example:
/// ```
///  ValueBuilder<bool>(
///    initialValue: false,
///    builder: (value, update) => Switch(
///    value: value,
///    onChanged: (flag) {
///       update( flag );
///    },),
///    onUpdate: (value) => print("Value updated: $value"),
///  ),
///  ```
class ValueBuilder<T> extends StatefulWidget {
  final T initialValue;
  final ValueBuilderBuilder<T> builder;
  final void Function()? onDispose;
  final void Function(T)? onUpdate;

  const ValueBuilder({
    Key? key,
    required this.initialValue,
    this.onDispose,
    this.onUpdate,
    required this.builder,
  }) : super(key: key);

  @override
  _ValueBuilderState<T> createState() => _ValueBuilderState<T>(initialValue);
}

class _ValueBuilderState<T> extends State<ValueBuilder<T>> {
  T value;
  _ValueBuilderState(this.value);


  @override
  Widget build(BuildContext context) => widget.builder(value, updater);

  void updater(T newValue) {
    if (widget.onUpdate != null) {
      widget.onUpdate!(newValue);
    }
    setState(() {
      value = newValue;
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.onDispose?.call();
    if (value is ChangeNotifier) {
      (value as ChangeNotifier?)?.dispose();
    } else if (value is StreamController) {
      (value as StreamController?)?.close();
    }
  }
}

class ObxElement = StatelessElement with ObserverComponent;

// It's a experimental feature
class Observer extends ObxStatelessWidget {
  final WidgetBuilder builder;

  const Observer({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context);
}

/// A StatelessWidget than can listen reactive changes.
abstract class ObxStatelessWidget extends StatelessWidget {
  /// Initializes [key] for subclasses.
  const ObxStatelessWidget({Key? key}) : super(key: key);
  @override
  StatelessElement createElement() => ObxElement(this);
}

/// a Component that can track changes in a reactive variable
mixin ObserverComponent on ComponentElement {
  final disposers = <Disposer>[];

  @override
  Widget build() =>
      NotifierManager.instance.exchange(disposers, markNeedsBuild, super.build);

  @override
  void unmount() {
    super.unmount();
    for (final disposer in disposers) {
      disposer();
    }
  }
}
