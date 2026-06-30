import 'package:flutter/material.dart';

/// Convenience wrapper using Flutter's RadioGroup (Material 3.32+)
class RadioGroupWidget<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final List<RadioGroupItem<T>> items;

  const RadioGroupWidget({
    Key? key,
    required this.groupValue,
    required this.onChanged,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      onChanged: onChanged,
      child: Column(
        children: items
            .map((item) => RadioListTile<T>(
                  value: item.value,
                  title: Text(item.title),
                ))
            .toList(),
      ),
    );
  }
}

/// Individual radio item configuration
class RadioGroupItem<T> {
  final T value;
  final String title;

  RadioGroupItem({
    required this.value,
    required this.title,
  });
}

/// Alternative: A more flexible RadioGroup that accepts custom builders
class RadioGroupBuilder<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final List<T> items;
  final Widget Function(BuildContext, T, bool) itemBuilder;

  const RadioGroupBuilder({
    Key? key,
    required this.groupValue,
    required this.onChanged,
    required this.items,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      onChanged: onChanged,
      child: Column(
        children: items
            .map((item) => RadioListTile<T>(
                  value: item,
                  title: itemBuilder(context, item, item == groupValue),
                ))
            .toList(),
      ),
    );
  }
}
