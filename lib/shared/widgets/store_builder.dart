import 'package:flutter/widgets.dart';

import '../../app/demo/catudy_demo_store.dart';

class StoreBuilder extends StatelessWidget {
  const StoreBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, CatudyDemoStore store) builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: catudyDemoStore,
      builder: (context, _) => builder(context, catudyDemoStore),
    );
  }
}
